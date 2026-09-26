return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            local configs = require("lspconfig.configs")

            local inlay_hints_config = {
                callArgumentNames = "all",
                variableTypes = true,
                functionReturnTypes = true,
                pytestParameters = true,
            }

            -- Define Pyrefly LSP configuration if not present in nvim-lspconfig
            if not configs.pyrefly then
                configs.pyrefly = {
                    default_config = {
                        cmd = { "pyrefly", "lsp" },
                        filetypes = { "python" },
                        root_dir = function(fname)
                            local util = require("lspconfig.util")
                            return util.root_pattern(
                                "pyproject.toml",
                                "pyrefly.toml",
                                "setup.py",
                                "setup.cfg",
                                "requirements.txt",
                                "Pipfile",
                                ".pyrefly",
                                ".git"
                            )(fname) or vim.fs.dirname(fname)
                        end,
                        single_file_support = true,
                        init_options = {
                            pyrefly = {
                                analysis = {
                                    inlayHints = inlay_hints_config,
                                },
                            },
                        },
                        settings = {
                            python = {
                                analysis = {
                                    inlayHints = inlay_hints_config,
                                },
                            },
                            pyrefly = {
                                analysis = {
                                    inlayHints = inlay_hints_config,
                                },
                            },
                        },
                    },
                }
            end

            opts.inlay_hints = opts.inlay_hints or {}
            opts.inlay_hints.enabled = true

            opts.servers = opts.servers or {}

            -- Configure Pyrefly as the active Python LSP
            opts.servers.pyrefly = vim.tbl_deep_extend("force", {
                enabled = true,
                init_options = {
                    pyrefly = {
                        analysis = {
                            inlayHints = inlay_hints_config,
                        },
                    },
                },
                settings = {
                    python = {
                        analysis = {
                            inlayHints = inlay_hints_config,
                        },
                    },
                    pyrefly = {
                        analysis = {
                            inlayHints = inlay_hints_config,
                        },
                    },
                },
            }, opts.servers.pyrefly or {})

            -- Configure Ruff to report unused vars, args, imports as hints (dimmed & italic like VS Code)
            local function mark_unused_as_hint(items)
                if not items then
                    return
                end
                for _, item in ipairs(items) do
                    local code = tostring(item.code or "")
                    if
                        code == "F841" -- Local variable is assigned to but never used
                        or code == "F401" -- Module imported but unused
                        or code == "B007" -- Loop control variable not used within loop body
                        or code:match("^ARG") -- Unused function/method/lambda arguments (ARG001-ARG005)
                    then
                        item.severity = vim.diagnostic.severity.HINT
                        item.tags = item.tags or {}
                        if not vim.tbl_contains(item.tags, 1) then
                            table.insert(item.tags, 1) -- DiagnosticTag.Unnecessary
                        end
                    end
                end
            end

            opts.servers.ruff = vim.tbl_deep_extend("force", {
                enabled = true,
                cmd_env = { RUFF_TRACE = "messages" },
                init_options = {
                    settings = {
                        logLevel = "error",
                        lint = {
                            extendSelect = {
                                "F", -- Pyflakes (F841: unused variables, F401: unused imports)
                                "ARG", -- flake8-unused-arguments (ARG001-ARG005: unused args)
                                "B007", -- flake8-bugbear (B007: unused loop variables)
                            },
                        },
                    },
                },
                handlers = {
                    ["textDocument/diagnostic"] = function(err, result, ctx, config)
                        if result and result.items then
                            mark_unused_as_hint(result.items)
                        end
                        return vim.lsp.diagnostic.on_diagnostic(err, result, ctx, config)
                    end,
                    ["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
                        if result and result.diagnostics then
                            mark_unused_as_hint(result.diagnostics)
                        end
                        return vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
                    end,
                },
            }, opts.servers.ruff or {})

            -- Explicitly disable other Python LSP servers to ensure Pyrefly is the default
            opts.servers.pyright = vim.tbl_deep_extend("force", opts.servers.pyright or {}, {
                enabled = false,
                autostart = false,
            })
            opts.servers.basedpyright = vim.tbl_deep_extend("force", opts.servers.basedpyright or {}, {
                enabled = false,
                autostart = false,
            })
            opts.servers.pylsp = vim.tbl_deep_extend("force", opts.servers.pylsp or {}, {
                enabled = false,
                autostart = false,
            })

            opts.setup = opts.setup or {}
            opts.setup.pyrefly = function()
                Snacks.util.lsp.on({ name = "pyrefly" }, function(buffer, client)
                    if client:supports_method("textDocument/inlayHint") and vim.lsp.inlay_hint then
                        vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
                    end
                end)
            end

            return opts
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                python = { "ruff_format", "ruff_organize_imports" },
            },
        },
    },
}
