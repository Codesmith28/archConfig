return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local java_runtime_path = "/usr/lib/jvm/java-21-openjdk-amd64"

      opts.cmd = opts.cmd or {}
      vim.list_extend(opts.cmd, {
        "--jvm-arg=-Djava.import.generatesMetadataFilesAtProjectRoot=false",
        "-jvm-arg=-Xms4g",
        "-jvm-arg=-Xmx8g",
        "-jvm-arg=-XX:+UseG1GC",
        "-jvm-arg=-Dsun.zip.disableMemoryMapping=true",
        "-jvm-arg=-Xverify:none",
      })

      opts.dap_main = false

      opts.capabilities = vim.tbl_deep_extend("force", opts.capabilities or {}, {
        offsetEncoding = { "utf-16" },
      })

      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
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
          autobuild = { enabled = false },
          referencesCodeLens = { enabled = false },
          implementationsCodeLens = { enabled = false },
          format = {
            enabled = true,
            settings = {
              url = vim.fn.expand("~/Default.xml"),
              profile = "Default",
            },
          },
        },
      })
      return opts
    end,
  },
}
