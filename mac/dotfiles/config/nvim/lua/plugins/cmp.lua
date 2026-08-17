return {
    "saghen/blink.cmp",
    opts = {
        cmdline = {
            enabled = true, -- Fuzzy complete Neovim commands
        },
        signature = {
            enabled = true, -- Shows function parameters context as you type
        },
        keymap = {
            -- Options: 'default', 'super-tab' (VSCode style), or 'enter'
            preset = "super-tab",
        },
        completion = {
            accept = {
                auto_brackets = {
                    enabled = true, -- Auto-inject () when completing a function
                },
            },
            menu = {
                -- Add borders to the completion menu
                border = "rounded",
                -- Change what is drawn inside the menu (e.g., icons, labels, source names)
                draw = {
                    columns = {
                        { "label", "label_description", gap = 1 },
                        { "kind_icon", "kind", gap = 1 },
                    },
                },
            },
            documentation = {
                window = {
                    -- Add borders to the documentation hover window
                    border = "rounded",
                },
            },
        },
    },
}
