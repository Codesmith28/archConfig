{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # Antidote & zsh-defer manage plugins dynamically in core/config/zsh
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/archConfig/distros/nixos";
      nrb = "sudo nixos-rebuild boot --flake ~/archConfig/distros/nixos";
      nrt = "sudo nixos-rebuild test --flake ~/archConfig/distros/nixos";
      nfu = "nix flake update --flake ~/archConfig/distros/nixos";
      nfc = "nix flake check ~/archConfig/distros/nixos";
      nix-clean = "nix-collect-garbage -d && sudo nix-collect-garbage -d";
    };

    # Preserves existing archConfig zsh setup and loads .zshrc
    initExtra = ''
      if [ -f "$HOME/.zshrc" ]; then
        :
      fi
    '';
  };
}
