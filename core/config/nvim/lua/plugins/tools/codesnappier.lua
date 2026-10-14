local local_repo = (vim.fn.isdirectory(vim.fn.expand("~/Projects/CodeSnappier.nvim")) == 1 and vim.fn.expand("~/Projects/CodeSnappier.nvim"))
  or (vim.fn.isdirectory(vim.fn.expand("~/Projects/codesnap.nvim")) == 1 and vim.fn.expand("~/Projects/codesnap.nvim"))
  or nil

return {
  {
    "Codesmith28/CodeSnappier.nvim",
    name = "codesnappier.nvim",
    dir = local_repo,
    build = "make build_generator",
    main = "codesnappier",
    cmd = {
      "CodeSnappier",
      "CodeSnappierSave",
      "CodeSnappierASCII",
      "CodeSnappierHighlight",
      "CodeSnappierHighlightSave",
      "CodeSnap",
      "CodeSnapSave",
      "CodeSnapASCII",
      "CodeSnapHighlight",
      "CodeSnapHighlightSave",
    },
    keys = {
      -- Visual mode snapshots
      { "<leader>Cc", "<cmd>CodeSnappier<cr>", mode = "x", desc = "Copy code snapshot to clipboard" },
      { "<leader>Cs", "<cmd>CodeSnappierSave<cr>", mode = "x", desc = "Save code snapshot to file" },
    },
    opts = {
      -- All defaults are automatically optimized:
      -- - Font family auto-detected via priority ladder:
      --     p0: Active terminal font (Ghostty, Kitty, Alacritty, WezTerm, iTerm2, or GUI guifont)
      --     p1: System monospace font (fc-match on Linux, Apple system fonts, Windows system fonts)
      --     p2: Fallback generic "monospace"
      -- - Strict Neovim colorscheme auto-extracted on the fly
      -- - Transparent background (#00000000) with 20px padding
      -- - macOS title bar enabled with current file name
      -- - Breadcrumbs enabled with repo-based path
      -- - No watermarks
      -- - Automatic diff (+ / -) highlighting
      -- - System default screenshot path (~/Pictures/Screenshots)
    },
  },
}
