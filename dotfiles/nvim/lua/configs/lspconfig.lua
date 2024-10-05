local base = require "nvchad.configs.lspconfig"
local on_attach = base.on_attach
local capabilities = base.capabilities

local lspconfig = require "lspconfig"
local util = require "lspconfig/util"

-- setup clangd server
lspconfig["clangd"].setup {
    on_attach = on_attach,
    capabilities = capabilities,
    cmd = { "clangd", "-header-insertion=never" },
}

-- for typescript
lspconfig.ts_ls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    init_options = {
        preferences = {
            disableSuggestions = true,
        },
    },
}

-- for go
lspconfig.gopls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_dir = util.root_pattern("go.work", "go.mod", ".git"),
    settings = {
        gopls = {
            completeUnimported = true,
            usePlaceholders = true,
            analyses = {
                unusedparams = true,
            },
        },
    },
}

-- for rust:
lspconfig.rust_analyzer.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    filetypes = { "rust" },
    root_dir = util.root_pattern "Cargo.toml",
    settings = {
        ["rust_analyzer"] = {
            cargo = {
                allFeatures = true,
            },
        },
    },
}

local servers = { "tailwindcss", "eslint", "ts_ls", "cssls" }

for _, lsp in ipairs(servers) do
    lspconfig[lsp].setup {
        on_attach = on_attach,
        capabilities = capabilities,
    }
end
