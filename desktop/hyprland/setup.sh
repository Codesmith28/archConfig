#!/usr/bin/env bash
# ==============================================================================
# Hyprland Desktop Setup & Verification Suite (Cross-Distro Universal)
# Supports: Fedora (fedora-gnome base), Arch Linux / OmArchy
# Zero-Intervention, Self-Healing Out-Of-The-Box Configuration
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

log_info()    { echo "  [INFO] $*"; }
log_success() { echo "  [OK]   $*"; }
log_warn()    { echo "  [WARN] $*" >&2; }
log_error()   { echo "  [ERR]  $*" >&2; }

DRY_RUN=false
NON_INTERACTIVE=false
VERIFY_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --non-interactive|-y) NON_INTERACTIVE=true ;;
        --verify-only) VERIFY_ONLY=true ;;
        -h|--help)
            echo "Usage: ./desktop/hyprland/setup.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run            Simulate operations without making changes"
            echo "  --verify-only        Run verification suite only"
            echo "  --non-interactive    Run non-interactively"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
    esac
done

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "  (dry-run) Would run: $*"
    else
        "$@"
    fi
}

run_root() {
    if [ "$DRY_RUN" = true ]; then
        echo "  (dry-run) Would run as root: $*"
    elif [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        log_error "Root privileges or sudo required to run: $*"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 1. Native Privilege Handling (Ensure execution runs as desktop user)
# ------------------------------------------------------------------------------
if [[ "$(id -u)" -eq 0 && "${1:-}" != "--user-run" ]]; then
    TARGET_USER="${SUDO_USER:-}"
    if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
        TARGET_USER="$(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $3}' | grep -v 'root' | head -n 1 || true)"
        if [[ -z "$TARGET_USER" ]]; then
            TARGET_USER="$(who | awk '$1 != "root" {print $1; exit}' || true)"
        fi
        if [[ -z "$TARGET_USER" ]]; then
            TARGET_USER="$(awk -F: '$3 >= 1000 && $3 < 60000 {print $1; exit}' /etc/passwd 2>/dev/null || id -un)"
        fi
    fi

    TARGET_UID=$(id -u "$TARGET_USER")
    TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    BUS_PATH="/run/user/${TARGET_UID}/bus"

    log_info "Dropping root privileges to ${TARGET_USER} (UID: ${TARGET_UID})..."
    if [[ -S "$BUS_PATH" ]]; then
        exec sudo -u "$TARGET_USER" -H env \
            HOME="$TARGET_HOME" \
            USER="$TARGET_USER" \
            XDG_RUNTIME_DIR="/run/user/${TARGET_UID}" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=${BUS_PATH}" \
            bash "$0" --user-run "$@"
    else
        exec sudo -u "$TARGET_USER" -H env \
            HOME="$TARGET_HOME" \
            USER="$TARGET_USER" \
            XDG_RUNTIME_DIR="/run/user/${TARGET_UID}" \
            bash "$0" --user-run "$@"
    fi
    exit $?
fi

log_info "Configuring Hyprland desktop environment and tools..."

# ------------------------------------------------------------------------------
# 2. Distro Package Verification
# ------------------------------------------------------------------------------
check_distro_packages() {
    local os_id=""
    if [[ -f /etc/os-release ]]; then
        os_id="$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')"
    fi

    case "$os_id" in
        fedora|rhel|centos)
            local missing=()
            for pkg in hyprland xdg-desktop-portal-hyprland hyprpolkitagent waybar hyprland-guiutils pavucontrol hyprshot hyprlock hypridle quickshell blueman; do
                if ! rpm -q "$pkg" >/dev/null 2>&1 && ! [ -x "$HOME/.local/bin/$pkg" ]; then
                    missing+=("$pkg")
                fi
            done
            if [[ ${#missing[@]} -gt 0 ]]; then
                log_warn "Missing recommended Fedora Hyprland packages: ${missing[*]}"
                log_info "Tip: Run './distros/fedora/setup.sh --install-hyprland' to install them via COPR lionheartp/Hyprland."
            else
                log_success "All required Fedora Hyprland packages are installed."
            fi
            ;;
        arch|manjaro|endeavouros)
            local missing=()
            for pkg in hyprland waybar hyprlauncher swaync pavucontrol hyprshot hyprlock hypridle quickshell; do
                if ! pacman -Qi "$pkg" >/dev/null 2>&1 && ! [ -x "$HOME/.local/bin/$pkg" ]; then
                    missing+=("$pkg")
                fi
            done
            if [[ ${#missing[@]} -gt 0 ]]; then
                log_warn "Missing Arch Hyprland packages: ${missing[*]}"
            else
                log_success "Core Arch Hyprland packages are present."
            fi
            ;;
        *)
            ;;
    esac
}

check_distro_packages

# ------------------------------------------------------------------------------
# 3. Systemd User Environment & PATH Persistence
# ------------------------------------------------------------------------------
if [ "$VERIFY_ONLY" = false ]; then
    log_info "Configuring systemd user session environment and directories..."
    CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$CONFIG_DIR" "$CONFIG_DIR/environment.d" "$HOME/.local/bin" "$HOME/.local/share/applications"
    fi

    # Write persistent environment so Hyprland and exec-once scripts resolve ~/.local/bin
    if [ "$DRY_RUN" = false ]; then
        cat > "$CONFIG_DIR/environment.d/10-archconfig.conf" << 'EOF'
PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
EOF
        if command -v systemctl >/dev/null 2>&1; then
            systemctl --user import-environment PATH 2>/dev/null || true
        fi
    else
        echo "  (dry-run) Would write $CONFIG_DIR/environment.d/10-archconfig.conf"
    fi

    # --------------------------------------------------------------------------
    # 4. Provision Default Terminal & Browser Launchers
    # --------------------------------------------------------------------------
    DEF_TERM_SRC=""
    if [[ -f "$SCRIPT_DIR/../gnome/default-terminal" ]]; then
        DEF_TERM_SRC="$SCRIPT_DIR/../gnome/default-terminal"
    elif [[ -f "$SCRIPT_DIR/vanilla/hypr/scripts/terminal.sh" ]]; then
        DEF_TERM_SRC="$SCRIPT_DIR/vanilla/hypr/scripts/terminal.sh"
    fi

    if [[ -n "$DEF_TERM_SRC" ]]; then
        if [ "$DRY_RUN" = false ]; then
            install -m 755 "$DEF_TERM_SRC" "$HOME/.local/bin/default-terminal" 2>/dev/null || true
        else
            echo "  (dry-run) Would install default-terminal to ~/.local/bin"
        fi
    fi

    DEF_BROWSER_SRC=""
    if [[ -f "$SCRIPT_DIR/../kde/default-browser" ]]; then
        DEF_BROWSER_SRC="$SCRIPT_DIR/../kde/default-browser"
    elif [[ -f "$SCRIPT_DIR/vanilla/hypr/scripts/browser.sh" ]]; then
        DEF_BROWSER_SRC="$SCRIPT_DIR/vanilla/hypr/scripts/browser.sh"
    fi

    if [[ -n "$DEF_BROWSER_SRC" ]]; then
        if [ "$DRY_RUN" = false ]; then
            install -m 755 "$DEF_BROWSER_SRC" "$HOME/.local/bin/default-browser" 2>/dev/null || true
        else
            echo "  (dry-run) Would install default-browser to ~/.local/bin"
        fi
    fi

    # --------------------------------------------------------------------------
    # 5. Helper Script Permissions & Desktop Application Entries
    # --------------------------------------------------------------------------
    log_info "Ensuring execution permissions on Hyprland helper scripts..."
    if [[ -d "$SCRIPT_DIR/vanilla/hypr/scripts" ]]; then
        for script_file in "$SCRIPT_DIR/vanilla/hypr/scripts"/*.sh "$SCRIPT_DIR/vanilla/hypr/scripts"/*.py; do
            [ -f "$script_file" ] || continue
            if [ "$DRY_RUN" = false ]; then
                chmod 755 "$script_file"
            else
                echo "  (dry-run) Would chmod 755 $script_file"
            fi
        done
    fi

    if [[ -d "$SCRIPT_DIR/vanilla/applications" ]]; then
        log_info "Installing Hyprland desktop application entries..."
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$HOME/.local/share/applications"
            for desktop_file in "$SCRIPT_DIR/vanilla/applications"/*.desktop; do
                [ -f "$desktop_file" ] || continue
                install -m 644 "$desktop_file" "$HOME/.local/share/applications/" 2>/dev/null || true
            done
            if command -v update-desktop-database >/dev/null 2>&1; then
                update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
            fi
        else
            echo "  (dry-run) Would install desktop application entries to ~/.local/share/applications"
        fi
    fi

    # --------------------------------------------------------------------------
    # 6. Fallback Standalone Configuration Symlinks
    # --------------------------------------------------------------------------
    # When setup.sh is run standalone without sync.sh, ensure links are established
    if [ ! -e "$CONFIG_DIR/hypr" ]; then
        run_cmd ln -snf "$SCRIPT_DIR/vanilla/hypr" "$CONFIG_DIR/hypr"
    fi
    mkdir -p "$CONFIG_DIR/hyprlauncher"
    if [ ! -e "$CONFIG_DIR/hyprlauncher/hyprlauncher.conf" ]; then
        run_cmd ln -snf "$SCRIPT_DIR/vanilla/hypr/hyprlauncher.conf" "$CONFIG_DIR/hyprlauncher/hyprlauncher.conf"
    fi
    mkdir -p "$CONFIG_DIR/hyprtoolkit"
    if [ ! -e "$CONFIG_DIR/hyprtoolkit/hyprtoolkit.conf" ]; then
        run_cmd ln -snf "$SCRIPT_DIR/vanilla/hypr/hyprtoolkit.conf" "$CONFIG_DIR/hyprtoolkit/hyprtoolkit.conf"
    fi
    if [ ! -e "$CONFIG_DIR/waybar" ]; then
        run_cmd ln -snf "$SCRIPT_DIR/vanilla/waybar" "$CONFIG_DIR/waybar"
    fi
    if [ ! -e "$CONFIG_DIR/rofi" ]; then
        run_cmd ln -snf "$SCRIPT_DIR/vanilla/rofi" "$CONFIG_DIR/rofi"
    fi
    if [ ! -e "$CONFIG_DIR/wofi" ] || [ -L "$CONFIG_DIR/wofi" ]; then
        run_cmd ln -snf "$SCRIPT_DIR/vanilla/wofi" "$CONFIG_DIR/wofi"
    fi
    if [ ! -e "$CONFIG_DIR/swaync" ]; then
        run_cmd ln -snf "$SCRIPT_DIR/vanilla/swaync" "$CONFIG_DIR/swaync"
    fi
    if [ ! -e "$CONFIG_DIR/clipse" ] && [ -d "$SCRIPT_DIR/vanilla/clipse" ]; then
        run_cmd ln -snf "$SCRIPT_DIR/vanilla/clipse" "$CONFIG_DIR/clipse"
    fi
fi

# ------------------------------------------------------------------------------
# 7. Post-Setup Verification Suite
# ------------------------------------------------------------------------------
log_info "Running post-setup verification suite..."

all_passed=true

check_item() {
    local label="$1"
    local condition="$2"
    if eval "$condition"; then
        log_success "$label"
    else
        log_warn "$label (check returned false)"
        all_passed=false
    fi
}

check_item "Hyprland main configuration exists" \
    "[ -f '$SCRIPT_DIR/vanilla/hypr/hyprland.conf' ]"

check_item "Hyprland Lua configuration exists" \
    "[ -f '$SCRIPT_DIR/vanilla/hypr/hyprland.lua' ]"

if command -v Hyprland >/dev/null 2>&1; then
    check_item "Hyprland config validation passes" \
        "env XDG_RUNTIME_DIR='${XDG_RUNTIME_DIR:-/run/user/$(id -u)}' Hyprland --verify-config --config '$SCRIPT_DIR/vanilla/hypr/hyprland.lua' >/dev/null 2>&1"
fi

check_item "Waybar configuration & styles exist" \
    "[ -f '$SCRIPT_DIR/vanilla/waybar/config.jsonc' ] && [ -f '$SCRIPT_DIR/vanilla/waybar/style.css' ]"

check_item "Waybar 6-theme palette definitions exist (3 dark, 3 light)" \
    "[ -f '$SCRIPT_DIR/vanilla/waybar/themes/tokyo-night.css' ] && [ -f '$SCRIPT_DIR/vanilla/waybar/themes/catppuccin.css' ] && [ -f '$SCRIPT_DIR/vanilla/waybar/themes/monochrome.css' ] && [ -f '$SCRIPT_DIR/vanilla/waybar/themes/catppuccin-latte.css' ] && [ -f '$SCRIPT_DIR/vanilla/waybar/themes/tokyo-night-light.css' ] && [ -f '$SCRIPT_DIR/vanilla/waybar/themes/monochrome-light.css' ] && [ -e '$SCRIPT_DIR/vanilla/waybar/theme.css' ]"

check_item "Waybar CSS syntax validates cleanly in GTK3 CssProvider" \
    "python3 -c \"import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk; p = Gtk.CssProvider(); p.load_from_path('$SCRIPT_DIR/vanilla/waybar/style.css')\" >/dev/null 2>&1"

check_item "System monospace font resolves dynamically via fontconfig" \
    "fc-match -f '%{family}' monospace | grep -qv '^$'"

check_item "Theme switcher script (theme-toggle.sh) exists and is executable" \
    "[ -x '$SCRIPT_DIR/vanilla/hypr/scripts/theme-toggle.sh' ]"

check_item "Hyprlauncher configuration exists" \
    "[ -f '$SCRIPT_DIR/vanilla/hypr/hyprlauncher.conf' ]"

check_item "Wofi configuration and stylesheets exist" \
    "[ -f '$SCRIPT_DIR/vanilla/wofi/config' ] && [ -f '$SCRIPT_DIR/vanilla/wofi/style.css' ] && [ -f '$SCRIPT_DIR/vanilla/wofi/wallpicker.css' ]"

check_item "Desktop applications entries exist (theme picker, wallpaper manager, wallpaper picker, emoji picker)" \
    "[ -f '$SCRIPT_DIR/vanilla/applications/theme-picker.desktop' ] && [ -f '$SCRIPT_DIR/vanilla/applications/wallpaper-manager.desktop' ] && [ -f '$SCRIPT_DIR/vanilla/applications/wallpaper-picker.desktop' ] && [ -f '$SCRIPT_DIR/vanilla/applications/emoji-picker.desktop' ]"

check_item "SwayNC notification center configuration exists" \
    "[ -f '$SCRIPT_DIR/vanilla/swaync/config.json' ] && [ -f '$SCRIPT_DIR/vanilla/swaync/style.css' ]"

check_item "Clipse configuration template exists" \
    "[ -f '$SCRIPT_DIR/vanilla/clipse/config.json' ] || [ -f '$SCRIPT_DIR/vanilla/hypr/clipse/config.json' ]"

check_item "GNOME appearance & theme importer exists" \
    "[ -f '$SCRIPT_DIR/vanilla/hypr/scripts/import-gnome-theme.sh' ]"

check_item "GNOME/system terminal resolver exists" \
    "[ -f '$SCRIPT_DIR/vanilla/hypr/scripts/terminal.sh' ]"

check_item "Hyprlock screen locker available" \
    "command -v hyprlock >/dev/null 2>&1 || [ -x '$HOME/.local/bin/hyprlock' ]"

check_item "Hypridle idle daemon available" \
    "command -v hypridle >/dev/null 2>&1 || [ -x '$HOME/.local/bin/hypridle' ]"

check_item "Hyprlock configuration exists" \
    "[ -f '$SCRIPT_DIR/vanilla/hypr/hyprlock.conf' ]"

check_item "Universal logout script exists and is executable" \
    "[ -x '$SCRIPT_DIR/vanilla/hypr/scripts/logout.sh' ]"

check_item "Polkit authentication agent available (hyprpolkitagent / polkit-kde / polkit-gnome)" \
    "command -v hyprpolkitagent >/dev/null 2>&1 || [ -f /usr/libexec/hyprpolkitagent ] || [ -f /usr/lib/hyprpolkitagent ] || command -v /usr/libexec/polkit-gnome-authentication-agent-1 >/dev/null 2>&1 || command -v /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 >/dev/null 2>&1 || command -v /usr/libexec/kf6/polkit-kde-authentication-agent-1 >/dev/null 2>&1"

check_item "XDG Desktop Portal Hyprland available" \
    "rpm -q xdg-desktop-portal-hyprland >/dev/null 2>&1 || pacman -Qi xdg-desktop-portal-hyprland >/dev/null 2>&1 || [ -f /usr/libexec/xdg-desktop-portal-hyprland ] || [ -f /usr/lib/xdg-desktop-portal-hyprland ]"

# Validate shell syntax for all helper scripts
scripts_valid=true
if [[ -d "$SCRIPT_DIR/vanilla/hypr/scripts" ]]; then
    for s in "$SCRIPT_DIR/vanilla/hypr/scripts"/*.sh; do
        [ -f "$s" ] || continue
        if ! bash -n "$s" 2>/dev/null; then
            log_error "Syntax error in $s"
            scripts_valid=false
            all_passed=false
        fi
    done
fi

if [ "$scripts_valid" = true ]; then
    log_success "All Hyprland vanilla helper scripts passed syntax validation (bash -n)"
fi

if [ "$all_passed" = true ]; then
    log_success "All Hyprland desktop verifications passed flawlessly!"
else
    log_warn "Some verifications did not pass. Check package installations or session state."
fi

log_success "Hyprland desktop setup and verification complete!"
