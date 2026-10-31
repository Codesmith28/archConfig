local deps = require("config.deps")

local function get_gpp_compiler()
    for v = 25, 11, -1 do
        local candidates = {
            "/opt/homebrew/bin/g++-" .. v,
            "/usr/local/bin/g++-" .. v,
            "/usr/bin/g++-" .. v,
            "g++-" .. v,
        }
        for _, path in ipairs(candidates) do
            if vim.fn.executable(path) == 1 then
                return path
            end
        end
    end

    local fallbacks = {
        "/opt/homebrew/bin/g++",
        "/usr/local/bin/g++",
        "/usr/bin/g++",
        "g++",
        "/usr/bin/clang++",
        "clang++",
    }
    for _, path in ipairs(fallbacks) do
        if vim.fn.executable(path) == 1 then
            return path
        end
    end

    return "g++"
end

-- Directory to store compiled binaries (out files) to prevent repo clutter
local out_dir = ".bin"

local function ensure_out_dir()
    local buf_dir = vim.fn.expand("%:p:h")
    if buf_dir and buf_dir ~= "" and vim.fn.isdirectory(buf_dir) == 1 then
        local target = buf_dir .. "/" .. out_dir
        if vim.fn.isdirectory(target) == 0 then
            vim.fn.mkdir(target, "p")
        end
    end

    local cwd = vim.fn.getcwd()
    local cwd_target = cwd .. "/" .. out_dir
    if vim.fn.isdirectory(cwd_target) == 0 then
        vim.fn.mkdir(cwd_target, "p")
    end
end

-- Prevent LSP and auto-formatters from crashing assistant.nvim testcase buffers
local assistant_group = vim.api.nvim_create_augroup("assistant_buffers", { clear = true })
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = assistant_group,
    pattern = "*",
    callback = function(args)
        local buf_name = vim.api.nvim_buf_get_name(args.buf)
        local filetype = vim.api.nvim_get_option_value("filetype", { buf = args.buf })
        local is_modifiable = vim.api.nvim_get_option_value("modifiable", { buf = args.buf })

        -- target assistant.nvim buffers or any non-modifiable UI buffers
        if string.match(buf_name:lower(), "assistant") or filetype == "assistant" or not is_modifiable then
            vim.b[args.buf].autoformat = false

            -- forcibly detach any LSP trying to hook into the UI
            for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
                vim.lsp.buf_detach_client(args.buf, client.id)
            end
        end
    end,
})

return {
    "A7lavinraj/assistant.nvim",
    enabled = deps.has_cpp,
    lazy = false,
    keys = {
        {
            "<leader>a",
            function()
                ensure_out_dir()
                vim.cmd("Assistant")
            end,
            desc = "Assistant.nvim",
        },
    },
    opts = function()
        return {
            core = {
                port = 10043,
                default_source = "cpp",
            },
            commands = {
                cpp = {
                    extension = "cpp",
                    compile = {
                        main = get_gpp_compiler(),
                        args = {
                            "-std=c++26",
                            "-Wall",
                            "-Wextra",
                            "-D_GLIBCXX_DEBUG",
                            "$FILENAME_WITH_EXTENSION",
                            "-o",
                            out_dir .. "/$FILENAME_WITHOUT_EXTENSION",
                        },
                    },
                    execute = {
                        main = "./" .. out_dir .. "/$FILENAME_WITHOUT_EXTENSION",
                        args = {},
                    },
                },
                c = {
                    extension = "c",
                    compile = {
                        main = "gcc",
                        args = {
                            "-std=c23",
                            "-Wall",
                            "-Wextra",
                            "$FILENAME_WITH_EXTENSION",
                            "-o",
                            out_dir .. "/$FILENAME_WITHOUT_EXTENSION",
                        },
                    },
                    execute = {
                        main = "./" .. out_dir .. "/$FILENAME_WITHOUT_EXTENSION",
                        args = {},
                    },
                },
            },
        }
    end,
    config = function(_, opts)
        -- Hook utils.get_source_config to ensure out_dir exists before compile / execute
        local ok_utils, utils = pcall(require, "assistant.utils")
        if ok_utils and utils.get_source_config then
            local orig_get_source_config = utils.get_source_config
            utils.get_source_config = function(...)
                ensure_out_dir()
                return orig_get_source_config(...)
            end
        end

        -- Ensure tcp module cleanly terminates on exit
        vim.api.nvim_create_autocmd("VimLeavePre", {
            group = vim.api.nvim_create_augroup("assistant_cleanup", { clear = true }),
            callback = function()
                local ok, tcp = pcall(require, "assistant.core.tcp")
                if ok and tcp.stop_server then
                    tcp.stop_server()
                end
            end,
        })

        require("assistant").setup(opts)

        -- Re-bind :Assistant command to ensure out_dir is always created
        vim.api.nvim_create_user_command("Assistant", function()
            ensure_out_dir()
            require("assistant.builtins.__wizard").standard:show()
        end, { nargs = 0, force = true })
    end,
}
