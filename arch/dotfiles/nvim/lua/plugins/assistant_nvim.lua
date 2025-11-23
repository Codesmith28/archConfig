return {
    "A7lavinraj/assistant.nvim",
    dependencies = { "folke/snacks.nvim" }, -- optional but recommended
    lazy = false, -- Start TCP Listener on Neovim startup
    keys = {
        { "<leader>a", "<cmd>Assistant<cr>", desc = "Assistant.nvim" },
    },
    opts = {},
}
