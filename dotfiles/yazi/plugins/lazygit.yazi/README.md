# lazygit.yazi
Plugin for [Yazi](https://github.com/sxyazi/yazi) to manage git repos with [lazygit](https://github.com/jesseduffield/lazygit)
## Dependencies
Make sure [lazygit](https://github.com/jesseduffield/lazygit) is installed and in your `PATH`.
## Installation

### Using `ya pack`
```
ya pack -a Lil-Dank/lazygit
```

### Manual
**Linux/macOS**
```
git clone https://github.com/Lil-Dank/lazygit.yazi.git ~/.config/yazi/plugins/lazygit.yazi
```
**Windows**
```
git clone https://github.com/Lil-Dank/lazygit.yazi.git %AppData%\yazi\config\plugins\lazygit.yazi
```
## Configuration
add this to your **keymap.toml** file
```toml
[[manager.prepend_keymap]]
on   = [ "g", "i" ]
run  = "plugin lazygit"
desc = "run lazygit"
```
you can customize the keybinding however you like. Please refer to the [keymap.toml](https://yazi-rs.github.io/docs/configuration/keymap) documentation
