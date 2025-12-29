# archConfig

Personal Linux bootstrap + dotfiles repo.

This repo primarily targets:

- **Arch Linux (KDE)** via a separate set of scripts and package lists.
- **Ubuntu** via a dedicated installer + dotfile sync.
- **Arch Linux (Hyprland/GNOME)** via a shell “black box” installer. ( Inspired by the Arch Linux dotfiles from `mylinuxforwork/dotfiles` (v2.9.1) and extended with additional configuration. )

## Table of contents

- [Quick start](#quick-start)
- [Arch KDE](#arch-kde)
- [GRUB / Windows dual-boot notes (Arch KDE)](#grub--windows-dual-boot-notes-arch-kde)
- [Ubuntu](#ubuntu)
- [Arch (shell installer)](#arch-shell-installer)
- [Repo layout](#repo-layout)

## Quick start

Clone the repo:

```bash
git clone https://github.com/Codesmith28/archConfig.git ~/archConfig
cd ~/archConfig
```

### Arch KDE

Typical flow:

1. Install packages (official repos + AUR):

	```bash
	cd arch_kde/packages
	chmod +x installPackages.sh
	./installPackages.sh
	```

2. Link dotfiles into your home directory:

	```bash
	cd arch_kde/dotfiles
	chmod +x sync.sh
	./sync.sh
	```

3. (Optional) Install systemd services + helper executables:

	```bash
	cd arch_kde/setup_scripts
	chmod +x setup.sh
	./setup.sh
	```

    These include:
    - battery-limit service
    - disable acpi and pci wakeup service (so that only power button can wake the laptop)
    - nvidia persistence mode service

4. (Optional) One-off helpers:

- Git + GitHub CLI: [arch_kde/basics/setGit.sh](arch_kde/basics/setGit.sh) ; configures user name, email, and SSH keys
- Docker: [arch_kde/basics/setDocker.sh](arch_kde/basics/setDocker.sh) ; installs Docker, adds user to `docker` group, and enables the Docker service
- Restore GRUB: [arch_kde/basics/restoreGrub.sh](arch_kde/basics/restoreGrub.sh) ; reinstalls GRUB bootloader and fixes it if not working

### GRUB / Windows dual-boot notes (Arch KDE)

#### GRUB not showing up

If GRUB is missing after a minimal install (or after something overwrote your EFI entry), you can run:

```bash
sudo bash arch_kde/basics/restoreGrub.sh
```

That script runs:

```bash
sudo pacman -Sy grub efibootmgr dosfstools mtools
sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

#### Windows not visible in GRUB

1. Install `os-prober`:

	```bash
	sudo pacman -S os-prober
	```

2. Edit `/etc/default/grub` and ensure this is set:

	```bash
	GRUB_DISABLE_OS_PROBER=false
	```

3. Regenerate the GRUB config:

	```bash
	sudo grub-mkconfig -o /boot/grub/grub.cfg
	```

### Ubuntu

Ubuntu has a dedicated installer. After it completes, follow the printed “Next steps”.

```bash
cd ubuntu
./install.sh
```

### Arch (shell installer)

Runs an ordered setup pipeline (pacman, packages, git, dotfiles, dev env, docker, etc.).

```bash
cd arch/black_box
chmod +x main.sh
./main.sh
```

Notes:

- Some steps require sudo.
- Docker group changes require a logout/login (or reboot).
- Wi‑Fi setup uses `nm-connection-editor` and expects a GUI.

## Repo layout

- `arch/` — Arch Linux setup (shell + Ansible) and dotfiles
- `arch_kde/` — Arch KDE setup scripts + package lists
- `ubuntu/` — Ubuntu installer, setup scripts, and dotfiles
