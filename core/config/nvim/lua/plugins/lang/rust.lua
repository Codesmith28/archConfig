local deps = require("config.deps")

return {
    {
        "mrcjkb/rustaceanvim",
        version = "^5", -- Recommended
        enabled = deps.has_rust,
        ft = { "rust" },
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
        config = function(_, opts)
            if LazyVim.has("mason.nvim") then
                local codelldb = vim.fn.exepath("codelldb")
                local codelldb_lib_ext = io.popen("uname"):read("*l") == "Linux" and ".so" or ".dylib"
                local library_path = vim.fn.expand("$MASON/opt/lldb/lib/liblldb" .. codelldb_lib_ext)
                opts.dap = {
                    adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb, library_path),
                }
            end
            vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
            -- Silently skip notification if rust-analyzer is not found in PATH
        end,
    },
    {
        "Saecki/crates.nvim",
        enabled = deps.has_rust,
    },
}
