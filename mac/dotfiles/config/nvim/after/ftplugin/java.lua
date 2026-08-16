-- after/ftplugin/java.lua
-- Enforce 4-space tab and indent size for Java files

vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
vim.opt_local.expandtab = true

-- Ensure vim-sleuth does not override buffer-local indent settings
vim.b.sleuth_heuristics = 0
