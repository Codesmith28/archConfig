-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local o = vim.opt

o.expandtab = true
o.smartindent = true
o.tabstop = 4
o.shiftwidth = 4

o.encoding = "utf-8"
o.fileencoding = "utf-8"

-- disable word wrap:
o.wrap = false
o.sidescroll = 10
o.sidescrolloff = 10
o.scrolloff = 8
o.cursorlineopt = "both"

-- other utilities
vim.opt.autochdir = true
vim.opt.winblend = 0
vim.opt.pumblend = 0
vim.opt.autoread = true

-- shell and search settings
o.shell = "zsh"
o.ignorecase = true
o.smartcase = true

-- Global Behavior Flags
vim.g.autoformat = true
vim.g.copilot_assume_mapped = true

-- UI Rendering and View Scrolloffs
o.termguicolors = true
o.background = "dark"
o.list = false

local java_home = "/usr/lib/jvm/java-21-openjdk-amd64" -- Adjust this path if your Java 21 home is elsewhere
vim.env.JAVA_HOME = java_home
vim.env.PATH = java_home .. "/bin:" .. vim.env.PATH
