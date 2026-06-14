-- Autocmds are automatically loaded on the VeryLazy event

-- 1. Safe Formatting Setup
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    callback = function(args)
        if vim.api.nvim_get_option_value("modifiable", { buf = args.buf }) then
            vim.cmd("FormatWriteLock")
        end
    end,
})

-- -- 2. Clean Indentation Settings
-- vim.api.nvim_create_autocmd("FileType", {
--     callback = function()
--         if vim.bo.filetype == "cpp" or vim.bo.filetype == "c" then
--             vim.opt_local.tabstop = 8
--             vim.opt_local.shiftwidth = 8
--         else
--             vim.opt_local.tabstop = 4
--             vim.opt_local.shiftwidth = 4
--         end
--     end,
-- })

-- 3. Optimized Refresh (Removed rapid CursorHold loops)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "WinEnter" }, {
    callback = function()
        if vim.o.buftype ~= "nofile" and vim.fn.getcmdwintype() == "" then
            vim.cmd("checktime")
        end
    end,
})

-- Notification when a file changes on disk
vim.api.nvim_create_autocmd("FileChangedShellPost", {
    callback = function()
        vim.notify("File changed on disk. Buffer reloaded!", vim.log.levels.INFO)
    end,
})
