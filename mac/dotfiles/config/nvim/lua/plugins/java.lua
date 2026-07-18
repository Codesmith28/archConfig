return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local java_runtime_path = "/usr/lib/jvm/java-21-openjdk-amd64"

      opts.cmd = opts.cmd or {}
      vim.list_extend(opts.cmd, {
        "--jvm-arg=-Djava.import.generatesMetadataFilesAtProjectRoot=false",
        "--jvm-arg=-Xms8g",
        "--jvm-arg=-Xmx16g",
        "--jvm-arg=-XX:+UseG1GC",
        "--jvm-arg=-Dsun.zip.disableMemoryMapping=true",
        "--jvm-arg=-Xverify:none",
      })

      opts.dap_main = false

      opts.capabilities = vim.tbl_deep_extend("force", opts.capabilities or {}, {
        offsetEncoding = { "utf-16" },
      })

      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          project = {
            referencedLibraries = {
              vim.fn.expand("$HOME/.gradle/caches/modules-2/files-2.1/org.scala-lang/scala-library/**/*.jar"),
            },
          },
          configuration = {
            updateBuildConfiguration = "interactive",
            runtimes = {
              {
                name = "JavaSE-21",
                path = java_runtime_path,
                default = true,
              },
            },
          },

          autobuild = { enabled = true },
          referencesCodeLens = { enabled = false },
          implementationsCodeLens = { enabled = false },

          format = {
            enabled = true,
            settings = {
              -- Point explicitly to your exported XML profile
              url = vim.uri_from_fname(vim.fn.expand("~/.config/nvim/langs/Default.xml")),
              profile = "Default", -- Change this if your scheme has a custom name inside the XML
              useProfileOptions = true, -- Merges with core local .editorconfig sizes if present
            },
          },

          -- =====================================================================
          -- INTELLIJ-STYLE INLAY HINTS
          -- =====================================================================
          inlayHints = {
            parameterNames = {
              -- Options: "none", "literals", "all"
              -- "all" forces hints for all arguments, matching IntelliJ's behavior
              enabled = "all",
            },
          },
          -- =====================================================================
        },
      })

      -- =====================================================================
      -- LIFECYCLE & AUTOMATION HOOKS
      -- =====================================================================
      opts.on_attach = function(client_or_args, bufnr)
        local client
        if type(client_or_args) == "table" and client_or_args.data and client_or_args.data.client_id then
          client = vim.lsp.get_client_by_id(client_or_args.data.client_id)
        else
          client = client_or_args
        end

        if client and client.server_capabilities then
          client.server_capabilities.semanticTokensProvider = nil

          -- KEEP THESE TRUE so LazyVim can orchestrate formatting commands to JDTLS
          client.server_capabilities.documentFormattingProvider = true
          client.server_capabilities.documentRangeFormattingProvider = true
        end

        -- Explicit manual trigger for heavy build/classpath updates (<leader>cu)
        vim.keymap.set("n", "<leader>cu", function()
          require("jdtls").update_project_config()
          vim.notify("JDTLS: Project configuration update triggered", vim.log.levels.INFO)
        end, { buffer = bufnr, desc = "Update JDTLS Project Config" })
      end

      return opts
    end,
  },
}

