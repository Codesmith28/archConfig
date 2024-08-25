local overrides = require "configs.overrides"

return {
    {
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        opts = {},
    },
    -- lazy.nvim
    {
        "stevearc/oil.nvim",
        opts = {},
        -- Optional dependencies
        dependencies = { { "echasnovski/mini.icons", opts = {} } },
        -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
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
        "stevearc/conform.nvim",
        event = "BufWritePre", -- uncomment for format on save
        config = function()
            require "configs.conform"
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
    },
    {
        "windwp/nvim-ts-autotag",
        ft = {
            "html",
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "svelte",
            "vue",
        },
        config = function()
            require("nvim-ts-autotag").setup()
        end,
    },
    {
        "mrcjkb/rustaceanvim",
        version = "^5", -- Recommended
        lazy = false,   -- This plugin is already lazy
    },

    -- These are some examples, uncomment them if you want to see them work!
    --
    -- {
    -- 	"williamboman/mason.nvim",
    -- 	opts = {
    -- 		ensure_installed = {
    -- 			"lua-language-server", "stylua",
    -- 			"html-lsp", "css-lsp" , "prettier"
    -- 		},
    -- 	},
    -- },
    --
    -- {
    -- 	"nvim-treesitter/nvim-treesitter",
    -- 	opts = {
    -- 		ensure_installed = {
    -- 			"vim", "lua", "vimdoc",
    --      "html", "css"
    -- 		},
    -- 	},
    -- },
}
