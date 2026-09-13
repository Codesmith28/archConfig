-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local o = vim.opt

o.expandtab = true
o.smartindent = true
o.tabstop = 4
o.shiftwidth = 4

o.encoding = "utf-8"
o.fileencoding = "utf-8"

-- disable word wrap:
o.wrap = false
o.sidescroll = 10
o.sidescrolloff = 10
o.scrolloff = 8
o.cursorlineopt = "both"

-- other utilities
vim.opt.winblend = 0
vim.opt.pumblend = 0
vim.opt.autoread = true

-- shell and search settings
o.ignorecase = true
o.smartcase = true

-- Global Behavior Flags
vim.g.autoformat = true

-- UI Rendering and View Scrolloffs
o.termguicolors = true
o.background = "dark"
o.list = false
