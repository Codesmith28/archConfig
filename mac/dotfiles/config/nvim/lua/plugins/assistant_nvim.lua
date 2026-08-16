local function get_gpp_compiler()
    for v = 25, 11, -1 do
        local candidates = {
            "/opt/homebrew/bin/g++-" .. v,
            "/usr/local/bin/g++-" .. v,
            "g++-" .. v,
        }
        for _, path in ipairs(candidates) do
            if vim.fn.executable(path) == 1 then
                return path
            end
        end
    end

    local fallbacks = {
        "/opt/homebrew/bin/g++",
        "/usr/local/bin/g++",
        "g++",
        "clang++",
    }
    for _, path in ipairs(fallbacks) do
        if vim.fn.executable(path) == 1 then
            return path
        end
    end

    return "g++"
end

return {
    "A7lavinraj/assistant.nvim",
    lazy = false,
    keys = {
        { "<leader>a", "<cmd>Assistant<cr>", desc = "Assistant.nvim" },
    },
    opts = function()
        return {
            commands = {
                cpp = {
                    extension = "cpp",
                    compile = {
                        main = get_gpp_compiler(),
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
                        main = "./$FILENAME_WITHOUT_EXTENSION",
                        args = {},
                    },
                },
            },
        }
    end,
}
