return {
    {
        "hedyhli/outline.nvim",
        lazy = true,
        cmd = { "Outline", "OutlineOpen" },
        keys = {
            { "<leader>o", "<cmd>Outline<CR>", desc = "Toggle outline" },
        },
        opts = {
            symbol_folding = {
                autofold_depth = 2,
            },
            outline_window = {
                auto_jump = true,
                width = 20,
            },
            guides = {
                markers = {
                    middle = "⎬",
                    bottom = "⎩",
                    vertical = "⎥",
                },
            },
        },
    },
    {
        "nvim-tree/nvim-tree.lua",
        cmd = { "NvimTreeToggle", "NvimTreeFocus" },

        opts = function()
            return require "configs.nvimtree"
        end,
        config = function(_, opts)
            require("nvim-tree").setup(opts)
        end,
    },
    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown" },
        -- dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
        -- dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" }, -- if you use standalone mini plugins
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
        ---@module 'render-markdown'
        -- -@type render.md.UserConfig,
        opts = {},
    },
}
