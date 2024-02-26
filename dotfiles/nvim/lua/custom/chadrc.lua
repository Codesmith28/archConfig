---@type ChadrcConfig
local M = {}

M.ui = { theme = 'solarized_dark', transparency = true }

M.plugins = "custom.plugins"

-- relative line numbering:
vim.opt.relativenumber = true

-- Set tabs to 4 spaces
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

return M
