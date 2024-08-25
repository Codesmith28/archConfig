return {
    {

        "stevearc/oil.nvim",
        opts = {},
        dependencies = { { "echasnovski/mini.icons", opts = {} } },
    },
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
        "mistricky/codesnap.nvim",
        lazy = false,
        build = "make build_generator",
        keys = {
            { "<leader>sc", "<cmd>CodeSnapSave<cr>", mode = "x", desc = "Save selected code snapshot in ~/Pictures" },
        },
        opts = {
            code_font_familty = "JetBrainsMono Nerd Font",
            save_path = "~/Pictures/Codesnaps",
            has_breadcrumbs = true,
            watermark = "",
            bg_color = "#535c68",
            bg_x_padding = 61,
            bg_y_padding = 41,
        },
        config = function(_, opts)
            require("codesnap").setup(opts)
        end,
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
}
