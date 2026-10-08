return {
    {
        "tpope/vim-sleuth",
        init = function()
            vim.g.sleuth_java_heuristics = 0
            vim.g.sleuth_c_heuristics = 0
            vim.g.sleuth_cpp_heuristics = 0
        end,
    },
}
