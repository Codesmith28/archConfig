local M = {}

local function fail(s, ...)
	ya.notify({ title = "Eza Preview", content = string.format(s, ...), timeout = 5, level = "error" })
end

local toggle_view_mode = ya.sync(function(state, _)
	if state.tree == nil then
		state.tree = false
	end

	state.tree = not state.tree
end)

local is_tree_view_mode = ya.sync(function(state, _)
	return state.tree
end)

function M:setup()
	toggle_view_mode()
end

function M:entry(_)
	toggle_view_mode()

	ya.manager_emit("seek", { 0 })
end

function M:peek()
	local args = {
		"-a",
		"--oneline",
		"--color=always",
		"--icons=always",
		"--group-directories-first",
		"--no-quotes",
		tostring(self.file.url),
	}

	if is_tree_view_mode() then
		table.insert(args, "-T")
	end

	local child = Command("eza"):args(args):stdout(Command.PIPED):stderr(Command.PIPED):spawn()

	local limit = self.area.h
	local lines = ""
	local num_lines = 1
	local num_skip = 0
	local empty_output = false

	repeat
		local line, event = child:read_line()
		if event == 1 then
			fail(tostring(event))
		elseif event ~= 0 then
			break
		end

		if num_skip >= self.skip then
			lines = lines .. line
			num_lines = num_lines + 1
		else
			num_skip = num_skip + 1
		end
	until num_lines >= limit

	if num_lines == 1 and not is_tree_view_mode() then
		empty_output = true
	elseif num_lines == 2 and is_tree_view_mode() then
		empty_output = true
	end

	child:start_kill()
	if self.skip > 0 and num_lines < limit then
		ya.manager_emit("peek", {
			tostring(math.max(0, self.skip - (limit - num_lines))),
			only_if = tostring(self.file.url),
			upper_bound = "",
		})
	elseif empty_output then
		ya.preview_widgets(self, {
			ui.Paragraph(self.area, { ui.Line("No items") }):align(ui.Paragraph.CENTER),
		})
	else
		ya.preview_widgets(self, { ui.Paragraph.parse(self.area, lines) })
	end
end

function M:seek(units)
	local h = cx.active.current.hovered
	if h and h.url == self.file.url then
		local step = math.floor(units * self.area.h / 10)
		ya.manager_emit("peek", {
			math.max(0, cx.active.preview.skip + step),
			only_if = tostring(self.file.url),
			force = true,
		})
	end
end

return M
