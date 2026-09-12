return {
    {
        "towolf/vim-helm",
        ft = { "helm" },
        init = function()
            -- Dynamic template detector:
            -- Instead of hardcoding extension tables, strip `.tmpl` and let Neovim
            -- detect the underlying filetype dynamically (e.g., foo.sql.tmpl -> sql, bar.json.tmpl -> json).
            local function detect_tmpl(path, bufnr)
                local unmasked = path:gsub("%.tmpl$", "")
                local ft = vim.filetype.match({ filename = unmasked })
                if ft == "yaml" then
                    return "helm"
                elseif ft then
                    return ft
                end

                -- Content inspection for standalone `.tmpl` files
                if bufnr and bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr) then
                    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)
                    local content = table.concat(lines, "\n")
                    if
                        content:match("apiVersion:")
                        or content:match("kind:")
                        or content:match("metadata:")
                        or content:match("spec:")
                        or content:match("^%s*%-%-%-")
                        or content:match("\n%s*%-%-%-")
                        or content:match("{{")
                        or content:match("{%%")
                    then
                        return "helm"
                    end
                end

                -- Fallback to Go template syntax
                return "gotmpl"
            end

            vim.filetype.add({
                extension = {
                    tmpl = detect_tmpl,
                    gotmpl = "gotmpl",
                },
                pattern = {
                    [".*/templates/.*%.tpl"] = "helm",
                    [".*/templates/.*%.ya?ml"] = "helm",
                    [".*/templates/.*%.txt"] = "helm",
                    ["helmfile.*%.ya?ml"] = "helm",
                },
            })

            -- Jinja2 & ${...} syntax highlighting for Helm/YAML templates
            -- Inlined directly to avoid needing an external `after/syntax/helm.vim` file
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "helm",
                group = vim.api.nvim_create_augroup("helm_syntax_ext", { clear = true }),
                callback = function()
                    vim.cmd([=[
                        syn region jinjaTag start="{%\(-\|\s\)\?" end="\(\-\|\s\)\?%}" contains=jinjaStatement,jinjaVariable,jinjaString,jinjaNumber,jinjaOperator display
                        syn keyword jinjaStatement contained if elif else endif for endfor in set include import block endblock raw endraw is defined not and or filter default
                        syn match jinjaVariable contained /[a-zA-Z_][a-zA-Z0-9_]*/
                        syn region jinjaString contained start=+"+ skip=+\\\\\|\\"+ end=+"+
                        syn region jinjaString contained start=+'+ skip=+\\\\\|\\'+ end=+'+
                        syn match jinjaNumber contained /\<\d\+\(\.\d\+\)\?\>/
                        syn match jinjaOperator contained /[=!<>&|+\-*\/]/

                        hi def link jinjaTag PreProc
                        hi def link jinjaStatement Keyword
                        hi def link jinjaVariable Identifier
                        hi def link jinjaString String
                        hi def link jinjaNumber Number
                        hi def link jinjaOperator Operator

                        syn region tmplEnvVar start='\${' end='}' containedin=yamlPlainScalar,yamlFlowString,yamlFlowMapping,yamlBlockMappingKey display
                        hi def link tmplEnvVar Special
                    ]=])
                end,
            })
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            if type(opts.ensure_installed) == "table" then
                vim.list_extend(opts.ensure_installed, { "gotmpl" })
            end
        end,
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                helm_ls = {},
            },
        },
    },
}

