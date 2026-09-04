return {
    "L3MON4D3/LuaSnip",
    lazy = false,
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
        history = true,
        delete_check_events = "TextChanged",
        updateevents = "TextChanged,TextChangedI",
        enable_autosnippets = true,
    },
    config = function(_, opts)
        local ls = require("luasnip")
        ls.setup(opts)

        -- community friendly-snippets (lazily by filetype)
        require("luasnip.loaders.from_vscode").lazy_load()

        -- custom VSCode-style snippets from lua/snippets
        local snippet_path = vim.fn.stdpath("config") .. "/lua/snippets"
        require("luasnip.loaders.from_vscode").lazy_load({
            paths = { snippet_path },
        })

        -- snipmate style snippets, if any exist
        require("luasnip.loaders.from_snipmate").lazy_load()

        -- unlink snippet session on leaving insert/select, so LuaSnip doesn't stay trapped in an old snippet state
        vim.api.nvim_create_autocmd("ModeChanged", {
            pattern = { "s:n", "i:n" },
            group = vim.api.nvim_create_augroup("LuaSnipUnlinkOnExit", { clear = true }),
            callback = function()
                if ls.session.current_nodes[vim.api.nvim_get_current_buf()] and not ls.session.jump_active then
                    ls.unlink_current()
                end
            end,
        })
    end,
}
