return {
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
          bg = c.none, -- Removes the background entirely
          fg = c.dark3, -- Keeps the text muted
        }
      end,
    },
  },

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
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "tokyonight-night",
        colorscheme = "catppuccin-mocha",
    },
  },
}