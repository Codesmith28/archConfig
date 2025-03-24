-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
    theme = "chadracula",

    hl_override = {
        Comment = { italic = true },
        ["@comment"] = { italic = true },
    },
}

M.ui = {
    telescope = { style = "bordered" }, -- borderless / bordered
}

M.term = {
    winopts = { winhl = "Normal:term,WinSeparator:WinSeparator" },
    sizes = { sp = 0.4, vsp = 0.4, ["bo sp"] = 0.4, ["bo vsp"] = 0.4 },
    float = {
        relative = "editor",
        row = 0.1,
        col = 0.2,
        width = 0.6,
        height = 0.7,
        border = "rounded",
    },
}

M.nvdash = {
    load_on_startup = true,
}

M.lsp = { signature = false }

M.mason = {
    cmd = true,
    pkgs = {
        -- for cpp:
        -- "clangd",
        "clang-format",
        "codelldb",
        -- for python:
        "pyright",
        "mypy",
        "ruff",
        "black",
        "isort",
        "flake8",
        "pylint",
        -- for sql:
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
        -- for markdown:
        "markdownlint",
    },
}

return M
