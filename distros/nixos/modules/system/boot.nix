{ config, pkgs, lib, ... }:

{
  boot = {
    # Systemd-boot EFI bootloader
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 15;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    # Linux 6.12+ kernel (latest stable/unstable kernel package)
    kernelPackages = pkgs.linuxPackages_latest;

    # Essential kernel parameters
    kernelParams = [
      "quiet"
      "splash"
    ];

    # Clean /tmp on boot
    tmp.cleanOnBoot = true;
  };
}
