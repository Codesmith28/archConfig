-- This file  needs to have same structure as nvc1wonfig.lua
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.ui = {
  theme = "gruvbox",
  transparency = true,
  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },

  cheatsheet = { theme = "grid" }, -- simple/grid

  lsp = { signature = true },

  term = {
    hl = "Normal:term,WinSeparator:WinSeparator",
    sizes = { sp = 0.3, vsp = 0.4 },
    float = {
      relative = "editor",
      row = 0.3,
      col = 0.25,
      width = 0.5,
      height = 0.4,
      border = "single",
    },
  },

-- show all thfiles and dont exclude those in .gitignore in NvimTree
  show_all_buffers = true,
}


-- relative line numbering:
vim.opt.relativenumber = true

vim.opt.shell = "zsh"
vim.g.copilot_assume_mapped = true

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.title = true
vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.expandtab = true
vim.opt.scrolloff = 8
vim.opt.inccommand = "split"
vim.opt.wrap = true
vim.opt.smarttab = true
vim.opt.breakindent = true
vim.opt.shiftwidth = 2

return M
