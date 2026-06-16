local autoread_group = vim.api.nvim_create_augroup("AutoReadFiles", { clear = true })

-- Check whether files changed on disk
vim.api.nvim_create_autocmd({
  "FocusGained",
  "BufEnter",
  "CursorHold",
  "CursorHoldI",
}, {
  group = autoread_group,
  callback = function()
    if vim.bo.buftype == "" then
      vim.cmd("silent! checktime")
    end
  end,
})

-- Notify when a file was reloaded from disk
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = autoread_group,
  callback = function()
    vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.INFO)
  end,
})
