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
            transparent = true, -- Enable transparent background

            -- Optional: adjust specific highlight groups if you want even more transparency
            on_highlights = function(hl, c)
                hl.TelescopeNormal = {
                    bg = c.none,
                    fg = c.fg_dark,
                }
                hl.TelescopeBorder = {
                    bg = c.none,
                    fg = c.fg_dark,
                }
                hl.LspInlayHint = {
                    -- bg = c.none, -- Removes the background entirely
                    fg = c.dark5, -- Keeps the text muted
                }
            end,
        },
    },

    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "catppuccin-mocha",
            -- colorscheme = "vscode",
            -- colorscheme = "tokyonight-night",
        },
    },
}
