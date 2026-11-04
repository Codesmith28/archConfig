local deps = require("config.deps")

local function get_gpp_compiler()
    for v = 25, 11, -1 do
        local candidates = {
            "/opt/homebrew/bin/g++-" .. v,
            "/usr/local/bin/g++-" .. v,
            "/usr/bin/g++-" .. v,
            "g++-" .. v,
        }
        for _, path in ipairs(candidates) do
            if vim.fn.executable(path) == 1 then
                return path
            end
        end
    end

    local fallbacks = {
        "/opt/homebrew/bin/g++",
        "/usr/local/bin/g++",
        "/usr/bin/g++",
        "g++",
        "/usr/bin/clang++",
        "clang++",
    }
    for _, path in ipairs(fallbacks) do
        if vim.fn.executable(path) == 1 then
            return path
        end
    end

    return "g++"
end

-- Directory to store compiled binaries (out files) to prevent repo clutter
local out_dir = ".bin"

local function ensure_out_dir()
    local buf_dir = vim.fn.expand("%:p:h")
    if buf_dir and buf_dir ~= "" and vim.fn.isdirectory(buf_dir) == 1 then
        local target = buf_dir .. "/" .. out_dir
        if vim.fn.isdirectory(target) == 0 then
            vim.fn.mkdir(target, "p")
        end
    end

    local cwd = vim.fn.getcwd()
    local cwd_target = cwd .. "/" .. out_dir
    if vim.fn.isdirectory(cwd_target) == 0 then
        vim.fn.mkdir(cwd_target, "p")
    end
end

-- Persistent module-level tracking of active source file across buffer switches and window closes
local last_tracked_filedir = nil
local last_tracked_filename = nil
local last_tracked_filepath = nil

local function track_source_file()
    local buf = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buf)
    if name and name ~= "" and not string.match(name:lower(), "assistant") then
        last_tracked_filedir = vim.fn.fnamemodify(name, ":p:h")
        last_tracked_filename = vim.fn.fnamemodify(name, ":t:r")
        last_tracked_filepath = vim.fn.fnamemodify(name, ":p")
        local ok_st, state = pcall(require, "assistant.state")
        if ok_st then
            state.set_local_key("source_buf", buf)
            state.set_local_key("source_file", name)
            state.set_local_key("filedir", last_tracked_filedir)
            state.set_local_key("filename", last_tracked_filename)
            state.set_local_key("extension", vim.fn.fnamemodify(name, ":e"))
        end
    end
end

-- Prevent LSP and auto-formatters from crashing assistant.nvim testcase buffers
local assistant_group = vim.api.nvim_create_augroup("assistant_buffers", { clear = true })
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = assistant_group,
    pattern = "*",
    callback = function(args)
        local buf_name = vim.api.nvim_buf_get_name(args.buf)
        local filetype = vim.api.nvim_get_option_value("filetype", { buf = args.buf })
        local is_modifiable = vim.api.nvim_get_option_value("modifiable", { buf = args.buf })

        -- target assistant.nvim buffers or any non-modifiable UI buffers
        if string.match(buf_name:lower(), "assistant") or filetype == "assistant" or not is_modifiable then
            vim.b[args.buf].autoformat = false

            -- forcibly detach any LSP trying to hook into the UI
            for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
                vim.lsp.buf_detach_client(args.buf, client.id)
            end
        end
    end,
})

return {
    "A7lavinraj/assistant.nvim",
    enabled = deps.has_cpp,
    lazy = false,
    keys = {
        {
            "<leader>a",
            function()
                track_source_file()
                ensure_out_dir()
                vim.cmd("Assistant")
            end,
            desc = "Assistant.nvim",
        },
    },
    opts = function()
        return {
            core = {
                port = 10043,
                default_source = "cpp",
            },
            commands = {
                cpp = {
                    extension = "cpp",
                    compile = {
                        main = get_gpp_compiler(),
                        args = {
                            "-std=c++26",
                            "-Wall",
                            "-Wextra",
                            "-D_GLIBCXX_DEBUG",
                            "$FILENAME_WITH_EXTENSION",
                            "-o",
                            out_dir .. "/$FILENAME_WITHOUT_EXTENSION",
                        },
                    },
                    execute = {
                        main = "./" .. out_dir .. "/$FILENAME_WITHOUT_EXTENSION",
                        args = {},
                    },
                },
            },
        }
    end,
    config = function(_, opts)
        -- 1. Ensure config is initialized first so assistant.mappings won't hit nil values
        local ok_conf, conf = pcall(require, "assistant.config")
        if ok_conf and conf.overwrite then
            local orig_overwrite = conf.overwrite
            conf.overwrite = function(user_opts)
                orig_overwrite(user_opts)
                if conf.values and conf.values.commands then
                    for k in pairs(conf.values.commands) do
                        if k ~= "cpp" then
                            conf.values.commands[k] = nil
                        end
                    end
                end
            end
            conf.overwrite(opts)
        end

        -- 2. Automatically select cpp without prompting picker if only one source exists
        local ok_picker, picker = pcall(require, "assistant.builtins.__picker")
        if ok_picker and picker.standard then
            local orig_pick = picker.standard.pick
            picker.standard.pick = function(self, items, options, on_choice)
                if options and options.prompt == "source" and #items == 1 then
                    on_choice(items[1])
                    return
                end
                return orig_pick(self, items, options, on_choice)
            end
        end

        -- 3. Run plugin setup
        require("assistant").setup(opts)

        if ok_conf and conf.values and conf.values.commands then
            for k in pairs(conf.values.commands) do
                if k ~= "cpp" then
                    conf.values.commands[k] = nil
                end
            end
        end

        -- 4. Load assistant modules safely
        local ok_utils, utils = pcall(require, "assistant.utils")
        local ok_state, state = pcall(require, "assistant.state")
        local ok_fs, fs = pcall(require, "assistant.core.fs")

        -- Helper to get directory of active source code file
        local function get_file_dir()
            if
                last_tracked_filedir
                and last_tracked_filedir ~= ""
                and last_tracked_filedir ~= "/"
                and vim.fn.isdirectory(last_tracked_filedir) == 1
            then
                return last_tracked_filedir
            end
            if ok_state then
                local dir = state.get_local_key("filedir")
                if dir and dir ~= "" and dir ~= "/" and vim.fn.isdirectory(dir) == 1 then
                    return dir
                end
            end
            local cur_buf_dir = vim.fn.expand("%:p:h")
            if cur_buf_dir and cur_buf_dir ~= "" and cur_buf_dir ~= "/" and vim.fn.isdirectory(cur_buf_dir) == 1 then
                return cur_buf_dir
            end
            local cwd = vim.fn.getcwd()
            return (cwd and cwd ~= "/") and cwd or vim.fn.expand("~")
        end

        -- Helper to immediately persist testcases to disk
        local function persist_state()
            if not ok_state or not ok_fs then
                return
            end
            local tests = state.get_global_key("tests")
            if not tests or vim.tbl_isempty(tests) then
                return
            end
            local filepath = fs.get_state_filepath()
            if filepath and filepath ~= "" then
                fs.write(filepath, vim.json.encode({ tests = tests }))
            end
        end

        -- Hook utils.get_source_config to ensure out_dir exists before compile / execute
        -- and format paths properly whether file is in cwd or a subdirectory
        if ok_utils and utils.get_source_config then
            local orig_get_source_config = utils.get_source_config
            utils.get_source_config = function(...)
                ensure_out_dir()
                local cmd = orig_get_source_config(...)
                local filedir = get_file_dir()
                local cwd = vim.fn.getcwd()
                if filedir and filedir ~= cwd and cmd then
                    local rel_dir = vim.fn.fnamemodify(filedir, ":.")
                    if rel_dir and rel_dir ~= "" and rel_dir ~= "." then
                        local fname = (ok_state and state.get_local_key("filename")) or last_tracked_filename or ""
                        local ext = (ok_state and state.get_local_key("extension")) or "cpp"
                        local target_file = string.format("%s.%s", fname, ext)

                        if cmd.compile and cmd.compile.args then
                            for i, arg in ipairs(cmd.compile.args) do
                                if string.match(arg, "^%.bin/") then
                                    cmd.compile.args[i] = rel_dir .. "/" .. arg
                                elseif arg == target_file or string.match(arg, target_file .. "$") then
                                    cmd.compile.args[i] = rel_dir .. "/" .. target_file
                                end
                            end
                        end
                        if cmd.execute and cmd.execute.main then
                            if string.match(cmd.execute.main, "^%./%.bin/") then
                                cmd.execute.main = "./" .. rel_dir .. "/.bin/" .. fname
                            end
                        end
                    end
                end
                return cmd
            end
        end

        -- Fix root search and .ast directory creation so testcases save properly in any folder
        if ok_fs then
            local function get_search_dirs()
                local dirs = {}
                local filedir = get_file_dir()
                if filedir and filedir ~= "" and filedir ~= "/" and vim.fn.isdirectory(filedir) == 1 then
                    table.insert(dirs, filedir)
                end
                local cwd = vim.fn.getcwd()
                if cwd and cwd ~= "/" and not vim.tbl_contains(dirs, cwd) then
                    table.insert(dirs, cwd)
                end
                return dirs
            end

            fs.find_root = function()
                for _, start_dir in ipairs(get_search_dirs()) do
                    local dir = start_dir
                    while dir and dir ~= "/" and dir ~= "." do
                        if vim.fn.isdirectory(dir .. "/.ast") == 1 then
                            return dir
                        end
                        local parent = vim.fn.fnamemodify(dir, ":h")
                        if parent == dir or parent == "/" then
                            break
                        end
                        dir = parent
                    end
                end
                return nil
            end

            fs.make_root = function()
                local dirs = get_search_dirs()
                local target_dir = dirs[1]
                if not target_dir or target_dir == "" or target_dir == "/" then
                    target_dir = last_tracked_filedir or vim.fn.getcwd()
                end
                if not target_dir or target_dir == "" or target_dir == "/" then
                    target_dir = vim.fn.expand("~")
                end
                local ast_path = target_dir .. "/.ast"
                if vim.fn.isdirectory(ast_path) == 0 then
                    vim.fn.mkdir(ast_path, "p")
                end
                return target_dir
            end

            fs.get_state_filepath = function()
                local fname = (ok_state and state.get_local_key("filename")) or last_tracked_filename
                if not fname or fname == "" then
                    fname = vim.fn.expand("%:t:r")
                end
                if not fname or fname == "" or fname == "." then
                    return nil
                end
                local root_dir = fs.find_root() or fs.make_root()
                if not root_dir or root_dir == "/" then
                    return nil
                end
                return string.format("%s/.ast/%s.json", root_dir, fname)
            end
        end

        -- Ensure state and tcp cleanly terminate on exit
        vim.api.nvim_create_autocmd("VimLeavePre", {
            group = vim.api.nvim_create_augroup("assistant_cleanup", { clear = true }),
            callback = function()
                pcall(persist_state)
                local ok_tcp, tcp = pcall(require, "assistant.core.tcp")
                if ok_tcp and tcp.stop_server then
                    pcall(tcp.stop_server)
                end
            end,
        })

        -- Patch testcase field editor (patcher) so :w, :wq, <CR>, and <C-s> write testcases and refresh previewer
        local ok_patcher, Patcher = pcall(require, "assistant.lib.patcher")
        if ok_patcher and Patcher.update then
            local orig_patcher_update = Patcher.update
            Patcher.update = function(self, content, options, on_update)
                options = options or {}
                local field = options.prompt or "field"
                local tc_id = options.testcase_id or (ok_state and state.get_local_key("assistant-cur-editing-id")) or 1
                local title_label =
                    string.format(" Testcase #%d %s | :w / <CR> to save | :q to cancel ", tc_id, field:upper())

                orig_patcher_update(self, content, options, function(new_content)
                    on_update(new_content)

                    -- Immediately update previewer canvas so user sees the written testcase
                    if ok_state then
                        local pw = state.get_local_key("assistant-previewer-window")
                        local pc = state.get_local_key("assistant-previewer-canvas")
                        local tests = state.get_global_key("tests")
                        if
                            pw
                            and pc
                            and tests
                            and tests[tc_id]
                            and pw.bufnr
                            and vim.api.nvim_buf_is_valid(pw.bufnr)
                        then
                            pc:set(pw.bufnr, tests[tc_id])
                        end
                    end

                    persist_state()
                end)

                if not ok_state then
                    return
                end

                local pw = state.get_local_key("assistant-patcher-window")
                if pw and pw.bufnr and vim.api.nvim_buf_is_valid(pw.bufnr) then
                    -- Set clear informative window title
                    if ok_utils and utils.set_win_config then
                        utils.set_win_config(pw.winid, {
                            title = title_label,
                            title_pos = "center",
                        })
                    end

                    -- Configure buffer to accept :w, :wq, and :x without 'buftype' or 'no file name' errors
                    vim.bo[pw.bufnr].buftype = "acwrite"
                    local dummy_name = string.format("assistant://patcher/%s_%d", field, pw.bufnr)
                    pcall(vim.api.nvim_buf_set_name, pw.bufnr, dummy_name)

                    vim.api.nvim_create_autocmd("BufWriteCmd", {
                        buffer = pw.bufnr,
                        callback = function()
                            local lines = vim.api.nvim_buf_get_lines(pw.bufnr, 0, -1, false)
                            local full_text = table.concat(lines, "\n")
                            on_update(full_text)
                            vim.bo[pw.bufnr].modified = false
                            vim.notify("Saved " .. field, vim.log.levels.INFO, { title = "Assistant.nvim" })

                            -- Refresh previewer
                            local prev_w = state.get_local_key("assistant-previewer-window")
                            local prev_c = state.get_local_key("assistant-previewer-canvas")
                            local tests = state.get_global_key("tests")
                            if
                                prev_w
                                and prev_c
                                and tests
                                and tests[tc_id]
                                and prev_w.bufnr
                                and vim.api.nvim_buf_is_valid(prev_w.bufnr)
                            then
                                prev_c:set(prev_w.bufnr, tests[tc_id])
                            end

                            persist_state()
                        end,
                    })

                    -- Add <C-s> to save
                    vim.keymap.set({ "n", "i" }, "<C-s>", function()
                        vim.cmd("write")
                    end, { buffer = pw.bufnr, silent = true, desc = "Save testcase" })

                    -- Prevent accidental <Esc> in normal mode from silently discarding everything
                    vim.keymap.set("n", "<Esc>", function()
                        -- Keep buffer open on accidental Esc after typing; use :q or q to cancel
                    end, { buffer = pw.bufnr, silent = true, desc = "Prevent accidental discard" })
                end
            end
        end

        -- Helper to patch a specific testcase field
        local function patch_field(testcase_ID, field, on_done)
            if not ok_state then
                return
            end
            local testcases = state.get_global_key("tests")
            if not testcases or not testcases[testcase_ID] then
                return
            end

            state.set_local_key("assistant-cur-editing-id", testcase_ID)
            local cur_status = state.get_local_key("status")
            if cur_status then
                cur_status.patcher = string.format("Patching(%s)", field)
            end

            local ok_pt, patcher_inst = pcall(require, "assistant.builtins.__patcher")
            if ok_pt and patcher_inst.standard then
                patcher_inst.standard:update(
                    testcases[testcase_ID][field] or "",
                    { prompt = field, testcase_id = testcase_ID },
                    function(content)
                        testcases[testcase_ID][field] = content
                        local pw = state.get_local_key("assistant-previewer-window")
                        local pc = state.get_local_key("assistant-previewer-canvas")
                        if pw and pc and pw.bufnr and vim.api.nvim_buf_is_valid(pw.bufnr) then
                            pc:set(pw.bufnr, testcases[testcase_ID])
                        end
                        persist_state()
                        if on_done then
                            on_done()
                        end
                    end
                )
            end
        end

        -- Patch actions (create, edit/patch, delete) for intuitive and responsive testcase writing
        local ok_act, actions = pcall(require, "assistant.actions")
        if ok_act then
            -- Create a new testcase and immediately launch the editor for input & expected output
            actions.create_new_testcase = function()
                local panel_window = state.get_local_key("assistant-panel-window")
                local panel_canvas = state.get_local_key("assistant-panel-canvas")
                local tests = state.get_global_key("tests")
                if not tests then
                    tests = {}
                    state.set_global_key("tests", tests)
                end

                table.insert(tests, { input = "", output = "" })
                local new_id = #tests

                if
                    panel_window
                    and panel_canvas
                    and panel_window.bufnr
                    and vim.api.nvim_buf_is_valid(panel_window.bufnr)
                then
                    panel_canvas:set(panel_window.bufnr, tests)
                    if panel_window.winid and vim.api.nvim_win_is_valid(panel_window.winid) then
                        pcall(vim.api.nvim_win_set_cursor, panel_window.winid, { new_id, 0 })
                    end
                end

                local pw = state.get_local_key("assistant-previewer-window")
                local pc = state.get_local_key("assistant-previewer-canvas")
                if pw and pc and pw.bufnr and vim.api.nvim_buf_is_valid(pw.bufnr) then
                    pc:set(pw.bufnr, tests[new_id])
                end

                persist_state()

                -- Prompt editor for input first, followed by expected output
                vim.schedule(function()
                    patch_field(new_id, "input", function()
                        vim.schedule(function()
                            patch_field(new_id, "output", function()
                                vim.notify(
                                    string.format("Testcase #%d saved!", new_id),
                                    vim.log.levels.INFO,
                                    { title = "Assistant.nvim" }
                                )
                            end)
                        end)
                    end)
                end)
            end

            -- Patch an existing testcase or create one if none exist
            actions.patch_testcase = function()
                local panel_window = state.get_local_key("assistant-panel-window")
                local panel_canvas = state.get_local_key("assistant-panel-canvas")
                local tests = state.get_global_key("tests") or {}

                if #tests == 0 then
                    actions.create_new_testcase()
                    return
                end

                local cur_id = 1
                if
                    panel_canvas
                    and panel_window
                    and panel_window.bufnr
                    and vim.api.nvim_buf_is_valid(panel_window.bufnr)
                then
                    cur_id = panel_canvas:get(panel_window.bufnr, panel_window.winid) or 1
                end
                if not tests[cur_id] then
                    cur_id = 1
                end

                state.set_local_key("assistant-cur-editing-id", cur_id)
                local cur_status = state.get_local_key("status")
                if cur_status then
                    cur_status.picker = "Picking(field)"
                end

                if ok_picker and picker.standard then
                    picker.standard:pick({ "input", "output" }, { prompt = "field" }, function(choice)
                        patch_field(cur_id, choice)
                    end)
                end
            end

            -- Run testcases: run selected, current, or all testcases
            local orig_run = actions.run_testcases
            actions.run_testcases = function()
                local tests = state.get_global_key("tests") or {}
                if #tests == 0 then
                    vim.notify(
                        "No testcases to run. Press 'c' to create one.",
                        vim.log.levels.WARN,
                        { title = "Assistant.nvim" }
                    )
                    return
                end
                local selected = {}
                for i, testcase in ipairs(tests) do
                    if testcase.selected then
                        table.insert(selected, i)
                    end
                end
                if vim.tbl_isempty(selected) then
                    local panel_window = state.get_local_key("assistant-panel-window")
                    local panel_canvas = state.get_local_key("assistant-panel-canvas")
                    local cur_id = panel_canvas
                        and panel_window
                        and panel_canvas:get(panel_window.bufnr, panel_window.winid)
                    if cur_id and tests[cur_id] then
                        require("assistant.core.processor").run_testcases({ cur_id })
                    else
                        local all_ids = {}
                        for i = 1, #tests do
                            table.insert(all_ids, i)
                        end
                        require("assistant.core.processor").run_testcases(all_ids)
                    end
                else
                    require("assistant.core.processor").run_testcases(selected)
                end
            end

            -- Remove testcases and immediately refresh previewer and disk
            local orig_remove = actions.remove_testcases
            actions.remove_testcases = function()
                orig_remove()
                local panel_window = state.get_local_key("assistant-panel-window")
                local panel_canvas = state.get_local_key("assistant-panel-canvas")
                local tests = state.get_global_key("tests") or {}
                local pw = state.get_local_key("assistant-previewer-window")
                local pc = state.get_local_key("assistant-previewer-canvas")
                if pw and pc and pw.bufnr and vim.api.nvim_buf_is_valid(pw.bufnr) then
                    local cur_id = panel_canvas
                        and panel_window
                        and panel_canvas:get(panel_window.bufnr, panel_window.winid)
                    if cur_id and tests[cur_id] then
                        pc:set(pw.bufnr, tests[cur_id])
                    else
                        pc:set(pw.bufnr, { input = "", output = "" })
                    end
                end
                persist_state()
            end
        end

        -- Configure panel, previewer, and patcher mappings
        local ok_mappings, mappings = pcall(require, "assistant.mappings")
        if ok_mappings and mappings.default_mappings then
            if mappings.default_mappings.panel and mappings.default_mappings.panel.n and ok_act then
                mappings.default_mappings.panel.n["<CR>"] = actions.patch_testcase
                mappings.default_mappings.panel.n["<cr>"] = actions.patch_testcase
                mappings.default_mappings.panel.n["e"] = actions.patch_testcase
                mappings.default_mappings.panel.n["c"] = actions.create_new_testcase
                mappings.default_mappings.panel.n["o"] = actions.create_new_testcase
                mappings.default_mappings.panel.n["d"] = actions.remove_testcases
            end
            if mappings.default_mappings.previewer and mappings.default_mappings.previewer.n and ok_act then
                mappings.default_mappings.previewer.n["<CR>"] = actions.patch_testcase
                mappings.default_mappings.previewer.n["<cr>"] = actions.patch_testcase
                mappings.default_mappings.previewer.n["e"] = actions.patch_testcase
            end
            if mappings.default_mappings.patcher and mappings.default_mappings.patcher.n then
                -- Disable single <Esc> from destroying modified patcher content
                mappings.default_mappings.patcher.n["<ESC>"] = function() end
                mappings.default_mappings.patcher.n["<esc>"] = function() end
            end
        end

        -- Hook Wizard:show to track source file, add keymap hints, and show helpful empty state
        local ok_wiz, wizard_mod = pcall(require, "assistant.builtins.__wizard")
        if ok_wiz and wizard_mod.standard then
            local orig_show = wizard_mod.standard.show
            wizard_mod.standard.show = function(self)
                track_source_file()
                orig_show(self)
                if ok_state and last_tracked_filedir then
                    state.set_local_key("filedir", last_tracked_filedir)
                    state.set_local_key("filename", last_tracked_filename)
                    state.set_local_key("filepath", last_tracked_filepath)
                end

                -- Display clear keybindings in panel footer
                if
                    self.panel_window
                    and self.panel_window.winid
                    and vim.api.nvim_win_is_valid(self.panel_window.winid)
                then
                    pcall(vim.api.nvim_win_set_config, self.panel_window.winid, {
                        footer = " [c] new  [e/<CR>] edit  [a] all  [r] run  [d] delete  [q] close ",
                        footer_pos = "center",
                    })
                end
            end

            -- Empty state helper in panel canvas
            if wizard_mod.standard.panel and wizard_mod.standard.panel.canvas then
                local orig_panel_fn = wizard_mod.standard.panel.canvas.fn
                wizard_mod.standard.panel.canvas.fn = function(bufnr, testcases)
                    if not testcases or #testcases == 0 then
                        local ok_txt, Text = pcall(require, "assistant.lib.text")
                        if ok_txt then
                            local text = Text.new({})
                            text:append("  No testcases found", "AssistantWarning"):nl(2)
                            text:append("  Press ", "AssistantParagraph")
                                :append("c", "AssistantTitle")
                                :append(" to create a testcase", "AssistantParagraph")
                                :nl()
                            text:append("  Press ", "AssistantParagraph")
                                :append("?", "AssistantTitle")
                                :append(" for keybindings", "AssistantParagraph")
                            text:render(bufnr)
                            return
                        end
                    end
                    orig_panel_fn(bufnr, testcases)
                end
            end
        end

        -- Re-bind :Assistant command to ensure source tracking and out_dir
        vim.api.nvim_create_user_command("Assistant", function()
            track_source_file()
            ensure_out_dir()
            require("assistant.builtins.__wizard").standard:show()
        end, { nargs = 0, force = true })
    end,
}
