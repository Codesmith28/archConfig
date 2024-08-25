require "nvchad.mappings"
require("oil").setup()

-- add yours here

local map = vim.keymap.set

map("i", "kj", "<ESC>")

-- Add go tags:
map("n", "<leader>gsj", "<cmd> GoTagAdd json <CR>", { desc = "Add json struct tags" })
map("n", "<leader>gsy", "<cmd> GoTagAdd yaml <CR>", { desc = "Add yaml struct tags" })

-- Telescope enhancements
map("n", "<C-p>", "<cmd>Telescope find_files<CR>", { desc = "Telescope Find files" })
map("n", "<C-F>", "<cmd>Telescope live_grep<CR>", { desc = "Telescope Live grep" })

-- editing
map("n", "<C-x>", "dd", { desc = "Delete current line" })
map("n", "<C-a>", "ggVG", { desc = "Select all" })

-- LSP Rename
map("n", "<leader>rm", vim.lsp.buf.rename, { desc = "LSP Renamer" })

-- Ctrl+j to open fullscreen terminal and Esc to escape from the terminal
map("n", "<c-`>", function()
    vim.cmd "terminal"
    vim.cmd "startinsert"
end, { desc = "terminal full screen" })

-- indenting
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- notification history:
map("n", "<M-n>", "<cmd>Telescope notify<CR>", { desc = "Notification history" })

-- oil.nvim:
map("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- change tab not buffer:
map("n", "<M-]>", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<M-[>", "<cmd>tabprevious<CR>", { desc = "Previous tab" })

-- navigation:
map("n", "<M-j>", "jzz", { desc = "Move down and center", silent = true })
map("n", "<M-k>", "kzz", { desc = "Move up and center", silent = true })
