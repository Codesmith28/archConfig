pcall(function()
    require("lazy").load({ plugins = { "gruvbox.nvim" } })
end)

local ok, gruvbox_v2 = pcall(require, "gruvbox_v2")
if ok and gruvbox_v2.load then
    gruvbox_v2.load()
else
    local g_ok, gruvbox = pcall(require, "gruvbox")
    if g_ok and gruvbox.load then
        gruvbox.load()
    end
    vim.g.colors_name = "gruvbox_v2"
end
