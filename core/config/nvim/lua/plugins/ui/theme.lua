return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = true,
        opts = function(_, opts)
            opts = opts or {}
            -- Support both `transparent` and `transparent_background`
            if opts.transparent ~= nil and opts.transparent_background == nil then
                opts.transparent_background = opts.transparent
            end
            if opts.transparent_background == nil then
                opts.transparent_background = true
            end

            opts.styles = opts.styles or {}
            opts.styles.comments = { "italic" }

            local prev_custom = opts.custom_highlights
            opts.custom_highlights = function(colors)
                local hls = type(prev_custom) == "function" and prev_custom(colors) or {}
                return vim.tbl_extend("force", hls, {
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
                    -- Ensure built-in terminal (Snacks terminal / :terminal) retains a solid background
                    SnacksNormal = { fg = colors.text, bg = colors.mantle },
                    Terminal = { bg = colors.mantle },
                })
            end
            return opts
        end,
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
        "Codesmith28/gruvbox_v2.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            transparent = "true",
            contrast = "medium",
        },
    },

    -- {
    --     "Codesmith28/gruvbox_v2.nvim",
    --     dir = "~/personal/Projects/gruvbox_v2.nvim", -- <--- test local repo
    --     lazy = false,
    --     priority = 1000,
    --     opts = {
    --         contrast = "hard",
    --         transparent = "true"
    --     },
    -- },

    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "catppuccin-mocha",
        },
    },
}
