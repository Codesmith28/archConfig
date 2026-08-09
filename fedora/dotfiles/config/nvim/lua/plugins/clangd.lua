return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                clangd = {
                    -- We set this to false so LazyVim doesn't use its default setup
                    setup = {
                        function(server, opts)
                            require("lspconfig")[server].setup(vim.tbl_deep_extend("force", opts, {
                                cmd = {
                                    "clangd",
                                    "--background-index",
                                    "--clang-tidy",
                                    "--fallback-style=file",
                                    "--query-driver=/opt/homebrew/bin/g++-15",
                                },
                                capabilities = {
                                    offsetEncoding = { "utf-16" },
                                },
                            }))
                            return true
                        end,
                    },
                },
            },
        },
    },
}
