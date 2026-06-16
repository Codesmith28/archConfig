return {
    {
        "stevearc/conform.nvim",
        opts = {
            default_format_opts = {
                timeout_ms = 10000,
                lsp_format = "fallback",
            },
            formatters_by_ft = {
                lua = { "stylua" },
                -- Java is explicitly removed from here so LazyVim natively routes it to JDTLS
            },
        },
    },
}