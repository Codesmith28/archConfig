local cf_cache = {}

local function sync_clang_format(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
        return
    end
    local file = vim.api.nvim_buf_get_name(buf)
    local dir = file ~= "" and vim.fs.dirname(file) or vim.uv.cwd()
    local cf = vim.fs.find(".clang-format", { upward = true, path = dir })[1]
    if not cf then
        return
    end

    local stat = vim.uv.fs_stat(cf)
    local mtime = stat and stat.mtime.sec or 0
    if not cf_cache[cf] or cf_cache[cf].mtime ~= mtime then
        local assume = file ~= "" and file or (vim.fs.dirname(cf) .. "/dummy.cpp")
        local out = vim.fn.system({ "clang-format", "-assume-filename=" .. assume, "--dump-config" })
        if vim.v.shell_error ~= 0 or not out or out == "" then
            return
        end

        local indent = tonumber(out:match("\nIndentWidth:%s*(%d+)")) or 4
        local use_tab = out:match("\nUseTab:%s*(%w+)") or "Never"
        local is_spaces = (use_tab == "Never")
        local tab = is_spaces and indent or (tonumber(out:match("\nTabWidth:%s*(%d+)")) or indent)
        local access = out:match("\nAccessModifierOffset:%s*(-?%d+)") or "-2"

        local cin = { ":" .. access, "g" .. access }
        if out:match("\nIndentCaseLabels:%s*true") then
            table.insert(cin, "l1")
        end
        if (out:match("\nNamespaceIndentation:%s*(%w+)") or "None") == "None" then
            table.insert(cin, "N-s")
        end
        table.insert(cin, "(0")
        table.insert(cin, "W" .. indent)

        cf_cache[cf] = {
            mtime = mtime,
            indent = indent,
            tab = tab,
            is_spaces = is_spaces,
            cinoptions = table.concat(cin, ","),
        }
    end

    local cfg = cf_cache[cf]
    if cfg then
        vim.b[buf].sleuth_automatic = 0
        vim.bo[buf].shiftwidth = cfg.indent
        vim.bo[buf].softtabstop = cfg.indent
        vim.bo[buf].tabstop = cfg.tab
        vim.bo[buf].expandtab = cfg.is_spaces
        vim.bo[buf].cinoptions = cfg.cinoptions
    end
end

return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            inlay_hints = {
                enabled = true,
            },
            servers = {
                clangd = {
                    cmd = {
                        "clangd",
                        "--background-index",
                        "--clang-tidy",
                        "--header-insertion=iwyu",
                        "--completion-style=detailed",
                        "--function-arg-placeholders=true",
                        "--fallback-style=llvm",
                        "--query-driver=/opt/homebrew/bin/g++*,/opt/homebrew/bin/clang++*,/usr/bin/g++*,/usr/bin/clang++*,/usr/local/bin/g++*,/usr/local/bin/clang++*",
                    },
                    root_markers = {
                        ".clang-format",
                        ".clangd",
                        ".clang-tidy",
                        "compile_commands.json",
                        "compile_flags.txt",
                        "configure.ac",
                        "Makefile",
                        "meson.build",
                        "build.ninja",
                        ".git",
                    },
                    capabilities = {
                        offsetEncoding = { "utf-16" },
                    },
                    init_options = {
                        usePlaceholders = true,
                        completeUnimported = true,
                        clangdFileStatus = true,
                    },
                    settings = {
                        clangd = {
                            InlayHints = {
                                Designators = true,
                                Enabled = true,
                                ParameterNames = true,
                                DeducedTypes = true,
                                BlockEnd = true,
                                DefaultArguments = true,
                                TypeNameLimit = 0,
                            },
                        },
                    },
                },
            },
        },
    },
    {
        "stevearc/conform.nvim",
        optional = true,
        init = function()
            local group = vim.api.nvim_create_augroup("ClangFormatSync", { clear = true })

            -- Format C/C++ buffers on open with nearest .clang-format and sync indent
            vim.api.nvim_create_autocmd("BufReadPost", {
                group = group,
                pattern = { "*.c", "*.cpp", "*.cc", "*.cxx", "*.h", "*.hpp", "*.cu" },
                callback = function(args)
                    pcall(function()
                        require("conform").format({ bufnr = args.buf }, function()
                            sync_clang_format(args.buf)
                        end)
                    end)
                    sync_clang_format(args.buf)
                end,
            })

            -- Dynamically sync indent on buffer focus / filetype
            vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "FocusGained" }, {
                group = group,
                pattern = { "c", "cpp", "objc", "objcpp", "cuda", "*.c", "*.cpp", "*.cc", "*.cxx", "*.h", "*.hpp", "*.cu" },
                callback = function(args)
                    sync_clang_format(args.buf)
                end,
            })

            -- Sync indent whenever Conform finishes formatting
            vim.api.nvim_create_autocmd("User", {
                group = group,
                pattern = "ConformFormatPost",
                callback = function(args)
                    local buf = args.data and args.data.bufnr or vim.api.nvim_get_current_buf()
                    sync_clang_format(buf)
                end,
            })

            -- Invalidate cache and update all buffers when .clang-format is saved
            vim.api.nvim_create_autocmd("BufWritePost", {
                group = group,
                pattern = { "*/.clang-format", ".clang-format" },
                callback = function()
                    cf_cache = {}
                    for _, b in ipairs(vim.api.nvim_list_bufs()) do
                        if vim.api.nvim_buf_is_loaded(b) then
                            sync_clang_format(b)
                        end
                    end
                end,
            })
        end,
    },
}
