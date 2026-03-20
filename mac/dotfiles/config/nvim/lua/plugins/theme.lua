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
                invert_indent_guides = false,
                inverse = true,

                contrast = "hard", -- "hard" | "medium" | "soft"

                palette_overrides = {},

                overrides = {
                    -- keep floats non-transparent
                    NormalFloat = { bg = "#282828" },
                    FloatBorder = { bg = "#282828" },
                    Pmenu = { bg = "#282828" },
                },

                dim_inactive = false,
                transparent_mode = true,
            })

            -- vim.cmd.colorscheme("gruvbox")
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
                -- custom_highlights = function(colors)
                --     return {
                --         Normal = { bg = "#171717", fg = "#deddda" },
                --         -- NormalFloat = { bg = "#171717", fg = "#deddda" },
                --         -- FloatBorder = { bg = "#171717", fg = "#deddda" },
                --
                --         -- Selections
                --         Visual = { bg = "#303030", fg = "#c0bfbc" },
                --         VisualNOS = { bg = "#303030", fg = "#c0bfbc" },
                --
                --         -- Cursor line (optional but recommended)
                --         CursorLine = { bg = "#1f1f1f" },
                --
                --         -- UI Elements
                --         LineNr = { fg = "#5a5a5a" },
                --         CursorLineNr = { fg = "#deddda" },
                --     }
                -- end,

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
                transparent_bg = true, -- set true only if you handle floats below
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
        "loctvl842/monokai-pro.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("monokai-pro").setup({
                transparent_background = true,
                terminal_colors = true,
                devicons = true,

                styles = {
                    comment = { italic = true },
                    keyword = { italic = true },
                    type = { italic = true },
                    storageclass = { italic = true },
                    structure = { italic = true },
                    parameter = { italic = true },
                    annotation = { italic = true },
                    tag_attribute = { italic = true },
                },

                filter = "machine",

                day_night = {
                    enable = false,
                    day_filter = "pro",
                    night_filter = "spectrum",
                },

                inc_search = "background",

                background_clear = {
                    "toggleterm",
                    "telescope",
                    "renamer",
                    "notify",
                },

                plugins = {
                    bufferline = {
                        underline_selected = false,
                        underline_visible = false,
                        underline_fill = false,
                        bold = true,
                    },
                    indent_blankline = {
                        context_highlight = "default",
                        context_start_underline = false,
                    },
                },

                override = function(scheme)
                    return {
                        -- keep transparency
                        Normal = { bg = "NONE" },
                        NormalNC = { bg = "NONE" },
                        SignColumn = { bg = "NONE" },
                        EndOfBuffer = { bg = "NONE" },

                        -- floats
                        NormalFloat = { bg = scheme.base2 },
                        FloatBorder = { bg = scheme.base2 },

                        -- popup menu
                        Pmenu = { bg = scheme.base2 },
                        PmenuSel = { bg = scheme.base3 },

                        -- telescope
                        TelescopeNormal = { bg = scheme.base2 },
                        TelescopeBorder = { bg = scheme.base2 },

                        -- cursor line
                        CursorLine = { bg = scheme.base2 },

                        -- splits
                        VertSplit = { fg = scheme.base4 },
                        WinSeparator = { fg = scheme.base4 },

                        -- LSP
                        LspInfoBorder = { fg = scheme.base5 },
                    }
                end,

                override_palette = function(filter)
                    return {}
                end,

                override_scheme = function(scheme, palette, colors)
                    return {}
                end,
            })
        end,
    },

    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "catppuccin",
            -- colorscheme = "monokai-pro-machine",
            -- colorscheme = "gruvbox",
        },
    },
}
