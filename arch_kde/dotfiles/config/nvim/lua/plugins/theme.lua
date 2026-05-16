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

                -- -- Adwaita Background
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
                -- end

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
        "Mofiqul/vscode.nvim",
        name = "vscode",
        priority = 1000, -- Ensure it loads first if it's your main theme
        config = function()
            require("vscode").setup({
                -- "dark" or "light"
                style = "dark",

                -- Enable transparent background
                transparent = true,

                -- Disable italics to match your previous styles = {} setup
                italic_comments = false,

                -- Disable nvim-tree background color to keep it transparent
                disable_nvimtree_bg = true,

                -- Override highlight groups for floating windows
                group_overrides = {
                    -- Set floating windows and borders to be transparent
                    NormalFloat = { bg = "NONE" },
                    FloatBorder = { bg = "NONE" },
                    WhichKeyFloat = { bg = "NONE" },
                },
            })
        end,
    },

    {
        "LazyVim/LazyVim",
        opts = {
            -- colorscheme = "catppuccin-mocha",
            colorscheme = "vscode",
        },
    },
}
