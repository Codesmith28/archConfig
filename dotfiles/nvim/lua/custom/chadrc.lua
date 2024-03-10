---@type ChadrcConfig
local M = {}

M.ui = { theme = 'doomchad', transparency = true }

M.plugins = "custom.plugins"

-- relative line numbering:
vim.opt.relativenumber = true

-- Set tabs to 4 spaces
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.shell = "zsh"

return M
