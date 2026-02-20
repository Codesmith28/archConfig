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
                styles = {
                    sidebars = "transparent",
                    -- floats = "transparent",
                    comments = {},
                },
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
    -- add dracula
    {
        "Mofiqul/dracula.nvim",
        priority = 1000, -- make sure it loads first
        config = function()
            local dracula = require("dracula")

            dracula.setup({
                transparent_bg = false, -- set true only if you handle floats below
                show_end_of_buffer = true,
                italic_comment = true,

                -- colors = {
                --     bg = "#282A36",
                --     fg = "#F8F8F2",
                --     selection = "#44475A",
                --     comment = "#6272A4",
                --     red = "#FF5555",
                --     orange = "#FFB86C",
                --     yellow = "#F1FA8C",
                --     green = "#50fa7b",
                --     purple = "#BD93F9",
                --     cyan = "#8BE9FD",
                --     pink = "#FF79C6",
                --     menu = "#21222C",
                --     visual = "#3E4452",
                --     gutter_fg = "#4B5263",
                --     nontext = "#3B4048",
                -- },

                overrides = function(colors)
                    return {
                        -- 🔹 Floats
                        NormalFloat = { bg = colors.menu },
                        FloatBorder = { fg = colors.purple, bg = colors.menu },
                        FloatTitle = { fg = colors.cyan, bg = colors.menu },

                        -- 🔹 Telescope / Snacks style popups
                        Pmenu = { bg = colors.menu },
                        PmenuSel = { bg = colors.selection },
                        PmenuBorder = { fg = colors.purple },

                        -- 🔹 LazyVim UI consistency
                        NormalDark = { bg = colors.bg },
                        CursorLine = { bg = colors.selection },

                        -- 🔹 Snacks (if using fancy borders)
                        SnacksNormal = { bg = colors.menu },
                        SnacksBorder = { fg = colors.purple, bg = colors.menu },
                    }
                end,
            })
        end,
    },
    {
        "projekt0n/github-nvim-theme",
        name = "github-theme",
        lazy = false, -- make sure we load this during startup if it is your main colorscheme
        config = function()
            require("github-theme").setup({})
        end,
    },
    -- {
    --     "LazyVim/LazyVim",
    --     opts = {
    --         colorscheme = "catppuccin",
    --         colorscheme = "gruvbox",
    --     },
    -- },
}
