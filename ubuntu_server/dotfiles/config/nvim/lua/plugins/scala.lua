return {
  {
    "scalameta/nvim-metals",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    ft = { "scala", "sbt" }, -- CRUCIAL: Never attach to Java files
    opts = function()
      local metals_config = require("metals").bare_config()

      -- Force Metals to put its cache outside the project
      metals_config.settings = {
        showImplicitArguments = true,
        showInferredType = true,
        excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
        -- Let Metals know we are handling Java elsewhere
        javaFormat = { enabled = false },
      }

      metals_config.init_options.statusBarProvider = "off"

      -- SAFE CAPABILITIES EXTRACTION:
      -- Works seamlessly whether LazyVim is using blink.cmp or nvim-cmp
      local has_blink, blink = pcall(require, "blink.cmp")
      local has_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")

      if has_blink then
        metals_config.capabilities = blink.get_lsp_capabilities()
      elseif has_cmp then
        metals_config.capabilities = cmp_lsp.default_capabilities()
      end

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
