{ config, pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      dejavu_fonts
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" "DejaVu Sans Mono" ];
        sansSerif = [ "Noto Sans" "DejaVu Sans" ];
        serif = [ "Noto Serif" "DejaVu Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
