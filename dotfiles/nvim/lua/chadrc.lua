-- This file  needs to have same structure as nvc1wonfig.lua
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.ui = {
  theme = "bearded-arc",
  transparency = true,
  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },

  cheatsheet = { theme = "grid" }, -- simple/grid

  lsp = { signature = true },
}

-- relative line numbering:
vim.opt.relativenumber = true

-- Set tabs to 4 spaces
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.shell = "zsh"
vim.g.copilot_assume_mapped = true

return M
