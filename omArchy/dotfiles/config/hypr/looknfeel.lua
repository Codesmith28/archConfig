-- Change the default Omarchy look'n'feel.


-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
hl.config({
	decoration = {
		-- Use round window corners.
		rounding = 8,

		-- Disable transparency
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		fullscreen_opacity = 1.0,

		blur = {
			enabled = false,
		},

		-- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
		-- dim_inactive = true,
		-- dim_strength = 0.15,
	},
})

-- Disable transparency on all windows
o.window(".*", {
	tag = "-default-opacity",
	opaque = true,
	opacity = "1.0 1.0",
})
o.window({ tag = "default-opacity" }, { opacity = "1.0 1.0" })
o.window({ tag = "chromium-based-browser" }, { opacity = "1.0 1.0" })
o.window({ tag = "firefox-based-browser" }, { opacity = "1.0 1.0" })

-- Window rules for specific applications
local small_window_size = { 1300, 900 }

-- WhatsApp: open in small floating window
o.window(".*[wW]hats[aA]pp.*", {
	float = true,
	center = true,
	size = small_window_size,
})

-- Ghostty: open in small floating window (same as WhatsApp)
o.window("com.mitchellh.ghostty", {
	float = true,
	center = true,
	size = small_window_size,
})

-- Telegram: open in small floating window (same as WhatsApp)
o.window(".*[tT]elegram.*", {
	float = true,
	center = true,
	size = small_window_size,
})


-- btop: open as regular tiled window (overriding Omarchy's default floating rule)
o.window(".*btop.*", {
	tile = true,
	tag = "-floating-window",
})



-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })
