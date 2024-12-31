# eza-preview.yazi

[Yazi](https://github.com/sxyazi/yazi) plugin to preview directories using [eza](https://github.com/eza-community/eza), can be switched between list and tree modes.

List mode:
![list.png](list.png)

Tree mode:
![tree.png](tree.png)

## Requirements

- [yazi (0.4+) or nightly](https://github.com/sxyazi/yazi)
- [eza (0.20+)](https://github.com/eza-community/eza)

## Installation

### Linux/MacOS

```sh
ya pack -a ahkohd/eza-preview
```

## Usage

Add `eza-preview` to previewers in `yazi.toml`:

```toml
[[plugin.prepend_previewers]]
name = "*/"
run = "eza-preview"
```

Set key binding to switch between list and tree modes in `keymap.toml`:

```toml
[manager]
prepend_keymap = [
  { on = [ "E" ], run = "plugin eza-preview",  desc = "Toggle tree/list dir preview" },
  { on = [ "-" ], run = "plugin eza-preview --args='--inc-level'", desc = "Increment tree level" },
  { on = [ "_" ], run = "plugin eza-preview --args='--dec-level'", desc = "Decrement tree level" },
  { on = [ "$" ], run = "plugin eza-preview --args='--toggle-follow-symlinks'", desc = "Toggle tree follow symlinks" },
]
```

List mode is the default, if you want to have tree mode instead when starting yazi - update `init.lua` with:

```lua
require("eza-preview"):setup({
  -- Determines the directory depth level to tree preview (default: 3)
  level = 3,

  -- Whether to follow symlinks when previewing directories (default: false)
  follow_symlinks = false

  -- Whether to show target file info instead of symlink info (default: false)
  dereference = false
})

-- Or use default settings with empty table
require("eza-preview"):setup({})

```
