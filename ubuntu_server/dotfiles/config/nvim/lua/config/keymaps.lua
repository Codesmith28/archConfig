-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.api.nvim_set_keymap

-- Escape in insert mode
map("i", "kj", "<Esc>", { noremap = false })

-- harpoon mappings
map("n", "<leader>ah", "<cmd>lua require('harpoon.mark').add_file()<CR>", { desc = "Add mark" })
map("n", "<leader>lh", "<cmd>Telescope harpoon marks<CR>", { desc = "Toggle mark telescope" })
map("n", "<leader>fm", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<CR>", { desc = "Toggle mark menu" })

-- Invert horizontal scroll for touchpad
vim.keymap.set("n", "<ScrollWheelRight>", "<ScrollWheelLeft>", { noremap = true, silent = true })
vim.keymap.set("n", "<ScrollWheelLeft>", "<ScrollWheelRight>", { noremap = true, silent = true })