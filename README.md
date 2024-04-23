# Arch Configuration by Codesmith28

## Introduction

This repository extends the Arch Linux configuration from [stephan-raabe/dotfiles](https://gitlab.com/stephan-raabe/dotfiles) with additional dotfiles and configurations.

## Installation

After installing the base configuration from [stephan-raabe/dotfiles](https://gitlab.com/stephan-raabe/dotfiles), follow these steps to integrate additional configurations:

1. Install CaskaydiaCove Nerd Fonts from [here](https://www.nerdfonts.com/font-downloads).

1. Clone this repository to your local machine. Assuming you have installed the base configuration in your home directory:

   ```
    git clone https://github.com/Codesmith28/archConfig.git ~/Downloads/arch-config
   ```

2. Navigate to the downloaded folder and view the content:

   ```
    cd ~/Downloads/arch-config
   ```

3. Run the installation script for basic packages:

   ```
   ./install.sh
   ```

4. Copy / Move the contents accordingly.

## Backup

You can also backup your current configuration by running:

```
./backup.sh
```

## Fixing Grub
### Grub not showing up:
After the minimal installation, you may face the issue of the grub not showing up. Thus, we click on yes for post installation configuration and then run the following commands sequentially:

```
pacman -Sy grub efibootmgr dosfstools mtools
```

```
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
```

```
grub-mkconfig -o /boot/grub/grub.cfg
```

Then exit and shutdown the system and then boot it up again.

### Windows not showing up in Grub:
If you have Windows installed and it is not showing up in the grub, then run the following commands sequentially:

- Install os-prober, if not already installed:
```
pacman -S os-prober
```

- Edit the file `etc/default/grub` and add the following line:

```
GRUB_DISABLE_OS_PROBER=false
```

- Update the grub configuration:
```
grub-mkconfig -o /boot/grub/grub.cfg
```

###  How to revive arch linux after any windows updates?
1. Boot into the arch linux live usb.
2. Connect to the internet and update all the packages as follows:
```
pacman -Sy
```

3. Mount the root partition of the arch linux to /mnt and the boot partition to /mnt/boot like: 

```
mount /dev/nvme0n1p5 /mnt
```
```
mount /dev/nvme0n1p6 /mnt/boot
```

```
arch-chroot /mnt
```

4. Run the grub-install and grub-mkconfig commands as mentioned above.
