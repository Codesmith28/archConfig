return {
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        opts = {},
        dependencies = {
            "rcarriga/nvim-notify",
        },
        config = function()
            require "configs.noice"
        end,
    },
    {
        "rcarriga/nvim-notify",
        opts = {
            background_colour = "#000000",
            fps = 60,
            level = 1,
            max_height = 10,
            render = "default",
            damping = 0.7,
            timeout = 2000,
        },
        config = function(_, opts)
            require("notify").setup(opts)
        end,
    },
    {
        "echasnovski/mini.indentscope",
        version = false, -- wait till new 0.7.0 release to put it back on semver
        event = "VeryLazy",
        opts = {
            symbol = "╎",
            delay = 50,
            options = { try_as_border = true },
        },
        init = function()
            vim.api.nvim_create_autocmd("FileType", {
                pattern = {
                    "alpha",
                    "dashboard",
                    "fzf",
                    "help",
                    "lazy",
                    "lazyterm",
                    "mason",
                    "neo-tree",
                    "notify",
                    "toggleterm",
                    "Trouble",
                    "trouble",
                },
                callback = function()
                    vim.b.miniindentscope_disable = true
                end,
            })
        end,
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        event = "VeryLazy",
        opts = {
            scope = { enabled = false },
        },
    },
}
