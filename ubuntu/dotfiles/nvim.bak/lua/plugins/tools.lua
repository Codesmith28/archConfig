local overrides = require "configs.overrides"
return {
    {
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        opts = {},
    },
    {
        "stevearc/oil.nvim",
        opts = {},
        -- Optional dependencies
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("oil").setup {
                skip_confirm_for_simple_edits = true,
                view_options = {
                    show_hidden = true,
                },
                float = {
                    max_width = 50,
                    max_height = 20,
                },
            }
        end,
    },
    {
        "wakatime/vim-wakatime",
        lazy = false,
    },
    {
        "kdheepak/lazygit.nvim",
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        -- optional for floating wow border decoration
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        -- setting the keybinding for LazyGit with 'keys' is recommended in
        -- order to load the plugin when the command is run for the first time
        keys = {
            { "<leader>ll", "<cmd>LazyGit<cr>", desc = "LazyGit" },
        },
    },

    -- for developement:
    {
        "mhartington/formatter.nvim",
        event = "VeryLazy",
        opts = function()
            return require "configs.formatter"
        end,
    },
    {
        "cameron-wags/rainbow_csv.nvim",
        config = true,

        ft = {
            "csv",
            "tsv",
            "csv_semicolon",
            "csv_whitespace",
            "csv_pipe",
            "rfc_csv",
            "rfc_semicolon",
        },
        cmd = {
            "RainbowDelim",
            -- "RainbowDelimSimple",
            "RainbowDelimQuoted",
            "RainbowMultiDelim",
        },
    },
    {
        "zbirenbaum/copilot.lua",
        -- Lazy load when event occurs. Events are triggered
        -- as mentioned in:
        -- https://vi.stackexchange.com/a/4495/20389
        event = "InsertEnter",
        -- You can also have it load at immediately at
        -- startup by commenting above and uncommenting below:
        lazy = false,
        opts = overrides.copilot,
    },
    {
        "xeluxee/competitest.nvim",
        dependencies = "MunifTanjim/nui.nvim",
        config = function()
            require("competitest").setup()
        end,
    },
}
