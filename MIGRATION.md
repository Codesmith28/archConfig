# archConfig Architecture Migration Guide

## 1. Overview & Motivation

Historically, `archConfig` grew organically to support multiple distributions (`arch`, `arch_kde`, `fedora`, `ubuntu`, `ubuntu_server`, `mac`, `omarchy`). However, maintaining identical Neovim configurations, shell aliases, terminal setups, and utilities across 7 separate directories led to configuration drift, stale files, and unnecessary bloat.

In September 2026, the repository underwent a major structural refactor:
1. **Clean History & Bloat Elimination**: Stripped tracked binary archives and wallpapers, reducing the Git packfile from **~600 MB down to 63.6 MB** (~90% reduction) while preserving all 346 commits. All sensitive tokens (PII) were scrubbed from repository history.
2. **Layered Architecture**: Decoupled core applications, desktop environments, distro packages, and troubleshooting runbooks.
3. **Universal Sync Engine (`sync.sh`)**: Added single-command auto-detecting dotfile synchronization.
4. **Dynamic Toolchain Resolution**: Eliminated hardcoded compiler versions (e.g. `g++-14`) in favor of dynamic fallback detection across macOS Homebrew and Linux distros.
5. **Clean Root Directory & Legacy Purge**: Completely removed the redundant legacy directories (`arch_kde/`, `fedora/`, `mac/`, `omArchy/`, `ubuntu/`, `ubuntu_neon/`, `ubuntu_server/`) after migrating all package scripts to `distros/`, DE configs to `desktop/`, and dotfiles to `core/`.
6. **Agentic Guard Skill**: Added `.agents/skills/archconfig-guard` so AI assistants strictly adhere to cross-platform compatibility rules and keep `troubleshoot/` updated.

---

## 2. Directory Structure Map

```text
archConfig/
├── core/                                # 🌐 Universal, platform-independent configs
│   ├── config/                          # Targets ~/.config/
│   │   ├── fastfetch/                   # ROG fastfetch banner & spec config
│   │   ├── fontconfig/                  # MesloLGS, JetBrains Mono font settings
│   │   ├── ghostty/                     # Universal Ghostty configuration
│   │   ├── nvim/                        # Unified LazyVim + Pyrefly + Java + Clangd
│   │   ├── herdr/                       # Herdr workspace & session manager config
│   │   ├── starship.toml                # Universal Starship prompt config
│   │   └── yazi/                        # Yazi file manager & plugins
│   └── home/                            # Targets ~/
│       ├── .bashrc                      # Interactive Bash loader
│       ├── .bashrc.d/                   # Modular bash scripts (00-path, 01-aliases, 02-functions, 04-compilers)
│       ├── .bash_profile               # Universal login loader (Fedora/Ubuntu Server/Arch/macOS)
│       ├── .profile                     # Canonical POSIX environment & PATH deduplicator
│       ├── .zshrc                       # Universal Zsh configuration
│       ├── .inputrc                     # Readline completion settings
│       └── .vimrc                       # Classic fallback Vim configuration
│
├── desktop/                             # 🖥️ Desktop Environment layers
│   ├── gnome/                           # GNOME extensions list & dconf settings
│   ├── kde/                             # KDE Plasma keyboard shortcuts (keyboardscs.kksrc) & setup
│   └── hyprland/                        # Hyprland configs
│       ├── classic/                     # Traditional Hyprland config
│       ├── lua/                         # Modern Lua-configured Hyprland (from OmArchy)
│       ├── waybar/                      # Waybar status bar configs
│       ├── rofi/                        # Rofi application launcher configs
│       └── swaync/                      # SwayNotificationCenter configs
│
├── distros/                             # 📦 Distro-specific package lists & systemd services
│   ├── fedora/                          # DNF packages, NVIDIA setup, systemd services
│   ├── arch/                            # Pacman/AUR package lists & hardware bootstrap
│   ├── ubuntu/                          # Ubuntu desktop bootstrap & PPA setup
│   ├── ubuntu_server/                   # Headless Ubuntu server setup & SSH hardening
│   ├── mac/                             # Homebrew bundle & macOS system defaults
│   └── omarchy/                         # OmArchy specific tweaks & helpers
│
├── troubleshoot/                        # 🩺 Diagnostic guides and runbooks
│   ├── gnome_cross_distro_setup.md      # Resolving GNOME cross-distro session & extension quirks
│   ├── restore_grub.md                  # Restoring GRUB & recovering Windows dual-boot
│   ├── restoreGrub.sh                   # Automated Arch EFI bootloader repair script
│   └── fix_bits_stdcxx_macos.md         # Fix macOS missing <bits/stdc++.h> header
│
├── .agents/skills/                      # 🤖 AI Agent Skills
│   └── archconfig-guard/                # Enforcement rules for cross-distro compatibility
│
├── sync.sh                              # 🚀 Root orchestrator & dotfile linker
├── README.md                            # Modernized project guide
└── MIGRATION.md                         # This migration record
```

---

## 3. Key Improvements & Technical Highlights

### A. Dynamic Compiler Resolution (macOS + Linux)
- **Problem**: macOS Homebrew installs GCC as `gcc-14`, `gcc-15`, or `gcc-16` without an unversioned `gcc`/`g++` symlink in `$PATH`. Meanwhile, Linux distributions provide unversioned `gcc` and `g++`. Hardcoding versions breaks on newer OS upgrades or across platforms.
- **Solution**:
  - `core/home/.bashrc.d/04-compilers.bash` scans candidate versions (`gcc-17` down to `gcc-10`, then `gcc`) and sets `$CC` and `$CXX` automatically, aliasing `gcc` and `g++` on macOS if unversioned aliases are missing.
  - `run_cpp` helper compiles with `-std=c++26 -O2 -Wall` using the dynamically resolved `$CXX`.
  - `core/config/nvim/lua/plugins/lang/clangd.lua` dynamically detects all installed GCC include paths to pass to `clangd --query-driver`.
  - `core/config/nvim/lua/plugins/tools/assistant.lua` dynamically resolves `g++-15` -> `g++-14` -> `g++` for the competitive programming test runner.

### B. Shell Portability & Login Unification
- Fedora and Ubuntu Server use `~/.bash_profile`.
- Canonical Ubuntu Desktop defaults to `~/.profile` without creating `~/.bash_profile`.
- macOS uses login shells for all terminal tabs (`~/.bash_profile` or `~/.zprofile`).
- **Solution**:
  - Created a robust `~/.bash_profile` that cleanly sources `~/.profile` (environment/PATH) followed by `~/.bashrc` (aliases/prompt/functions) without duplicate sourcing loops.
  - Added clipboard detection (`wl-copy` on Wayland, `xclip` on X11, `pbcopy` on macOS) in `01-aliases.bash`.

### C. Unified Neovim Environment
- **Java**: Added dynamic `resolve_java_home()` supporting macOS Homebrew OpenJDK, Fedora `/usr/lib/jvm/java-*-openjdk`, Ubuntu, and Arch JVM paths.
- **Python**: Integrated modern `pyrefly` fast Python type-checker alongside `pyright`/`basedpyright`.
- **Clangd**: Universal query-driver configuration for C++23 standard library headers across all distros.

---

## 4. How to Synchronize on Any Machine

To sync dotfiles on your current machine:

```bash
# Auto-detects your OS and Desktop Environment
./sync.sh

# Preview changes before applying
./sync.sh --dry-run

# Override detection if needed
./sync.sh --distro fedora --de gnome
./sync.sh --distro arch --de hyprland
./sync.sh --distro mac --de none
```
