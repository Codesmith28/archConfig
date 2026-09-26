return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = true,
        opts = {
            styles = {
                comments = { "italic" },
            },
            custom_highlights = function(colors)
                return {
                    LspInlayHint = {
                        fg = colors.overlay1,
                        bg = colors.none,
                        style = { "italic" },
                    },
                }
            end,
        },
    },
    {
        "folke/tokyonight.nvim",
        lazy = true,
        opts = {
            styles = {
                comments = { italic = true },
            },
            on_highlights = function(hl, c)
                hl.LspInlayHint = {
                    fg = c.dark3,
                    bg = c.none,
                    italic = true,
                }
            end,
        },
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "tokyonight-night",
            -- colorscheme = "catppuccin-macchiato",
        },
    },
}
