return {
    "folke/trouble.nvim",
    opts = {
        open_no_results = true,
        warn_no_results = false,
    },
    init = function()
        local group = vim.api.nvim_create_augroup("TroubleDefaultDiagnostics", { clear = true })

        local function open_trouble_default()
            if vim.t.trouble_diagnostics_opened then
                return
            end

            local buf = vim.api.nvim_get_current_buf()
            local buftype = vim.bo[buf].buftype
            local filetype = vim.bo[buf].filetype

            -- Ignore special / non-file buffers
            if buftype ~= "" or filetype == "snacks_dashboard" or filetype == "trouble" or filetype == "help" then
                return
            end

            local bufname = vim.api.nvim_buf_get_name(buf)
            if bufname == "" then
                return
            end

            vim.t.trouble_diagnostics_opened = true
            vim.schedule(function()
                if not require("trouble").is_open("diagnostics") then
                    require("trouble").open({ mode = "diagnostics", focus = false })
                end
            end)
        end

        vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
            group = group,
            callback = open_trouble_default,
        })

        vim.api.nvim_create_autocmd("VimEnter", {
            group = group,
            callback = function()
                vim.schedule(open_trouble_default)
            end,
        })
    end,
}
