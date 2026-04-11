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
                    -- Delegate to the shell to securely read our environment variables
                    main = "sh",
                    args = {
                        "-c",
                        '/opt/homebrew/bin/g++-15 -std=c++2b -Wall -Wextra -D_GLIBCXX_DEBUG "$CP_FILE" -o "$CP_OUT"',
                    },
                },
                execute = {
                    -- Ensure the plugin runs the binary from the correct subdirectory
                    main = "sh",
                    args = {
                        "-c",
                        -- 'exec' ensures the binary connects directly to the plugin's test case pipes
                        'exec "$CP_OUT"',
                    },
                },
            },
        },
    },
}
