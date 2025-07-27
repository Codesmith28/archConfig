-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Escape in insert mode
map("i", "kj", "<Esc>", { noremap = false })

-- editing
map("n", "<C-a>", "ggVG", { desc = "Select all" })

-- Ctrl+C: Copy all to system clipboard, keep cursor position
map("n", "<C-c>", 'mzggVG"+y`z', opts)

-- enable horizontal scrolling with mouse
vim.opt.mouse = "a"
map("n", "<S-ScrollWheelUp>", "10zh", { noremap = true, silent = true })
map("n", "<S-ScrollWheelDown>", "10zl", { noremap = true, silent = true })

-- harpoon mappings
map("n", "<leader>ah", "<cmd>lua require('harpoon.mark').add_file()<CR>", { desc = "Add mark" })
map("n", "<leader>lh", "<cmd>Telescope harpoon marks<CR>", { desc = "Toggle mark telescope" })
map("n", "<leader>fm", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<CR>", { desc = "Toggle mark menu" })

-- Move lines
map("v", "<C-j>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true, desc = "Move line down" })
map("v", "<C-k>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true, desc = "Move line up" })

-- change tab not buffer:
map("n", "<M-]>", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<M-[>", "<cmd>tabprevious<CR>", { desc = "Previous tab" })

-- indenting
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Add go tags:
map("n", "<leader>gsj", "<cmd> GoTagAdd json <CR>", { desc = "Add json struct tags" })
map("n", "<leader>gsy", "<cmd> GoTagAdd yaml <CR>", { desc = "Add yaml struct tags" })
