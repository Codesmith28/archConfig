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

            -- Do not clutter lines with virtual text for unused variables/imports (like VS Code)
            opts.diagnostics.virtual_text = opts.diagnostics.virtual_text or {}
            if type(opts.diagnostics.virtual_text) == "table" then
                local orig_format = opts.diagnostics.virtual_text.format
                opts.diagnostics.virtual_text.format = function(diagnostic)
                    if
                        (diagnostic._tags and diagnostic._tags.unnecessary)
                        or (diagnostic.tags and vim.tbl_contains(diagnostic.tags, 1))
                    then
                        return nil
                    end
                    if orig_format then
                        return orig_format(diagnostic)
                    end
                    return diagnostic.message
                end
            end

            return opts
        end,
    },
}
