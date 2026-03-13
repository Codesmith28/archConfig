return {
    "A7lavinraj/assistant.nvim",
    lazy = false,
    keys = {
        { "<leader>a", "<cmd>Assistant<cr>", desc = "Assistant.nvim" },
    },
    opts = {
        commands = {
            cpp = {
                compile = {
                    -- Explicitly point to your M4 Homebrew compiler
                    main = "/opt/homebrew/bin/g++-15",
                    -- args = {
                    --     -- Modern C++ and strict warnings
                    --     "-std=c++2b",
                    --     "-Wall",
                    --     "-Wextra",
                    --     -- GCC's built-in bounds checking for vectors/strings!
                    --     "-D_GLIBCXX_DEBUG",
                    --     -- The plugin's required variables for I/O
                    --     "$FILENAME_WITH_EXTENSION",
                    --     "-o",
                    --     "$FILENAME_WITHOUT_EXTENSION",
                    -- },
                },
            },
        },
    },
}
