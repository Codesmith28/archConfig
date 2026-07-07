return {
    {
        "folke/snacks.nvim",
        opts = {
            picker = {
                -- 1. Tell the global pickers to default to your custom layout style profile
                layout = {
                    preset = "my_telescope_style",
                },

                -- 2. Define the structural design inside the proper picker layouts directory
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
                },
                -- 3. Your explorer explicitly retains its separate inline layout block overrides
                sources = {
                    explorer = {
                        layout = {
                            layout = {
                                -- position = "right",
                                width = 0.23,
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
            -- ─── DEFINE THE ISOLATED TELESCOPE STYLE HERE ───
            styles = {
                -- Your clean custom template layout style
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

                -- Keeps your floating terminal layout untouched
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
    -- {
    --     "folke/trouble.nvim",
    --     opts = {
    --         modes = {
    --             diagnostics = {
    --                 auto_open = true,
    --                 auto_close = false,
    --             },
    --         },
    --     },
    -- },
}
