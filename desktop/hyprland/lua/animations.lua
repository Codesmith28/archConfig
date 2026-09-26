-- Hyprland Animation Configuration
-- Documentation: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

local M = {}

hl.config({
	animations = {
		enabled = true,
	},
})

-- =============================================================================
-- Animation Curves (Béziers)
-- =============================================================================
-- easeOutQuint: Smooth and elegant deceleration, ideal for sliding movements
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })

-- easeInOutCubic: Balanced acceleration and deceleration
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })

-- fluentDecel: Fast initial response with a smooth, natural landing
hl.curve("fluentDecel", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })

-- almostLinear: Very gentle curve tailored for opacity / fade transitions
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })

-- quick: Snappy curve for immediate feedback
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

-- =============================================================================
-- Workspace Animations (Consistent Horizontal & Vertical Sliding)
-- =============================================================================
-- Horizontal slide for standard workspaces (smooth visual continuity & 1:1 swipe gestures)
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "easeOutQuint", style = "slide" })

-- Vertical slide for the special/scratchpad workspace (drawer/visor style)
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.8, bezier = "easeOutQuint", style = "slidevert" })

-- =============================================================================
-- Window Animations (Cohesive Sliding In & Out)
-- =============================================================================
-- Base window animation
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slide" })

-- Window opening: slides into place from the nearest screen edge
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slide" })

-- Window closing: slides out towards the nearest edge (slightly faster for responsiveness)
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.8, bezier = "easeOutQuint", style = "slide" })

-- Window moving: smooth interpolation when tiling, dragging, or shifting windows
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.5, bezier = "easeOutQuint" })

-- =============================================================================
-- Fade Animations (Subtle & Natural Opacity Transitions)
-- =============================================================================
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2.5, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "quick" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2.5, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2, bezier = "almostLinear" })
hl.animation({ leaf = "fadePopups", enabled = true, speed = 2, bezier = "almostLinear" })

-- =============================================================================
-- Layer Animations (Notifications, Overlays & Surfaces)
-- =============================================================================
hl.animation({ leaf = "layers", enabled = true, speed = 3.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3.5, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "almostLinear", style = "fade" })

-- =============================================================================
-- Border Animations
-- =============================================================================
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "easeOutQuint" })

-- =============================================================================
-- Secret Workspace (Scratchpad) Slide Transition Helper
-- =============================================================================
-- Moves active window into the secret workspace with a smooth slide-down animation,
-- or restores it back to the current workspace if already in the secret workspace.
function M.move_to_secret()
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
	local mon = hl.get_active_monitor()
	local mon_h = (mon and mon.height) or (win.monitor and win.monitor.height) or 1200
	local delta_y = mon_h - orig_y + 120

	if win.fullscreen and win.fullscreen ~= 0 then
		hl.dispatch(hl.dsp.window.fullscreen({ window = "address:" .. addr, action = "unset" }))
	end

	if not was_floating then
		hl.dispatch(hl.dsp.window.float({ window = "address:" .. addr, action = "enable" }))
	end

	hl.dispatch(hl.dsp.window.move({ window = "address:" .. addr, x = 0, y = delta_y, relative = true }))

	-- windowsMove speed is 3.5 (350ms); 370ms ensures the window completes its slide off-screen
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
	end, { timeout = 370, type = "oneshot" })
end

return M
