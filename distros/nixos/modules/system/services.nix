{ config, pkgs, lib, ... }:

{
  # Core system services
  services = {
    # D-Bus message broker daemon
    dbus.enable = true;

    # udev device management
    udev.enable = true;

    # Weekly fstrim for NVMe/SSD health and performance
    fstrim.enable = true;
  };
}
