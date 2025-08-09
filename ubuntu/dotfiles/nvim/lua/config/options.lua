-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local o = vim.opt

o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.smartindent = true

o.encoding = "utf-8"
o.fileencoding = "utf-8"

-- disable word wrap:
o.wrap = false
o.sidescroll = 10
o.sidescrolloff = 10
o.scrolloff = 8
o.cursorlineopt = "both"

-- other utilities
vim.g.copilot_assume_mapped = true

-- shell and search settings
o.shell = "zsh"
o.ignorecase = true
o.smartcase = true
