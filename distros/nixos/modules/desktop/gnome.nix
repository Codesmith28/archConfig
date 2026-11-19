{ config, pkgs, lib, ... }:

{
  # Enable X11 / Wayland server, GDM display manager, and GNOME desktop environment
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Core GNOME packages and utilities
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnome-extension-manager
    dconf-editor
    nautilus
    wl-clipboard
    adwaita-icon-theme
  ];

  # Essential udev rules and services for GNOME settings daemon
  services.udev.packages = with pkgs; [ gnome-settings-daemon ];
}
