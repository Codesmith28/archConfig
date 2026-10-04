#!/usr/bin/env bash
# ==============================================================================
# Fedora AppStream & Software Store Integration Setup (GNOME & KDE Compatible)
# Enables RPM Fusion AppStream metadata and refreshes PackageKit so GUI RPM
# packages appear alongside Flatpaks in GNOME Software and KDE Discover.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
else
    log_info()    { echo -e "  \033[0;34m[INFO]\033[0m $*"; }
    log_success() { echo -e "  \033[0;32m[OK]\033[0m   $*"; }
    log_warn()    { echo -e "  \033[1;33m[WARN]\033[0m $*" >&2; }
    log_error()   { echo -e "  \033[0;31m[ERR]\033[0m  $*" >&2; }
    run_as_root() {
        if [[ "$(id -u)" -eq 0 ]]; then
            "$@"
        elif command -v sudo >/dev/null 2>&1; then
            sudo "$@"
        else
            log_error "Root privileges required. Please run with sudo or as root."
            exit 1
        fi
    }
fi

log_info "Configuring AppStream metadata for Software Store (GNOME Software & KDE Discover)..."

# 1. Verify Fedora environment
if ! command -v dnf >/dev/null 2>&1; then
    log_warn "DNF not detected. Skipping Fedora AppStream setup."
    exit 0
fi

# 2. Ensure RPM Fusion Free and Nonfree repositories are installed
missing_repos=()
if ! rpm -q rpmfusion-free-release >/dev/null 2>&1; then
    missing_repos+=("https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm")
fi
if ! rpm -q rpmfusion-nonfree-release >/dev/null 2>&1; then
    missing_repos+=("https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm")
fi

if [[ ${#missing_repos[@]} -gt 0 ]]; then
    log_info "Installing RPM Fusion repositories..."
    run_as_root dnf install -y "${missing_repos[@]}"
fi

# 3. Install AppStream metadata packages (Required for GNOME Software / KDE Discover on Fedora 41+ DNF5)
missing_appstream=()
if ! rpm -q rpmfusion-free-appstream-data >/dev/null 2>&1; then
    missing_appstream+=("rpmfusion-free-appstream-data")
fi
if ! rpm -q rpmfusion-nonfree-appstream-data >/dev/null 2>&1; then
    missing_appstream+=("rpmfusion-nonfree-appstream-data")
fi

if [[ ${#missing_appstream[@]} -gt 0 ]]; then
    log_info "Installing AppStream metadata packages: ${missing_appstream[*]}..."
    run_as_root dnf install -y "${missing_appstream[@]}"
else
    log_success "RPM Fusion AppStream metadata packages are already installed."
fi

# 4. KDE Plasma & Discover Integration
# KDE Discover requires the plasma-discover-packagekit backend to browse and install RPMs
is_kde=0
if [[ "${XDG_CURRENT_DESKTOP:-}" =~ [Kk][Dd][Ee] ]] || \
   rpm -q plasma-discover >/dev/null 2>&1 || \
   command -v plasma-discover >/dev/null 2>&1; then
    is_kde=1
fi

if [[ $is_kde -eq 1 ]]; then
    log_info "KDE Plasma / Discover environment detected."
    if ! rpm -q plasma-discover-packagekit >/dev/null 2>&1; then
        log_info "Installing plasma-discover-packagekit backend for native RPM support in Discover..."
        run_as_root dnf install -y plasma-discover-packagekit || log_warn "Could not install plasma-discover-packagekit"
    else
        log_success "KDE Discover PackageKit backend is already installed."
    fi
fi

# 5. Restart PackageKit daemon
if command -v systemctl >/dev/null 2>&1; then
    log_info "Restarting PackageKit daemon to recognize newly installed AppStream metadata..."
    run_as_root systemctl restart packagekit 2>/dev/null || log_warn "PackageKit service restart returned non-zero code."
fi

# 6. Trigger PackageKit metadata cache refresh
if command -v pkcon >/dev/null 2>&1; then
    log_info "Forcing PackageKit catalog refresh..."
    pkcon refresh force -y >/dev/null 2>&1 || log_warn "pkcon refresh force returned warning or was skipped."
fi

# 7. Invalidate running App Store background daemon caches (GNOME Software & KDE Discover)
if pgrep -f "gnome-software" >/dev/null 2>&1; then
    log_info "Reloading GNOME Software background process..."
    pkill -f "gnome-software" 2>/dev/null || true
fi

if pgrep -f "plasma-discover" >/dev/null 2>&1; then
    log_info "Reloading KDE Discover background process..."
    pkill -f "plasma-discover" 2>/dev/null || true
fi

if [[ -d "$HOME/.cache/discover" ]]; then
    rm -rf "$HOME/.cache/discover" 2>/dev/null || true
fi

log_success "AppStream metadata & PackageKit configured. RPM packages are now available in GNOME Software and KDE Discover!"
