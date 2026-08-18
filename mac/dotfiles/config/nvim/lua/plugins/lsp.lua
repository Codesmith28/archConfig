return {
    {
        "neovim/nvim-lspconfig",
        opts = function()
            -- 1. Rounded borders for LSP Hover ('K') and Signature Help
            vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
                border = "rounded",
            })
            vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
                border = "rounded",
            })

            -- 2. Rounded borders for Diagnostic floating popups
            vim.diagnostic.config({
                float = {
                    border = "rounded",
                },
            })
        end,
    },
}
