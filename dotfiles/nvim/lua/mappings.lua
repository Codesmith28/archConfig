require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

-- map("i", "jk", "<ESC>")
map("n", "<leader>gsj", "<cmd> GoTagAdd json <CR>", { desc = "Add json struct tags" })
map("n", "<leader>gsy", "<cmd> GoTagAdd yaml <CR>", { desc = "Add yaml struct tags" })
map("n", "<C-p>", "<cmd>Telescope find_files<CR>", { desc = "Telescope Find files" })
map("n", "<C-F>", "<cmd>Telescope live_grep<CR>", { desc = "Telescope Live grep" })
map("n", "<C-x>", "dd", { desc = "Delete current line" })

-- Ctrl+j to open fullscreen terminal and Esc to escape from the terminal
map("n", "<c-`>", function()
    vim.cmd "terminal"
    vim.cmd "startinsert"
end, { desc = "terminal full screen" })
-- map("t", "<esc>", "<c-\\><c-n>", { desc = "escape from terminal mode" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- M.gopher = {
--     plugin = true,
--     n = {
--         ["<leader>gsj"] = {
--             "<cmd> GoTagAdd json <CR>",
--             "Add json struct tags",
--         },
--         ["<leader>gsy"] = {
--             "<cmd> GoTagAdd yaml <CR>",
--             "Add yaml struct tags",
--         },
--     },
-- }
