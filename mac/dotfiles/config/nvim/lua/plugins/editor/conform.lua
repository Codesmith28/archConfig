return {
    "stevearc/conform.nvim",
    event = "VeryLazy",
    opts = {
        default_format_opts = {
            timeout_ms = 10000,
            lsp_format = "fallback",
        },
        formatters_by_ft = {
            c = { "clang-format" },
            cpp = { "clang-format" },
            javascript = { "prettier" },
            typescript = { "prettier" },
            json = { "prettier" },
            python = { "black", "isort" },
            java = { "google-java-format" },
            lua = { "stylua" },
            go = { "goimports-reviser", "gofumpt" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            ["_"] = { "trim_whitespace" }, -- Conform has built-in whitespace trimming
        },
        formatters = {
            ["google-java-format"] = {
                prepend_args = { "--aosp" },
            },
        },
    },
}
