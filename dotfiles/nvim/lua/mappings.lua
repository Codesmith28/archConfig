require "nvchad.mappings"

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

-- change tab not buffer:
map("n", "<M-]>", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<M-[>", "<cmd>tabprevious<CR>", { desc = "Previous tab" })

-- navigation:
map("n", "<M-j>", "jzz", { desc = "Move down and center", silent = true })
map("n", "<M-k>", "kzz", { desc = "Move up and center", silent = true })
map("n", "-", "<CMD>Oil --float<CR>", { desc = "Open parent directory" })

-- toggle-checkboxes in markdown:
map("n", "<leader>tt", function()
    vim.cmd ":lua require('./configs/toggle-checkbox').toggle()"
end)

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

-- append the line below and cursor stays at same place
map("n", "J", "mzJ`z", { desc = "Append line below" })

-- toggle inlay hints:
map("n", "<leader>ih", "<cmd>lua require('lsp_extensions').inlay_hints()<CR>", { desc = "Toggle inlay hints" })
