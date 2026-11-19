{ config, pkgs, lib, ... }:

let
  userConfigPath = ../../user-config.nix;
  userConfigTemplatePath = ../../user-config.nix.template;
  userConfig =
    if builtins.pathExists userConfigPath then
      import userConfigPath
    else
      import userConfigTemplatePath;
in
{
  # Expose userConfig via _module.args so other NixOS modules / Home Manager can consume it
  _module.args.userConfig = userConfig;

  # System-wide zsh registration so it is a valid login shell
  programs.zsh.enable = true;

  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.description or "Primary User";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
    ];
    shell = pkgs.zsh;
  };

  # Security / sudo configuration
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };
}
