-- Autocmds are automatically loaded on the VeryLazy event

-- Treat Helm chart templates as filetype "helm" instead of "yaml", so yamlls
-- (which chokes on Go-template {{ }} syntax) doesn't attach, and helm_ls
-- (which understands it) does instead.
vim.filetype.add({
    pattern = {
        [".*/templates/.*%.tpl"] = "helm",
        [".*/templates/.*%.ya?ml"] = "helm",
        [".*/templates/.*%.txt"] = "helm",
        ["helmfile.*%.ya?ml"] = "helm",
    },
})

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
