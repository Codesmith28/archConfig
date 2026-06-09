return {
    "nvim-treesitter/nvim-treesitter",
    opts = {
        auto_install = true,
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
        -- This MUST be present to stop auto_install from re-fetching them on launch
        ignore_install = { "vim", "lua", "query" },
    },
}
