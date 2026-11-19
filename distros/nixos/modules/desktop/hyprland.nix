{ config, pkgs, lib, ... }:

{
  # Enable Hyprland tiling Wayland compositor with Universal Wayland Session Manager (UWSM)
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # XDG Desktop Portal integration for Hyprland
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # Polkit service for privilege escalation dialogs
  security.polkit.enable = true;

  # Polkit KDE authentication agent systemd user service
  systemd.user.services.polkit-kde-authentication-agent-1 = {
    description = "polkit-kde-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Hint Electron / Chromium / Ozone applications to use native Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Essential Wayland / Hyprland ecosystem tools
  environment.systemPackages = with pkgs; [
    polkit-kde-agent
    kdePackages.qtwayland
    qt6.qtwayland
    waybar
    rofi-wayland
    swaynotificationcenter
    hyprpaper
    hyprlock
    hypridle
    wl-clipboard
    grim
    slurp
  ];
}
