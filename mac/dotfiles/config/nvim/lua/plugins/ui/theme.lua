return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        config = function()
            require("catppuccin").setup({
                flavour = "mocha", -- or "latte", "frappe", "macchiato"
                transparent_background = true,
                show_end_of_buffer = true,
                term_colors = true,

                integrations = {
                    -- theme the builtin LSP highlight/underline groups
                    native_lsp = {
                        enabled = true,
                        virtual_text = {
                            errors = { "italic" },
                            hints = { "italic" },
                            warnings = { "italic" },
                            information = { "italic" },
                        },
                        underlines = {
                            errors = { "underline" },
                            hints = { "underline" },
                            warnings = { "underline" },
                            information = { "underline" },
                        },
                        inlay_hints = {
                            background = true,
                        },
                    },
                    cmp = true,
                    blink_cmp = true,
                    gitsigns = true,
                    nvimtree = true,
                    treesitter = true,
                    telescope = { style = "transparent" },
                    mason = true,
                    which_key = true,
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
            })
        end,
    },

    {
        "folke/tokyonight.nvim",
        lazy = true,
        opts = {
            style = "night",
            transparent = true, -- Makes the main editor code buffer transparent
            terminal_colors = true,
            styles = {
                comments = { italic = true },
                keywords = { italic = true },
                functions = {},
                variables = {},
                sidebars = "dark", -- Keep sidebars (neo-tree, etc.) solid/opaque
                floats = "dark", -- Keep floating windows (telescope, popups, hover) solid/opaque
            },
            on_highlights = function(hl, c)
                hl.LspInlayHint = {
                    fg = c.dark5,
                    bg = c.none,
                    italic = true,
                }

                hl.DiagnosticVirtualTextError = {
                    fg = c.error,
                    bg = c.none,
                    italic = true,
                }
                hl.DiagnosticVirtualTextWarn = {
                    fg = c.warning,
                    bg = c.none,
                    italic = true,
                }
                hl.DiagnosticVirtualTextInfo = {
                    fg = c.info,
                    bg = c.none,
                    italic = true,
                }
                hl.DiagnosticVirtualTextHint = {
                    fg = c.hint,
                    bg = c.none,
                    italic = true,
                }

                hl.DiagnosticUnderlineError = { undercurl = true, sp = c.error }
                hl.DiagnosticUnderlineWarn = { undercurl = true, sp = c.warning }
                hl.DiagnosticUnderlineInfo = { undercurl = true, sp = c.info }
                hl.DiagnosticUnderlineHint = { undercurl = true, sp = c.hint }
            end,
        },
    },

    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "tokyonight-night",
        },
    },
}
