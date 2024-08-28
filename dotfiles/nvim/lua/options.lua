require "nvchad.options"

-- add yours here!

local o = vim.o

-- relative line numbering:
o.relativenumber = true

-- set default tab size to 4 spaces
o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.smartindent = true

-- vim.api.nvim_create_autocmd({ "FileType" }, {
--     pattern = { "javascript", "typescript", "json", "css", "html", "jsx", "tsx", "javascriptreact", "typescriptreact" },
--     callback = function()
--         vim.bo.tabstop = 2
--         vim.bo.shiftwidth = 2
--     end,
-- })

-- other utilities
vim.g.copilot_assume_mapped = true

-- shell and search settings
o.shell = "zsh"
o.ignorecase = true
o.smartcase = true

-- disable word wrap:
o.wrap = false
o.sidescroll = 10
o.sidescrolloff = 10
o.scrolloff = 8
o.cursorlineopt = "both"

-- enable horizontal scrolling with mouse
vim.opt.mouse = "a"
vim.api.nvim_set_keymap("n", "<S-ScrollWheelUp>", "10zh", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<S-ScrollWheelDown>", "10zl", { noremap = true, silent = true })

-- comments
vim.api.nvim_set_keymap("n", "<C-/>", "gcc", { noremap = false })
vim.api.nvim_set_keymap("v", "<C-/>", "gcc", { noremap = false })

-- for neovide
vim.g.neovide_floating_blur_amount_x = 2.0
vim.g.neovide_floating_blur_amount_y = 2.0

vim.g.neovide_floating_shadow = true
vim.g.neovide_floating_z_height = 10
vim.g.neovide_light_angle_degrees = 45
vim.g.neovide_light_radius = 5

vim.opt.termguicolors = true
