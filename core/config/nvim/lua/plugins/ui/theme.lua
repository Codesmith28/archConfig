return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = true,
        opts = {
            transparent_background = true,
            styles = {
                comments = { "italic" },
            },
            custom_highlights = function(colors)
                return {
                    LspInlayHint = {
                        fg = colors.surface2,
                        bg = colors.none,
                        style = { "italic" },
                    },
                    DiagnosticUnnecessary = {
                        fg = colors.overlay0,
                        style = { "italic" },
                    },
                    DiagnosticUnderlineHint = {
                        style = {},
                    },
                }
            end,
        },
    },
    {
        "folke/tokyonight.nvim",
        lazy = true,
        opts = {
            transparent = true,
            styles = {
                comments = { italic = true },
            },
            on_highlights = function(hl, c)
                hl.LspInlayHint = {
                    fg = c.dark3,
                    bg = c.none,
                    italic = true,
                }
                hl.DiagnosticUnnecessary = {
                    fg = c.dark3,
                    italic = true,
                }
                hl.DiagnosticUnderlineHint = {
                    undercurl = false,
                }
            end,
        },
    },

    {
        "Shatur/neovim-ayu",
        config = function()
            require("ayu").setup({
                mirage = false, -- Set to true for the softer mirage variant, false for dark
                terminal = true, -- Set terminal colors
                overrides = {}, -- Add custom color overrides here if needed
            })
        end,
    },

    {
        "LazyVim/LazyVim",
        opts = {
            -- colorscheme = "tokyonight-night",
            colorscheme = "catppuccin-mocha",
        },
    },
}
