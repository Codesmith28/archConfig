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
                    -- Point directly to your custom Homebrew compiler path
                    main = "/opt/homebrew/bin/g++-16",
                    args = {
                        "-std=c++2b",
                        "-Wall",
                        "-Wextra",
                        "-D_GLIBCXX_DEBUG",
                        "$FILENAME_WITH_EXTENSION",
                        "-o",
                        "$FILENAME_WITHOUT_EXTENSION",
                    },
                },
                execute = {
                    -- Directly run the generated binary locally
                    main = "./$FILENAME_WITHOUT_EXTENSION",
                    args = {},
                },
            },
        },
    },
}
