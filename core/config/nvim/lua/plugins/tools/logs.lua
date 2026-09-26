return {
    "fei6409/log-highlight.nvim",
    ft = { "log" }, -- Lazy loads only when opening a .log file
    opts = {
        extension = "log",
        keywords = {
            error = { "FATAL", "CRITICAL", "FAIL" },
            warning = { "WARN", "WARNING", "ALERT" },
            info = { "INFO", "NOTICE" },
        },
    },
}
