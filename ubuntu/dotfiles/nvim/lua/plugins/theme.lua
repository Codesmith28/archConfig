return {
    {
        "ellisonleao/gruvbox.nvim",
        priority = 1000,
        config = function()
            require("gruvbox").setup({
                terminal_colors = true,
                undercurl = true,
                underline = true,
                bold = true,
                italic = {
                    strings = true,
                    comments = true,
                    operators = false,
                    folds = true,
                    emphasis = true,
                },
                strikethrough = true,
                invert_selection = false,
                invert_signs = false,
                invert_tabline = false,
                invert_intend_guides = false,
                inverse = true, -- invert background for search, diffs, statuslines
                contrast = "hard", -- options: "hard", "soft", "medium"
                palette_overrides = {},
                overrides = {},
                dim_inactive = false,
                transparent_mode = true,
            })
        end,
    },
    {
        "Mofiqul/vscode.nvim",
        priority = 1000,
        config = function()
            require("vscode").setup({
                transparent = true,
                italic_comments = true,
                disable_nvimtree_bg = false,
                terminal_colors = true,
            })
        end,
    },
    {
        "LazyVim/LazyVim",
        opts = {
            -- colorscheme = "tokyonight-night",
            colorscheme = "vscode",
        },
    },
}
