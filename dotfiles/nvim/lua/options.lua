require "nvchad.options"

-- add yours here!

local o = vim.o

-- relative line numbering:
o.relativenumber = true

-- set tabs to have 2 spaces
o.tabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.smartindent = true

-- other utilites
vim.g.copilot_assume_mapped = true

-- shell and search settings
o.shell = "zsh"
o.ignorecase = true
o.smartcase = true

-- o.cursorlineopt ='both' -- to enable cursorline!
