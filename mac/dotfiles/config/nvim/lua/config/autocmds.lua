-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    callback = function(args)
        -- Only attempt formatting if the buffer can actually be modified
        if vim.api.nvim_get_option_value("modifiable", { buf = args.buf }) then
            vim.cmd("FormatWriteLock")
        end
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    callback = function()
        if vim.bo.filetype == "cpp" or vim.bo.filetype == "c" then
            vim.opt_local.tabstop = 8
            vim.opt_local.shiftwidth = 8
        else
            vim.opt_local.tabstop = 4
            vim.opt_local.shiftwidth = 4
        end
    end,
})
