local M = {}

function M:peek(job)
  local child = Command('mdcat')
    :args({
      '--columns',
      tostring(job.area.w),
      tostring(job.file.url),
    })
    :stdout(Command.PIPED)
    :stderr(Command.PIPED)
    :spawn()
  local count, lines = 0, ''
  repeat
    local line, event = child:read_line()
    if event ~= 0 then
      break
    else
      count = count + 1
      if count > job.skip then
        lines = lines .. line
      end
    end
  until count >= job.skip + job.area.h
  child:start_kill()
  if job.skip > 0 and count < job.skip + job.area.h then
    ya.manager_emit('peek', {
      tostring(math.max(0, count - job.area.h)),
      only_if = job.file.url,
      upper_bound = '',
    })
  else
    ya.preview_widgets(job, { ui.Text.parse(lines):area(job.area) })
  end
end

function M:seek(job)
  local h = cx.active.current.hovered
  if h and h.url == job.file.url then
    ya.manager_emit('peek', {
      math.max(0, cx.active.preview.skip + job.units),
      only_if = job.file.url,
    })
  end
end

return M
