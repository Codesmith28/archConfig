-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local o = vim.opt

o.expandtab = true
o.tabstop = 4
o.shiftwidth = 4

-- Clipboard: Use OSC 52 for yanking to host system clipboard universally
-- (works over SSH, across terminal multiplexers like Herdr, on macOS, and on Wayland
-- without invoking wl-copy which causes transient window flicker in GNOME).
-- For pasting, avoid terminal OSC 52 read queries (which time out or get blocked
-- by terminals/multiplexers for security reasons); instead, paste from internal
-- registers/cache directly. External text pasted into terminal Neovim is handled
-- automatically via terminal bracketed paste (Ctrl+Shift+V / Cmd+V).
o.clipboard = "unnamedplus"

local osc52 = require("vim.ui.clipboard.osc52")
local clipboard_cache = { ["+"] = nil, ["*"] = nil }

local function osc_copy(reg)
    local fn = osc52.copy(reg)
    return function(lines, regtype)
        clipboard_cache[reg] = { lines, regtype }
        fn(lines)
    end
end

local function safe_paste(reg)
    return function()
        local val = clipboard_cache[reg] or clipboard_cache[reg == "+" and "*" or "+"]
        if val and val[1] and #val[1] > 0 then
            return val
        end
        local reginfo = vim.fn.getreginfo('"')
        if reginfo and reginfo.regcontents and #reginfo.regcontents > 0 then
            return { reginfo.regcontents, reginfo.regtype or "v" }
        end
        return { {}, "" }
    end
end

vim.g.clipboard = {
    name = "OSC 52",
    copy = {
        ["+"] = osc_copy("+"),
        ["*"] = osc_copy("*"),
    },
    paste = {
        ["+"] = safe_paste("+"),
        ["*"] = safe_paste("*"),
    },
}

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
vim.g.autoformat = true

-- Disable swap files to avoid conflicts, file locks, and freezes when opening
-- the same file across multiple Neovim instances. Persistent undo ('undofile') is
-- already enabled by LazyVim for crash recovery.
o.swapfile = false

-- Fallback swap handling for any legacy swap files on disk:
-- Silently open for editing without blocking prompt, then notify non-intrusively
vim.opt.shortmess:append("A")
vim.api.nvim_create_autocmd("SwapExists", {
    group = vim.api.nvim_create_augroup("user_swap_handling", { clear = true }),
    callback = function(args)
        vim.v.swapchoice = "e"
        vim.schedule(function()
            vim.notify(
                string.format("Swap file found for '%s' (opened anyway).", vim.fn.fnamemodify(args.file, ":t")),
                vim.log.levels.WARN,
                { title = "Swap File" }
            )
        end)
    end,
})

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
