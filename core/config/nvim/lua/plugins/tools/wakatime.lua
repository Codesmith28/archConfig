local function get_wakatime_key()
    local env_key = vim.env.WAKATIME_API_KEY
    if env_key and env_key ~= "" then
        return env_key
    end

    local home = vim.fn.expand("~")
    local candidates = {
        home .. "/.wakatime.cfg.local",
        home .. "/.wakatime.cfg",
    }

    for _, path in ipairs(candidates) do
        local f = io.open(path, "r")
        if f then
            local is_disabled = false
            local found_key = nil
            for line in f:lines() do
                if line:match("^%s*disabled%s*=%s*true") then
                    is_disabled = true
                end
                local key = line:match("^%s*api_key%s*=%s*(%S+)") or line:match("^%s*apikey%s*=%s*(%S+)")
                if key and key ~= "" and not key:match("^%[") and not key:match("^#") and not key:match("^;") then
                    found_key = key
                end
            end
            f:close()
            if is_disabled then
                return nil
            end
            if found_key then
                return found_key
            end
        end
    end
    return nil
end

local api_key = get_wakatime_key()

return {
    "wakatime/vim-wakatime",
    lazy = false,
    enabled = api_key ~= nil,
    init = function()
        if api_key then
            vim.env.WAKATIME_API_KEY = api_key
        end
    end,
}
