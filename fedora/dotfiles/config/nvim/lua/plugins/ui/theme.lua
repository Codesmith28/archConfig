-- Universal theme styling: applies italics, diagnostic undercurls,
-- clean virtual text, inlay hints, and transparency across ALL themes.
local function apply_theme_overrides()
    -- 1. Italics for comments, keywords, and syntax tokens
    local italic_groups = {
        "Comment",
        "@comment",
        "@comment.documentation",
        "Keyword",
        "Statement",
        "Conditional",
        "Repeat",
        "Label",
        "Exception",
        "Include",
        "StorageClass",
        "Structure",
        "TypeDef",
        "@keyword",
        "@keyword.function",
        "@keyword.return",
        "@keyword.conditional",
        "@keyword.repeat",
        "@keyword.operator",
        "@keyword.import",
        "@keyword.coroutine",
        "@keyword.storage",
        "@keyword.modifier",
        "@keyword.type",
        "@type.qualifier",
        "@lsp.type.keyword",
        "@lsp.type.modifier",
        "LspInlayHint",
        "DiagnosticVirtualTextError",
        "DiagnosticVirtualTextWarn",
        "DiagnosticVirtualTextInfo",
        "DiagnosticVirtualTextHint",
    }

    for _, name in ipairs(italic_groups) do
        local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
        ---@cast hl any
        if hl and not vim.tbl_isempty(hl) then
            hl.italic = true
            if name:match("^DiagnosticVirtualText") or name == "LspInlayHint" then
                hl.bg = nil
            end
            vim.api.nvim_set_hl(0, name, hl)
        else
            vim.api.nvim_set_hl(0, name, { italic = true })
        end
    end

    -- 2. Diagnostic undercurls (preserving theme's diagnostic colors for sp)
    local diags = {
        Error = vim.api.nvim_get_hl(0, { name = "DiagnosticError", link = false }).fg,
        Warn = vim.api.nvim_get_hl(0, { name = "DiagnosticWarn", link = false }).fg,
        Info = vim.api.nvim_get_hl(0, { name = "DiagnosticInfo", link = false }).fg,
        Hint = vim.api.nvim_get_hl(0, { name = "DiagnosticHint", link = false }).fg,
    }

    for type, color in pairs(diags) do
        local group = "DiagnosticUnderline" .. type
        local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
        ---@cast hl any
        hl.undercurl = true
        hl.underline = false
        if color then
            hl.sp = color
        end
        vim.api.nvim_set_hl(0, group, hl)
    end

    -- 3. Transparency for editor buffer (keeps floating windows & sidebars solid)
    local transparent_groups = { "Normal", "NormalNC", "SignColumn", "FoldColumn", "Folded" }
    for _, name in ipairs(transparent_groups) do
        local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
        ---@cast hl any
        if hl then
            hl.bg = nil
            vim.api.nvim_set_hl(0, name, hl)
        end
    end
end

local theme_group = vim.api.nvim_create_augroup("ThemeCustomHighlights", { clear = true })
vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
    group = theme_group,
    callback = apply_theme_overrides,
})

local specs = {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = true,
        opts = {
            term_colors = true,
        },
    },
    {
        "folke/tokyonight.nvim",
        lazy = true,
        opts = {
            style = "night",
            terminal_colors = true,
            styles = {
                -- sidebars = "dark",
                -- floats = "dark",
            },
            on_highlights = function(hl, c)
                hl.LspInlayHint = {
                    fg = c.dark3,
                    bg = c.none,
                }
            end,
        },
    },
}

-- Call the symlinked Omarchy themeing mechanism
local ok, omarchy_spec = pcall(require, "plugins.theme")
if ok and type(omarchy_spec) == "table" then
    -- Include Omarchy hotreload and theme registry for live switching
    local ok_omarchy, omarchy = pcall(require, "omarchy")
    if ok_omarchy and type(omarchy) == "table" then
        if omarchy.hotreload then
            table.insert(specs, omarchy.hotreload)
        end
        if omarchy.all_themes then
            for _, theme in ipairs(omarchy.all_themes) do
                table.insert(specs, theme)
            end
        end
    end

    for _, spec in ipairs(omarchy_spec) do
        table.insert(specs, spec)
    end
else
    table.insert(specs, {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "tokyonight-night",
        },
    })
end

return specs
