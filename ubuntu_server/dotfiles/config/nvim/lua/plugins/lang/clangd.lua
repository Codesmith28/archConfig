return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            inlay_hints = {
                enabled = true,
            },
            servers = {
                clangd = {
                    cmd = {
                        "clangd",
                        "--background-index",
                        "--clang-tidy",
                        "--header-insertion=iwyu",
                        "--completion-style=detailed",
                        "--function-arg-placeholders",
                        "--fallback-style=llvm",
                        "--query-driver=/opt/homebrew/bin/g++*,/opt/homebrew/bin/**,/usr/local/bin/g++*,/usr/bin/clang++,/usr/bin/g++",
                    },
                    capabilities = {
                        offsetEncoding = { "utf-16" },
                    },
                    init_options = {
                        usePlaceholders = true,
                        completeUnimported = true,
                        clangdFileStatus = true,
                    },
                    settings = {
                        clangd = {
                            InlayHints = {
                                Designators = true,
                                Enabled = true,
                                ParameterNames = true,
                                DeducedTypes = true,
                                BlockEnd = true,
                                DefaultArguments = true,
                                TypeNameLimit = 0,
                            },
                        },
                    },
                },
            },
        },
    },
}
