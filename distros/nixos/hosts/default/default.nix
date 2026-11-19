{ config, pkgs, lib, ... }:

let
  userConfig =
    if builtins.pathExists ../../user-config.nix then
      import ../../user-config.nix
    else
      import ../../user-config.nix.template;
in
{
  imports = [
    # Hardware configuration generated for this machine
    ./hardware-configuration.nix

    # Core system modules
    ../../modules/system/boot.nix
    ../../modules/system/networking.nix
    ../../modules/system/services.nix
    ../../modules/system/users.nix
    ../../modules/system/fonts.nix

    # Hardware optimization modules (ASUS ROG Strix G16 G614JV)
    ../../modules/hardware/asus.nix
    ../../modules/hardware/nvidia.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/audio.nix
    ../../modules/hardware/power.nix

    # Desktop environment & window manager modules
    ../../modules/desktop/gnome.nix
    ../../modules/desktop/hyprland.nix

    # User environment via Home Manager
    ../../home
  ];

  # Host identification (dynamically resolved)
  networking.hostName = userConfig.hostname or "nixos";

  # Nix package manager settings: enable Nix Flakes and modern CLI tools
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    warn-dirty = false;
  };

  # Allow unfree packages (proprietary NVIDIA drivers, broadcom, etc.)
  nixpkgs.config.allowUnfree = true;

  # Home Manager module settings
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  # NixOS state version
  system.stateVersion = "24.11";
}
