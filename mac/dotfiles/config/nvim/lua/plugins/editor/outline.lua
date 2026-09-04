return {
    "hedyhli/outline.nvim",
    lazy = true,
    cmd = { "Outline", "OutlineOpen" },
    keys = {
        { "<leader>o", "<cmd>Outline<CR>", desc = "Toggle outline" },
    },
    opts = {
        symbol_folding = {
            autofold_depth = 2,
        },
        outline_window = {
            auto_jump = true,
            width = 20,
        },
        guides = {
            markers = {
                middle = "⎬",
                bottom = "⎩",
                vertical = "⎥",
            },
        },
    },
}
