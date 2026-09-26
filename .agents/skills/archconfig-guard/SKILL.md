---
name: archconfig-guard
description: >-
  Enforces multi-distro compatibility and architectural guidelines for archConfig.
  Use whenever modifying core configs (Neovim, Ghostty, Shell, Yazi, Starship),
  managing dotfile symlinks, or resolving OS-specific hardware/system quirks.
---

# archConfig Cross-Distro Guardian Skill

## Purpose
`archConfig` manages dotfiles and bootstrap routines for **Fedora, Arch Linux, Ubuntu (Desktop & Server), macOS, and OmArchy**.
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
- Dynamic GCC/G++ Discovery (`04-compilers.bash`): Always dynamically search for the latest versioned compiler (`gcc-17` down to `gcc-10` and `g++-17` down to `g++-10`) rather than hardcoding compiler version numbers.

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
- **NEVER** commit `.env` files, API keys, tokens, session cookies, or credentials to this repository.
- Use dynamic secret retrieval (e.g., `export KEY="$(grep '^KEY=' "$HOME/.env" ...)"`) so secrets remain strictly local on the host machine.
- Block files larger than 5 MB (such as high-res wallpapers or installer `.deb`/`.zip` archives) from entering Git packfiles.
