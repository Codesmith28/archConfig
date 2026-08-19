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

        -- 1. Load community friendly-snippets (lazily by filetype)
        require("luasnip.loaders.from_vscode").lazy_load()

        -- 2. Load custom VSCode-style snippets from lua/snippets
        local snippet_path = vim.fn.stdpath("config") .. "/lua/snippets"
        require("luasnip.loaders.from_vscode").lazy_load({
            paths = { snippet_path },
        })

        -- 3. Load snipmate style snippets if any exist
        require("luasnip.loaders.from_snipmate").lazy_load()

        -- 4. Cleanly unlink snippet session when leaving insert/select mode
        -- Prevents LuaSnip from staying trapped in an old snippet state
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
