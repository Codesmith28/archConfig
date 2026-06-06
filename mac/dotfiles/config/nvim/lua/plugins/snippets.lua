return {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function(_, opts)
        -- Run LazyVim's default setup first so you don't break built-in behavior
        require("luasnip").setup(opts)

        -- 1. Load friendly-snippets (VSCode style)
        require("luasnip.loaders.from_vscode").lazy_load()

        -- 2. Load your custom VSCode-style snippets safely expanding the home path
        require("luasnip.loaders.from_vscode").lazy_load({
            paths = { vim.fn.stdpath("config") .. "/lua/snippets" },
        })

        -- 3. Load snipmate style snippets (looks for a "snippets" directory in runtimepath)
        require("luasnip.loaders.from_snipmate").lazy_load()
    end,
    opts = {
        updateevents = "TextChanged,TextChangedI",
        enable_autosnippets = true,
        store_selection_keys = "<Tab>",
    },
}
