-- after/ftplugin/c.lua
-- Dynamic indentation for C files (Reads .clang-format if present, falls back to sleuth/4 spaces)

local function apply_c_indent()
    local bufname = vim.api.nvim_buf_get_name(0)
    local dir = (bufname and bufname ~= "") and vim.fs.dirname(bufname) or vim.fn.getcwd()
    local clang_format = vim.fs.find({ ".clang-format", "_clang-format" }, { upward = true, path = dir })[1]

    if clang_format and vim.fn.filereadable(clang_format) == 1 then
        local content = vim.fn.readfile(clang_format, "", 80)
        local indent_width = nil
        local use_tab = nil
        local tab_width = nil

        for _, line in ipairs(content) do
            local iw = line:match("^%s*IndentWidth:%s*(%d+)")
            if iw then indent_width = tonumber(iw) end
            local ut = line:match("^%s*UseTab:%s*([%a_]+)")
            if ut then use_tab = ut end
            local tw = line:match("^%s*TabWidth:%s*(%d+)")
            if tw then tab_width = tonumber(tw) end
        end

        if indent_width then
            local effective_tab = tab_width or indent_width
            vim.opt_local.shiftwidth = indent_width
            vim.opt_local.tabstop = effective_tab
            vim.opt_local.softtabstop = indent_width

            if use_tab == "Never" then
                vim.opt_local.expandtab = true
            elseif use_tab == "Always" or use_tab == "ForIndentationOnMultiline" or use_tab == "ForContinuationAndIndentation" then
                vim.opt_local.expandtab = false
            end
            vim.b.sleuth_heuristics = 0
            return
        end
    end

    -- Default fallback: 4 spaces
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
end

apply_c_indent()
