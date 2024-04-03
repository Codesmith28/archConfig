require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- unmap conrtol c 
map("n", "<C-c>", "<Nop>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
