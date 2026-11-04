return {
    "stevearc/conform.nvim",
    opts = {
        notify_on_error = true,
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
                command = (function()
                    for _, path in ipairs({
                        "/usr/bin/clang-format",
                        "/opt/homebrew/bin/clang-format",
                        "/usr/local/bin/clang-format",
                    }) do
                        if vim.fn.executable(path) == 1 then
                            return path
                        end
                    end
                    return "clang-format"
                end)(),
                cwd = require("conform.util").root_file({
                    ".clang-format",
                    ".clangd",
                    "compile_commands.json",
                    ".git",
                }),
                prepend_args = { "-style=file", "-fallback-style=llvm" },
            },
        },
    },
}
