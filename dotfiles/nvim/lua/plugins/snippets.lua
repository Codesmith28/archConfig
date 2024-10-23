return {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
        require("luasnip/loaders/from_vscode").lazy_load { paths = "../snippets" }
        require("luasnip").setup {
            updateevents = "TextChanged, TextChangedI",
        }
    end,
}
