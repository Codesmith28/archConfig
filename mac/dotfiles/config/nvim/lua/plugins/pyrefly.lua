return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            local configs = require("lspconfig.configs")

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
                            )(fname) or util.path.dirname(fname)
                        end,
                        single_file_support = true,
                        settings = {},
                    },
                }
            end

            opts.servers = opts.servers or {}

            -- Configure Pyrefly as the active Python LSP
            opts.servers.pyrefly = vim.tbl_deep_extend("force", {
                enabled = true,
                settings = {},
            }, opts.servers.pyrefly or {})

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
            opts.setup.pyrefly = function(_, server_opts)
                Snacks.util.lsp.on({ name = "pyrefly" }, function(buffer, client)
                    if vim.lsp.inlay_hint then
                        vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
                    end
                end)
            end

            return opts
        end,
    },
}
