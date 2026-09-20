-- Autocmds are automatically loaded on the VeryLazy event
-- (Helm filetype detection lives in ftdetect/helm.lua instead -- it needs to
-- run at startup, before VeryLazy fires.)

-- 1. Optimized Refresh
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

-- 2. Sync yanked text to system clipboard
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Sync yanked text to system clipboard",
    group = vim.api.nvim_create_augroup("SyncYankToClipboard", { clear = true }),
    callback = function()
        if vim.v.event.operator == "y" then
            pcall(function()
                vim.fn.setreg("+", vim.fn.getreg('"'))
            end)
        end
    end,
})
