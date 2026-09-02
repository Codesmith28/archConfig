local function get_gpp_compiler()
    for v = 25, 11, -1 do
        local candidates = {
            "/opt/homebrew/bin/g++-" .. v,
            "/usr/local/bin/g++-" .. v,
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
        "g++",
        "clang++",
    }
    for _, path in ipairs(fallbacks) do
        if vim.fn.executable(path) == 1 then
            return path
        end
    end

    return "g++"
end

-- Prevent LSP and auto-formatters from crashing assistant.nvim testcase buffers
vim.api.nvim_create_autocmd("BufWinEnter", {
    pattern = "*",
    callback = function(args)
        local buf_name = vim.api.nvim_buf_get_name(args.buf)
        local filetype = vim.api.nvim_get_option_value("filetype", { buf = args.buf })
        local is_modifiable = vim.api.nvim_get_option_value("modifiable", { buf = args.buf })
        
        -- Target assistant.nvim buffers or any non-modifiable UI buffers
        if string.match(buf_name:lower(), "assistant") or filetype == "assistant" or not is_modifiable then
            -- 1. Disable LazyVim autoformat for this specific buffer
            vim.b[args.buf].autoformat = false
            
            -- 2. Forcibly detach any LSP trying to hook into the UI
            for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
                vim.lsp.buf_detach_client(args.buf, client.id)
            end
        end
    end,
})

return {
    "A7lavinraj/assistant.nvim",
    lazy = false,
    keys = {
        { "<leader>a", "<cmd>Assistant<cr>", desc = "Assistant.nvim" },
    },
    opts = function()
        return {
            commands = {
                cpp = {
                    extension = "cpp",
                    compile = {
                        main = get_gpp_compiler(),
                        args = {
                            "-std=c++2b",
                            "-Wall",
                            "-Wextra",
                            "-D_GLIBCXX_DEBUG",
                            "$FILENAME_WITH_EXTENSION",
                            "-o",
                            "$FILENAME_WITHOUT_EXTENSION",
                        },
                    },
                    execute = {
                        main = "./$FILENAME_WITHOUT_EXTENSION",
                        args = {},
                    },
                },
            },
        }
    end,
}
