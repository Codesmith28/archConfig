return {
    {
        "williamboman/mason.nvim",
        opts = {
            ensure_installed = {
                -- C/C++
                -- "clangd",
                "clang-format",
                "codelldb",

                -- Python
                "pyright",
                "mypy",
                "ruff",
                "black",
                "isort",
                "flake8",
                "pylint",

                -- SQL
                "sql-formatter",

                -- JS/TS, Web dev
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

                -- Lua
                "lua-language-server",
                "stylua",

                -- Go
                "gopls",
                "goimports-reviser",
                "golines",
                "gofumpt",

                -- Shell
                "bash-language-server",
                "shellcheck",
                "shfmt",

                -- Docker
                "dockerfile-language-server",
                "docker-compose-language-service",

                -- Markdown
                "markdownlint",

                -- json:
                "json-lsp",
                "json-to-struct",
                "biome",
            },
        },
    },
}
