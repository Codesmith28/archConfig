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

-- Move active window to secret workspace with slide-down animation
local function move_to_secret_with_animation()
	local win = hl.get_active_window()
	if not win then
		return
	end

	local addr = win.address
	local in_special = (win.workspace and win.workspace.name == "special:magic")

	if in_special then
		local current_ws = hl.get_active_workspace()
		local target_ws = (current_ws and current_ws.name) or "1"
		hl.dispatch(hl.dsp.window.move({ window = "address:" .. addr, workspace = target_ws, follow = true }))
		return
	end

	local was_floating = win.floating
	local orig_x = (win.at and win.at.x) or 0
	local orig_y = (win.at and win.at.y) or 0
	local mon_h = (win.monitor and win.monitor.height) or 1200
	local delta_y = mon_h - orig_y + 100

	if win.fullscreen and win.fullscreen ~= 0 then
		hl.dispatch(hl.dsp.window.fullscreen({ window = "address:" .. addr, action = "unset" }))
	end

	if not was_floating then
		hl.dispatch(hl.dsp.window.float({ window = "address:" .. addr, action = "enable" }))
	end

	hl.dispatch(hl.dsp.window.move({ window = "address:" .. addr, x = 0, y = delta_y, relative = true }))

	hl.timer(function()
		local target = hl.get_window("address:" .. addr)
		if not target then
			return
		end

		hl.dispatch(hl.dsp.window.move({ window = "address:" .. addr, workspace = "special:magic", follow = false }))

		if was_floating then
			hl.dispatch(hl.dsp.window.move({ window = "address:" .. addr, x = orig_x, y = orig_y, relative = false }))
		else
			hl.dispatch(hl.dsp.window.float({ window = "address:" .. addr, action = "disable" }))
		end
	end, { timeout = 250, type = "oneshot" })
end

-- SUPER + M -> Magic / Move window to secret workspace (with slide-down animation)
hl.unbind("SUPER + M")
o.bind("SUPER + M", "Move to secret workspace", move_to_secret_with_animation)

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
