local M = {}

-- Dedicated dark background for sidebar panels, error lists, snacks picker, and intellisense
M.bg_dark = "#141617"
-- Standard buffer background (Gruvbox dark hard) for main buffer
M.bg_buffer = "#1d2021"

--- Gruvbox setup configuration options
M.opts = function()
    local ok, gruvbox = pcall(require, "gruvbox")
    local p = ok and gruvbox.palette or {
        dark0_hard = "#1d2021",
        dark0 = "#282828",
        dark1 = "#3c3836",
        dark2 = "#504945",
        dark3 = "#665c54",
        dark4 = "#7c6f64",
        gray = "#928374",
        light0_hard = "#f9f5d7",
        light0 = "#fbf1c7",
        light1 = "#ebdbb2",
        light2 = "#d5c4a1",
        light3 = "#bdae93",
        light4 = "#a89984",
        bright_red = "#fb4934",
        bright_green = "#b8bb26",
        bright_yellow = "#fabd2f",
        bright_blue = "#83a598",
        bright_purple = "#d3869b",
        bright_aqua = "#8ec07c",
        bright_orange = "#fe8019",
    }
    local bg_dark = M.bg_dark
    local bg_buffer = M.bg_buffer

    -- Ensure terminal ANSI black matches the darker background
    vim.g.terminal_color_0 = bg_dark

    return {
        contrast = "hard",
        transparent_mode = false,
        overrides = {
            -- Keep buffer background clean when sidebar/other windows are active
            NormalNC = { link = "Normal" },

            -- Floating windows & dialogs
            NormalFloat = { bg = bg_dark, fg = p.light1 },
            FloatBorder = { bg = bg_dark, fg = p.dark2 },
            FloatTitle = { bg = bg_dark, fg = p.bright_yellow, bold = true },

            -- Sidebars (Explorer, Zen, Outline, Neo-tree) with darkened background
            NormalSB = { bg = bg_dark, fg = p.light1 },
            SignColumnSB = { bg = bg_dark },
            NeoTreeNormal = { bg = bg_dark, fg = p.light1 },
            NeoTreeNormalNC = { bg = bg_dark, fg = p.light1 },
            OutlineNormal = { bg = bg_dark, fg = p.light1 },

            -- Snacks panels and sidebar windows with darkened background
            SnacksNormal = { bg = bg_dark, fg = p.light1 },
            SnacksNormalNC = { bg = bg_dark, fg = p.light1 },
            SnacksWinBar = { bg = bg_dark, fg = p.light1 },
            SnacksWinBarNC = { bg = bg_dark, fg = p.dark4 },

            -- Terminal panels
            Terminal = { bg = bg_dark },
            TermCursor = { fg = bg_dark, bg = p.light1 },
            TermCursorNC = { fg = bg_dark, bg = p.dark4 },

            -- Text Selection & Visual Mode (softened, less harsh than default #665c54)
            Visual = { bg = p.dark2 },
            VisualNOS = { link = "Visual" },

            -- Intellisense / Completion Menu (Pmenu & Blink.cmp) keep darker background
            Pmenu = { bg = bg_dark, fg = p.light1 },
            PmenuSel = { bg = p.dark1, fg = p.light1 },
            PmenuSbar = { bg = bg_dark },
            PmenuThumb = { bg = p.dark2 },
            PmenuBorder = { bg = bg_dark, fg = p.dark2 },

            BlinkCmpMenu = { bg = bg_dark, fg = p.light1 },
            BlinkCmpMenuBorder = { bg = bg_dark, fg = p.dark2 },
            BlinkCmpMenuSelection = { bg = p.dark1, fg = p.light1 },
            BlinkCmpDoc = { bg = bg_dark, fg = p.light1 },
            BlinkCmpDocBorder = { bg = bg_dark, fg = p.dark2 },
            BlinkCmpDocSeparator = { bg = bg_dark, fg = p.dark2 },
            BlinkCmpDocCursorLine = { bg = p.dark0 },
            BlinkCmpSignatureHelp = { bg = bg_dark, fg = p.light1 },
            BlinkCmpSignatureHelpBorder = { bg = bg_dark, fg = p.dark2 },
            BlinkCmpLabel = { fg = p.light2 },
            BlinkCmpLabelMatch = { fg = p.bright_blue },
            BlinkCmpGhostText = { fg = p.dark4 },

            -- Error list panels (Trouble & Quickfix) keep darker background
            TroubleNormal = { bg = bg_dark, fg = p.light1 },
            TroubleNormalNC = { bg = bg_dark, fg = p.light1 },
            QuickFixLine = { bg = p.dark0, bold = true },
            qfLineNr = { fg = p.dark4 },

            -- Default StatusLine fallback
            StatusLine = { bg = bg_dark, fg = p.light1 },
            StatusLineNC = { bg = bg_dark, fg = p.dark4 },

            -- Snacks File Picker (Darkened background restored)
            SnacksPicker = { bg = bg_dark, fg = p.light1 },
            SnacksPickerBorder = { bg = bg_dark, fg = p.dark2 },
            SnacksPickerTitle = { bg = bg_dark, fg = p.bright_yellow, bold = true },
            SnacksPickerFooter = { bg = bg_dark, fg = p.dark4 },
            SnacksPickerBox = { bg = bg_dark },
            SnacksPickerBoxBorder = { bg = bg_dark, fg = p.dark2 },
            SnacksPickerBoxTitle = { bg = bg_dark, fg = p.bright_yellow, bold = true },
            SnacksPickerInput = { bg = bg_dark, fg = p.light1 },
            SnacksPickerInputBorder = { bg = bg_dark, fg = p.dark2 },
            SnacksPickerInputTitle = { bg = bg_dark, fg = p.bright_red, bold = true },
            SnacksPickerPrompt = { bg = bg_dark, fg = p.bright_red },
            SnacksPickerList = { bg = bg_dark },
            SnacksPickerListBorder = { bg = bg_dark, fg = p.dark2 },
            SnacksPickerListTitle = { bg = bg_dark, fg = p.bright_blue, bold = true },
            SnacksPickerListCursorLine = { bg = p.dark1 },
            SnacksPickerPreview = { bg = bg_dark },
            SnacksPickerPreviewBorder = { bg = bg_dark, fg = p.dark2 },
            SnacksPickerPreviewTitle = { bg = bg_dark, fg = p.bright_green, bold = true },
            SnacksPickerPreviewCursorLine = { bg = p.dark1 },
            SnacksPickerMatch = { fg = p.bright_orange, bold = true },
            SnacksPickerSelected = { bg = p.dark1, fg = p.light1 },
            SnacksPickerDir = { fg = p.gray },
            SnacksPickerTotals = { fg = p.dark4 },

            -- Telescope (Consistent darkened background)
            TelescopeNormal = { bg = bg_dark, fg = p.light1 },
            TelescopeBorder = { bg = bg_dark, fg = p.dark2 },
            TelescopeTitle = { bg = bg_dark, fg = p.bright_yellow, bold = true },
            TelescopePromptNormal = { bg = bg_dark, fg = p.light1 },
            TelescopePromptBorder = { bg = bg_dark, fg = p.dark2 },
            TelescopePromptTitle = { bg = p.bright_red, fg = bg_dark, bold = true },
            TelescopePromptPrefix = { bg = bg_dark, fg = p.bright_red },
            TelescopePromptCounter = { bg = bg_dark, fg = p.dark4 },
            TelescopeResultsNormal = { bg = bg_dark, fg = p.light1 },
            TelescopeResultsBorder = { bg = bg_dark, fg = p.dark2 },
            TelescopeResultsTitle = { bg = bg_dark, fg = p.bright_blue, bold = true },
            TelescopePreviewNormal = { bg = bg_dark, fg = p.light1 },
            TelescopePreviewBorder = { bg = bg_dark, fg = p.dark2 },
            TelescopePreviewTitle = { bg = p.bright_green, fg = bg_dark, bold = true },
            TelescopeSelection = { bg = p.dark1, fg = p.light1 },
        },
    }
end

--- Snacks explorer window highlight options to preserve darker sidebar background
M.snacks_opts = {
    picker = {
        sources = {
            explorer = {
                win = {
                    list = { wo = { winhighlight = "NormalFloat:NormalSB,FloatBorder:NormalSB" } },
                    input = { wo = { winhighlight = "NormalFloat:NormalSB,FloatBorder:NormalSB" } },
                },
            },
        },
    },
}

--- Dynamic Lualine theme for Gruvbox
M.get_lualine_theme = function()
    local ok, gruvbox = pcall(require, "gruvbox")
    local p = ok and gruvbox.palette or {
        dark1 = "#3c3836",
        dark4 = "#7c6f64",
        light1 = "#ebdbb2",
        light4 = "#a89984",
        bright_red = "#fb4934",
        bright_green = "#b8bb26",
        bright_yellow = "#fabd2f",
        bright_blue = "#83a598",
        bright_orange = "#fe8019",
    }
    local bg_dark = M.bg_dark
    local bg_buffer = M.bg_buffer

    return {
        normal = {
            a = { bg = p.bright_green, fg = bg_buffer, gui = "bold" },
            b = { bg = p.dark1, fg = p.light1 },
            c = { bg = bg_dark, fg = p.light4 },
            y = { bg = p.dark1, fg = p.light1 },
            z = { bg = p.bright_green, fg = bg_buffer, gui = "bold" },
        },
        insert = {
            a = { bg = p.bright_blue, fg = bg_buffer, gui = "bold" },
            b = { bg = p.dark1, fg = p.light1 },
            c = { bg = bg_dark, fg = p.light4 },
            y = { bg = p.dark1, fg = p.light1 },
            z = { bg = p.bright_blue, fg = bg_buffer, gui = "bold" },
        },
        visual = {
            a = { bg = p.bright_orange, fg = bg_buffer, gui = "bold" },
            b = { bg = p.dark1, fg = p.light1 },
            c = { bg = bg_dark, fg = p.light4 },
            y = { bg = p.dark1, fg = p.light1 },
            z = { bg = p.bright_orange, fg = bg_buffer, gui = "bold" },
        },
        replace = {
            a = { bg = p.bright_red, fg = bg_buffer, gui = "bold" },
            b = { bg = p.dark1, fg = p.light1 },
            c = { bg = bg_dark, fg = p.light4 },
            y = { bg = p.dark1, fg = p.light1 },
            z = { bg = p.bright_red, fg = bg_buffer, gui = "bold" },
        },
        command = {
            a = { bg = p.bright_yellow, fg = bg_buffer, gui = "bold" },
            b = { bg = p.dark1, fg = p.light1 },
            c = { bg = bg_dark, fg = p.light4 },
            y = { bg = p.dark1, fg = p.light1 },
            z = { bg = p.bright_yellow, fg = bg_buffer, gui = "bold" },
        },
        inactive = {
            a = { bg = bg_dark, fg = p.dark4, gui = "bold" },
            b = { bg = bg_dark, fg = p.dark4 },
            c = { bg = bg_dark, fg = p.dark4 },
            y = { bg = bg_dark, fg = p.dark4 },
            z = { bg = bg_dark, fg = p.dark4 },
        },
    }
end

function M.setup()
    local ok, gruvbox = pcall(require, "gruvbox")
    if ok and gruvbox.setup then
        gruvbox.setup(M.opts())
    end
end

function M.load()
    M.setup()
    local ok, gruvbox = pcall(require, "gruvbox")
    if ok and gruvbox.load then
        gruvbox.load()
    end
    vim.g.colors_name = "gruvbox_v2"
end

setmetatable(M, {
    __index = function(t, key)
        if key == "lualine_theme" then
            return t.get_lualine_theme()
        end
    end,
})

return M
