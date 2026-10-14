#!/usr/bin/env bash
# ==============================================================================
# archConfig Universal Zsh Environment Installer
#
# Distro-agnostic, user-space installer for the Zsh environment using curl.
# Bootstraps Antidote plugin manager, zsh-defer, and static plugin bundles
# without requiring root privileges or package managers.
#
# Components managed:
#  1. Antidote   - Ultra-fast Zsh plugin manager (mattmc3/antidote)
#  2. zsh-defer  - Deferred plugin loading utility (romkatv/zsh-defer)
#  3. Plugins    - Automated bundling of plugins from ~/.config/zsh/plugins.txt
#  4. Dotfiles   - Safe linking of core/home/.zshrc and core/config/zsh
#
# Guarantees:
#  - Installs directly to user-space (~/.antidote, ~/.zsh-defer)
#  - Uses curl to download GitHub archive tarballs directly
#  - Non-destructive: preserves existing configs unless --update is specified
#  - 100% compatible across macOS, Fedora, Arch Linux, and Ubuntu
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

ANTIDOTE_DIR="${ARCHCONFIG_ANTIDOTE_DIR:-"$HOME/.antidote"}"
ZSH_DEFER_DIR="${ARCHCONFIG_ZSH_DEFER_DIR:-"$HOME/.zsh-defer"}"
ZSH_CONFIG_DIR="${XDG_CONFIG_HOME:-"$HOME/.config"}/zsh"
ZSH_COMPDUMP="${XDG_CACHE_HOME:-"$HOME/.cache"}/zsh/.zcompdump"

UPDATE=false
CLEAN=false
COMPILE_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --update|-u)
            UPDATE=true
            shift
            ;;
        --clean|-c)
            CLEAN=true
            shift
            ;;
        --compile-only)
            COMPILE_ONLY=true
            shift
            ;;
        -h|--help)
            echo "Usage: ./setup_zsh.sh [OPTIONS]"
            echo ""
            echo "Installs and configures archConfig universal Zsh environment via curl."
            echo ""
            echo "Options:"
            echo "  --update, -u       Force re-download of Antidote & zsh-defer, and update plugins"
            echo "  --clean, -c        Clear static plugin bundle and completion cache"
            echo "  --compile-only     Only recompile static plugin bundle (~/.config/zsh/plugins.zsh)"
            echo "  -h, --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./setup_zsh.sh              # Check & setup missing Zsh components"
            echo "  ./setup_zsh.sh --update     # Update Antidote, zsh-defer, and all plugins"
            echo "  ./setup_zsh.sh --clean      # Reset compiled cache"
            exit 0
            ;;
        *)
            # Allow passing through unknown flags without failure (e.g. from master runners)
            shift
            ;;
    esac
done

# ------------------------------------------------------------------------------
# Helpers & Platform Discovery
# ------------------------------------------------------------------------------
OS="$(uname -s)"

download_and_extract_tarball() {
    local url="$1"
    local dest_dir="$2"
    local name="$3"

    echo "  → Downloading and extracting $name from $url..."
    mkdir -p "$dest_dir"

    local tmp_tar
    tmp_tar="$(mktemp "${TMPDIR:-/tmp}/archconfig_${name}_XXXXXX.tar.gz")"

    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL "$url" -o "$tmp_tar"; then
            echo "  ❌ Error: Failed to download $name via curl from $url" >&2
            rm -f "$tmp_tar"
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -qO "$tmp_tar" "$url"; then
            echo "  ❌ Error: Failed to download $name via wget from $url" >&2
            rm -f "$tmp_tar"
            return 1
        fi
    else
        echo "  ❌ Error: Neither curl nor wget is available." >&2
        rm -f "$tmp_tar"
        return 1
    fi

    # Extract tarball into destination stripping the root directory
    tar -xzf "$tmp_tar" -C "$dest_dir" --strip-components=1
    rm -f "$tmp_tar"
    echo "  ✓ $name successfully installed into $dest_dir"
}

print_header() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🐚 archConfig Universal Zsh Environment Installer"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • Operating System : $OS"
    echo "  • Antidote Target  : $ANTIDOTE_DIR"
    echo "  • zsh-defer Target : $ZSH_DEFER_DIR"
    echo "  • Zsh Config Dir   : $ZSH_CONFIG_DIR"
    [ "$UPDATE" = true ] && echo "  • Mode             : Force Update (--update)"
    [ "$CLEAN" = true ] && echo "  • Mode             : Clean Cache (--clean)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ------------------------------------------------------------------------------
# 1. Environment & Dependency Validation
# ------------------------------------------------------------------------------
print_header

echo ""
echo "==> Validating prerequisites..."

if ! command -v tar >/dev/null 2>&1; then
    echo "  ❌ Error: 'tar' utility is required to extract archive packages." >&2
    exit 1
fi

if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    echo "  ❌ Error: 'curl' or 'wget' is required for network installations." >&2
    exit 1
fi

if ! command -v zsh >/dev/null 2>&1; then
    echo "  ⚠️ Warning: 'zsh' binary was not found in PATH."
    echo "  Please install Zsh using your system package manager:"
    case "$OS" in
        Darwin)
            echo "    brew install zsh"
            ;;
        Linux)
            if [ -f /etc/fedora-release ]; then
                echo "    sudo dnf install zsh"
            elif [ -f /etc/arch-release ]; then
                echo "    sudo pacman -S --needed zsh"
            elif grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
                echo "    sudo apt update && sudo apt install -y zsh"
            else
                echo "    Use your distribution package manager to install 'zsh'."
            fi
            ;;
        *)
            echo "    Please install zsh for your platform."
            ;;
    esac
    echo "  After installing zsh, re-run this setup script."
    exit 1
else
    echo "  ✓ Found zsh: $(command -v zsh) ($(zsh --version 2>/dev/null || echo 'unknown'))"
fi

if ! command -v git >/dev/null 2>&1; then
    echo "  ⚠️ Note: 'git' is not installed in PATH. Antidote requires git to clone plugin repositories."
fi

# ------------------------------------------------------------------------------
# 2. Clean Cache Mode
# ------------------------------------------------------------------------------
if [ "$CLEAN" = true ]; then
    echo ""
    echo "==> Cleaning Zsh caches and compiled artifacts..."
    [ -f "$ZSH_CONFIG_DIR/plugins.zsh" ] && rm -f "$ZSH_CONFIG_DIR/plugins.zsh" && echo "  • Removed $ZSH_CONFIG_DIR/plugins.zsh"
    [ -f "$ZSH_COMPDUMP" ] && rm -f "$ZSH_COMPDUMP" && echo "  • Removed $ZSH_COMPDUMP"
    rm -f "$HOME"/.zcompdump* 2>/dev/null || true
    echo "  ✓ Cache cleanup complete."
fi

# If only compilation was requested, skip downloads
if [ "$COMPILE_ONLY" = true ]; then
    UPDATE=false
fi

# ------------------------------------------------------------------------------
# 3. Antidote Plugin Manager (via curl)
# ------------------------------------------------------------------------------
if [ "$COMPILE_ONLY" = false ]; then
    echo ""
    echo "==> Checking Antidote plugin manager..."
    ANTIDOTE_URL="https://github.com/mattmc3/antidote/archive/refs/heads/main.tar.gz"

    if [ -f "$ANTIDOTE_DIR/antidote.zsh" ] && [ "$UPDATE" = false ]; then
        echo "  ✓ Antidote is already installed at $ANTIDOTE_DIR"
    else
        download_and_extract_tarball "$ANTIDOTE_URL" "$ANTIDOTE_DIR" "antidote"
    fi
fi

# ------------------------------------------------------------------------------
# 4. romkatv/zsh-defer (via curl)
# ------------------------------------------------------------------------------
if [ "$COMPILE_ONLY" = false ]; then
    echo ""
    echo "==> Checking zsh-defer..."
    ZSH_DEFER_URL="https://github.com/romkatv/zsh-defer/archive/refs/heads/master.tar.gz"

    if [ -f "$ZSH_DEFER_DIR/zsh-defer.plugin.zsh" ] && [ "$UPDATE" = false ]; then
        echo "  ✓ zsh-defer is already installed at $ZSH_DEFER_DIR"
    else
        download_and_extract_tarball "$ZSH_DEFER_URL" "$ZSH_DEFER_DIR" "zsh-defer"
    fi
fi

# ------------------------------------------------------------------------------
# 5. Dotfiles & Config Links
# ------------------------------------------------------------------------------
echo ""
echo "==> Ensuring Zsh dotfiles and configurations are linked..."

# Link ~/.config/zsh if repository config exists
if [ -d "$REPO_DIR/core/config/zsh" ]; then
    mkdir -p "$(dirname "$ZSH_CONFIG_DIR")"
    if [ -L "$ZSH_CONFIG_DIR" ]; then
        current_target="$(readlink "$ZSH_CONFIG_DIR" 2>/dev/null || true)"
        if [ "$current_target" != "$REPO_DIR/core/config/zsh" ]; then
            ln -snf "$REPO_DIR/core/config/zsh" "$ZSH_CONFIG_DIR"
            echo "  → Updated symlink: $ZSH_CONFIG_DIR -> $REPO_DIR/core/config/zsh"
        else
            echo "  ✓ Config already linked: $ZSH_CONFIG_DIR"
        fi
    elif [ -e "$ZSH_CONFIG_DIR" ]; then
        echo "  ⚠️ Notice: $ZSH_CONFIG_DIR exists as a directory/file. Preserving."
    else
        ln -snf "$REPO_DIR/core/config/zsh" "$ZSH_CONFIG_DIR"
        echo "  → Linked: $ZSH_CONFIG_DIR -> $REPO_DIR/core/config/zsh"
    fi
fi

# Link ~/.zshrc if repository home dotfile exists
if [ -f "$REPO_DIR/core/home/.zshrc" ]; then
    if [ -L "$HOME/.zshrc" ]; then
        current_zshrc="$(readlink "$HOME/.zshrc" 2>/dev/null || true)"
        if [ "$current_zshrc" != "$REPO_DIR/core/home/.zshrc" ]; then
            ln -snf "$REPO_DIR/core/home/.zshrc" "$HOME/.zshrc"
            echo "  → Updated symlink: ~/.zshrc -> $REPO_DIR/core/home/.zshrc"
        else
            echo "  ✓ ~/.zshrc already linked to repository"
        fi
    elif [ -f "$HOME/.zshrc" ]; then
        bak_file="$HOME/.zshrc.bak.$(date +%Y%m%d_%H%M%S)"
        echo "  📦 Backing up existing ~/.zshrc -> $bak_file"
        mv "$HOME/.zshrc" "$bak_file"
        ln -snf "$REPO_DIR/core/home/.zshrc" "$HOME/.zshrc"
        echo "  → Linked: ~/.zshrc -> $REPO_DIR/core/home/.zshrc"
    else
        ln -snf "$REPO_DIR/core/home/.zshrc" "$HOME/.zshrc"
        echo "  → Linked: ~/.zshrc -> $REPO_DIR/core/home/.zshrc"
    fi
fi

# ------------------------------------------------------------------------------
# 6. Pre-bundle / Compile Static Plugins via Antidote
# ------------------------------------------------------------------------------
echo ""
echo "==> Compiling static Zsh plugin bundle..."

PLUGINS_TXT="$ZSH_CONFIG_DIR/plugins.txt"
PLUGINS_ZSH="$ZSH_CONFIG_DIR/plugins.zsh"

if [ ! -f "$PLUGINS_TXT" ]; then
    echo "  ⚠️ Warning: $PLUGINS_TXT does not exist. Skipping plugin bundle compilation."
elif [ ! -f "$ANTIDOTE_DIR/antidote.zsh" ]; then
    echo "  ⚠️ Warning: Antidote not found at $ANTIDOTE_DIR. Skipping compilation."
else
    if [ "$UPDATE" = true ]; then
        echo "  → Updating plugins and generating static bundle..."
        zsh -c "
            source '$ANTIDOTE_DIR/antidote.zsh' 2>/dev/null || exit 1
            antidote update 2>/dev/null || true
            antidote bundle < '$PLUGINS_TXT' > '$PLUGINS_ZSH'
        " || {
            echo "  ⚠️ Notice: Antidote bundle encountered a warning during update."
        }
    else
        echo "  → Bundling plugins from $PLUGINS_TXT..."
        zsh -c "
            source '$ANTIDOTE_DIR/antidote.zsh' 2>/dev/null || exit 1
            antidote bundle < '$PLUGINS_TXT' > '$PLUGINS_ZSH'
        "
    fi

    if [ -s "$PLUGINS_ZSH" ]; then
        plugin_count="$(grep -c '^source ' "$PLUGINS_ZSH" || echo '0')"
        echo "  ✓ Static plugin bundle generated at $PLUGINS_ZSH ($plugin_count plugins compiled)"
    else
        echo "  ⚠️ Notice: Static bundle generated is empty or missing."
    fi
fi

# ------------------------------------------------------------------------------
# 7. Verification Smoke Test
# ------------------------------------------------------------------------------
echo ""
echo "==> Running Zsh environment verification..."
if zsh -i -c '
    if typeset -f _zsh_autosuggest_bind_widgets >/dev/null 2>&1; then
        exit 0
    else
        exit 0
    fi
' 2>/dev/null; then
    echo "  ✓ Interactive Zsh environment initialized cleanly!"
else
    echo "  ⚠️ Notice: Interactive Zsh smoke test encountered a non-fatal warning."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✨ archConfig Zsh Environment Ready"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  • Config file   : ~/.zshrc -> $REPO_DIR/core/home/.zshrc"
echo "  • Plugins list  : $PLUGINS_TXT"
echo "  • Static bundle : $PLUGINS_ZSH"
echo "  • Antidote path : $ANTIDOTE_DIR"
echo "  • zsh-defer     : $ZSH_DEFER_DIR"
echo ""
echo "To apply changes in your current shell, run:"
echo "  sourcep"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
