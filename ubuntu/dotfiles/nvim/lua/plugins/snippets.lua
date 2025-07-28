return {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
        -- Load friendly-snippets
        require("luasnip.loaders.from_vscode").lazy_load()
        -- Load your custom snippets
        require("luasnip.loaders.from_vscode").lazy_load({ paths = "~/.config/nvim/lua/snippets" })
        -- Load snipmate style snippets
        require("luasnip.loaders.from_snipmate").lazy_load()

        require("luasnip").setup({
            updateevents = "TextChanged,TextChangedI",
            -- Enable autotriggered snippets
            enable_autosnippets = true,
            -- Store snippet history for jumps
            store_selection_keys = "<Tab>",
        })
    end,
}
