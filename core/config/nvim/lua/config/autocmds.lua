-- Autocmds are automatically loaded on the VeryLazy event
-- (Helm filetype detection lives in ftdetect/helm.lua instead -- it needs to
-- run at startup, before VeryLazy fires.)

local user_checktime_group = vim.api.nvim_create_augroup("user_checktime", { clear = true })

-- 1. Optimized Refresh
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "WinEnter" }, {
    group = user_checktime_group,
    callback = function()
        if vim.o.buftype ~= "nofile" and vim.fn.getcmdwintype() == "" then
            vim.cmd("checktime")
        end
    end,
})

-- Notification when a file changes on disk
vim.api.nvim_create_autocmd("FileChangedShellPost", {
    group = user_checktime_group,
    callback = function()
        vim.notify("File changed on disk. Buffer reloaded!", vim.log.levels.INFO)
    end,
})

-- Optimize format-on-save: skip formatting if buffer is unmodified
-- (prevents UI freeze and slowdowns when repeatedly saving or spamming save commands)
if LazyVim and LazyVim.format then
    local orig_format = LazyVim.format.format
    LazyVim.format.format = function(opts)
        opts = opts or {}
        local buf = opts.buf or vim.api.nvim_get_current_buf()
        if not opts.force and not vim.bo[buf].modified then
            return
        end
        return orig_format(opts)
    end
end

-- Ensure unused code/variables (DiagnosticUnnecessary) remain dimmed and italic across any colorscheme
local user_unnecessary_group = vim.api.nvim_create_augroup("user_diagnostic_unnecessary", { clear = true })
vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
    group = user_unnecessary_group,
    callback = function()
        local hl = vim.api.nvim_get_hl(0, { name = "DiagnosticUnnecessary" })
        if hl and not hl.italic then
            vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", vim.tbl_extend("force", hl, { italic = true }))
        end
    end,
})
