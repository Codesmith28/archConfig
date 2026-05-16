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
                    comments = false,
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
                -- transparent_mode = true,
            })
        end,
    },
    {
        "folke/tokyonight.nvim",
        lazy = false,
        config = function()
            require("tokyonight").setup({
                -- transparent = true,
                -- styles = {
                --     sidebars = "transparent",
                --     -- floats = "transparent",
                --     comments = {},
                -- },
            })
        end,
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        config = function()
            require("catppuccin").setup({
                flavour = "mocha", -- or "latte", "frappe", "macchiato"
                transparent_background = true,
                show_end_of_buffer = false, -- hide ~ at end of buffer
                term_colors = true, -- terminal colors matching theme

                -- Adwaita Background
                custom_highlights = function(colors)
                    return {
                        Normal = { bg = "#171717", fg = "#deddda" },
                        -- NormalFloat = { bg = "#171717", fg = "#deddda" },
                        -- FloatBorder = { bg = "#171717", fg = "#deddda" },

                        -- Selections
                        Visual = { bg = "#303030", fg = "#c0bfbc" },
                        VisualNOS = { bg = "#303030", fg = "#c0bfbc" },

                        -- Cursor line (optional but recommended)
                        CursorLine = { bg = "#1f1f1f" },

                        -- UI Elements
                        LineNr = { fg = "#5a5a5a" },
                        CursorLineNr = { fg = "#deddda" },
                    }
                end,

                styles = {
                    comments = {},
                    conditionals = {},
                    loops = {},
                    functions = {},
                    keywords = {},
                    strings = {},
                    variables = {},
                    numbers = {},
                    booleans = {},
                    properties = {},
                    types = {},
                    operators = {},
                },

                integrations = {
                    native_lsp = {
                        enabled = true,
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
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "catppuccin",
            -- colorscheme = "gruvbox",
        },
    },
}
