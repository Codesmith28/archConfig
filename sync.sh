#!/usr/bin/env bash
# ==============================================================================
# archConfig Universal Cross-Distro Dotfile Synchronizer
# ==============================================================================
set -euo pipefail

trap 'echo "❌ Error encountered on line $LINENO. Synchronization aborted." >&2' ERR

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
TARGET_DISTRO=""
TARGET_DE=""
CUSTOM_BACKUP_DIR=""
WAKATIME_KEY_ARG=""
OPT_OUT_WAKATIME=false
RECONFIGURE_WAKATIME=false
NON_INTERACTIVE=false
SYNC_CORE_ONLY=false
SYNC_DESKTOP_ONLY=false
SKIP_DEPS=false

# Respect XDG Base Directory specification
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --distro)
            TARGET_DISTRO="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
            shift 2
            ;;
        --de)
            TARGET_DE="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
            shift 2
            ;;
        --core-only)
            SYNC_CORE_ONLY=true
            shift
            ;;
        --desktop-only)
            SYNC_DESKTOP_ONLY=true
            shift
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --backup-dir)
            CUSTOM_BACKUP_DIR="$2"
            shift 2
            ;;
        --wakatime-key)
            WAKATIME_KEY_ARG="$2"
            shift 2
            ;;
        --no-wakatime|--skip-wakatime)
            OPT_OUT_WAKATIME=true
            shift
            ;;
        --reconfigure-wakatime)
            RECONFIGURE_WAKATIME=true
            shift
            ;;
        --non-interactive)
            NON_INTERACTIVE=true
            export NON_INTERACTIVE=true
            shift
            ;;
        -h|--help)
            echo "Usage: ./sync.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run                 Show what symlinks would be created without making changes"
            echo "  --distro <name>           Override distro (fedora, arch, ubuntu, ubuntu_server, mac, omarchy)"
            echo "  --de <name>               Override desktop environment (gnome, kde, hyprland, none)"
            echo "  --core-only               Only synchronize core application configs and home dotfiles"
            echo "  --desktop-only            Only synchronize desktop environment configurations"
            echo "  --skip-deps               Skip downloading or running core dependency installers"
            echo "  --backup-dir <path>       Custom directory for backing up existing host configs (default: ~/.config/old_config_backups)"
            echo "  --wakatime-key <key>      Provide WakaTime API key directly"
            echo "  --reconfigure-wakatime    Prompt to reconfigure existing WakaTime API key"
            echo "  --no-wakatime             Opt out of WakaTime (do not configure or prompt for API key)"
            echo "  --non-interactive         Run non-interactively without prompting"
            echo "  -h, --help                Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ------------------------------------------------------------------------------
# 1. Environment & OS Detection
# ------------------------------------------------------------------------------
detect_os() {
    if [ -n "$TARGET_DISTRO" ]; then
        echo "$TARGET_DISTRO"
        return
    fi

    if [ "$(uname -s)" = "Darwin" ]; then
        echo "mac"
    elif [ -f /etc/fedora-release ]; then
        echo "fedora"
    elif [ -f /etc/arch-release ]; then
        if grep -qi "omarchy" /etc/os-release 2>/dev/null; then
            echo "omarchy"
        else
            echo "arch"
        fi
    elif grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
        if grep -qiE 'VARIANT="?Server"?|VARIANT_ID="?server"?' /etc/os-release 2>/dev/null || \
           { ! command -v Xorg >/dev/null 2>&1 && ! command -v wayland-scanner >/dev/null 2>&1 && ! command -v gnome-shell >/dev/null 2>&1; }; then
            echo "ubuntu_server"
        else
            echo "ubuntu"
        fi
    else
        echo "generic"
    fi
}

detect_de() {
    if [ -n "$TARGET_DE" ]; then
        echo "$TARGET_DE"
        return
    fi

    if [ "$(uname -s)" = "Darwin" ]; then
        echo "none"
        return
    fi

    # Check for Hyprland session
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || pgrep -x "Hyprland" >/dev/null 2>&1; then
        echo "hyprland"
        return
    fi

    local current_de="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"
    current_de=$(echo "$current_de" | tr '[:upper:]' '[:lower:]')

    if echo "$current_de" | grep -q "hyprland"; then
        echo "hyprland"
    elif echo "$current_de" | grep -q "gnome" || pgrep -x "gnome-shell" >/dev/null 2>&1; then
        echo "gnome"
    elif echo "$current_de" | grep -qE "kde|plasma" || [ -n "${KDE_FULL_SESSION:-}" ] || [ -n "${KDE_SESSION_VERSION:-}" ] || pgrep -x "plasmashell" >/dev/null 2>&1 || pgrep -x "kwin_wayland" >/dev/null 2>&1; then
        echo "kde"
    elif [ -f /usr/share/wayland-sessions/plasmawayland.desktop ] || [ -f /usr/share/wayland-sessions/plasma.desktop ]; then
        echo "kde"
    elif [ -f /usr/share/wayland-sessions/gnome.desktop ]; then
        echo "gnome"
    else
        echo "none"
    fi
}

DETECTED_OS="$(detect_os)"
DETECTED_DE="$(detect_de)"

BACKUP_ROOT="${CUSTOM_BACKUP_DIR:-${ARCHCONFIG_BACKUP_DIR:-$CONFIG_DIR/old_config_backups}}"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
HAS_BACKUPS=false

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 archConfig Cross-Distro Synchronizer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  • Operating System   : $DETECTED_OS"
echo "  • Desktop Environment: $DETECTED_DE"
echo "  • Repository Root    : $REPO_DIR"
echo "  • Backup Directory   : $BACKUP_DIR"
[ "$DRY_RUN" = true ] && echo "  • Mode               : DRY RUN (no modifications)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ------------------------------------------------------------------------------
# 2. Safe Backup & Symlink Helpers
# ------------------------------------------------------------------------------
backup_target() {
    local target="$1"
    local rel_path
    if [[ "$target" == "$HOME/"* ]]; then
        rel_path="${target#$HOME/}"
    else
        rel_path="$(basename "$target")"
    fi
    local dest_backup="$BACKUP_DIR/$rel_path"

    echo "  📦 Backing up: $target -> $dest_backup"
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$(dirname "$dest_backup")"
        mv "$target" "$dest_backup"
        HAS_BACKUPS=true
    fi
}

link_item() {
    local src="$1"
    local dest="$2"

    if [ ! -e "$src" ]; then
        echo "  ⚠️ Warning: Source does not exist: $src (skipping)" >&2
        return 0
    fi

    if [ -L "$dest" ]; then
        local raw_target
        raw_target="$(readlink "$dest" 2>/dev/null || true)"
        if [ "$raw_target" = "$src" ]; then
            echo "  ✓ Already linked: $dest"
            return 0
        fi
        backup_target "$dest"
    elif [ -e "$dest" ]; then
        backup_target "$dest"
    fi

    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$(dirname "$dest")"
        ln -snf "$src" "$dest"
        echo "  → Linked: $dest -> $src"
    else
        echo "  (dry-run) Would link: $dest -> $src"
    fi
}

# ------------------------------------------------------------------------------
# 3. Synchronize Core Configurations (~/.config/)
# ------------------------------------------------------------------------------
if [ "$SYNC_DESKTOP_ONLY" = false ]; then
    echo ""
    echo "==> Synchronizing Core Application Configs ($CONFIG_DIR/)..."
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$CONFIG_DIR"
        if [ "$(uname -s)" = "Darwin" ]; then
            mkdir -p "$HOME/Library/Fonts"
        else
            mkdir -p "$DATA_DIR/fonts"
        fi
    fi

    for item in "$REPO_DIR/core/config"/*; do
        [ -e "$item" ] || continue
        name="$(basename "$item")"
        if [ "$name" = "herdr" ]; then
            if [ "$DRY_RUN" = false ]; then
                mkdir -p "$CONFIG_DIR/herdr"
            fi
            if [ -f "$item/config.toml" ]; then
                link_item "$item/config.toml" "$CONFIG_DIR/herdr/config.toml"
            fi
            continue
        fi
        link_item "$item" "$CONFIG_DIR/$name"
    done

    # Clean legacy wireplumber scripts on Linux if present
    if [ "$(uname -s)" = "Linux" ]; then
        if [ "$DRY_RUN" = false ]; then
            if [ -L "$DATA_DIR/wireplumber/scripts/device/autoswitch-bluetooth-profile.lua" ]; then
                rm -f "$DATA_DIR/wireplumber/scripts/device/autoswitch-bluetooth-profile.lua"
                rmdir "$DATA_DIR/wireplumber/scripts/device" 2>/dev/null || true
                rmdir "$DATA_DIR/wireplumber/scripts" 2>/dev/null || true
            fi
        fi
    fi

    # ------------------------------------------------------------------------------
    # 4. Synchronize Core Home Dotfiles (~/.*)
    # ------------------------------------------------------------------------------
    echo ""
    echo "==> Synchronizing Home Dotfiles (~/)..."

    # Ensure local git identity is preserved before ~/.gitconfig symlink
    if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ] && [ ! -f "$HOME/.gitconfig.local" ]; then
        if command -v git >/dev/null 2>&1; then
            _ex_name="$(git config --file "$HOME/.gitconfig" user.name 2>/dev/null || true)"
            _ex_email="$(git config --file "$HOME/.gitconfig" user.email 2>/dev/null || true)"
            if [ -n "$_ex_name" ] || [ -n "$_ex_email" ]; then
                if [ "$DRY_RUN" = false ]; then
                    touch "$HOME/.gitconfig.local"
                    [ -n "$_ex_name" ] && git config --file "$HOME/.gitconfig.local" user.name "$_ex_name"
                    [ -n "$_ex_email" ] && git config --file "$HOME/.gitconfig.local" user.email "$_ex_email"
                    echo "  📦 Preserved existing Git identity in ~/.gitconfig.local"
                else
                    echo "  (dry-run) Would preserve existing Git identity in ~/.gitconfig.local"
                fi
            fi
        fi
    fi

    # Manage WakaTime API key & Opt-out preference before ~/.wakatime.cfg symlink
    WAKATIME_LOCAL_CFG="$HOME/.wakatime.cfg.local"
    _existing_waka_key=""

    if [ -f "$WAKATIME_LOCAL_CFG" ]; then
        _existing_waka_key="$(grep -E '^[[:space:]]*api_key[[:space:]]*=' "$WAKATIME_LOCAL_CFG" 2>/dev/null | head -n 1 | sed -E 's/^[[:space:]]*api_key[[:space:]]*=[[:space:]]*//' | tr -d ' "\r\n' || true)"
    fi
    if [ -z "$_existing_waka_key" ] && [ -f "$HOME/.wakatime.cfg" ] && [ ! -L "$HOME/.wakatime.cfg" ]; then
        _existing_waka_key="$(grep -E '^[[:space:]]*api_key[[:space:]]*=' "$HOME/.wakatime.cfg" 2>/dev/null | head -n 1 | sed -E 's/^[[:space:]]*api_key[[:space:]]*=[[:space:]]*//' | tr -d ' "\r\n' || true)"
    fi

    FINAL_WAKA_KEY=""

    if [ "$OPT_OUT_WAKATIME" = true ]; then
        FINAL_WAKA_KEY=""
    elif [ -n "$WAKATIME_KEY_ARG" ]; then
        FINAL_WAKA_KEY="$(echo "$WAKATIME_KEY_ARG" | tr -d ' "\r\n')"
    elif [ -n "$_existing_waka_key" ]; then
        if [ "$RECONFIGURE_WAKATIME" = false ] || [ "$NON_INTERACTIVE" = true ] || [ "$DRY_RUN" = true ] || [ ! -t 0 ]; then
            FINAL_WAKA_KEY="$_existing_waka_key"
        else
            _masked_key="$(echo "$_existing_waka_key" | sed -E 's/^(.{8}).*(.{4})$/\1...\2/')"
            echo ""
            echo "  🕒 WakaTime Configuration:"
            echo "     Existing API Key detected: $_masked_key"
            read -rp "     Enter WakaTime API key [Press Enter to keep, or type 'opt-out'/'none' to disable]: " _user_input || true
            _clean_input="$(echo "${_user_input:-}" | tr -d ' "\r\n')"
            case "$_clean_input" in
                opt-out|none|skip|disable|no)
                    echo "  ⏭️ Opted out of WakaTime."
                    FINAL_WAKA_KEY=""
                    ;;
                "")
                    FINAL_WAKA_KEY="$_existing_waka_key"
                    ;;
                *)
                    FINAL_WAKA_KEY="$_clean_input"
                    ;;
            esac
        fi
    else
        # No existing key found
        if [ "$NON_INTERACTIVE" = true ] || [ "$DRY_RUN" = true ] || [ ! -t 0 ]; then
            FINAL_WAKA_KEY=""
        else
            echo ""
            echo "  🕒 WakaTime Configuration:"
            echo "     Leaderboards & code stats require an API key from https://wakatime.com/api-key"
            read -rp "     Enter your WakaTime API key (leave blank to opt out): " _user_input || true
            _clean_input="$(echo "${_user_input:-}" | tr -d ' "\r\n')"
            if [ -n "$_clean_input" ] && [ "$_clean_input" != "opt-out" ] && [ "$_clean_input" != "none" ] && [ "$_clean_input" != "skip" ]; then
                FINAL_WAKA_KEY="$_clean_input"
            else
                echo "  ⏭️ No API key provided. Opting out of WakaTime."
                FINAL_WAKA_KEY=""
            fi
        fi
    fi

    if [ "$DRY_RUN" = false ]; then
        touch "$WAKATIME_LOCAL_CFG"
        chmod 600 "$WAKATIME_LOCAL_CFG"
        if [ -n "$FINAL_WAKA_KEY" ]; then
            cat <<EOF > "$WAKATIME_LOCAL_CFG"
[settings]
api_key = $FINAL_WAKA_KEY
EOF
            echo "  📦 WakaTime API key configured in ~/.wakatime.cfg.local"
        else
            cat <<EOF > "$WAKATIME_LOCAL_CFG"
[settings]
# WakaTime opted out (no API key configured)
EOF
            echo "  ⏭️ WakaTime opted out in ~/.wakatime.cfg.local"
        fi
    else
        if [ -n "$FINAL_WAKA_KEY" ]; then
            echo "  (dry-run) Would configure WakaTime API key in ~/.wakatime.cfg.local"
        else
            echo "  (dry-run) Would opt out of WakaTime in ~/.wakatime.cfg.local"
        fi
    fi

    for item in "$REPO_DIR/core/home"/.* "$REPO_DIR/core/home"/*; do
        [ -e "$item" ] || continue
        name="$(basename "$item")"
        [ "$name" = "." ] && continue
        [ "$name" = ".." ] && continue
        [ "$name" = "*" ] && continue
        link_item "$item" "$HOME/$name"
    done
fi

# ------------------------------------------------------------------------------
# 5. Universal Core Dependencies (curl / user-space)
# ------------------------------------------------------------------------------
if [ "$SYNC_DESKTOP_ONLY" = false ] && [ "$SKIP_DEPS" = false ]; then
    echo ""
    echo "==> Ensuring Universal Core Dependencies are installed..."
    if [ -f "$REPO_DIR/core/setup.sh" ]; then
        if [ "$DRY_RUN" = false ]; then
            bash "$REPO_DIR/core/setup.sh"
        else
            echo "  (dry-run) Would execute $REPO_DIR/core/setup.sh"
        fi
    fi

    # Yazi Plugin Provisioning
    if command -v ya >/dev/null 2>&1; then
        echo ""
        echo "==> Ensuring Yazi packages are installed (git, full-border, etc.)..."
        if [ "$DRY_RUN" = false ]; then
            (cd "$REPO_DIR/core/config/yazi" && ya pkg install --discard 2>/dev/null || true)
        else
            echo "  (dry-run) Would execute 'ya pkg install --discard' in core/config/yazi"
        fi
    fi
fi

# ------------------------------------------------------------------------------
# 6. Apply Desktop Environment Layer (if applicable)
# ------------------------------------------------------------------------------
if [ "$SYNC_CORE_ONLY" = false ]; then
    if [ "$DETECTED_DE" = "gnome" ]; then
        echo ""
        echo "==> Applying GNOME Desktop Layer..."
        if [ -f "$REPO_DIR/desktop/gnome/setup.sh" ]; then
            if [ "$DRY_RUN" = false ]; then
                bash "$REPO_DIR/desktop/gnome/setup.sh"
            else
                echo "  (dry-run) Would execute $REPO_DIR/desktop/gnome/setup.sh"
            fi
        fi
    elif [ "$DETECTED_DE" = "kde" ]; then
        echo ""
        echo "==> Applying KDE Plasma Layer..."
        if [ -f "$REPO_DIR/desktop/kde/setup.sh" ]; then
            if [ "$DRY_RUN" = false ]; then
                bash "$REPO_DIR/desktop/kde/setup.sh"
            else
                echo "  (dry-run) Would execute $REPO_DIR/desktop/kde/setup.sh"
            fi
        fi
    elif [ "$DETECTED_DE" = "hyprland" ]; then
        echo ""
        echo "==> Applying Hyprland Wayland Layer..."
        if [ "$DETECTED_OS" = "omarchy" ]; then
            link_item "$REPO_DIR/desktop/hyprland/lua" "$CONFIG_DIR/hypr"
        else
            link_item "$REPO_DIR/desktop/hyprland/classic" "$CONFIG_DIR/hypr"
        fi
        link_item "$REPO_DIR/desktop/hyprland/waybar" "$CONFIG_DIR/waybar"
        link_item "$REPO_DIR/desktop/hyprland/rofi" "$CONFIG_DIR/rofi"
        link_item "$REPO_DIR/desktop/hyprland/swaync" "$CONFIG_DIR/swaync"
        if [ -d "$REPO_DIR/desktop/hyprland/hyprshell" ]; then
            link_item "$REPO_DIR/desktop/hyprland/hyprshell" "$CONFIG_DIR/hyprshell"
        fi
    fi
fi

# ------------------------------------------------------------------------------
# 7. Check Linux Hardware & Power Optimizations (if applicable)
# ------------------------------------------------------------------------------
if [ "$SYNC_DESKTOP_ONLY" = false ] && [ "$(uname -s)" = "Linux" ] && [ -f "$REPO_DIR/hardware-linux/setup.sh" ]; then
    echo ""
    echo "==> Verifying Linux Hardware & Power Optimizations..."
    bash "$REPO_DIR/hardware-linux/setup.sh" --verify || true
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ All configurations synchronized successfully!"
if [ "$HAS_BACKUPS" = true ]; then
    echo ""
    echo "  📦 Previous host configurations safely backed up to:"
    echo "     $BACKUP_DIR"
fi
if { [ ! -f "$HOME/.ssh/id_rsa" ] && [ ! -f "$HOME/.ssh/id_ed25519" ]; } || [ ! -f "$HOME/.gitconfig.local" ]; then
    echo ""
    echo "  💡 Tip: Run ./core/scripts/setup_git.sh to configure Git identity and SSH keys."
fi
if [ "$(uname -s)" = "Linux" ]; then
    echo ""
    echo "  ⚡ Hardware & Power: To install kernel power rules, battery limits & sleep fixes, run:"
    echo "     sudo ./hardware-linux/setup.sh"
    target_distro_script="$DETECTED_OS"
    [ "$target_distro_script" = "ubuntu_server" ] && target_distro_script="ubuntu"
    if [ -f "$REPO_DIR/distros/$target_distro_script/setup.sh" ]; then
        echo "     sudo ./distros/$target_distro_script/setup.sh"
    fi
elif [ "$(uname -s)" = "Darwin" ]; then
    if [ -f "$REPO_DIR/distros/mac/setup.sh" ]; then
        echo ""
        echo "  🍏 macOS Packages: To install Homebrew formulae and casks, run:"
        echo "     ./distros/mac/setup.sh"
    fi
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
