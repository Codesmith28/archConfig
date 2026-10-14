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
