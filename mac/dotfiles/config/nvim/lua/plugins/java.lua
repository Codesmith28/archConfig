return {
    {
        "mfussenegger/nvim-jdtls",
        opts = function(_, opts)
            local java_runtime_path = "/usr/lib/jvm/java-21-openjdk-amd64"

            opts.cmd = opts.cmd or {}
            vim.list_extend(opts.cmd, {
                "--jvm-arg=-Djava.import.generatesMetadataFilesAtProjectRoot=false",
                "--jvm-arg=-Xms8g",
                "--jvm-arg=-Xmx16g",
                "--jvm-arg=-XX:+UseG1GC",
                "--jvm-arg=-Dsun.zip.disableMemoryMapping=true",
                "--jvm-arg=-Xverify:none",
            })

            opts.dap_main = false

            opts.capabilities = vim.tbl_deep_extend("force", opts.capabilities or {}, {
                offsetEncoding = { "utf-16" },
            })

            opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
                java = {
                    project = {
                        referencedLibraries = {
                            vim.fn.expand(
                                "$HOME/.gradle/caches/modules-2/files-2.1/org.scala-lang/scala-library/**/*.jar"
                            ),
                        },
                    },
                    configuration = {
                        updateBuildConfiguration = "interactive",
                        runtimes = {
                            {
                                name = "JavaSE-21",
                                path = java_runtime_path,
                                default = true,
                            },
                        },
                    },

                    autobuild = { enabled = true },
                    referencesCodeLens = { enabled = false },
                    implementationsCodeLens = { enabled = false },

                    format = {
                        enabled = true,
                        settings = {
                            url = vim.uri_from_fname(vim.fn.expand("~/.config/nvim/langs/Default.xml")),
                            profile = "Default",
                            useProfileOptions = true,
                        },
                    },

                    -- =====================================================================
                    -- CLEAN NATIVE INLAY HINTS
                    -- =====================================================================

                    inlayHints = {
                        parameterNames = {
                            enabled = "all", -- Options: "none", "literals", "all"
                        },
                        parameterTypes = {
                            enabled = true, -- Enables type hints for lambda parameters like (k, v)
                        },
                        variableTypes = {
                            enabled = true, -- Enables type hints for local variables (e.g. `var`)
                        },
                        propertyDeclarationTypes = {
                            enabled = true, -- Enables type hints for field/property declarations
                        },
                        functionLikeReturnTypes = {
                            enabled = true, -- Enables return type hints for methods/lambdas
                        },
                    },

                    -- =====================================================================
                },
            })

            opts.on_attach = function(client_or_args, bufnr)
                local client, bufn
                if type(client_or_args) == "table" and client_or_args.data and client_or_args.data.client_id then
                    client = vim.lsp.get_client_by_id(client_or_args.data.client_id)
                    bufn = client_or_args.buf
                else
                    client = client_or_args
                    bufn = bufnr
                end

                if client and client.server_capabilities then
                    client.server_capabilities.semanticTokensProvider = nil
                    client.server_capabilities.documentFormattingProvider = true
                    client.server_capabilities.documentRangeFormattingProvider = true
                end

                -- Explicitly enable Neovim's native LSP inlay hints for the buffer
                if vim.lsp.inlay_hint then
                    vim.lsp.inlay_hint.enable(true, { bufnr = bufn })
                end

                vim.keymap.set("n", "<leader>cu", function()
                    require("jdtls").update_project_config()
                    vim.notify("JDTLS: Project configuration update triggered", vim.log.levels.INFO)
                end, { buffer = bufn, desc = "Update JDTLS Project Config" })
            end

            return opts
        end,
    },
}
