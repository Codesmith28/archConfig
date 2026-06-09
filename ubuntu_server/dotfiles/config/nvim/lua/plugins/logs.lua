return {
  "fei6409/log-highlight.nvim",
  ft = { "log" }, -- Lazy loads only when opening a .log file
  config = function()
    require("log-highlight").setup({
      -- Extension to match
      extension = "log",
      -- You can add custom keywords to highlight groups here
      keywords = {
        error = { "FATAL", "CRITICAL", "FAIL" },
        warning = { "WARN", "WARNING", "ALERT" },
        info = { "INFO", "NOTICE" },
      },
    })
  end,
}
