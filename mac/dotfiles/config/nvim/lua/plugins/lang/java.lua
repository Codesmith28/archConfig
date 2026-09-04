return {
    {
        "mfussenegger/nvim-jdtls",
        -- Merges with LazyVim's official Java Extra
        opts = function(_, opts)
            -- Performance: allocate sufficient heap and disable main class scanning on large projects
            opts.dap_main = false
            opts.cmd = opts.cmd or { vim.fn.exepath("jdtls") }
            vim.list_extend(opts.cmd, {
                "--jvm-arg=-Xmx4G",
                "--jvm-arg=-XX:+UseG1GC",
            })

            opts.settings = opts.settings or {}
            opts.settings.java = vim.tbl_deep_extend("force", opts.settings.java or {}, {
                -- Performance optimizations: disable heavy background building and codelens
                autobuild = { enabled = false },
                maxConcurrentBuilds = 4,

                -- CodeLens is a major performance bottleneck on large multi-module codebases
                referencesCodeLens = { enabled = false },
                implementationsCodeLens = { enabled = false },

                -- Runtimes configuration matching installed JDKs
                configuration = {
                    runtimes = {
                        {
                            name = "JavaSE-11",
                            path = "/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home",
                        },
                        {
                            name = "JavaSE-17",
                            path = "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home",
                        },
                        {
                            name = "JavaSE-21",
                            path = "/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home",
                        },
                    },
                },

                -- Disable heavy whole-project nullness flow analysis
                nullAnalysis = { mode = "disabled" },

                -- Organize imports (match IntelliJ behavior: no wildcard imports)
                sources = {
                    organizeImports = {
                        starThreshold = 99,
                        staticStarThreshold = 99,
                    },
                },
                format = { enabled = false }, -- Let Conform + google-java-format handle formatting

                -- Full Max-Verbosity Inlay Hints (No exclusions)
                inlayHints = {
                    parameterNames = {
                        enabled = "all",
                        exclusions = {},
                    },
                    parameterTypes = { enabled = true },
                    variableTypes = { enabled = true },
                    propertyDeclarationTypes = { enabled = true },
                    functionLikeReturnTypes = { enabled = true },
                },
            })

            -- Attach handler: Disable JDTLS format capabilities & register project config keymap
            local old_on_attach = opts.on_attach
            opts.on_attach = function(client_or_args, bufnr)
                if old_on_attach then
                    old_on_attach(client_or_args, bufnr)
                end

                local client, buf
                if type(client_or_args) == "table" and client_or_args.data and client_or_args.data.client_id then
                    client = vim.lsp.get_client_by_id(client_or_args.data.client_id)
                    buf = client_or_args.buf
                else
                    client = client_or_args
                    buf = bufnr
                end

                if client and client.name == "jdtls" then
                    -- DISABLE JDTLS formatting so Conform.nvim handles formatting via google-java-format (--aosp)
                    client.server_capabilities.documentFormattingProvider = false
                    client.server_capabilities.documentRangeFormattingProvider = false

                    if buf then
                        -- Enforce full Inlay Hinting on Java buffer
                        if vim.lsp.inlay_hint then
                            vim.lsp.inlay_hint.enable(true, { bufnr = buf })
                        end

                        vim.keymap.set("n", "<leader>cu", function()
                            require("jdtls").update_project_config()
                            vim.notify("JDTLS: Project configuration update triggered", vim.log.levels.INFO)
                        end, { buffer = buf, desc = "Update JDTLS Project Config" })
                    end
                end
            end

            return opts
        end,
    },
}
