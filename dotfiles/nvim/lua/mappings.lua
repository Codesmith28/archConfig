require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
-- map("i", "jk", "<ESC>")
map("n", "<leader>gsj", "<cmd> GoTagAdd json <CR>", { desc = "Add json struct tags" })
map("n", "<leader>gsy", "<cmd> GoTagAdd yaml <CR>", { desc = "Add yaml struct tags" })

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
