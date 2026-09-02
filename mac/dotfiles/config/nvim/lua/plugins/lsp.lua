return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts = opts or {}
            vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
                border = "rounded",
            })
            vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
                border = "rounded",
            })
            opts.diagnostics = opts.diagnostics or {}
            opts.diagnostics.float = opts.diagnostics.float or {}
            opts.diagnostics.float.border = "rounded"
            return opts
        end,
    },
}
