-- file explorer as buffer
vim.api.nvim_create_autocmd("FileType", {
    pattern = "oil",
    callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
    end,
})

return {
    "stevearc/oil.nvim",
    lazy = false,
    opts = {},
    -- Optional dependencies
    -- dependencies = { { "echasnovski/mini.icons", opts = {} } },
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
    config = function()
        require("oil").setup {
            columns = {
                "icon",
                "permissions",
                "size",
            },
            -- keymaps = {
            --     ["g?"] = "actions.show_help",
            --     ["<CR>"] = "actions.select",
            --     ["<C-\\>"] = "actions.select_vsplit",
            --     ["<C-enter>"] = "actions.select_split", -- this is used to navigate left
            --     ["<C-t>"] = "actions.select_tab",
            --     ["<C-p>"] = "actions.preview",
            --     ["<C-c>"] = "actions.close",
            --     ["<C-r>"] = "actions.refresh",
            --     ["-"] = "actions.parent",
            --     ["_"] = "actions.open_cwd",
            --     ["`"] = "actions.cd",
            --     ["~"] = "actions.tcd",
            --     ["gs"] = "actions.change_sort",
            --     ["gx"] = "actions.open_external",
            --     ["g."] = "actions.toggle_hidden",
            -- },
            -- use_default_keymaps = false,
            skip_confirm_for_simple_edits = true,
            view_options = {
                show_hidden = true,
            },
            float = {
                max_width = 80,
                max_height = 20,
            },
        }
    end,
}
