# ~/.bashrc.d/06-bun.bash - Bun JavaScript runtime configuration
# Automatically configures BUN_INSTALL, PATH, and completions for Bash & Zsh

if [ -d "$HOME/.bun" ]; then
    export BUN_INSTALL="$HOME/.bun"

    # Prepend bun binary directory to PATH safely (avoiding duplicate entries)
    if [ -d "$BUN_INSTALL/bin" ]; then
        case ":$PATH:" in
            *":$BUN_INSTALL/bin:"*) ;;
            *) export PATH="$BUN_INSTALL/bin:$PATH" ;;
        esac
    fi

    # Zsh completions
    if [ -n "$ZSH_VERSION" ] && [ -s "$BUN_INSTALL/_bun" ]; then
        if command -v zsh-defer >/dev/null 2>&1; then
            zsh-defer source "$BUN_INSTALL/_bun"
        else
            source "$BUN_INSTALL/_bun"
        fi
    fi
fi
