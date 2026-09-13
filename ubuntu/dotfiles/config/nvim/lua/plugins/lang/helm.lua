return {
    {
        "towolf/vim-helm",
        ft = "helm",
        init = function()
            vim.filetype.add({
                pattern = {
                    [".*/templates/.*%.tpl"] = "helm",
                    [".*/templates/.*%.ya?ml"] = "helm",
                    [".*/templates/.*%.txt"] = "helm",
                    ["helmfile.*%.ya?ml"] = "helm",
                },
            })
        end,
    },
}
