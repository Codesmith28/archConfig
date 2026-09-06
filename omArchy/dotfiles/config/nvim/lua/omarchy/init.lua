local M = {}

-- All themes supported by Omarchy for dynamic switching
M.all_themes = {
    { "ribru17/bamboo.nvim", lazy = true, priority = 1000 },
    { "bjarneo/aether.nvim", branch = "v3", name = "aether", lazy = true, priority = 1000 },
    { "bjarneo/ethereal.nvim", lazy = true, priority = 1000 },
    { "bjarneo/hackerman.nvim", lazy = true, priority = 1000 },
    { "bjarneo/vantablack.nvim", lazy = true, priority = 1000 },
    { "bjarneo/white.nvim", lazy = true, priority = 1000 },
    { "catppuccin/nvim", name = "catppuccin", lazy = true, priority = 1000 },
    { "neanias/everforest-nvim", lazy = true, priority = 1000 },
    { "kepano/flexoki-neovim", lazy = true, priority = 1000 },
    { "ellisonleao/gruvbox.nvim", lazy = true, priority = 1000 },
    { "rebelot/kanagawa.nvim", lazy = true, priority = 1000 },
    { "tahayvr/matteblack.nvim", lazy = true, priority = 1000 },
    { "gthelding/monokai-pro.nvim", lazy = true, priority = 1000 },
    { "EdenEast/nightfox.nvim", lazy = true, priority = 1000 },
    { "rose-pine/neovim", name = "rose-pine", lazy = true, priority = 1000 },
    { "ficcdaf/ashen.nvim", lazy = true, priority = 1000 },
    { "folke/tokyonight.nvim", lazy = true, priority = 1000 },
    { "OldJobobo/miasma.nvim", lazy = true, priority = 1000 },
    { "OldJobobo/retro-82.nvim", lazy = true, priority = 1000 },
    { "omacom-io/lumon.nvim", lazy = true, priority = 1000 },
}

-- Theme hot-reloading plugin for Omarchy desktop theme switches
M.hotreload = {
    name = "theme-hotreload",
    dir = vim.fn.stdpath("config"),
    lazy = false,
    priority = 1000,
    config = function()
        local transparency_file = vim.fn.stdpath("config") .. "/plugin/after/transparency.lua"

        vim.api.nvim_create_autocmd("User", {
            pattern = "LazyReload",
            callback = function()
                -- Unload the theme module
                package.loaded["plugins.theme"] = nil
                package.loaded["plugins.ui.theme"] = nil

                vim.schedule(function()
                    local ok, theme_spec = pcall(require, "plugins.theme")
                    if not ok then
                        return
                    end

                    -- Find the theme plugin and unload it
                    local theme_plugin_name = nil
                    for _, spec in ipairs(theme_spec) do
                        if spec[1] and spec[1] ~= "LazyVim/LazyVim" then
                            theme_plugin_name = spec.name or spec[1]
                            break
                        end
                    end

                    -- Clear all highlight groups before applying new theme
                    vim.cmd("highlight clear")
                    if vim.fn.exists("syntax_on") then
                        vim.cmd("syntax reset")
                    end

                    -- Reset background to default so colorscheme can set it properly (light themes will set to light)
                    vim.o.background = "dark"

                    -- Unload theme plugin modules to force full reload
                    if theme_plugin_name then
                        local plugin = require("lazy.core.config").plugins[theme_plugin_name]
                        if plugin then
                            -- Unload all lua modules from the plugin directory
                            local plugin_dir = plugin.dir .. "/lua"
                            require("lazy.core.util").walkmods(plugin_dir, function(modname)
                                package.loaded[modname] = nil
                                package.preload[modname] = nil
                            end)
                        end
                    end

                    -- Find and apply the new colorscheme
                    for _, spec in ipairs(theme_spec) do
                        if spec[1] == "LazyVim/LazyVim" and spec.opts and spec.opts.colorscheme then
                            local colorscheme = spec.opts.colorscheme

                            -- Load the colorscheme plugin. If it's already loaded (old and new
                            -- theme sharing the same plugin, e.g. generic themes on aether.nvim),
                            -- lazy won't rerun setup() on a spec reload and keeps the old
                            -- resolved opts in the plugin's property cache, so fully reload it
                            -- to reapply setup() with the new theme's opts.
                            local theme_plugin = theme_plugin_name
                                and require("lazy.core.config").plugins[theme_plugin_name]
                            if theme_plugin and theme_plugin._.loaded then
                                require("lazy.core.loader").reload(theme_plugin)
                            else
                                require("lazy.core.loader").colorscheme(colorscheme)
                            end

                            vim.defer_fn(function()
                                -- Apply the colorscheme (it will set background itself)
                                pcall(vim.cmd.colorscheme, colorscheme)

                                -- Force redraw to update all UI elements
                                vim.cmd("redraw!")

                                -- Reload transparency settings
                                if vim.fn.filereadable(transparency_file) == 1 then
                                    vim.defer_fn(function()
                                        vim.cmd.source(transparency_file)

                                        -- Trigger UI updates for various plugins
                                        vim.api.nvim_exec_autocmds("ColorScheme", { modeline = false })
                                        vim.api.nvim_exec_autocmds("VimEnter", { modeline = false })

                                        -- Final redraw
                                        vim.cmd("redraw!")
                                    end, 5)
                                end
                            end, 5)

                            break
                        end
                    end
                end)
            end,
        })
    end,
}

return M
