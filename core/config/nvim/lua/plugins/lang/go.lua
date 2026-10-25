local deps = require("config.deps")

return {
    {
        "olexsmir/gopher.nvim",
        enabled = deps.has_go,
        ft = "go",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
        opts = {},
        build = ":GoInstallDeps",
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                gopls = {
                    enabled = deps.has_go,
                },
            },
        },
    },
}
