{ config, pkgs, lib, userConfig ? null, ... }:

let
  userConfigFile = ../user-config.nix;
  userConfigTemplate = ../user-config.nix.template;
  resolvedUserConfig =
    if userConfig != null then
      userConfig
    else if builtins.pathExists userConfigFile then
      import userConfigFile
    else if builtins.pathExists userConfigTemplate then
      import userConfigTemplate
    else
      { username = "username"; description = "Primary User"; };
in
{
  # Home Manager entry point with dynamic user resolution.
  # Reads distros/nixos/user-config.nix (or falls back to user-config.nix.template)
  # to strictly avoid hardcoding personal usernames or sensitive credentials in Git.
  home-manager.users.${resolvedUserConfig.username} = {
    home.username = resolvedUserConfig.username;
    home.homeDirectory = "/home/${resolvedUserConfig.username}";
    home.stateVersion = "24.11";

    # Let Home Manager install and manage itself
    programs.home-manager.enable = true;

    # Import modular Home Manager submodules
    imports = [
      ./packages.nix
      ./links.nix
      ./shell.nix
    ];
  };
}
