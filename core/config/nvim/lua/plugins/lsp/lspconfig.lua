return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts = opts or {}
            opts.servers = opts.servers or {}
            opts.servers["*"] = opts.servers["*"] or {}
            local ok_blink, blink = pcall(require, "blink.cmp")
            if ok_blink and blink.get_lsp_capabilities then
                opts.servers["*"].capabilities = vim.tbl_deep_extend(
                    "force",
                    opts.servers["*"].capabilities or {},
                    blink.get_lsp_capabilities()
                )
            end
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
