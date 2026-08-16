return {
    {
        "mason-org/mason.nvim",
        opts = {
            ensure_installed = {
                -- C/C++
                "clangd",
                "clang-format",
                "codelldb",

                -- Java
                "jdtls",
                "java-debug-adapter",
                "java-test",
                "google-java-format",

                -- Rust
                "rust-analyzer",

                -- Python
                "pyright",
                "pyrefly",
                "black",
                "isort",
                "flake8",

                -- Go
                "gopls",
                "delve",
                "goimports-reviser",
                "golines",
                "gofumpt",

                -- JS/TS, Web Dev
                "vtsls",
                "typescript-language-server",
                "eslint-lsp",
                "prettier",
                "prettierd",
                "tailwindcss-language-server",
                "html-lsp",
                "css-lsp",
                "biome",
                "nextls",
                "js-debug-adapter",

                -- Lua
                "lua-language-server",
                "stylua",

                -- Shell
                "bash-language-server",
                "shellcheck",
                "shfmt",

                -- Markdown
                "marksman",
                "markdownlint",
                "markdownlint-cli2",
                "markdown-toc",
                "mdformat",

                -- JSON / YAML / TOML
                "json-lsp",
                "json-to-struct",
                "yaml-language-server",
                "yamlfix",
                "yamllint",
                "taplo",

                -- SQL / XML / Docker / Misc
                "sql-formatter",
                "xmlformatter",
                "dockerfile-language-server",
                "docker-compose-language-service",
                "tree-sitter-cli",
            },
        },
    },
}
