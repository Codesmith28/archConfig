-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Import GNOME appearance and theme defaults (GTK, icon, cursor, fonts)
local home = os.getenv("HOME") or ""
local theme_importer = home .. "/.config/hypr/scripts/import-gnome-theme.sh"
local f = io.open(theme_importer, "r")
if f then
	f:close()
	if o and o.launch_on_start then
		o.launch_on_start(theme_importer)
	elseif hl and hl.exec_cmd then
		hl.exec_cmd(theme_importer)
	end
end


