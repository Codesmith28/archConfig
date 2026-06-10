return {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function(_, opts)
        -- Run LazyVim's default setup first
        require("luasnip").setup(opts)

        -- 1. Load community friendly-snippets
        require("luasnip.loaders.from_vscode").lazy_load()

        -- 2. Load your custom VSCode-style snippets with an absolute path
        local snippet_path = vim.fn.stdpath("config") .. "/lua/snippets"
        require("luasnip.loaders.from_vscode").lazy_load({
            paths = { snippet_path },
        })

        -- 3. Load snipmate style snippets if you have any
        require("luasnip.loaders.from_snipmate").lazy_load()
    end,
    opts = {
        updateevents = "TextChanged,TextChangedI",
        enable_autosnippets = true,
        store_selection_keys = "<Tab>",
    },
}
