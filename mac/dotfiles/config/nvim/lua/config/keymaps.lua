-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Escape in insert mode
map("i", "kj", "<Esc>", { noremap = false })

-- editing
map("n", "<C-a>", "ggVG", { desc = "Select all" })

-- Ctrl+C: Copy all to system clipboard, keep cursor position
map("n", "<C-c>", 'mzggVG"+y`z', opts)

-- enable horizontal scrolling with mouse
vim.opt.mouse = "a"
map("n", "<S-ScrollWheelUp>", "10zh", { noremap = true, silent = true })
map("n", "<S-ScrollWheelDown>", "10zl", { noremap = true, silent = true })

-- harpoon mappings
map("n", "<leader>ah", "<cmd>lua require('harpoon.mark').add_file()<CR>", { desc = "Add mark" })
map("n", "<leader>lh", "<cmd>Telescope harpoon marks<CR>", { desc = "Toggle mark telescope" })
map("n", "<leader>fm", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<CR>", { desc = "Toggle mark menu" })

-- Move lines
map("v", "<C-j>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true, desc = "Move line down" })
map("v", "<C-k>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true, desc = "Move line up" })

-- indenting
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Add go tags:
map("n", "<leader>gsj", "<cmd> GoTagAdd json <CR>", { desc = "Add json struct tags" })
map("n", "<leader>gsy", "<cmd> GoTagAdd yaml <CR>", { desc = "Add yaml struct tags" })

-- Invert horizontal scroll for touchpad
vim.keymap.set("n", "<ScrollWheelRight>", "<ScrollWheelLeft>", { noremap = true, silent = true })
vim.keymap.set("n", "<ScrollWheelLeft>", "<ScrollWheelRight>", { noremap = true, silent = true })

-- Format only git-modified lines (Works for both Conform formatters & LSP/JDTLS)
local function format_modified_lines()
    local gs = package.loaded.gitsigns
    if not gs then
        vim.notify("Gitsigns not loaded", vim.log.levels.WARN)
        return
    end

    local hunks = gs.get_hunks()
    if not hunks or vim.tbl_isempty(hunks) then
        vim.notify("No modified lines found to format", vim.log.levels.INFO)
        return
    end

    local conform = require("conform")

    -- Loop bottom-up (reverse order) so line-number shifts from formatting
    -- do not break the calculated positions of earlier hunks higher up.
    for i = #hunks, 1, -1 do
        local hunk = hunks[i]
        if hunk.type ~= "delete" and hunk.added.count > 0 then
            local start_line = hunk.added.start
            local end_line = hunk.added.start + hunk.added.count - 1

            conform.format({
                async = false, -- Crucial: Blocks execution so line positions update sequentially
                lsp_format = "fallback", -- Crucial: Forces Java to fall back to your JDTLS XML setup
                range = {
                    ["start"] = { start_line, 0 },
                    ["end"] = { end_line, 0 },
                },
            })
        end
    end
    vim.notify("Formatted modified lines", vim.log.levels.INFO)
end

-- Bind the function to a keymap (e.g., <leader>cm for "Code Modified")
vim.keymap.set("n", "<leader>mf", format_modified_lines, { desc = "Format modified lines" })
