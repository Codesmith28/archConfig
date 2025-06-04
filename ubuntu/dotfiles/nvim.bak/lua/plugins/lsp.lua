return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            inlay_hints = {
                enabled = true,
            },
        },
        config = function()
            require "configs.lspconfig"
        end,
    },

    -- {
    --     "nvimtools/none-ls.nvim",
    --     ft = "all",
    --     event = "VeryLazy",
    --     config = function()
    --         local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
    --         local null_ls = require "null-ls"
    --         null_ls.setup {
    --             sources = {
    --                 null_ls.builtins.formatting.clang_format,
    --                 null_ls.builtins.formatting.prettierd,
    --                 null_ls.builtins.formatting.gofumpt,
    --                 null_ls.builtins.formatting.goimports_reviser,
    --                 null_ls.builtins.formatting.golines,
    --                 null_ls.builtins.formatting.stylua,
    --                 null_ls.builtins.formatting.sqlformat,
    --             },
    --             on_attach = function(client, bufnr)
    --                 if client.supports_method "textDocument/formatting" then
    --                     vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
    --                     vim.api.nvim_create_autocmd("BufWritePre", {
    --                         group = augroup,
    --                         buffer = bufnr,
    --                         callback = function()
    --                             vim.lsp.buf.format { async = false }
    --                         end,
    --                     })
    --                 end
    --             end,
    --         }
    --     end,
    -- },

    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        config = function()
            require("conform").setup {
                formatters_by_ft = {
                    lua = { "stylua" },
                    cpp = { "clang_format" },
                    javascript = { "prettierd" },
                    typescript = { "prettierd" },
                    go = { "goimports-reviser", "gofumpt", "golines" },
                    sql = { "sql-formatter" },
                },
                format_on_save = {
                    lsp_fallback = true,
                    timeout_ms = 750,
                },
            }
        end,
    },
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPost", "BufWritePost", "InsertLeave" },
        config = function()
            local lint = require "lint"

            lint.linters_by_ft = {
                lua = { "luacheck" },
                javascript = { "eslint_d" },
                typescript = { "eslint_d" },
                go = { "golangcilint" },
                -- Add more linters as needed
            }

            vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
                callback = function()
                    lint.try_lint()
                end,
            })
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
        version = "^6", -- Recommended
        lazy = false,   -- This plugin is already lazy
    },
    {
        "rust-lang/rust.vim",
        ft = "rust",
        init = function()
            vim.g.rustfmt_autosave = 1
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            auto_install = true,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
            indent = { enable = true },
        },
    },
}
