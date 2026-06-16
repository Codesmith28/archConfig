return {
    {
        "folke/snacks.nvim",
        opts = {
            -- File picker
            picker = {
                sources = {
                    explorer = {
                        hidden = true, -- show hidden files (dotfiles)
                        ignored = true, -- show git-ignored files

                        -- Persistent Scope settings
                        follow_file = false,
                        focus = "list",
                        jump = { close = false },

                        -- Custom Keybindings
                        win = {
                            list = {
                                keys = {
                                    ["<C-E>"] = "explore_all",
                                },
                            },
                            input = {
                                keys = {
                                    ["<C-E>"] = "explore_all",
                                },
                            },
                        },

                        -- Custom Action
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

                -- Icons
                formatters = {
                    file = {
                        icons = {
                            directory = {
                                close = "󰉋 ",
                                open = "󰝰 ",
                                empty = "󱞞 ",
                            },
                        },
                    },
                },
            },

            -- Floating terminal
            styles = {
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
        "folke/trouble.nvim",
        opts = {
            modes = {
                diagnostics = {
                    auto_open = true,
                    auto_close = false,
                },
            },
        },
    },
}
