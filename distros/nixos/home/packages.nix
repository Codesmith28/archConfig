{ config, pkgs, ... }:

{
  # Global development toolchain and productivity packages managed by Home Manager
  home.packages = with pkgs; [
    # --------------------------------------------------------------------------
    # C / C++ Toolchain
    # --------------------------------------------------------------------------
    clang
    clang-tools
    gcc
    gnumake
    cmake

    # --------------------------------------------------------------------------
    # Rust Toolchain
    # --------------------------------------------------------------------------
    rustc
    cargo
    rust-analyzer

    # --------------------------------------------------------------------------
    # Go Toolchain
    # --------------------------------------------------------------------------
    go
    gopls

    # --------------------------------------------------------------------------
    # JavaScript / TypeScript Toolchain
    # --------------------------------------------------------------------------
    nodejs
    pnpm
    bun

    # --------------------------------------------------------------------------
    # Python Toolchain
    # --------------------------------------------------------------------------
    python3
    uv

    # --------------------------------------------------------------------------
    # TeX Live Publishing & Documentation
    # MANDATORY: pkgs.texliveMedium (modern distribution, avoids obsolete scheme)
    # --------------------------------------------------------------------------
    texliveMedium

    # --------------------------------------------------------------------------
    # Terminal & Core CLI Productivity Utilities
    # --------------------------------------------------------------------------
    git
    gh
    ripgrep
    fd
    bat
    fzf
    zoxide
    eza
    btop
    fastfetch
    lazygit
    lazydocker
    just
    jq
    yq
    yazi
    starship
    ghostty
    neovim
    nvd
    tree
    unzip
    curl
    wget
  ];
}
