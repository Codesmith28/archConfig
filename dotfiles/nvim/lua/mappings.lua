require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("i", "kj", "<ESC>")
map("n", "<leader>gsj", "<cmd> GoTagAdd json <CR>", { desc = "Add json struct tags" })
map("n", "<leader>gsy", "<cmd> GoTagAdd yaml <CR>", { desc = "Add yaml struct tags" })
map("n", "<C-p>", "<cmd>Telescope find_files<CR>", { desc = "Telescope Find files" })
map("n", "<C-F>", "<cmd>Telescope live_grep<CR>", { desc = "Telescope Live grep" })
map("n", "<C-x>", "dd", { desc = "Delete current line" })
map("n", "<leader>rm", vim.lsp.buf.rename, { desc = "LSP Renamer" })
-- vim.keymap.set("n", "<leader>rm", vim.lsp.buf.rename, { noremap = true, silent = true }

-- Ctrl+j to open fullscreen terminal and Esc to escape from the terminal
map("n", "<c-`>", function()
    vim.cmd "terminal"
    vim.cmd "startinsert"
end, { desc = "terminal full screen" })

-- indenting
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })