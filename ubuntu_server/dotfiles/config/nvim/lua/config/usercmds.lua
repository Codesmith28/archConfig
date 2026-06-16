vim.api.nvim_create_user_command("ExpandAll", function()
  -- Checks if you are currently using snacks picker/explorer
  local picker = require("snacks.picker.core").get_current()
  if picker and picker.source.name == "explorer" then
    -- Programmatically trigger the recursive expand action
    require("snacks.explorer.actions").recursive_toggle(picker)
  else
    vim.notify("Not inside snacks.explorer", vim.log.levels.WARN)
  end
end, {})
