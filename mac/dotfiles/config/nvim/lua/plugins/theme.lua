return {

    {
        "catppuccin/nvim",
        name = "catppuccin",
        config = function()
            require("catppuccin").setup({
                flavour = "mocha", -- or "latte", "frappe", "macchiato"
                transparent_background = true,
                show_end_of_buffer = true, -- hide ~ at end of buffer
                term_colors = true, -- terminal colors matching theme

                integrations = {
                    native_lsp = {
                        enabled = false,
                        inlay_hints = { background = true },
                    },
                    cmp = true,
                    gitsigns = true,
                    nvimtree = true,
                    treesitter = true,
                    telescope = { style = "transparent" },
                    mason = true,
                    which_key = true,
                },
            })
        end,
    },

    {
        "folke/tokyonight.nvim",
        lazy = true,
        opts = {
            transparent = true, -- Enable transparent background

            styles = {
                comments = { italic = false },
            },

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
