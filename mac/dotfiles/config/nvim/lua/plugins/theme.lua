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
                    -- 1. Enable Native LSP integration so Catppuccin themes builtin LSP groups
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

                -- 2. Explicitly override the LspInlayHint highlight group to make text italic
                custom_highlights = function(colors)
                    return {
                        LspInlayHint = {
                            fg = colors.overlay1, -- Standard subtle Catppuccin gray
                            bg = colors.none, -- Subtle background pill (or colors.none for transparent)
                            style = { "italic" }, -- Enables italic styling
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
                -- 1. LSP Inlay Hints: Italic text styling with subtle muted color & transparent bg on buffer
                hl.LspInlayHint = {
                    fg = c.dark5,
                    bg = c.none,
                    italic = true,
                }

                -- 2. Native LSP diagnostic virtual text with italic styling
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

                -- 3. Native LSP diagnostic underlines
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
            -- colorscheme = "catppuccin-mocha",
            --colorscheme = "ghostty-default-style-dark",
            -- colorscheme = "vscode",
            -- colorscheme = "tokyonight-night",
        },
    },
}
