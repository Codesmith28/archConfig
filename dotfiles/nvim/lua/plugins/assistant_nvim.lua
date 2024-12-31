return {
    "A7lavinraj/assistant.nvim",
    event = "VimEnter",
    dependencies = { "stevearc/dressing.nvim" }, -- optional but recommended
    keys = {
        { "<leader>a", "<cmd>AssistantToggle<cr>", desc = "Toggle Assistant.nvim window" },
    },
    opts = {},
}
