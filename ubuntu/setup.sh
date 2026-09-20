#!/usr/bin/env bash
# ==============================================================================
# Ubuntu Machine Setup & Configuration Master Script
# ==============================================================================
# Reproducible, resilient, and safe across diverse hardware (laptops,
# desktops, VMs, WSL, x86_64, aarch64, NVIDIA, Intel, AMD).
#
# Usage:
#   ./setup.sh                 # Full automated setup
#   ./setup.sh --skip-root     # Skip steps requiring root privileges
#   ./setup.sh --skip-desktop  # Skip GNOME desktop shortcuts and keybindings
# ==============================================================================
set -eo pipefail

# ------------------------------------------------------------------------------
# 1. Colors & Logging Helpers
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_step()    { echo -e "\n${BOLD}${CYAN}==>${NC} ${BOLD}$*${NC}"; }
log_info()    { echo -e "    ${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "    ${GREEN}[OK]${NC}   $*"; }
log_warn()    { echo -e "    ${YELLOW}[WARN]${NC} $*" >&2; }
log_error()   { echo -e "    ${RED}[ERR]${NC}  $*" >&2; }

# ------------------------------------------------------------------------------
# 2. Context & Privilege Detection
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
TARGET_HOME="${TARGET_HOME:-$HOME}"
TARGET_UID=$(id -u "$TARGET_USER" 2>/dev/null || id -u)

SKIP_ROOT=0
SKIP_DESKTOP=0

for arg in "$@"; do
    case "$arg" in
        --skip-root)    SKIP_ROOT=1 ;;
        --skip-desktop) SKIP_DESKTOP=1 ;;
        -h|--help)
            echo "Usage: $0 [--skip-root] [--skip-desktop]"
            exit 0
            ;;
    esac
done

has_sudo() {
    if [[ "$SKIP_ROOT" -eq 1 ]]; then
        return 1
    fi
    if [[ "$(id -u)" -eq 0 ]]; then
        return 0
    fi
    if command -v sudo >/dev/null 2>&1; then
        if sudo -n true 2>/dev/null || sudo -v 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

run_as_root() {
    if [[ "$SKIP_ROOT" -eq 1 ]]; then
        log_warn "Skipping root task: $*"
        return 0
    fi
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        log_warn "Root privileges unavailable. Skipping: $*"
        return 1
    fi
}

run_as_user() {
    if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
        sudo -u "$TARGET_USER" "$@"
    else
        "$@"
    fi
}

# ------------------------------------------------------------------------------
# 3. Architecture Detection
# ------------------------------------------------------------------------------
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)
        ARCH_DEB="amd64"
        EZA_ARCH="x86_64-unknown-linux-gnu"
        LAZYGIT_ARCH="Linux_x86_64"
        NVIM_ARCH="nvim-linux-x86_64"
        YAZI_ARCH="x86_64-unknown-linux-musl"
        ;;
    aarch64|arm64)
        ARCH_DEB="arm64"
        EZA_ARCH="aarch64-unknown-linux-gnu"
        LAZYGIT_ARCH="Linux_arm64"
        NVIM_ARCH="nvim-linux-arm64"
        YAZI_ARCH="aarch64-unknown-linux-musl"
        ;;
    *)
        ARCH_DEB=""
        EZA_ARCH=""
        LAZYGIT_ARCH=""
        NVIM_ARCH=""
        YAZI_ARCH=""
        log_warn "Architecture '$ARCH' may require manual compilation for some binary tools."
        ;;
esac

log_info "Running setup for user: ${BOLD}$TARGET_USER${NC} (Home: $TARGET_HOME, Arch: $ARCH)"

# ------------------------------------------------------------------------------
# 4. System Package Bootstrapping (apt)
# ------------------------------------------------------------------------------
log_step "1. System Packages Bootstrapping"

if command -v apt-get >/dev/null 2>&1 && has_sudo; then
    BASE_PACKAGES=(
        curl
        wget
        git
        build-essential
        procps
        file
        tar
        unzip
        fontconfig
        dconf-cli
        ripgrep
        fd-find
        fzf
        zoxide
        btop
    )

    missing_pkgs=()
    for pkg in "${BASE_PACKAGES[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
        log_info "Installing missing base packages via apt: ${missing_pkgs[*]}"
        run_as_root apt-get update -y
        run_as_root apt-get install -y --no-install-recommends "${missing_pkgs[@]}"
        log_success "Base system packages installed."
    else
        log_success "All base system packages are already satisfied."
    fi

    # Fix Ubuntu command aliases for bat and fd
    if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
        run_as_root ln -sf "$(command -v batcat)" /usr/local/bin/bat
        log_success "Created symlink: /usr/local/bin/bat -> batcat"
    fi
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
        run_as_root ln -sf "$(command -v fdfind)" /usr/local/bin/fd
        log_success "Created symlink: /usr/local/bin/fd -> fdfind"
    fi
else
    log_info "Skipping apt bootstrap (non-apt system, root skipped, or non-sudo mode)."
fi

# Ensure user local directories exist
run_as_user mkdir -p "$TARGET_HOME/.local/bin" "$TARGET_HOME/.local/share" "$TARGET_HOME/.config"

# ------------------------------------------------------------------------------
# 5. Modern Neovim (>= 0.9.0)
# ------------------------------------------------------------------------------
log_step "2. Ensuring Modern Neovim (>= 0.9.0)"

install_nvim=0
if command -v nvim >/dev/null 2>&1; then
    CURRENT_NVIM_VER=$(nvim --version 2>/dev/null | head -n1 | grep -Po 'v\K[0-9]+\.[0-9]+' || echo "0.0")
    MAJOR=$(echo "$CURRENT_NVIM_VER" | cut -d. -f1)
    MINOR=$(echo "$CURRENT_NVIM_VER" | cut -d. -f2)
    if [[ "$MAJOR" -lt 1 && "$MINOR" -lt 9 ]]; then
        log_warn "Installed Neovim version ($CURRENT_NVIM_VER) is older than 0.9.0 (LazyVim incompatible). Upgrading..."
        install_nvim=1
    else
        log_success "Neovim version $CURRENT_NVIM_VER satisfies requirements."
    fi
else
    log_info "Neovim not found. Installing..."
    install_nvim=1
fi

if [[ "$install_nvim" -eq 1 && -n "$NVIM_ARCH" ]]; then
    NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/${NVIM_ARCH}.tar.gz"
    NVIM_DEST_DIR="$TARGET_HOME/.local/share/neovim"
    log_info "Downloading Neovim binary from $NVIM_URL..."
    TMP_DIR=$(mktemp -d)
    if curl -fsSL "$NVIM_URL" -o "$TMP_DIR/nvim.tar.gz"; then
        rm -rf "$NVIM_DEST_DIR"
        mkdir -p "$NVIM_DEST_DIR"
        tar -xzf "$TMP_DIR/nvim.tar.gz" -C "$NVIM_DEST_DIR" --strip-components=1
        ln -sf "$NVIM_DEST_DIR/bin/nvim" "$TARGET_HOME/.local/bin/nvim"
        chown -R "$TARGET_USER:$TARGET_USER" "$NVIM_DEST_DIR" "$TARGET_HOME/.local/bin/nvim" 2>/dev/null || true
        log_success "Neovim installed to $TARGET_HOME/.local/bin/nvim"

        # Compatibility symlink for /opt/nvim-linux-x86_64/bin if root is available and arch is x86_64
        if has_sudo && [[ "$ARCH" == "x86_64" ]]; then
            run_as_root mkdir -p /opt
            run_as_root ln -sfn "$NVIM_DEST_DIR" "/opt/nvim-linux-x86_64"
        fi
    else
        log_warn "Failed to download Neovim prebuilt binary. You may install it via PPA or snap."
    fi
    rm -rf "$TMP_DIR"
fi

# ------------------------------------------------------------------------------
# 6. CLI Tools Installation (eza, starship, lazygit, yazi, fastfetch)
# ------------------------------------------------------------------------------
log_step "3. Installing / Updating CLI Tools"

# eza
if ! command -v eza >/dev/null 2>&1 && [[ -n "$EZA_ARCH" ]]; then
    log_info "Installing eza for $ARCH..."
    TMP_TAR=$(mktemp)
    if curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_${EZA_ARCH}.tar.gz" -o "$TMP_TAR"; then
        tar -xzf "$TMP_TAR" -C "$TARGET_HOME/.local/bin" eza
        chmod +x "$TARGET_HOME/.local/bin/eza"
        chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.local/bin/eza" 2>/dev/null || true
        log_success "eza installed successfully."
    fi
    rm -f "$TMP_TAR"
else
    log_success "eza is present."
fi

# starship
if ! command -v starship >/dev/null 2>&1; then
    log_info "Installing starship prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- -b "$TARGET_HOME/.local/bin" -y >/dev/null 2>&1 || true
    chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.local/bin/starship" 2>/dev/null || true
    log_success "starship installed successfully."
else
    log_success "starship is present."
fi

# lazygit (with rate-limit fallback)
if ! command -v lazygit >/dev/null 2>&1 && [[ -n "$LAZYGIT_ARCH" ]]; then
    log_info "Installing lazygit for $ARCH..."
    LAZYGIT_VER=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" 2>/dev/null | grep -Po '"tag_name": *"v\K[^"]*' || true)
    if [[ -z "$LAZYGIT_VER" ]]; then
        LAZYGIT_VER=$(curl -sIL -o /dev/null -w '%{url_effective}' "https://github.com/jesseduffield/lazygit/releases/latest" 2>/dev/null | grep -Po 'tag/v\K[^/]+' || true)
    fi
    LAZYGIT_VER="${LAZYGIT_VER:-0.44.1}"

    TMP_TAR=$(mktemp)
    if curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VER}/lazygit_${LAZYGIT_VER}_${LAZYGIT_ARCH}.tar.gz" -o "$TMP_TAR"; then
        tar -xzf "$TMP_TAR" -C "$TARGET_HOME/.local/bin" lazygit
        chmod +x "$TARGET_HOME/.local/bin/lazygit"
        chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.local/bin/lazygit" 2>/dev/null || true
        log_success "lazygit (v$LAZYGIT_VER) installed successfully."
    else
        log_warn "Failed to download lazygit."
    fi
    rm -f "$TMP_TAR"
else
    log_success "lazygit is present."
fi

# yazi
if ! command -v yazi >/dev/null 2>&1 && [[ -n "$YAZI_ARCH" ]]; then
    log_info "Installing yazi for $ARCH..."
    TMP_DIR=$(mktemp -d)
    if curl -fsSL "https://github.com/sxyazi/yazi/releases/latest/download/${YAZI_ARCH}.zip" -o "$TMP_DIR/yazi.zip"; then
        unzip -q "$TMP_DIR/yazi.zip" -d "$TMP_DIR"
        EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "yazi-*" | head -n1)
        if [[ -n "$EXTRACTED_DIR" && -f "$EXTRACTED_DIR/yazi" ]]; then
            cp "$EXTRACTED_DIR/yazi" "$TARGET_HOME/.local/bin/yazi"
            [[ -f "$EXTRACTED_DIR/ya" ]] && cp "$EXTRACTED_DIR/ya" "$TARGET_HOME/.local/bin/ya"
            chmod +x "$TARGET_HOME/.local/bin/yazi" "$TARGET_HOME/.local/bin/ya" 2>/dev/null || true
            chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.local/bin/yazi" "$TARGET_HOME/.local/bin/ya" 2>/dev/null || true
            log_success "yazi installed successfully."
        fi
    fi
    rm -rf "$TMP_DIR"
else
    log_success "yazi is present."
fi

# fastfetch
if ! command -v fastfetch >/dev/null 2>&1 && [[ -n "$ARCH_DEB" ]]; then
    log_info "Installing fastfetch..."
    TMP_DIR=$(mktemp -d)
    FASTFETCH_URL="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${ARCH_DEB}.deb"
    if curl -fsSL "$FASTFETCH_URL" -o "$TMP_DIR/fastfetch.deb" 2>/dev/null && has_sudo; then
        run_as_root dpkg -i "$TMP_DIR/fastfetch.deb" >/dev/null 2>&1 || run_as_root apt-get install -f -y >/dev/null 2>&1
        log_success "fastfetch installed via package."
    else
        # Fallback to tarball
        TAR_URL="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${ARCH_DEB}.tar.gz"
        if curl -fsSL "$TAR_URL" -o "$TMP_DIR/fastfetch.tar.gz" 2>/dev/null; then
            tar -xzf "$TMP_DIR/fastfetch.tar.gz" -C "$TMP_DIR"
            EXTRACTED=$(find "$TMP_DIR" -type f -name "fastfetch" | head -n1)
            if [[ -n "$EXTRACTED" ]]; then
                cp "$EXTRACTED" "$TARGET_HOME/.local/bin/fastfetch"
                chmod +x "$TARGET_HOME/.local/bin/fastfetch"
                chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.local/bin/fastfetch" 2>/dev/null || true
                log_success "fastfetch binary installed."
            fi
        fi
    fi
    rm -rf "$TMP_DIR"
else
    log_success "fastfetch is present."
fi

# ------------------------------------------------------------------------------
# 7. Nerd Fonts & Font Cache
# ------------------------------------------------------------------------------
log_step "4. Fonts Configuration"

FONTS_DIR="$TARGET_HOME/.local/share/fonts/NerdFonts"
has_nerd_font=0
if command -v fc-list >/dev/null 2>&1; then
    if (fc-list : family 2>/dev/null || true) | grep -i "nerd font" >/dev/null 2>&1; then
        has_nerd_font=1
    fi
fi

if [[ "$has_nerd_font" -eq 0 ]]; then
    log_info "Downloading Ubuntu Nerd Font..."
    mkdir -p "$FONTS_DIR"
    TMP_ZIP=$(mktemp)
    if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Ubuntu.zip" -o "$TMP_ZIP"; then
        unzip -qo "$TMP_ZIP" -d "$FONTS_DIR" "*.ttf" 2>/dev/null || true
        chown -R "$TARGET_USER:$TARGET_USER" "$FONTS_DIR" 2>/dev/null || true
        log_success "Ubuntu Nerd Font installed to $FONTS_DIR"
    else
        log_warn "Failed to download Ubuntu Nerd Font."
    fi
    rm -f "$TMP_ZIP"
else
    log_success "Nerd Font is already installed on the system."
fi

if command -v fc-cache >/dev/null 2>&1; then
    log_info "Refreshing font cache..."
    run_as_user fc-cache -f "$TARGET_HOME/.local/share/fonts" 2>/dev/null || true
    log_success "Font cache refreshed."
fi

# ------------------------------------------------------------------------------
# 8. Dotfiles Symlinking
# ------------------------------------------------------------------------------
log_step "5. Syncing Dotfiles Symlinks"

link_item() {
    local src="$1"
    local dest="$2"

    if [[ -e "$dest" || -L "$dest" ]]; then
        if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
            return 0
        fi
        rm -rf "${dest}.bak"
        mv "$dest" "${dest}.bak"
        log_info "Backed up existing $(basename "$dest") -> $(basename "$dest").bak"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    chown -h "$TARGET_USER:$TARGET_USER" "$dest" 2>/dev/null || true
}

# Link home dotfiles
if [[ -d "$SCRIPT_DIR/dotfiles/home" ]]; then
    for file in "$SCRIPT_DIR/dotfiles/home"/.*; do
        base="$(basename "$file")"
        [[ "$base" == "." || "$base" == ".." ]] && continue
        link_item "$file" "$TARGET_HOME/$base"
    done
    log_success "Home dotfiles linked into $TARGET_HOME"
fi

# Link .config items
if [[ -d "$SCRIPT_DIR/dotfiles/config" ]]; then
    for item in "$SCRIPT_DIR/dotfiles/config"/*; do
        [[ -e "$item" ]] || continue
        base="$(basename "$item")"
        link_item "$item" "$TARGET_HOME/.config/$base"
    done
    log_success "Config folders linked into $TARGET_HOME/.config"
fi

# ------------------------------------------------------------------------------
# 9. GNOME Desktop & Terminal Settings (Gated)
# ------------------------------------------------------------------------------
log_step "6. GNOME Desktop & Terminal Configuration"

can_configure_gnome=0
if [[ "$SKIP_DESKTOP" -eq 0 ]] && command -v gsettings >/dev/null 2>&1; then
    if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" ]]; then
        can_configure_gnome=1
    elif [[ -e "/run/user/${TARGET_UID}/bus" ]]; then
        can_configure_gnome=1
    fi
fi

if [[ "$can_configure_gnome" -eq 1 ]]; then
    log_info "Configuring GNOME desktop shortcuts and keybindings for user $TARGET_USER..."
    GNOME_CONFIG_SCRIPT="$SCRIPT_DIR/optimizations/optimize_gnome/config.sh"
    if [[ -f "$GNOME_CONFIG_SCRIPT" ]]; then
        if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
            sudo -u "$TARGET_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${TARGET_UID}/bus" bash "$GNOME_CONFIG_SCRIPT" 2>/dev/null || true
        else
            bash "$GNOME_CONFIG_SCRIPT" 2>/dev/null || true
        fi
        log_success "GNOME desktop keybindings & Ptyxis terminal configuration applied."
    fi
else
    log_info "No active graphical GNOME session detected (headless/SSH/non-GNOME). Skipping desktop keybindings."
fi

# ------------------------------------------------------------------------------
# 10. Hardware-Specific System Optimizations (Safely Gated)
# ------------------------------------------------------------------------------
log_step "7. Hardware-Specific Optimizations"

if has_sudo; then
    # A. Battery charging threshold optimization
    log_info "Checking battery threshold support..."
    BAT_THRESHOLD_FILE=""
    for f in /sys/class/power_supply/BAT*/charge_control_end_threshold; do
        if [[ -f "$f" ]]; then
            BAT_THRESHOLD_FILE="$f"
            break
        fi
    done

    if [[ -n "$BAT_THRESHOLD_FILE" ]]; then
        log_info "Supported battery charge threshold detected at $BAT_THRESHOLD_FILE"
        BAT_SCRIPT="$SCRIPT_DIR/optimizations/battery/set-battery-limit.sh"
        BAT_SERVICE="$SCRIPT_DIR/optimizations/battery/battery-limit.service"
        if [[ -f "$BAT_SCRIPT" && -f "$BAT_SERVICE" ]]; then
            run_as_root cp "$BAT_SCRIPT" /usr/local/bin/set-battery-limit.sh
            run_as_root chmod 755 /usr/local/bin/set-battery-limit.sh
            run_as_root cp "$BAT_SERVICE" /etc/systemd/system/battery-limit.service
            run_as_root chmod 644 /etc/systemd/system/battery-limit.service
            run_as_root systemctl daemon-reload
            run_as_root systemctl enable --now battery-limit.service 2>/dev/null || true
            log_success "Battery limit service installed and enabled (85% limit)."
        fi
    else
        log_info "No supported battery threshold interface found (desktop, VM, or non-ASUS). Skipping battery limit."
    fi

    # B. USB ACPI wake isolation (Only for laptops; preserves USB keyboard/mouse wake on desktops)
    log_info "Checking chassis type for USB wake isolation..."
    is_laptop=0
    if [[ -d /sys/class/power_supply ]]; then
        for b in /sys/class/power_supply/BAT*; do
            [[ -d "$b" ]] && is_laptop=1 && break
        done
    fi
    if [[ -f /sys/class/dmi/id/chassis_type ]]; then
        chassis=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo 0)
        case "$chassis" in
            8|9|10|11|14|31|32) is_laptop=1 ;;
        esac
    fi

    if [[ "$is_laptop" -eq 1 && -f /proc/acpi/wakeup ]]; then
        log_info "Laptop chassis detected. Installing USB ACPI wake isolation to prevent sleep wakeups in bags..."
        WAKE_SCRIPT="$SCRIPT_DIR/optimizations/usb-wake/isolate-wake.sh"
        WAKE_SERVICE="$SCRIPT_DIR/optimizations/usb-wake/disable-xhci-wake.service"
        if [[ -f "$WAKE_SCRIPT" && -f "$WAKE_SERVICE" ]]; then
            run_as_root cp "$WAKE_SCRIPT" /usr/local/bin/isolate-wake.sh
            run_as_root chmod 755 /usr/local/bin/isolate-wake.sh
            run_as_root cp "$WAKE_SERVICE" /etc/systemd/system/disable-xhci-wake.service
            run_as_root chmod 644 /etc/systemd/system/disable-xhci-wake.service
            run_as_root systemctl daemon-reload
            run_as_root systemctl enable --now disable-xhci-wake.service 2>/dev/null || true
            log_success "USB wake isolation service enabled."
        fi
    else
        log_info "Desktop or non-ACPI system detected. Preserving USB keyboard/mouse sleep wake functionality."
    fi

    # C. NVIDIA Power Management (Hot Backpack Fix & Memory Preservation)
    log_info "Checking for NVIDIA GPU..."
    has_nvidia=0
    if lspci 2>/dev/null | grep -qi nvidia || lsmod 2>/dev/null | grep -q "^nvidia" || dpkg -l "*nvidia-driver*" >/dev/null 2>&1; then
        has_nvidia=1
    fi

    if [[ "$has_nvidia" -eq 1 ]]; then
        log_info "NVIDIA hardware detected. Configuring power management..."
        NV_CONF="$SCRIPT_DIR/optimizations/nvidia-power/nvidia-power-management.conf"
        if [[ -f "$NV_CONF" ]]; then
            run_as_root mkdir -p /etc/modprobe.d
            run_as_root cp "$NV_CONF" /etc/modprobe.d/nvidia-power-management.conf
            run_as_root chmod 644 /etc/modprobe.d/nvidia-power-management.conf
            run_as_root systemctl daemon-reload
            for s in nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service; do
                if systemctl list-unit-files "$s" 2>/dev/null | grep -q "$s"; then
                    run_as_root systemctl enable "$s" 2>/dev/null || true
                fi
            done
            log_success "NVIDIA power management & suspend hooks configured."
        fi
    else
        log_info "No NVIDIA GPU detected. Skipping NVIDIA power management."
    fi
else
    log_info "Root privileges not available; hardware optimizations skipped."
fi

# ------------------------------------------------------------------------------
# 11. Completion
# ------------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${GREEN}✨ Setup completed successfully!${NC}"
echo -e "Open a new shell or terminal tab to start using your configured environment."
