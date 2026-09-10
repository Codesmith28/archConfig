-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Unbind SUPER + W (previously Close window)
hl.unbind("SUPER + W")

-- SUPER + Q -> Close window
hl.unbind("SUPER + Q")
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

-- SUPER + SHIFT + Q -> killactive
hl.unbind("SUPER + SHIFT + Q")
o.bind("SUPER + SHIFT + Q", "Kill active window", hl.dsp.window.kill())

-- SUPER + C -> Center window
hl.unbind("SUPER + C")
o.bind("SUPER + C", "Center window", hl.dsp.window.center())

local animations = require("hypr.animations")

-- SUPER + M -> Magic / Move window to secret workspace (smooth slide-down)
hl.unbind("SUPER + M")
o.bind("SUPER + M", "Move to secret workspace", animations.move_to_secret)

-- SUPER + S -> Toggle between secret and previous workspace
hl.unbind("SUPER + S")
o.bind("SUPER + S", "Toggle secret workspace", hl.dsp.workspace.toggle_special("magic"))

-- SUPER + CTRL + T -> Activity (focus if already running, otherwise launch)
hl.unbind("SUPER + CTRL + T")
o.bind("SUPER + CTRL + T", "Activity", { tui = "btop", focus = true })

-- SUPER + SHIFT + click and drag -> Resize window
o.bind("SUPER + SHIFT + mouse:272", "Resize window", hl.dsp.window.resize(), { mouse = true })

-- =============================================================================
-- Omarchy Plugins: omalt-tab window switcher
-- =============================================================================
local omalt_tab_binding = (os.getenv("HOME") or "")
	.. "/.config/omarchy/plugins/io.github.codesmith28.omalt-tab/hypr/bindings.lua"
local f_omalt = io.open(omalt_tab_binding, "r")
if f_omalt then
	f_omalt:close()
	dofile(omalt_tab_binding)
end
