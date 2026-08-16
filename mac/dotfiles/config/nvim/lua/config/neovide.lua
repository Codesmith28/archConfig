if vim.g.neovide then
    -- vim.g.neovide_opacity = 0.72
    -- vim.g.neovide_background_color = "#080707"
    -- vim.g.neovide_window_blurred = true
    vim.g.neovide_cursor_vfx_mode = "pixiedust"
    vim.g.neovide_floating_shadow = false

    -- Save file directly using Cmd+S across Normal, Insert, and Visual modes
    vim.keymap.set({ "n", "i", "v" }, "<D-s>", "<cmd>write<cr>", { desc = "Save file" })

    -- Dynamically sync font settings from Ghostty config
    local function sync_ghostty_font()
        local ghostty_config_path = vim.fn.expand("~/.config/ghostty/config")
        local file = io.open(ghostty_config_path, "r")
        if not file then
            return
        end

        local font_family = "monospace"
        local font_size = "10"

        for line in file:lines() do
            local family = line:match('^%s*font%-family%s*=%s*"?(.-)"?%s*$')
            if family then
                font_family = family
            end

            local size = line:match("^%s*font%-size%s*=%s*(%d+%.?%d*)")
            if size then
                font_size = size
            end
        end
        file:close()

        vim.schedule(function()
            vim.o.guifont = font_family .. ":h" .. font_size
        end)
    end

    -- Run once on startup
    sync_ghostty_font()

    -- Watch ghostty config for live updates
    local uv = vim.uv or vim.loop
    local ghostty_config_path = vim.fn.expand("~/.config/ghostty/config")
    if uv and uv.fs_stat(ghostty_config_path) then
        local w = uv.new_fs_event()
        w:start(ghostty_config_path, {}, function(err, filename, events)
            if not err then
                sync_ghostty_font()
            end
        end)
    end

    vim.g.neovide_padding_top = 10
    vim.g.neovide_padding_bottom = 10
    vim.g.neovide_padding_right = 0
    vim.g.neovide_padding_left = 0

    -- use system's clipboard
    vim.o.clipboard = "unnamedplus"
end
