return {
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
            null_ls.setup {
                sources = {
                    null_ls.builtins.formatting.clang_format,
                    null_ls.builtins.formatting.prettierd,
                    null_ls.builtins.formatting.gofumpt,
                    null_ls.builtins.formatting.goimports_reviser,
                    null_ls.builtins.formatting.golines,
                    null_ls.builtins.formatting.stylua,
                    null_ls.builtins.formatting.sqlformat,
                },
                on_attach = function(client, bufnr)
                    if client.supports_method "textDocument/formatting" then
                        vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            group = augroup,
                            buffer = bufnr,
                            callback = function()
                                vim.lsp.buf.format { async = false }
                            end,
                        })
                    end
                end,
            }
        end,
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
        lazy = false, -- This plugin is already lazy
    },
    {
        "rust-lang/rust.vim",
        ft = "rust",
        init = function()
            vim.g.rustfmt_autosave = 1
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

                -- for rust:
                "rust-analyzer",
            },
        },
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = {
                -- General
                "vim",
                "lua",
                "vimdoc",

                -- Web development
                "html",
                "css",
                "javascript",
                "typescript",
                "tsx",
                "json",
                "yaml",

                -- Programming languages
                "python",
                "cpp",
                "go",
                "rust",

                -- Scripting
                "bash",

                -- Markup and config
                "markdown",

                -- DevOps
                "dockerfile",
            },
            auto_install = true,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
            indent = { enable = true },
        },
    },
}
