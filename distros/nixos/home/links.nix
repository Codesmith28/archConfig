{ config, lib, ... }:

let
  dotfiles = "${config.home.homeDirectory}/archConfig";
in
{
  # ----------------------------------------------------------------------------
  # Application Configurations (~/.config/)
  # Out-of-store symlinks maintain core/config/ as the single source of truth.
  # Edits to configuration files take effect immediately without rebuilding.
  # ----------------------------------------------------------------------------
  xdg.configFile = {
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/config/nvim";
    "ghostty".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/config/ghostty";
    "fastfetch".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/config/fastfetch";

    # Link ONLY config.toml for herdr, never the entire herdr directory
    "herdr/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/config/herdr/config.toml";

    "leaf".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/config/leaf";
    "starship.toml".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/config/starship.toml";
    "wireplumber".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/config/wireplumber";
    "yazi".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/config/yazi";
    "zsh".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/config/zsh";
    "fontconfig".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/config/fontconfig";
  };

  # ----------------------------------------------------------------------------
  # Home Dotfiles (~/.*)
  # Out-of-store symlinks maintain core/home/ as the single source of truth.
  #
  # STRICT SECURITY & SECRET HYGIENE GUARD:
  # The following host-local files are NEVER managed or symlinked here:
  #   - ~/.gitconfig.local   (personal user identity, email, signing keys)
  #   - ~/.wakatime.cfg.local (private API keys)
  #   - ~/.profile.local     (machine-local PATH / secrets)
  #   - ~/.zshrc.local       (machine-local shell tokens / credentials)
  # ----------------------------------------------------------------------------
  home.file = {
    ".bashrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/home/.bashrc";
    ".bashrc.d".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/home/.bashrc.d";
    ".bash_profile".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/home/.bash_profile";
    ".profile".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/home/.profile";
    ".gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/home/.gitconfig";
    ".inputrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/home/.inputrc";
    ".vimrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/home/.vimrc";
    ".wakatime.cfg".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/home/.wakatime.cfg";
    ".zshrc".source = lib.mkForce (config.lib.file.mkOutOfStoreSymlink "${dotfiles}/core/home/.zshrc");
  };
}
