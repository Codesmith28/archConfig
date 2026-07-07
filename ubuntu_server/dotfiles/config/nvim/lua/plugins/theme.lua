-- Detect if we are in an SSH session
local is_ssh = os.getenv("SSH_CLIENT") ~= nil or osgetenv("SSH_TTY") ~= nil

return {
  -- 1. Catppuccin Configuration
  {
    "catppuccin/nvim",
    name = "catppuccin",
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- Provide a hard structural fallback for SSH sessions
        transparent_background = true,
        show_end_of_buffer = true,
        term_colors = true,
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          telescope = { style = "transparent" },
          mason = true,
          which_key = true,
        },
      })
    end,
  },

  -- 2. Github Nvim Theme
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    priority = 1000,
    config = function() end,
  },

  -- 3. Auto Dark Mode (Only active locally)
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    enabled = not is_ssh, -- Completely disables the plugin when inside an SSH VM
    priority = 1001,
    config = function()
      local auto_dark_mode = require("auto-dark-mode")
      auto_dark_mode.setup({
        update_interval = 1000,
        set_dark_mode = function()
          vim.api.nvim_set_option_value("background", "dark", {})
          vim.cmd("colorscheme catppuccin-mocha")
        end,
        set_light_mode = function()
          vim.api.nvim_set_option_value("background", "light", {})
          vim.cmd("colorscheme catppuccin-latte")
        end,
      })
    end,
  },

  -- 4. LazyVim Configuration
  {
    "LazyVim/LazyVim",
    opts = function()
      if is_ssh then
        -- Over SSH, rely on native terminal background query detection
        return {
          colorscheme = function()
            vim.schedule(function()
              if vim.o.background == "light" then
                vim.cmd("colorscheme catppuccin-latte")
              else
                vim.cmd("colorscheme catppuccin-mocha")
              end
            end)
          end,
        }
      else
        -- Locally, hand control directly off to auto-dark-mode string
        return { colorscheme = "catppuccin" }
      end
    end,
  },
}
