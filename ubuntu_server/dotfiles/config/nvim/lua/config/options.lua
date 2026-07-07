local o = vim.opt

-- Global Behavior Flags
vim.g.autoformat = false
vim.g.copilot_assume_mapped = true

-- Tabs and Indentation
o.expandtab = true
o.tabstop = 4
o.shiftwidth = 4
o.smartindent = true

-- UI Rendering and View Scrolloffs
o.termguicolors = true
o.background = "dark"
o.wrap = false
o.list = false

o.scrolloff = 8
o.sidescroll = 10
o.sidescrolloff = 10
o.cursorlineopt = "both"

o.winblend = 0
o.pumblend = 0

-- Search Patterns
o.ignorecase = true
o.smartcase = true

-- System and Buffer Management
o.encoding = "utf-8"
o.fileencoding = "utf-8"

o.autoread = true
o.autochdir = true

-- Important for responsive checktime
o.updatetime = 200

-- Clipboard Configuration (OSC52)
o.clipboard = "unnamedplus"

vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
    ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
  },
}

local java_home = "/usr/lib/jvm/java-21-openjdk-amd64"
vim.env.JAVA_HOME = java_home
vim.env.PATH = java_home .. "/bin:" .. vim.env.PATH