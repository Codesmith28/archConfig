return {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {},
    dependencies = {
        "rcarriga/nvim-notify",
    },
    config = function()
        require "configs.noice"
    end,
}
