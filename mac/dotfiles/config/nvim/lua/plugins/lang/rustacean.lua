return {
    "mrcjkb/rustaceanvim",
    version = "^5", -- Recommended
    lazy = false, -- This plugin is already lazy
    opts = {
        server = {
            default_settings = {
                ["rust-analyzer"] = {
                    inlayHints = {
                        bindingModeHints = { enable = true },
                        chainingHints = { enable = true },
                        closingBraceHints = { enable = true, minLines = 25 },
                        closureReturnTypeHints = { enable = "always" },
                        discriminantHints = { enable = "always" },
                        expressionAdjustmentHints = { enable = "always" },
                        lifetimeElisionHints = { enable = "always", useParameterNames = true },
                        parameterHints = { enable = true },
                        rangeExclusiveHints = { enable = true },
                        reborrowHints = { enable = "always" },
                        typeHints = {
                            enable = true,
                            hideClosureInitialization = false,
                            hideNamedConstructor = false,
                        },
                    },
                },
            },
        },
    },
}
