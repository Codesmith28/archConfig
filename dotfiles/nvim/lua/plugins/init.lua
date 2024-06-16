local overrides = require "configs.overrides"

return {
    {
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        opts = {},
    },

    {
        "stevearc/conform.nvim",
        -- event = "BufWritePre", -- uncomment for format on save
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
        -- optional for floating window border decoration
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        -- setting the keybinding for LazyGit with 'keys' is recommended in
        -- order to load the plugin when the command is run for the first time
        keys = {
            { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
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
        "mfussenegger/nvim-lint",
        event = "VeryLazy",
        config = function()
            require "configs.lint"
        end,
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

    -- for cpp:
    {
        "jay-babu/mason-nvim-dap.nvim",
        event = "VeryLazy",
        dependencies = {
            "williamboman/mason.nvim",
            "mfussenegger/nvim-dap",
        },
        opts = {
            handlers = {},
        },
    },
    {
        "jose-elias-alvarez/null-ls.nvim",
        -- support all languages:
        ft = "all",
        event = "VeryLazy",
        opts = function()
            return require "configs.null-ls"
        end,
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            require("nvchad.configs.lspconfig").defaults()
            require "configs.lspconfig"
        end,
    },
    {
        "williamboman/mason.nvim",
        opts = {
            ensure_installed = {
                -- for cpp:
                "clangd",
                "clang-format",
                "codelldb",

                -- for python and sql:
                "python-lsp-server",
                "sql-formatter",

                -- for development:
                "nextls",
                "eslint-lsp",
                "js-debug-adapter",
                "prettier",
                "typescript-language-server",
                "tailwindcss-language-server",
                "yaml-language-server",
                "yamlfix",
                "yamllint",
                "html-lsp",
                "css-lsp",

                -- for lua:
                "lua-language-server",
                "stylua",

                -- for go:
                "gopls",
                "goimports-reviser",
                "golines",
                "gofumpt",

                -- for bash scripts:
                "bash-language-server",
                "shellcheck",
                "shfmt",

                -- for docker:
                "dockerfile-language-server",
                "docker-compose-language-service",
            },
        },
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
