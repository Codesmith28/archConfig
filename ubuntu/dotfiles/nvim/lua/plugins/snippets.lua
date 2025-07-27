return {
    "L3MON4D3/LuaSnip",
    version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
        require("luasnip.loaders.from_snipmate").lazy_load()
        require("luasnip/loaders/from_vscode").lazy_load({ paths = "~/.config/nvim/lua/snippets" })
        require("luasnip").setup({
            updateevents = "TextChanged, TextChangedI",
        })
    end,
}
