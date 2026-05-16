-- ~/.config/nvim/lua/neovide_ui.lua

vim.g.neovide_opacity = 0.72
vim.g.neovide_background_color = "#080707"
vim.g.neovide_window_blurred = true
vim.g.neovide_cursor_vfx_mode = "pixiedust"
vim.g.neovide_floating_shadow = false

-- vim.o.winblend = 2
-- vim.o.pumblend = 2

-- local function make_transparent()
--     vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
--     vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
--     vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE" })
--     vim.api.nvim_set_hl(0, "NoiceCmdlinePopup", { bg = "NONE" })
--     vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorder", { bg = "NONE" })
-- end
--
-- make_transparent()

-- vim.api.nvim_create_autocmd("ColorScheme", {
--     pattern = "*",
--     callback = make_transparent,
-- })
