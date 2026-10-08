return {
    "stevearc/conform.nvim",
    opts = {
        notify_on_error = false,
        default_format_opts = {
            timeout_ms = 2000,
            lsp_format = "fallback",
        },
        formatters_by_ft = {
            c = { "clang-format" },
            cpp = { "clang-format" },
            javascript = { "prettierd", "prettier", stop_after_first = true },
            typescript = { "prettierd", "prettier", stop_after_first = true },
            json = { "prettierd", "prettier", stop_after_first = true },
            java = { "google-java-format" },
            lua = { "stylua" },
            go = { "goimports-reviser", "gofumpt" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            ["_"] = { "trim_whitespace" },
        },
        formatters = {
            ["google-java-format"] = {
                prepend_args = { "--aosp" },
            },
            ["clang-format"] = {
                cwd = require("conform.util").root_file({
                    ".clang-format",
                    ".clangd",
                    "compile_commands.json",
                    ".git",
                }),
                prepend_args = { "-style=file", "-fallback-style=none" },
            },
        },
    },
    init = function()
        -- Auto-format C/C++ buffers on open using the nearest .clang-format via conform
        vim.api.nvim_create_autocmd("BufReadPost", {
            desc = "Format C/C++ buffers on open with nearest .clang-format",
            pattern = { "*.c", "*.cpp", "*.cc", "*.cxx", "*.h", "*.hpp", "*.cu" },
            callback = function(args)
                require("conform").format({ bufnr = args.buf })
            end,
        })
    end,
}
