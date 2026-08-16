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
vim.opt.autochdir = false -- Disabled to prevent breaking LSP root detection & fuzzy finders
vim.opt.winblend = 0
vim.opt.pumblend = 0
vim.opt.autoread = true

-- shell and search settings
o.shell = "zsh"
o.ignorecase = true
o.smartcase = true

-- Global Behavior Flags
vim.g.autoformat = false
vim.g.copilot_assume_mapped = true

-- UI Rendering and View Scrolloffs
o.termguicolors = true
o.background = "dark"
o.list = false

-- Cross-platform JAVA_HOME resolver (macOS & Linux)
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
