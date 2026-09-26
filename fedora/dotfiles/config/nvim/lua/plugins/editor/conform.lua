return {
    "stevearc/conform.nvim",
    event = "VeryLazy",
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
        },
    },
}
