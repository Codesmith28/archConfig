return {
  {
    "scalameta/nvim-metals",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    ft = { "scala", "sbt" }, -- CRUCIAL: Never attach to Java files
    opts = function()
      local metals_config = require("metals").bare_config()

      -- Metals Inlay & Implicit Hints
      metals_config.settings = {
        showImplicitArguments = true,
        showInferredType = true,
        showImplicitConversionsAndClasses = true,
        superMethodLensesEnabled = true,
        excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
        -- Let Metals know we are handling Java elsewhere
        javaFormat = { enabled = false },
      }

      local ok_blink, blink = pcall(require, "blink.cmp")
      metals_config.capabilities = ok_blink and blink.get_lsp_capabilities()
        or vim.lsp.protocol.make_client_capabilities()

      return metals_config
    end,
    config = function(_, metals_config)
      local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "scala", "sbt" },
        callback = function()
          require("metals").initialize_or_attach(metals_config)
        end,
        group = nvim_metals_group,
      })
    end,
  },
}
