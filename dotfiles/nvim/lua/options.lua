require "nvchad.options"

-- add yours here!

local o = vim.o

-- relative line numbering:
o.relativenumber = true

-- set tabs to have 4 spaces
o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.smartindent = true

vim.cmd [[
    autocmd FileType javascript,typescript,json,css setlocal shiftwidth=2 tabstop=2
]]

-- other utilites
vim.g.copilot_assume_mapped = true

-- shell and search settings
o.shell = "zsh"
o.ignorecase = true
o.smartcase = true

-- disable word wrap:
o.wrap = false
o.sidescroll = 10
o.sidescrolloff = 8
o.cursorlineopt = "both" -- to enable cursorline!

-- enable horizontal scrolling with mouse
vim.opt.mouse = "a"
vim.api.nvim_set_keymap("n", "<S-ScrollWheelUp>", "10zh", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<S-ScrollWheelDown>", "10zl", { noremap = true, silent = true })

-- center the screen when moving up and down
vim.api.nvim_set_keymap("n", "j", "jzz", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "k", "kzz", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "G", "Gzz", { noremap = true, silent = true })

-- comments
vim.api.nvim_set_keymap("n", "<C-/>", "gcc", { noremap = false })
vim.api.nvim_set_keymap("v", "<C-/>", "gcc", { noremap = false })
