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

local function strip_default_args(param_str)
    local res = {}
    local depth_paren = 0
    local depth_angle = 0
    local depth_brace = 0
    local in_default = false
    local in_quote = false
    local quote_char = ""

    for i = 1, #param_str do
        local c = param_str:sub(i, i)
        local prev = i > 1 and param_str:sub(i - 1, i - 1) or ""

        if in_quote then
            if c == quote_char and prev ~= "\\" then
                in_quote = false
            end
        elseif c == '"' or c == "'" then
            in_quote = true
            quote_char = c
        elseif not in_default then
            if c == "=" then
                in_default = true
            else
                table.insert(res, c)
            end
        else
            if c == "(" then
                depth_paren = depth_paren + 1
            elseif c == ")" then
                if depth_paren > 0 then
                    depth_paren = depth_paren - 1
                else
                    in_default = false
                    table.insert(res, c)
                end
            elseif c == "<" then
                depth_angle = depth_angle + 1
            elseif c == ">" then
                if depth_angle > 0 then
                    depth_angle = depth_angle - 1
                end
            elseif c == "{" then
                depth_brace = depth_brace + 1
            elseif c == "}" then
                if depth_brace > 0 then
                    depth_brace = depth_brace - 1
                end
            elseif c == "," and depth_paren == 0 and depth_angle == 0 and depth_brace == 0 then
                in_default = false
                table.insert(res, c)
            end
        end
    end
    local s = table.concat(res, "")
    s = s:gsub("%s+,", ",")
    s = s:gsub("%s+%)", ")")
    return s
end

local function clean_signature(sig)
    if not sig then
        return nil
    end
    local params, trailing = sig:match("^(%b())(.*)$")
    if not params then
        params, trailing = sig:match("(%b())(.*)$")
    end
    if not params then
        return nil
    end

    local cleaned_params = strip_default_args(params)

    trailing = trailing or ""
    trailing = trailing:gsub("%s*override%f[%A]", "")
    trailing = trailing:gsub("%s*final%f[%A]", "")
    trailing = trailing:gsub("%s*=%s*0", "")
    trailing = trailing:gsub("%s*=%s*default", "")
    trailing = trailing:gsub("%s*=%s*delete", "")
    trailing = vim.trim(trailing)

    if trailing ~= "" then
        return cleaned_params .. " " .. trailing
    else
        return cleaned_params
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
                        "--function-arg-placeholders=1",
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
                    capabilities = vim.tbl_deep_extend(
                        "force",
                        vim.lsp.protocol.make_client_capabilities(),
                        (function()
                            local ok, blink = pcall(require, "blink.cmp")
                            return ok and blink.get_lsp_capabilities() or {}
                        end)(),
                        {
                            offsetEncoding = { "utf-16" },
                        }
                    ),
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
    {
        "saghen/blink.cmp",
        opts = {
            sources = {
                providers = {
                    lsp = {
                        transform_items = function(ctx, items)
                            local cpp_fts = { c = true, cpp = true, objc = true, objcpp = true, cuda = true }
                            local ft = vim.bo[ctx.bufnr or 0].filetype
                            if not cpp_fts[ft] then
                                return items
                            end

                            local line_after_cursor = ""
                            if ctx.line and ctx.cursor and ctx.cursor[2] then
                                line_after_cursor = ctx.line:sub(ctx.cursor[2] + 1)
                            end
                            local has_paren_ahead = line_after_cursor:match("^%s*%(") ~= nil

                            for _, item in ipairs(items) do
                                -- Method (2), Function (3), Constructor (4)
                                if (item.kind == 2 or item.kind == 3 or item.kind == 4) and not has_paren_ahead then
                                    local new_text = item.textEdit and item.textEdit.newText or item.insertText or item.label
                                    if new_text and not new_text:find("%(") and item.insertTextFormat ~= 2 then
                                        local sig = nil
                                        if item.labelDetails and item.labelDetails.detail and item.labelDetails.detail:find("%(") then
                                            sig = item.labelDetails.detail
                                        elseif item.label and item.label:find("%b()") then
                                            sig = item.label
                                        end

                                        if sig then
                                            local clean_sig = clean_signature(sig)
                                            if clean_sig then
                                                if item.textEdit then
                                                    item.textEdit.newText = item.textEdit.newText .. clean_sig
                                                end
                                                if item.insertText then
                                                    item.insertText = item.insertText .. clean_sig
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            return items
                        end,
                    },
                },
            },
        },
    },
}
