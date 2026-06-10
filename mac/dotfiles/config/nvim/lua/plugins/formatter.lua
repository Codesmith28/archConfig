return {
    "mhartington/formatter.nvim",
    event = "VeryLazy",
    opts = function()
        return {
            default_format_opts = {
                timeout_ms = 10000,
                lsp_format = "fallback",
            },
            filetype = {
                javascript = {
                    require("formatter.filetypes.javascript").prettier,
                },
                typescript = {
                    require("formatter.filetypes.typescript").prettier,
                },
                python = {
                    require("formatter.filetypes.python").black,
                    require("formatter.filetypes.python").isort,
                },
                ["*"] = {
                    require("formatter.filetypes.any").remove_trailing_whitespace,
                },
            },
        }
    end,
}
