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
        lsp_fallback = true,
      },
    },
  },
}