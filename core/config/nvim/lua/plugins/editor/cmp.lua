local function get_snippet_paths()
    local paths = {}
    local seen = {}

    local function add_if_exists(dir)
        if not dir or dir == "" then
            return
        end
        local real = vim.uv.fs_realpath(vim.fn.expand(dir))
        if real and vim.fn.isdirectory(real) == 1 and not seen[real] then
            seen[real] = true
            table.insert(paths, real)
        end
    end

    -- 1. Neovim config snippets (~/.config/nvim/snippets) if present
    add_if_exists(vim.fn.stdpath("config") .. "/snippets")

    -- 2. Current Git repo root snippets (<repo_root>/snippets) if present
    local root = vim.fs.root(0, { ".git" }) or vim.uv.cwd()
    if root then
        add_if_exists(root .. "/snippets")
    end

    return paths
end

return {
    "saghen/blink.cmp",
    opts = function(_, opts)
        opts = opts or {}
        opts.snippets = vim.tbl_deep_extend("force", opts.snippets or {}, {
            preset = "default",
        })
        opts.signature = vim.tbl_deep_extend("force", opts.signature or {}, {
            enabled = true,
        })
        opts.completion = vim.tbl_deep_extend("force", opts.completion or {}, {
            menu = {
                border = "rounded",
                draw = {
                    columns = {
                        { "label", "label_description", gap = 1 },
                        { "kind_icon", "kind", gap = 1 },
                    },
                },
            },
            documentation = {
                window = {
                    border = "rounded",
                },
            },
        })
        opts.sources = opts.sources or {}
        opts.sources.providers = opts.sources.providers or {}
        opts.sources.providers.snippets = vim.tbl_deep_extend("force", opts.sources.providers.snippets or {}, {
            opts = {
                search_paths = get_snippet_paths(),
            },
        })
        return opts
    end,
}
