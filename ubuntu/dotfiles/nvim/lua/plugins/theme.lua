return {
    {
        "marko-cerovac/material.nvim",
        opts = {
            contrast = {
                terminal = true, -- Enable contrast for the built-in terminal
                sidebars = true, -- Enable contrast for sidebar-like windows ( for example Nvim-Tree )
                floating_windows = true, -- Enable contrast for floating windows
                cursor_line = false, -- Enable darker background for the cursor line
                lsp_virtual_text = false, -- Enable contrasted background for lsp virtual text
                non_current_windows = false, -- Enable contrasted background for non-current windows
                filetypes = {}, -- Specify which filetypes get the contrasted (darker) background
            },

            high_visibility = {
                lighter = false, -- Enable higher contrast text for lighter style
                darker = true, -- Enable higher contrast text for darker style
            },

            disable = {
                colored_cursor = true, -- Disable the colored cursor
                borders = false, -- Disable borders between vertically split windows
                background = false, -- Prevent the theme from setting the background (NeoVim then uses your terminal background)
                term_colors = false, -- Prevent the theme from setting terminal colors
                eob_lines = false, -- Hide the end-of-buffer lines
            },
        },
    },
    {
        "LazyVim/LazyVim",
        opts = {
            -- colorscheme = "material-darke",
        },
    },
}
