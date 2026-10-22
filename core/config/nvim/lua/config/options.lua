-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local o = vim.opt

o.expandtab = true
o.tabstop = 4
o.shiftwidth = 4

-- Clipboard (use OSC 52 in terminal to prevent Wayland dock glitches)
o.clipboard = "unnamedplus"

-- Over SSH there is no local clipboard provider, so yank via OSC 52 escape sequences
-- that the terminal forwards to the host's clipboard (needs clipboard-write allowed in terminal)
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
    local osc52 = require("vim.ui.clipboard.osc52")
    vim.g.clipboard = {
        name = "OSC 52",
        copy = {
            ["+"] = osc52.copy("+"),
            ["*"] = osc52.copy("*"),
        },
        paste = {
            ["+"] = osc52.paste("+"),
            ["*"] = osc52.paste("*"),
        },
    }
end

o.fileencoding = "utf-8"

-- disable word wrap:
o.wrap = false
o.sidescroll = 10
o.sidescrolloff = 10
o.scrolloff = 8
o.cursorlineopt = "both"

-- other utilities
vim.opt.winblend = 0
vim.opt.pumblend = 0
vim.opt.autoread = true

-- shell and search settings
o.ignorecase = true
o.smartcase = true

-- Global Behavior Flags
vim.g.autoformat = false

-- UI Rendering and View Scrolloffs
o.termguicolors = true
o.background = "dark"
o.list = false

-- Set project root based on .git, .clang-format, .clangd for consistency across tools
vim.g.root_spec = { { ".git", ".clang-format", ".clangd" }, "cwd" }

-- Cross-platform JAVA_HOME resolver (macOS Homebrew & Linux paths)
local function resolve_java_home()
    local env_java = os.getenv("JAVA_HOME")
    if env_java and env_java ~= "" and vim.fn.isdirectory(env_java) == 1 then
        return env_java
    end

    if vim.fn.executable("/usr/libexec/java_home") == 1 then
        local handle = io.popen("/usr/libexec/java_home -v 21 2>/dev/null || /usr/libexec/java_home 2>/dev/null")
        if handle then
            local result = handle:read("*a")
            handle:close()
            result = result:gsub("%s+", "")
            if result ~= "" and vim.fn.isdirectory(result) == 1 then
                return result
            end
        end
    end

    local candidate_paths = {
        "/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home",
        "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home",
        "/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home",
        "/usr/lib/jvm/java-21-openjdk-amd64",
        "/usr/lib/jvm/java-21-openjdk",
        "/usr/lib/jvm/default-java",
    }

    for _, path in ipairs(candidate_paths) do
        if vim.fn.isdirectory(path) == 1 then
            return path
        end
    end
    return nil
end

local java_home = resolve_java_home()
if java_home then
    vim.env.JAVA_HOME = java_home
    vim.env.PATH = java_home .. "/bin:" .. vim.env.PATH
end

