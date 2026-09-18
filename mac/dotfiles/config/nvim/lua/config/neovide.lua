if vim.g.neovide then
    -- Sync font configuration with Ghostty
    local ghostty_paths = {
        (vim.env.XDG_CONFIG_HOME or vim.fn.expand("~/.config")) .. "/ghostty/config",
        vim.fn.expand("~/Library/Application Support/com.mitchellh.ghostty/config"),
    }
    local f
    for _, path in ipairs(ghostty_paths) do
        f = io.open(path, "r")
        if f then break end
    end
    if f then
        local families, size = {}, nil
        for line in f:lines() do
            local clean = line:match("^%s*([^#]+)")
            if clean then
                local key, val = clean:match("^([%w_-]+)%s*=%s*(.-)%s*$")
                if key and val then
                    val = val:gsub('^["\']', ''):gsub('["\']$', '')
                    if key == "font-family" and val ~= "" then
                        table.insert(families, val)
                    elseif key == "font-size" and val ~= "" then
                        size = val
                    end
                end
            end
        end
        f:close()

        if #families > 0 then
            if size then
                for i, family in ipairs(families) do
                    families[i] = family .. ":h" .. size
                end
            end
            vim.o.guifont = table.concat(families, ",")
        end
    end

    vim.g.neovide_opacity = 0.75
    -- vim.g.neovide_background_color = "#080707"
    vim.g.neovide_window_blurred = true
    vim.g.neovide_cursor_vfx_mode = "pixiedust"
    vim.g.neovide_floating_shadow = false

    -- Save file directly using Cmd+S across Normal, Insert, and Visual modes
    vim.keymap.set({ "n", "i", "v" }, "<D-s>", "<cmd>write<cr>", { desc = "Save file" })
end
