local gruvbox = require("gruvbox_v2")

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
        "ellisonleao/gruvbox.nvim",
        lazy = false,
        priority = 1000,
        opts = gruvbox.opts,
    },

    {
        "folke/snacks.nvim",
        opts = gruvbox.snacks_opts,
    },

    {
        "nvim-lualine/lualine.nvim",
        opts = function(_, opts)
            opts.options = opts.options or {}
            opts.options.theme = function()
                if vim.g.colors_name == "gruvbox" or vim.g.colors_name == "gruvbox_v2" then
                    return gruvbox.lualine_theme
                end
                return "auto"
            end
        end,
    },

    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "gruvbox_v2",
        },
    },
}
