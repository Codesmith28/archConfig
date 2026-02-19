return {
    {
        "folke/snacks.nvim",
        opts = {
            picker = {
                sources = {
                    explorer = {
                        hidden = true, -- show hidden files (dotfiles)
                        ignored = true, -- show git-ignored files
                    },
                },
            },
        },
    },
}
