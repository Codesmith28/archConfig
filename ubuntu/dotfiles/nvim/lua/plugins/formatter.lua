return {
    "mhartington/formatter.nvim",
    event = "VeryLazy",
    opts = function()
        return require "configs.formatter"
    end,
}
