return {
    {
        "folke/snacks.nvim",
        opts = {
            -- file picker
            picker = {
                sources = {
                    explorer = {
                        hidden = true, -- show hidden files (dotfiles)
                        ignored = true, -- show git-ignored files
                    },
                },
            },
            -- terminal
            styles = {
                terminal = {
                    position = "float", -- Forces it to open in the center
                    width = 0.8, -- Takes up 80% of screen width
                    height = 0.8, -- Takes up 80% of screen height
                    border = "rounded",
                    backdrop = 60, -- Dims the editor behind the float
                },
            },
        },
    },
}
