return {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        -- Skip confirmation for simple edits
        skip_confirm_for_simple_edits = true,
        -- Decrease delay in actions
        keymaps = {
            ["g?"] = "actions.show_help",
            ["<CR>"] = "actions.select",
            ["<C-v>"] = "actions.select_vsplit",
            ["<C-s>"] = "actions.select_split",
            ["<C-t>"] = "actions.select_tab",
            ["<C-p>"] = "actions.preview",
            ["<C-c>"] = "actions.close",
            ["<C-r>"] = "actions.refresh",
            ["-"] = "actions.parent",
            ["_"] = "actions.open_cwd",
            ["`"] = "actions.cd",
            ["~"] = "actions.tcd",
            ["gs"] = "actions.change_sort",
            ["gx"] = "actions.open_external",
            ["g."] = "actions.toggle_hidden",
        },
        -- Show hidden files by default
        view_options = {
            show_hidden = true,
        },
        -- Configure floating window
        float = {
            padding = 2,
            max_width = 60,
            max_height = 30,
            border = "rounded",
            win_options = {
                winblend = 0,
            },
        },
        -- Add more columns of information
        columns = {
            "icon",
            "permissions",
            "size",
            "mtime",
        },
        -- Customize progress display
        progress = {
            max_width = 0.9,
            min_width = { 40, 0.4 },
            width = nil,
            max_height = 0.9,
            min_height = { 5, 0.1 },
            height = nil,
            border = "rounded",
            minimized_border = "none",
            win_options = {
                winblend = 0,
            },
        },
    },
}
