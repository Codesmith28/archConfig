return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
      },
    },
    keys = {
      { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Harpoon Add File" },
      { "<leader>hh", function() local h = require("harpoon") h.ui:toggle_quick_menu(h:list()) end, desc = "Harpoon Menu" },
      { "<leader>h1", function() require("harpoon"):list():select(1) end, desc = "Harpoon File 1" },
      { "<leader>h2", function() require("harpoon"):list():select(2) end, desc = "Harpoon File 2" },
      { "<leader>h3", function() require("harpoon"):list():select(3) end, desc = "Harpoon File 3" },
      { "<leader>h4", function() require("harpoon"):list():select(4) end, desc = "Harpoon File 4" },
    },
  },
}
