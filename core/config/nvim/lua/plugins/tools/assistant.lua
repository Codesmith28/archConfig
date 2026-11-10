local deps = require("config.deps")
local local_project = vim.fn.expand("~/Projects/assistant.nvim")

return {
    "Codesmith28/assistant.nvim",
    dir = vim.fn.isdirectory(local_project) == 1 and local_project or nil,
    enabled = deps.has_cpp or deps.has_python or deps.has_rust,
    lazy = false,
    cmd = { "Assistant" },
    keys = {
        {
            "<leader>a",
            "<cmd>Assistant<cr>",
            desc = "Assistant.nvim",
        },
    },
    opts = {
        core = {
            port = 10043,
            process_budget = 5000,
            default_source = "cpp",
            out_dir = ".ast/bin",
        },
    },
}
