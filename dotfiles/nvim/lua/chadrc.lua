-- This file  needs to have same structure as nvc1wonfig.lua
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.ui = {
  theme = "everblush",
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

  nvim_tree_ignore = { ".git", "node_modules", ".cache" }, -- add or remove as needed
  -- other options...
}

-- relative line numbering:
vim.opt.relativenumber = true

-- Set tabs to 2 spaces
vim.opt.shell = "zsh"
vim.g.copilot_assume_mapped = true

return M
