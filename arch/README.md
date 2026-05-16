# Arch Configuration (BlackBox)

Opinionated Arch Linux bootstrap + dotfiles.

This setup is inspired by the Arch Linux configuration from `mylinuxforwork/dotfiles` (v2.9.1) and extended with additional scripts, packages, and configuration.

## What this does

The shell pipeline (and its Ansible equivalent) can configure:

- Pacman configuration
- Base + desktop packages (pacman + AUR via `yay`)
- Git + GitHub CLI setup
- GNOME keybindings/tweaks (optional)
- Dotfiles sync + symlinks into `~/.config`
- Dev environment (Rust, Node tooling, Python tooling, etc.)
- Docker installation + service enablement
- Startup apps (systemd user services)
- Campus Wi‑Fi helper (NetworkManager)
- Key remapping
- GRUB configuration (including enabling Windows detection via os-prober)
- System font configuration

## Prerequisites

- A working Arch install (minimal is fine)
- Internet access
- `sudo` available for your user
- For AUR installs: `base-devel` and `git`

### Pacman keyring (recommended)

If you hit keyring / signature errors, initialize the keyring first:

```bash
sudo pacman-key --init
sudo pacman-key --populate archlinux
```

## Installation (shell)

1. Clone the repo:

   ```bash
   git clone https://github.com/Codesmith28/archConfig.git ~/archConfig
   cd ~/archConfig
   ```

2. Run the black box installer:

   ```bash
   cd arch/black_box
   chmod +x main.sh
   ./main.sh
   ```

`main.sh` runs the setup scripts in order (pacman → packages → git → dotfiles → dev env → docker → …).

Notes:

- Some steps require sudo.
- Docker group membership changes require a logout/login (or reboot).
- The university Wi‑Fi helper uses `nm-connection-editor` and expects a GUI.

### Run individual steps

All steps live under `arch/black_box/` as separate folders. If you only want one part, run that script directly, for example:

```bash
sudo bash arch/black_box/config_pacman/setup.sh
bash arch/black_box/link_dotfiles/link.sh
sudo bash arch/black_box/config_grub/setup.sh
```

## Installation (Ansible)

There is an Ansible version of the same workflow under `arch/black_box_ansible/`.

```bash
cd ~/archConfig/arch/black_box_ansible
ansible-playbook -i inventory.yml playbook.yml --ask-become-pass
```

The playbook prompts for Wi‑Fi details (SSID / identity / password / interface).

## Dotfiles

Dotfiles for Arch are stored in `arch/dotfiles/`.

The linker script copies missing files into `$HOME/dotfiles` and then creates symlinks into `$HOME/.config` (and related locations).

## Backup

To copy your current `$HOME/dotfiles/` back into the repo structure, run from the repo root:

```bash
cd ~/archConfig
./backup.sh
```

By default, the backup script syncs into `$HOME/Downloads/archConfig/dotfiles`.

## GRUB fixes

### GRUB not showing up (after minimal install)

From a chroot / live environment (or from your system if applicable):

```bash
pacman -Sy grub efibootmgr dosfstools mtools
```

```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
```

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

### Windows not showing up in GRUB

This repo includes a helper script at `arch/black_box/config_grub/setup.sh` that:

- installs `os-prober`
- copies a provided `/etc/default/grub`
- regenerates `/boot/grub/grub.cfg`

Manual steps (if preferred):

```bash
pacman -S os-prober
```

Edit `/etc/default/grub` and ensure:

```bash
GRUB_DISABLE_OS_PROBER=false
```

Then regenerate:

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

### Revive Arch after Windows updates

1. Boot the Arch live USB.
2. Mount your partitions and chroot:

   ```bash
   mount /dev/<root-partition> /mnt
   mount /dev/<boot-partition> /mnt/boot
   arch-chroot /mnt
   ```

3. Re-run `grub-install` and `grub-mkconfig` as shown above.
