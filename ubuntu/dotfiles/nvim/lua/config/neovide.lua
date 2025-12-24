-- Load only if running inside Neovide
if not vim.g.neovide then
    return
end

---------------------------------------------------------
-- Font settings tuned for Neovide
---------------------------------------------------------

-- System default monospace font (no explicit family)
vim.o.guifont = "monospace:h14"

-- Line/column adjustments
vim.g.neovide_font_adjust_line_height = 0
vim.g.neovide_font_adjust_column_width = 0

-- Baseline adjustment
vim.g.neovide_font_adjust_baseline = 1

-- Ligatures: disable/never/always → we choose "never"
vim.g.neovide_disable_ligatures = "never"

-- Force left-to-right rendering
vim.g.neovide_force_ltr = true

-- Box drawing scaling values
vim.g.neovide_box_drawing_scale = { 0.001, 1, 1.5, 2 }

-- Cursor visual effects mode
vim.g.neovide_cursor_vfx_mode = "pixiedust"

-- Opacity (0.0 is fully transparent, 1.0 is opaque)
vim.g.neovide_opacity = 0.90

-- Enable background blur (On/Off only, no numeric value like 32)
vim.g.neovide_window_blurred = true
