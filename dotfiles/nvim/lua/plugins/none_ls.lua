return {
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
}
