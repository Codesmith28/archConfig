return {
    {
        "folke/snacks.nvim",
        opts = {
            quickfile = { enabled = true },
            words = { enabled = true },
            indent = {
                enabled = true,
                animate = {
                    enabled = vim.fn.has("nvim-0.10") == 1,
                    style = "out",
                    duration = {
                        step = 20,
                        total = 300,
                    },
                },
            },
            picker = {
                -- adapt orientation depending on available window width
                layout = {
                    preset = function()
                        return vim.o.columns >= 120 and "my_telescope_style" or "my_telescope_style_vertical"
                    end,
                },

                layouts = {
                    my_telescope_style = {
                        layout = {
                            box = "horizontal",
                            width = 0.90,
                            height = 0.92,
                            {
                                box = "vertical",
                                border = "rounded",
                                title = " {title} {live} {flags} ",
                                title_pos = "center",
                                { win = "list", border = "none" },
                                { win = "input", height = 1, border = "top" },
                            },
                            -- Back to 2:3 ratio scale allocation (Preview gets exactly 60% of the total width)
                            {
                                win = "preview",
                                title = " {preview} ",
                                title_pos = "center",
                                border = "rounded",
                                width = 0.60,
                            },
                        },
                    },
                    my_telescope_style_vertical = {
                        layout = {
                            box = "vertical",
                            width = 0.90,
                            height = 0.92,
                            {
                                win = "preview",
                                title = " {preview} ",
                                title_pos = "center",
                                border = "rounded",
                                height = 0.50,
                            },
                            {
                                box = "vertical",
                                border = "rounded",
                                title = " {title} {live} {flags} ",
                                title_pos = "center",
                                { win = "list", border = "none" },
                                { win = "input", height = 1, border = "top" },
                            },
                        },
                    },
                },
                sources = {
                    explorer = {
                        layout = {
                            layout = {
                                width = 0.20,
                            },
                        },
                        hidden = true,
                        ignored = true,
                        follow_file = true,
                        focus = "list",
                        jump = { close = false },
                        win = {
                            list = { keys = { ["<C-E>"] = "explore_all" } },
                            input = { keys = { ["<C-E>"] = "explore_all" } },
                        },
                        actions = {
                            explore_all = function(picker)
                                local item = picker:current()
                                if not item or item.dir == false then
                                    return
                                end
                                local Tree = require("snacks.explorer.tree")
                                local Actions = require("snacks.explorer.actions")
                                local target_node = Tree:find(item.file)
                                if not target_node then
                                    return
                                end
                                Tree:walk(target_node, function(node)
                                    if node.dir then
                                        Tree:open(node.path)
                                        Tree:expand(node)
                                    end
                                end, { all = true })
                                Actions.update(picker, { refresh = true })
                            end,
                        },
                    },
                },
                formatters = {
                    file = {
                        icons = {
                            directory = { close = "󰉋 ", open = "󰝰 ", empty = "󱞞 " },
                        },
                    },
                },
            },
            styles = {
                my_telescope_style = {
                    layout = {
                        box = "horizontal",
                        width = 0.85,
                        height = 0.80,
                        {
                            box = "vertical",
                            border = "rounded",
                            title = " {title} {live} {flags} ",
                            title_pos = "center",
                            { win = "list", border = "none" },
                            { win = "input", height = 1, border = "top" }, -- Search bar down
                        },
                        {
                            win = "preview",
                            title = " {preview} ",
                            title_pos = "center",
                            border = "rounded",
                            width = 0.60,
                        }, -- 2:3 ratio layout
                    },
                },

                terminal = {
                    position = "float",
                    width = 0.8,
                    height = 0.8,
                    border = "rounded",
                    backdrop = 60,
                },
            },
        },
    },
    {
        "folke/which-key.nvim",
        opts = {
            win = {
                border = "rounded",
            },
        },
    },
    {
        "folke/noice.nvim",
        opts = {
            presets = {
                lsp_doc_border = true, -- Adds rounded border to hover docs and signature help
            },
        },
    },
}
