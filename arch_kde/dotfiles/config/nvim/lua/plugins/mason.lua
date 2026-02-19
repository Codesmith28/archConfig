return {
    {
        "mason-org/mason.nvim",
        opts = {
            ensure_installed = {
                -- C/C++
                "clang-format",
                "clangd",
                "codelldb",

                -- Python
                "pyrefly",

                -- SQL
                "sql-formatter",

                -- JS/TS, Web dev
                "nextls",
                "eslint-lsp", -- eslint
                "js-debug-adapter",
                "prettierd",
                "typescript-language-server", -- ts_ls
                "vtsls",
                "tailwindcss-language-server", -- tailwindcss
                "yaml-language-server", -- yamlls
                "yamlfix",
                "yamllint",
                "html-lsp", -- html
                "css-lsp", -- cssls
                "mdformat",

                -- Lua
                "lua-language-server", -- lua_ls
                "stylua",

                -- Go
                "gopls",
                "goimports-reviser",
                "golines",
                "gofumpt",

                -- Shell
                "bash-language-server", -- bashls
                "shellcheck",
                "shfmt",

                -- Docker
                "dockerfile-language-server", -- dockerls
                "docker-compose-language-service", -- docker_compose_language_service

                -- Markdown
                "markdownlint",
                "markdownlint-cli2",
                "markdown-toc",
                "marksman",

                -- JSON
                "json-lsp", -- jsonls
                "json-to-struct",
                "biome",

                -- Java
                "jdtls",
                "google-java-format",

                -- Configs / Misc
                "mesonlsp",
                "tree-sitter-cli",
                "xmlformatter",

                --rust
                "rust-analyzer",
            },
        },
    },
}
