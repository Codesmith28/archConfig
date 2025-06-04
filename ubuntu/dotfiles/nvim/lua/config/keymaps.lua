-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Escape in insert mode
map("i", "kj", "<Esc>", { noremap = false })

-- Ctrl+A: Select all, keep cursor position
map("n", "<C-a>", "mzggVG", opts)

-- Ctrl+C: Copy all to system clipboard, keep cursor position
map("n", "<C-c>", 'mzggVG"+y`z', opts)
