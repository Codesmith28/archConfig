local deps = require("config.deps")

return {
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.ui = opts.ui or {}
            opts.ui.border = "rounded"
            opts.ensure_installed = opts.ensure_installed or {}

            -- Core standalone tools (self-contained binaries, independent of language runtimes)
            local tools = {
                "stylua",
                "shfmt",
                "shellcheck",
                "marksman",
                "mdformat",
                "json-lsp",
                "yamlfix",
                "yamllint",
                "taplo",
                "xmlformatter",
            }

            -- C/C++
            if deps.has_cpp then
                vim.list_extend(tools, {
                    "clangd",
                    "clang-format",
                    "codelldb",
                })
            end

            -- Java
            if deps.has_java then
                vim.list_extend(tools, {
                    "jdtls",
                    "java-debug-adapter",
                    "java-test",
                    "google-java-format",
                })
            end

            -- Rust
            if deps.has_rust then
                vim.list_extend(tools, {
                    "rust-analyzer",
                    "codelldb",
                })
            end

            -- Python
            if deps.has_python then
                vim.list_extend(tools, {
                    "pyrefly",
                    "ruff",
                    "black",
                    "isort",
                    "flake8",
                })
            end

            -- Go
            if deps.has_go then
                vim.list_extend(tools, {
                    "gopls",
                    "delve",
                    "goimports-reviser",
                    "golines",
                    "gofumpt",
                    "json-to-struct",
                })
            end

            -- JS/TS, Web Dev
            if deps.has_node then
                vim.list_extend(tools, {
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
                    "bash-language-server",
                    "markdownlint",
                    "markdownlint-cli2",
                    "markdown-toc",
                    "yaml-language-server",
                    "sql-formatter",
                    "dockerfile-language-server",
                    "docker-compose-language-service",
                    "tree-sitter-cli",
                })
            end

            -- Kubernetes / Helm
            if deps.has_helm then
                vim.list_extend(tools, {
                    "helm-ls",
                })
            end

            vim.list_extend(opts.ensure_installed, tools)
            opts.ensure_installed = LazyVim.dedup(opts.ensure_installed)

            -- Filter out packages whose language runtimes/compilers are not present on the system,
            -- including any packages that upstream LazyVim extras may have appended.
            local go_tools = {
                ["gopls"] = true,
                ["delve"] = true,
                ["goimports-reviser"] = true,
                ["golines"] = true,
                ["gofumpt"] = true,
                ["json-to-struct"] = true,
                ["goimports"] = true,
                ["gomodifytags"] = true,
                ["impl"] = true,
            }
            local rust_tools = {
                ["rust-analyzer"] = true,
                ["bacon"] = true,
            }
            local java_tools = {
                ["jdtls"] = true,
                ["java-debug-adapter"] = true,
                ["java-test"] = true,
                ["google-java-format"] = true,
            }
            local python_tools = {
                ["pyrefly"] = true,
                ["ruff"] = true,
                ["black"] = true,
                ["isort"] = true,
                ["flake8"] = true,
            }

            local filtered = {}
            for _, pkg in ipairs(opts.ensure_installed) do
                local keep = true
                if not deps.has_go and go_tools[pkg] then
                    keep = false
                elseif not deps.has_rust and rust_tools[pkg] then
                    keep = false
                elseif not deps.has_java and java_tools[pkg] then
                    keep = false
                elseif not deps.has_python and python_tools[pkg] then
                    keep = false
                elseif not deps.has_cpp and (pkg == "clangd" or pkg == "clang-format") then
                    keep = false
                elseif not deps.has_helm and pkg == "helm-ls" then
                    keep = false
                end
                if keep then
                    table.insert(filtered, pkg)
                end
            end
            opts.ensure_installed = filtered
        end,
    },
}
