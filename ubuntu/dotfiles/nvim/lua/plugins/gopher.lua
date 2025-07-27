return {
    "olexsmir/gopher.nvim",
    ft = "go",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
        require("gopher").setup()
    end,
    build = ":GoInstallDeps",
}
