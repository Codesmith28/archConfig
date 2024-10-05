-- This file  needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.ui = {
    theme = "gruvchad",
    transparency = false,

    hl_override = {
        Comment = { italic = true },
        ["@comment"] = { italic = true },
    },

    cmp = {
        icons = true,
        lspkind_text = true,
    },
    mason = { cmd = true, pkgs = {} },

    cheatsheet = {
        theme = "grid",
    },

    telescope = { style = "bordered" }, -- borderless / bordered

    -- term = {
    --     winopts = { winhl = "Normal:term,WinSeparator:WinSeparator" },
    --     sizes = { sp = 0.5, vsp = 0.5, ["bo sp"] = 0.5, ["bo vsp"] = 0.5 },
    --     float = {
    --         relative = "editor",
    --         row = 0.15,
    --         col = 0.2,
    --         width = 0.6,
    --         height = 0.6,
    --         border = "rounded",
    --     },
    -- },
}

---@type ChadrcConfig
M.term = {
    winopts = { winhl = "Normal:term,WinSeparator:WinSeparator" },
    sizes = { sp = 0.4, vsp = 0.4, ["bo sp"] = 0.4, ["bo vsp"] = 0.4 },
    float = {
        relative = "editor",
        row = 0.15,
        col = 0.2,
        width = 0.6,
        height = 0.6,
        border = "rounded",
    },
}

M.lsp = { signature = false }

M.mason = {
    cmd = true,
    pkgs = {
        -- for cpp:
        -- "clangd",
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
}

return M
