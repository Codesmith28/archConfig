if vim.g.neovide then
    vim.g.neovide_opacity = 0.72
    vim.g.neovide_background_color = "#080707"
    vim.g.neovide_window_blurred = true
    vim.g.neovide_cursor_vfx_mode = "pixiedust"
    vim.g.neovide_floating_shadow = false

    -- Save file directly using Cmd+S across Normal, Insert, and Visual modes
    vim.keymap.set({ "n", "i", "v" }, "<D-s>", "<cmd>write<cr>", { desc = "Save file" })
end
