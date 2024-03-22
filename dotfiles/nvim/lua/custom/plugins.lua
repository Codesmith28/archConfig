local overrides = require("custom.configs.overrides")

local plugins = {
    -- for developement:
    {
        "mhartington/formatter.nvim",
        event = "VeryLazy",
        opts = function()
            return require "custom.configs.formatter"
        end
    },
    {
        "mfussenegger/nvim-lint",
        event = "VeryLazy",
        config = function()
            require "custom.configs.lint"
        end
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

    -- for cpp:
    {
        "jay-babu/mason-nvim-dap.nvim",
        event = "VeryLazy",
        dependencies = {
            "williamboman/mason.nvim",
            "mfussenegger/nvim-dap",
        },
        opts = {
            handlers = {}
        },
    },
    {
        "mfussenegger/nvim-dap",
        config = function(_, _)
            require("core.utils").load_mappings("dap")
        end
    },
    {
        "jose-elias-alvarez/null-ls.nvim",
        event = "VeryLazy",
        opts = function()
            return require "custom.configs.null-ls"
        end,
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            require "plugins.configs.lspconfig"
            require "custom.configs.lspconfig"
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
                -- for developement:
                "nextls",
                "eslint-lsp",
                "js-debug-adapter",
                "prettier",
                "typescript-language-server",
                "tailwindcss-language-server",
                "yaml-language-server",
                "yamlfix",
                "yamllint",
                -- for lua:
                "lua-language-server",
            }
        }
    },
}
return plugins
