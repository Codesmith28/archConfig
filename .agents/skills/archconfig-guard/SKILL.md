---
name: archconfig-guard
description: >-
  Enforces multi-distro compatibility and architectural guidelines for archConfig.
  Use whenever modifying core configs (Neovim, Ghostty, Shell, Yazi, Starship),
  managing dotfile symlinks, or resolving OS-specific hardware/system quirks.
---

# archConfig Cross-Distro Guardian Skill

## Purpose
`archConfig` manages dotfiles and bootstrap routines for **Fedora, Arch Linux, Ubuntu (Desktop & Server), macOS, OmArchy, and NixOS**.
This skill ensures that changes made to core tools remain 100% functional across all target environments without causing configuration drift, breaking live symlinks, or leaking secrets.

---

## Architecture Rules

### 1. The Core Principle: Edit Once, Active Everywhere
- All cross-platform applications (**Neovim**, **Ghostty**, **Herdr**, **Starship**, **Yazi**, **Fastfetch**, **Fontconfig**) live in `core/config/`.
- **NEVER** create a separate copy or fork of an application config for an individual distro unless it is an isolated DE shortcut or OS-level package script.
- If an application requires different behavior on macOS vs Linux, handle it **dynamically within the configuration**:
  - In Lua/Neovim: `local is_mac = vim.fn.has("macunix") == 1`
  - In Shell scripts: `case "$(uname -s)" in Darwin) ... ;; Linux) ... ;; esac`
  - In Ghostty: Use native cross-platform options or optional `?include` directives.

### 2. Shell Environment & Compiler Resolution
- `core/home/.profile`: Universal POSIX login environment (PATH, default editor, JAVA_HOME).
- `core/home/.bash_profile`: Universal login loader that sources `.profile` and `.bashrc`.
- `core/home/.bashrc`: Modular loader reading `core/home/.bashrc.d/*.bash`.
- Dynamic GCC/G++ Discovery (`04-compilers.bash`): Always dynamically search for the latest versioned compiler across system binary paths (e.g. `gcc-[0-9]*` and `g++-[0-9]*`) and evaluate unversioned fallbacks rather than hardcoding compiler version lists.

### 3. Desktop Environment (DE) Modularity
- GNOME extensions, dconf scripts, and GTK titlebars live in `desktop/gnome/`.
- KDE Plasma shortcut schemes and kxmlgui settings live in `desktop/kde/`.
- Wayland / Hyprland tiling configs live in `desktop/hyprland/`.
- Distro setup scripts (`distros/*/setup.sh`) only handle package installation and hardware optimizations; they call `desktop/*/setup.sh` as needed.

### 4. Continuous Troubleshooting Runbooks (`troubleshoot/`)
- Whenever you diagnose or solve an OS-specific issue, hardware quirk, or bootloader failure (e.g., GRUB overwritten by Windows, NVIDIA dGPU sleep state, Wayland display scaling, macOS Homebrew header missing):
  - **MANDATORY STEP**: Document the root cause, verification commands, and recovery steps in a new or existing markdown guide inside `troubleshoot/`.
  - Ensure any reusable recovery scripts (like `restoreGrub.sh`) are executable in `troubleshoot/`.

### 5. Secret & PII Hygiene
- **NEVER** commit `.env` files, API keys, tokens, session cookies, personal usernames, or credentials to this repository.
- Use dynamic secret retrieval (e.g., `export KEY="$(grep '^KEY=' "$HOME/.env" ...)"`) so secrets remain strictly local on the host machine.
- Block files larger than 5 MB (such as high-res wallpapers or installer `.deb`/`.zip` archives) from entering Git packfiles.
- **Git Identity & NixOS Template Patterns**: User-specific identity is separated into templates (`core/home/.gitconfig.local.template` copied to `~/.gitconfig.local`, and `distros/nixos/user-config.nix.template` copied to `distros/nixos/user-config.nix`). Both `.local` files and `user-config.nix` are gitignored so personal credentials or usernames are never committed.

### 6. Declarative NixOS & Home Manager Architecture
- **Single Source of Truth in `core/`**: All universal application configurations (`core/config/`) and shell dotfiles (`core/home/`) remain the single authoritative source of truth. NixOS modules must never fork or maintain duplicate dotfile copies.
- **Dynamic User Configuration via Templates**: NixOS modules (`modules/system/users.nix`, `home/default.nix`) must dynamically read `distros/nixos/user-config.nix` (with fallback to `distros/nixos/user-config.nix.template`). Never hardcode personal usernames into NixOS configs or Home Manager declarations.
- **Home Manager Out-of-Store Symlinks**: In `distros/nixos/home/links.nix`, configuration files must be mapped via `config.lib.file.mkOutOfStoreSymlink` pointing to absolute paths in `~/archConfig/core/config/` and `~/archConfig/core/home/`. This maintains identical file paths across distros and enables live dotfile editing without rebuilding the system.
- **Herdr Scoping**: Link only `core/config/herdr/config.toml` to `~/.config/herdr/config.toml` (do not link the parent `core/config/herdr/` directory) to keep runtime logs, sockets, and transient state unmanaged.
- **Local Secret Isolation**: Home Manager modules must NEVER link or manage host-local secret files (`~/.gitconfig.local`, `~/.wakatime.cfg.local`, `~/.profile.local`, `~/.zshrc.local`).
- **Strict `sync.sh` Safety Guard & Offload**: `sync.sh` explicitly detects NixOS (`/etc/NIXOS`, `/etc/nixos/configuration.nix`, or `ID=nixos` in `/etc/os-release`), initializes user/git template configs if missing, and offloads system and dotfile deployment to `sudo nixos-rebuild switch --flake ./distros/nixos` (or `bun run switch` / `pnpm run switch`). Imperative symlinks are never created on NixOS.
