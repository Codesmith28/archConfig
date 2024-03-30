---@type ChadrcConfig
local M = {}

M.ui = { theme = 'monekai', transparency = true,
	hl_override = {
		Comment = { italic = true },
		["@comment"] = { italic = true },
	},
}

M.plugins = "custom.plugins"

-- relative line numbering:
vim.opt.relativenumber = true

-- Set tabs to 4 spaces
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.shell = "zsh"
vim.g.copilot_assume_mapped = true

return M
