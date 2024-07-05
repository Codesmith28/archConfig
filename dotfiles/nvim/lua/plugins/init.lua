local overrides = require "configs.overrides"

return {
    {
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        opts = {},
    },
    {
        "mistricky/codesnap.nvim",
        lazy = true,
        build = "make build_generator",
        keys = {
            { "<leader>sc", "<cmd>CodeSnapSave<cr>", mode = "x", desc = "Save selected code snapshot in ~/Pictures" },
        },
        opts = {
            save_path = "~/Pictures/Codesnaps",
            has_breadcrumbs = true,
            watermark = "",
            bg_color = "#535c68",
            code_font_familty = "JetBrainsMono Nerd Font",
        },
        config = function(_, opts)
            require("codesnap").setup(opts)
        end,
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

    -- for cpp:
    {
        "neovim/nvim-lspconfig",
        config = function()
            require("nvchad.configs.lspconfig").defaults()
            require "configs.lspconfig"
        end,
    },
    {
        "nvimtools/none-ls.nvim",
        ft = "all",
        event = "VeryLazy",
        config = function()
            local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
            local null_ls = require "null-ls"
            -- return "configs.null-ls"

            null_ls.setup {
                sources = {
                    null_ls.builtins.formatting.clang_format,
                    null_ls.builtins.formatting.prettierd,
                    null_ls.builtins.formatting.gofumpt,
                    null_ls.builtins.formatting.goimports_reviser,
                    null_ls.builtins.formatting.golines,
                    null_ls.builtins.formatting.stylua,
                    null_ls.builtins.formatting.sqlformat,
                    -- null_ls.builtins.diagnostics.eslint,
                },
                -- format on save:
                on_attach = function(client, bufnr)
                    if client.supports_method "textDocument/formatting" then
                        vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            group = augroup,
                            buffer = bufnr,
                            callback = function()
                                -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
                                -- on later neovim version, you should use vim.lsp.buf.format({ async = false }) instead
                                vim.lsp.buf.format { async = false }
                            end,
                        })
                    end
                end,
            }
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
                "prettierd",
                "typescript-language-server",
                "tailwindcss-language-server",
                "yaml-language-server",
                "yamlfix",
                "yamllint",
                "html-lsp",
                "css-lsp",
                "mdformat",

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
