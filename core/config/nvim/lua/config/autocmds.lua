-- Autocmds are automatically loaded on the VeryLazy event
-- (Helm filetype detection lives in ftdetect/helm.lua instead -- it needs to
-- run at startup, before VeryLazy fires.)

local user_checktime_group = vim.api.nvim_create_augroup("user_checktime", { clear = true })

-- 1. Optimized refresh across windows/instances
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "WinEnter", "CursorHold" }, {
    group = user_checktime_group,
    callback = function()
        if vim.o.buftype ~= "nofile" and vim.fn.getcmdwintype() == "" and vim.fn.mode() == "n" then
            pcall(vim.cmd, "checktime")
        end
    end,
})

-- Safe external file change handler:
-- Automatically reloads if buffer is NOT modified locally.
-- If buffer HAS unsaved local modifications, suppresses blocking modal dialogs (W11)
-- to prevent UI freeze and keeps local edits while notifying non-intrusively.
vim.api.nvim_create_autocmd("FileChangedShell", {
    group = user_checktime_group,
    callback = function(args)
        local reason = vim.v.fcs_reason
        if reason == "changed" or reason == "time" or reason == "mode" then
            vim.v.fcs_choice = "reload"
        elseif reason == "conflict" then
            vim.v.fcs_choice = ""
            local filename = vim.fn.fnamemodify(args.file or "", ":t")
            vim.schedule(function()
                vim.notify(
                    string.format("File '%s' changed externally on disk. Retaining unsaved local buffer edits.", filename),
                    vim.log.levels.WARN,
                    { title = "File Conflict" }
                )
            end)
        end
    end,
})

-- Notification when a file is reloaded from disk
vim.api.nvim_create_autocmd("FileChangedShellPost", {
    group = user_checktime_group,
    callback = function(args)
        local filename = vim.fn.fnamemodify(args.file or "", ":t")
        vim.notify(
            string.format("File '%s' changed on disk. Buffer reloaded!", filename),
            vim.log.levels.INFO,
            { title = "File Reloaded" }
        )
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
