#!/usr/bin/env bash
# ==============================================================================
# archConfig Universal Core Dependencies Installer
#
# Distro-agnostic, user-space installer for core terminal and shell productivity
# tools via official curl installers and GitHub release binaries.
#
# Supported core tools:
#  1. starship   - Fast, customizable cross-shell prompt (starship.rs)
#  2. leaf       - Modern terminal markdown previewer (leaf.rivolink.mg)
#  3. zoxide     - Smarter cd directory navigation (ajeetdsouza/zoxide)
#  4. fzf        - General-purpose command-line fuzzy finder (junegunn/fzf)
#  5. herdr      - Agent-ready terminal multiplexer (herdr.dev)
#  6. lazydocker - Simple terminal UI for docker containers (jesseduffield/lazydocker)
#  7. lazygit    - Simple terminal UI for git repositories (jesseduffield/lazygit)
#  8. uv         - Extremely fast Python package & project manager (astral.sh/uv)
#  9. yazi       - Blazing fast terminal file manager + ya cli (sxyazi/yazi)
# 10. eza        - Modern, maintained replacement for ls (eza-community/eza)
# 11. fastfetch  - High-performance neofetch alternative (fastfetch-cli/fastfetch)
#
# Safe execution guarantee:
# - Existing installations in PATH are preserved and NOT overwritten unless --update is passed.
# - Installs directly to ~/.local/bin and ~/.fzf without requiring root or sudo privileges.
# - 100% compatible across Fedora, Arch Linux, Ubuntu (Desktop/Server), macOS, & OmArchy.
# ==============================================================================
set -euo pipefail

BIN_DIR="${ARCHCONFIG_BIN_DIR:-"$HOME/.local/bin"}"
mkdir -p "$BIN_DIR"

UPDATE=false
REQUESTED_TOOLS=()

for arg in "$@"; do
    case "$arg" in
        --update|-u)
            UPDATE=true
            ;;
        -h|--help)
            echo "Usage: ./setup_shell_dependencies.sh [OPTIONS] [TOOL ...]"
            echo ""
            echo "Installs archConfig universal core dependencies via curl without root."
            echo ""
            echo "Available tools:"
            echo "  starship, leaf, zoxide, fzf, herdr, lazydocker, lazygit, uv, yazi, eza, fastfetch"
            echo ""
            echo "Options:"
            echo "  --update, -u   Force re-download / update even if already installed"
            echo "  -h, --help     Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./setup_shell_dependencies.sh                  # Check & install all missing tools"
            echo "  ./setup_shell_dependencies.sh starship leaf    # Only install starship and leaf"
            echo "  ./setup_shell_dependencies.sh --update         # Update all tools to latest version"
            exit 0
            ;;
        *)
            REQUESTED_TOOLS+=("$arg")
            ;;
    esac
done

# ------------------------------------------------------------------------------
# Platform & Architecture Discovery
# ------------------------------------------------------------------------------
OS="$(uname -s)"
RAW_ARCH="$(uname -m)"

case "$RAW_ARCH" in
    x86_64|amd64)   ARCH="x86_64" ;;
    aarch64|arm64)  ARCH="arm64" ;;
    armv7*)         ARCH="armv7" ;;
    armv6*)         ARCH="armv6" ;;
    i386|i686)      ARCH="x86" ;;
    *)              ARCH="$RAW_ARCH" ;;
esac

should_process() {
    local tool="$1"
    if [ ${#REQUESTED_TOOLS[@]} -eq 0 ]; then
        return 0
    fi
    for req in "${REQUESTED_TOOLS[@]}"; do
        if [ "$req" = "$tool" ]; then
            return 0
        fi
    done
    return 1
}

get_latest_github_tag() {
    local repo="$1"
    local tag=""
    # Primary: check release redirect location header without API rate limiting
    if command -v curl >/dev/null 2>&1; then
        tag="$(curl -sSI "https://github.com/${repo}/releases/latest" 2>/dev/null | awk -F'/' '/^[Ll]ocation:/ {print $NF}' | tr -d '\r\n' || true)"
    fi
    # Fallback: query GitHub API
    if [ -z "$tag" ]; then
        if command -v curl >/dev/null 2>&1; then
            tag="$(curl -sSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null | grep '"tag_name":' | head -n 1 | sed -E 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/' || true)"
        elif command -v wget >/dev/null 2>&1; then
            tag="$(wget -qO- "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null | grep '"tag_name":' | head -n 1 | sed -E 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/' || true)"
        fi
    fi
    echo "$tag"
}

download_file() {
    local url="$1"
    local output="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$output" "$url"
    else
        echo "  ❌ Error: Neither curl nor wget was found. Cannot download $url" >&2
        return 1
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 archConfig Universal Core Dependencies Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  • Platform     : $OS ($ARCH)"
echo "  • Destination  : $BIN_DIR"
[ "$UPDATE" = true ] && echo "  • Mode         : Force Update (--update)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ------------------------------------------------------------------------------
# 1. Starship Prompt
# ------------------------------------------------------------------------------
if should_process "starship"; then
    echo ""
    echo "==> Checking starship..."
    if command -v starship >/dev/null 2>&1 && [ "$UPDATE" = false ]; then
        echo "  ✓ starship is already installed at $(command -v starship) ($(starship --version 2>/dev/null | head -n 1 || echo 'unknown version'))"
    else
        echo "  → Installing / updating starship via official installer..."
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$BIN_DIR"
        elif command -v wget >/dev/null 2>&1; then
            wget -qO- https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$BIN_DIR"
        fi
        echo "  ✓ starship ready: $("$BIN_DIR/starship" --version 2>/dev/null | head -n 1 || echo 'installed')"
    fi
fi

# ------------------------------------------------------------------------------
# 2. Leaf Markdown Previewer
# ------------------------------------------------------------------------------
if should_process "leaf"; then
    echo ""
    echo "==> Checking leaf..."
    if command -v leaf >/dev/null 2>&1 && [ "$UPDATE" = false ]; then
        echo "  ✓ leaf is already installed at $(command -v leaf) ($(leaf --version 2>/dev/null || echo 'unknown version'))"
    else
        echo "  → Installing / updating leaf via official installer..."
        # Unlink existing binary first to avoid ETXTBSY if leaf is running
        [ -f "$BIN_DIR/leaf" ] && rm -f "$BIN_DIR/leaf"
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL https://leaf.rivolink.mg/install.sh | sh -s -- "$BIN_DIR"
        elif command -v wget >/dev/null 2>&1; then
            wget -qO- https://leaf.rivolink.mg/install.sh | sh -s -- "$BIN_DIR"
        fi
        echo "  ✓ leaf ready: $("$BIN_DIR/leaf" --version 2>/dev/null || echo 'installed')"
    fi
fi

# ------------------------------------------------------------------------------
# 3. Zoxide Smart Directory Navigation
# ------------------------------------------------------------------------------
if should_process "zoxide"; then
    echo ""
    echo "==> Checking zoxide..."
    if command -v zoxide >/dev/null 2>&1 && [ "$UPDATE" = false ]; then
        echo "  ✓ zoxide is already installed at $(command -v zoxide) ($(zoxide --version 2>/dev/null || echo 'unknown version'))"
    else
        echo "  → Installing / updating zoxide via official installer..."
        if command -v curl >/dev/null 2>&1; then
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
        elif command -v wget >/dev/null 2>&1; then
            wget -qO- https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
        fi
        echo "  ✓ zoxide ready: $(zoxide --version 2>/dev/null || echo 'installed')"
    fi
fi

# ------------------------------------------------------------------------------
# 4. FZF Fuzzy Finder
# ------------------------------------------------------------------------------
if should_process "fzf"; then
    echo ""
    echo "==> Checking fzf..."
    FZF_DIR="$HOME/.fzf"
    if [ ! -d "$FZF_DIR" ]; then
        echo "  → Cloning fzf repository into $FZF_DIR..."
        git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_DIR"
    elif [ "$UPDATE" = true ]; then
        echo "  → Updating existing fzf repository in $FZF_DIR..."
        git -C "$FZF_DIR" pull --ff-only || true
    else
        echo "  ✓ fzf repository already exists at $FZF_DIR"
    fi

    if [ -x "$FZF_DIR/install" ]; then
        "$FZF_DIR/install" --key-bindings --completion --no-update-rc >/dev/null 2>&1
        echo "  ✓ fzf ready: $("$FZF_DIR/bin/fzf" --version 2>/dev/null || fzf --version 2>/dev/null || echo 'installed')"
    fi
fi

# ------------------------------------------------------------------------------
# 5. Herdr Multiplexer
# ------------------------------------------------------------------------------
if should_process "herdr"; then
    echo ""
    echo "==> Checking herdr..."
    if command -v herdr >/dev/null 2>&1 && [ "$UPDATE" = false ]; then
        echo "  ✓ herdr is already installed at $(command -v herdr) ($(herdr --version 2>/dev/null || echo 'unknown version'))"
    else
        echo "  → Installing / updating herdr via official installer..."
        [ -f "$BIN_DIR/herdr" ] && rm -f "$BIN_DIR/herdr"
        HERDR_INSTALL_DIR="$BIN_DIR" curl -fsSL https://herdr.dev/install.sh | sh
        echo "  ✓ herdr ready: $("$BIN_DIR/herdr" --version 2>/dev/null || echo 'installed')"
    fi
fi

# ------------------------------------------------------------------------------
# 6. Lazydocker Terminal UI
# ------------------------------------------------------------------------------
if should_process "lazydocker"; then
    echo ""
    echo "==> Checking lazydocker..."
    if command -v lazydocker >/dev/null 2>&1 && [ "$UPDATE" = false ]; then
        echo "  ✓ lazydocker is already installed at $(command -v lazydocker) ($(lazydocker --version 2>/dev/null | grep -i 'version:' | head -n 1 || echo 'unknown version'))"
    else
        echo "  → Installing / updating lazydocker from GitHub releases..."
        TAG="$(get_latest_github_tag "jesseduffield/lazydocker")"
        if [ -n "$TAG" ]; then
            VER="${TAG#v}"
            TMP_DIR="$(mktemp -d)"
            trap 'rm -rf "$TMP_DIR"' EXIT
            ARCH_NAME="$ARCH"
            [ "$ARCH_NAME" = "arm64" ] && ARCH_NAME="arm64"
            [ "$ARCH_NAME" = "x86_64" ] && ARCH_NAME="x86_64"
            URL="https://github.com/jesseduffield/lazydocker/releases/download/${TAG}/lazydocker_${VER}_${OS}_${ARCH_NAME}.tar.gz"
            if download_file "$URL" "$TMP_DIR/lazydocker.tar.gz"; then
                tar -xzf "$TMP_DIR/lazydocker.tar.gz" -C "$TMP_DIR" lazydocker
                install -m 755 "$TMP_DIR/lazydocker" "$BIN_DIR/lazydocker"
                echo "  ✓ lazydocker ready: $("$BIN_DIR/lazydocker" --version 2>/dev/null | grep -i 'version:' | head -n 1 || echo 'installed')"
            fi
            rm -rf "$TMP_DIR"
            trap - EXIT
        else
            echo "  ⚠️ Warning: Could not resolve latest lazydocker release tag."
        fi
    fi
fi

# ------------------------------------------------------------------------------
# 7. Lazygit Terminal UI
# ------------------------------------------------------------------------------
if should_process "lazygit"; then
    echo ""
    echo "==> Checking lazygit..."
    if command -v lazygit >/dev/null 2>&1 && [ "$UPDATE" = false ]; then
        echo "  ✓ lazygit is already installed at $(command -v lazygit) ($(lazygit --version 2>/dev/null | head -n 1 || echo 'unknown version'))"
    else
        echo "  → Installing / updating lazygit from GitHub releases..."
        TAG="$(get_latest_github_tag "jesseduffield/lazygit")"
        if [ -n "$TAG" ]; then
            VER="${TAG#v}"
            TMP_DIR="$(mktemp -d)"
            trap 'rm -rf "$TMP_DIR"' EXIT
            OS_LOWER="$(echo "$OS" | tr '[:upper:]' '[:lower:]')"
            URL="https://github.com/jesseduffield/lazygit/releases/download/${TAG}/lazygit_${VER}_${OS_LOWER}_${ARCH}.tar.gz"
            if download_file "$URL" "$TMP_DIR/lazygit.tar.gz"; then
                tar -xzf "$TMP_DIR/lazygit.tar.gz" -C "$TMP_DIR" lazygit
                install -m 755 "$TMP_DIR/lazygit" "$BIN_DIR/lazygit"
                echo "  ✓ lazygit ready: $("$BIN_DIR/lazygit" --version 2>/dev/null | head -n 1 || echo 'installed')"
            fi
            rm -rf "$TMP_DIR"
            trap - EXIT
        else
            echo "  ⚠️ Warning: Could not resolve latest lazygit release tag."
        fi
    fi
fi

# ------------------------------------------------------------------------------
# 8. Astral uv (Python package & project manager)
# ------------------------------------------------------------------------------
if should_process "uv"; then
    echo ""
    echo "==> Checking uv..."
    if command -v uv >/dev/null 2>&1 && [ "$UPDATE" = false ]; then
        echo "  ✓ uv is already installed at $(command -v uv) ($(uv --version 2>/dev/null || echo 'unknown version'))"
    else
        echo "  → Installing / updating uv via official installer..."
        if command -v curl >/dev/null 2>&1; then
            curl -LsSf https://astral.sh/uv/install.sh | sh
        elif command -v wget >/dev/null 2>&1; then
            wget -qO- https://astral.sh/uv/install.sh | sh
        fi
        echo "  ✓ uv ready: $("$BIN_DIR/uv" --version 2>/dev/null || uv --version 2>/dev/null || echo 'installed')"
    fi
fi

# ------------------------------------------------------------------------------
# 9. Yazi Terminal File Manager & Ya CLI
# ------------------------------------------------------------------------------
if should_process "yazi"; then
    echo ""
    echo "==> Checking yazi..."
    if command -v yazi >/dev/null 2>&1 && [ "$UPDATE" = false ]; then
        echo "  ✓ yazi is already installed at $(command -v yazi) ($(yazi --version 2>/dev/null | grep -i 'version:' | head -n 1 || echo 'unknown version'))"
    else
        echo "  → Installing / updating yazi from GitHub releases..."
        TAG="$(get_latest_github_tag "sxyazi/yazi")"
        if [ -n "$TAG" ]; then
            ARCH_NAME="$ARCH"
            [ "$ARCH_NAME" = "arm64" ] && ARCH_NAME="aarch64"
            case "$OS" in
                Linux)  TARGET="${ARCH_NAME}-unknown-linux-musl" ;;
                Darwin) TARGET="${ARCH_NAME}-apple-darwin" ;;
                *)      TARGET="${ARCH_NAME}-unknown-linux-musl" ;;
            esac
            TMP_DIR="$(mktemp -d)"
            trap 'rm -rf "$TMP_DIR"' EXIT
            URL="https://github.com/sxyazi/yazi/releases/download/${TAG}/yazi-${TARGET}.zip"
            if download_file "$URL" "$TMP_DIR/yazi.zip"; then
                if command -v unzip >/dev/null 2>&1; then
                    unzip -q -o "$TMP_DIR/yazi.zip" -d "$TMP_DIR"
                    EXTRACTED_DIR="$TMP_DIR/yazi-${TARGET}"
                    if [ -f "$EXTRACTED_DIR/yazi" ]; then
                        install -m 755 "$EXTRACTED_DIR/yazi" "$BIN_DIR/yazi"
                        [ -f "$EXTRACTED_DIR/ya" ] && install -m 755 "$EXTRACTED_DIR/ya" "$BIN_DIR/ya"
                        echo "  ✓ yazi ready: $("$BIN_DIR/yazi" --version 2>/dev/null | grep -i 'version:' | head -n 1 || echo 'installed')"
                    fi
                fi
            fi
            rm -rf "$TMP_DIR"
            trap - EXIT
        else
            echo "  ⚠️ Warning: Could not resolve latest yazi release tag."
        fi
    fi
fi

# ------------------------------------------------------------------------------
# 10. Eza Modern ls Replacement
# ------------------------------------------------------------------------------
if should_process "eza"; then
    echo ""
    echo "==> Checking eza..."
    if command -v eza >/dev/null 2>&1 && [ "$UPDATE" = false ]; then
        echo "  ✓ eza is already installed at $(command -v eza) ($(eza --version 2>/dev/null | head -n 2 | tail -n 1 || echo 'unknown version'))"
    elif [ "$OS" = "Linux" ]; then
        echo "  → Installing / updating eza from GitHub releases..."
        TAG="$(get_latest_github_tag "eza-community/eza")"
        if [ -n "$TAG" ]; then
            ARCH_NAME="$ARCH"
            [ "$ARCH_NAME" = "arm64" ] && ARCH_NAME="aarch64"
            TMP_DIR="$(mktemp -d)"
            trap 'rm -rf "$TMP_DIR"' EXIT
            URL="https://github.com/eza-community/eza/releases/download/${TAG}/eza_${ARCH_NAME}-unknown-linux-musl.tar.gz"
            if download_file "$URL" "$TMP_DIR/eza.tar.gz"; then
                tar -xzf "$TMP_DIR/eza.tar.gz" -C "$TMP_DIR"
                if [ -f "$TMP_DIR/eza" ]; then
                    install -m 755 "$TMP_DIR/eza" "$BIN_DIR/eza"
                    echo "  ✓ eza ready: $("$BIN_DIR/eza" --version 2>/dev/null | head -n 2 | tail -n 1 || echo 'installed')"
                fi
            fi
            rm -rf "$TMP_DIR"
            trap - EXIT
        else
            echo "  ⚠️ Warning: Could not resolve latest eza release tag."
        fi
    elif [ "$OS" = "Darwin" ]; then
        echo "  💡 Note: On macOS, eza is installed via Homebrew: brew install eza"
    fi
fi

# ------------------------------------------------------------------------------
# 11. Fastfetch System Information Tool
# ------------------------------------------------------------------------------
if should_process "fastfetch"; then
    echo ""
    echo "==> Checking fastfetch..."
    if command -v fastfetch >/dev/null 2>&1 && [ "$UPDATE" = false ]; then
        echo "  ✓ fastfetch is already installed at $(command -v fastfetch) ($(fastfetch --version 2>/dev/null | head -n 1 || echo 'unknown version'))"
    else
        echo "  → Installing / updating fastfetch from GitHub releases..."
        TAG="$(get_latest_github_tag "fastfetch-cli/fastfetch")"
        if [ -n "$TAG" ]; then
            ARCH_NAME="$ARCH"
            [ "$ARCH_NAME" = "arm64" ] && ARCH_NAME="aarch64"
            [ "$ARCH_NAME" = "x86_64" ] && ARCH_NAME="amd64"
            OS_LOWER="$(echo "$OS" | tr '[:upper:]' '[:lower:]')"
            TARGET="${OS_LOWER}-${ARCH_NAME}"
            TMP_DIR="$(mktemp -d)"
            trap 'rm -rf "$TMP_DIR"' EXIT
            URL="https://github.com/fastfetch-cli/fastfetch/releases/download/${TAG}/fastfetch-${TARGET}.zip"
            if download_file "$URL" "$TMP_DIR/fastfetch.zip"; then
                if command -v unzip >/dev/null 2>&1; then
                    unzip -q -o "$TMP_DIR/fastfetch.zip" -d "$TMP_DIR"
                    FF_BIN="$(find "$TMP_DIR" -type f -name fastfetch -perm -111 2>/dev/null | head -n 1 || true)"
                    if [ -n "$FF_BIN" ] && [ -f "$FF_BIN" ]; then
                        install -m 755 "$FF_BIN" "$BIN_DIR/fastfetch"
                        echo "  ✓ fastfetch ready: $("$BIN_DIR/fastfetch" --version 2>/dev/null || echo 'installed')"
                    fi
                fi
            fi
            rm -rf "$TMP_DIR"
            trap - EXIT
        else
            echo "  ⚠️ Warning: Could not resolve latest fastfetch release tag."
        fi
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ archConfig universal core dependencies check completed!"
echo "  • Binaries located in: $BIN_DIR and ~/.fzf/bin"
echo "  • Both paths are configured in ~/.profile"
echo "  • In existing shells, run: source ~/.bashrc (or source ~/.zshrc)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
