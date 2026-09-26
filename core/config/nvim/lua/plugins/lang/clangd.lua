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
                        "--function-arg-placeholders=true",
                        "--fallback-style=llvm",
                        "--query-driver=/opt/homebrew/bin/g++*,/opt/homebrew/bin/clang++*,/usr/bin/g++*,/usr/bin/clang++*,/usr/local/bin/g++*,/usr/local/bin/clang++*",
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
