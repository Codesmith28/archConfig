-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    command = "FormatWriteLock",
})

vim.api.nvim_create_autocmd("FileType", {
    callback = function()
        if vim.bo.filetype == "cpp" then
            vim.opt.tabstop = 8
            vim.opt.shiftwidth = 8
        else
            vim.opt.tabstop = 4
            vim.opt.shiftwidth = 4
        end
    end,
})

-- Force Neovim to follow your file into subdirectories
-- Dynamically update system environment variables with absolute paths
vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*.cpp",
    callback = function()
        vim.env.CP_FILE = vim.fn.expand("%:p") -- Absolute path to the source code
        vim.env.CP_OUT = vim.fn.expand("%:p:r") -- Absolute path for the output binary
    end,
})
