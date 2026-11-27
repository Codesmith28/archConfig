#!/usr/bin/env bash
# ==============================================================================
# Hardware Profile Setup: ASUS ROG + NVIDIA RTX Laptop
# Distro-agnostic power management, D3cold, Cardwire eBPF isolation & AC/Battery switching
# Validated for Fedora, Arch Linux, Ubuntu, and OmArchy
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color formatting
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
BOLD=$'\033[1m'
NC=$'\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error()   { echo -e "${RED}[ERR]${NC}  $*" >&2; }

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

# ------------------------------------------------------------------------------
# Hardware Validation: ASUS ROG / TUF + NVIDIA dGPU Guard
# ------------------------------------------------------------------------------
is_rog_machine() {
    local prod_fam prod_name sys_ven board_name
    prod_fam="$(cat /sys/class/dmi/id/product_family 2>/dev/null || true)"
    prod_name="$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"
    sys_ven="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
    board_name="$(cat /sys/class/dmi/id/board_name 2>/dev/null || true)"
    echo "$prod_fam $prod_name $sys_ven $board_name" | grep -qiE "ROG|TUF|ASUS|Strix|Zephyrus|Flow|Scar"
}

dgpu_present_on_pci() {
    if [[ -r /proc/bus/pci/devices ]] && grep -qiE '^[0-9a-f]+[[:space:]]+10de' /proc/bus/pci/devices 2>/dev/null; then
        return 0
    fi
    if compgen -G "/proc/driver/nvidia/gpus/*" >/dev/null 2>&1; then
        return 0
    fi
    [[ -n "$(lspci -d 10de: 2>/dev/null || true)" ]]
}

has_nvidia_gpu() {
    dgpu_present_on_pci || \
    lspci 2>/dev/null | grep -qiE "(VGA|3D|Display).*NVIDIA" || \
    { command -v cardwire >/dev/null 2>&1 && cardwire list 2>/dev/null | grep -qi "NVIDIA"; } || \
    [[ -f /sys/devices/platform/asus-nb-wmi/dgpu_disable ]] || \
    [[ -d /proc/driver/nvidia ]] || \
    [[ -d /sys/module/nvidia ]] || \
    grep -qiE "ROG|TUF|G614|G814|Zephyrus" /sys/class/dmi/id/product_name 2>/dev/null
}

rebuild_initramfs() {
    if command -v dracut >/dev/null 2>&1; then
        log_info "Updating initramfs via dracut..."
        run_as_root dracut -f
    elif command -v mkinitcpio >/dev/null 2>&1; then
        log_info "Updating initramfs via mkinitcpio..."
        run_as_root mkinitcpio -P
    elif command -v update-initramfs >/dev/null 2>&1; then
        log_info "Updating initramfs via update-initramfs..."
        run_as_root update-initramfs -u
    fi
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        case "${ID:-}" in
            fedora)
                echo "fedora"
                ;;
            arch|archarm|endeavouros|manjaro|omarchy)
                echo "arch"
                ;;
            ubuntu|debian|pop|mint)
                echo "ubuntu"
                ;;
            *)
                if [[ "${ID_LIKE:-}" =~ (fedora|rhel) ]]; then
                    echo "fedora"
                elif [[ "${ID_LIKE:-}" =~ arch ]]; then
                    echo "arch"
                elif [[ "${ID_LIKE:-}" =~ (ubuntu|debian) ]]; then
                    echo "ubuntu"
                else
                    echo "unknown"
                fi
                ;;
        esac
    else
        echo "unknown"
    fi
}

# ------------------------------------------------------------------------------
# ASUS Control & Cardwire Installation Helpers
# ------------------------------------------------------------------------------
configure_asusd_policies() {
    if command -v busctl >/dev/null 2>&1 && systemctl is-active --quiet asusd.service 2>/dev/null; then
        busctl set-property xyz.ljones.Asusd /xyz/ljones xyz.ljones.Platform ChangePlatformProfileOnBattery b false >/dev/null 2>&1 || true
        busctl set-property xyz.ljones.Asusd /xyz/ljones xyz.ljones.Platform ChangePlatformProfileOnAc b false >/dev/null 2>&1 || true
        busctl set-property xyz.ljones.Asusd /xyz/ljones xyz.ljones.Platform PlatformProfileLinkedEpp b false >/dev/null 2>&1 || true
    fi
    if command -v asusd >/dev/null 2>&1 || [[ -d /etc/asusd ]]; then
        run_as_root mkdir -p /etc/asusd
        local asusd_conf="/etc/asusd/asusd.ron"
        if [[ -f "$asusd_conf" ]]; then
            run_as_root sed -i 's/change_platform_profile_on_battery:[[:space:]]*true/change_platform_profile_on_battery: false/g; s/change_platform_profile_on_ac:[[:space:]]*true/change_platform_profile_on_ac: false/g; s/platform_profile_linked_epp:[[:space:]]*true/platform_profile_linked_epp: false/g; s/disable_nvidia_powerd_on_battery:[[:space:]]*true/disable_nvidia_powerd_on_battery: false/g; s/ChargeMode:[[:space:]]*[0-9]*,//g' "$asusd_conf"
            command -v systemctl >/dev/null 2>&1 && run_as_root systemctl try-restart asusd.service 2>/dev/null || true
            log_success "asusd configured: internal profile switching, nvidia-powerd toggling, and rogue ChargeMode disabled"
        fi
    fi
    if [[ -d "$SCRIPT_DIR/tuned-profiles" ]] && { [[ -d /etc/tuned ]] || command -v tuned-adm >/dev/null 2>&1; }; then
        run_as_root mkdir -p /etc/tuned/profiles
        for prof in rog-powersave rog-balanced rog-performance; do
            if [[ -f "$SCRIPT_DIR/tuned-profiles/$prof/tuned.conf" ]]; then
                run_as_root mkdir -p "/etc/tuned/profiles/$prof"
                run_as_root cp -f "$SCRIPT_DIR/tuned-profiles/$prof/tuned.conf" "/etc/tuned/profiles/$prof/tuned.conf"
                run_as_root chmod 644 "/etc/tuned/profiles/$prof/tuned.conf"
            fi
        done
        log_success "Installed custom ASUS ROG TuneD profiles (eliminates intermediate balanced platform_profile bounce)"
    fi
    if [[ -f /etc/tuned/ppd.conf ]]; then
        if [[ -d "$SCRIPT_DIR/tuned-profiles" ]]; then
            run_as_root sed -i -E 's/^power-saver[[:space:]]*=[[:space:]]*powersave[[:space:]]*$/power-saver=rog-powersave/; s/^balanced[[:space:]]*=[[:space:]]*balanced[[:space:]]*$/balanced=rog-balanced/; s/^performance[[:space:]]*=[[:space:]]*throughput-performance[[:space:]]*$/performance=rog-performance/' /etc/tuned/ppd.conf
        fi
        run_as_root sed -i 's/sysfs_acpi_monitor=[[:space:]]*true/sysfs_acpi_monitor=false/g; s/battery_detection=[[:space:]]*true/battery_detection=false/g' /etc/tuned/ppd.conf
        command -v systemctl >/dev/null 2>&1 && run_as_root systemctl try-restart tuned.service tuned-ppd.service 2>/dev/null || true
        log_success "tuned-ppd configured: sysfs_acpi_monitor, battery_detection disabled, and rog-* profiles active"
    fi
    local dgpu_node="/sys/devices/platform/asus-nb-wmi/dgpu_disable"
    if [[ -f "$dgpu_node" ]]; then
        local cur_val
        cur_val="$(cat "$dgpu_node" 2>/dev/null || true)"
        if [[ "$cur_val" != "0" ]]; then
            run_as_root bash -c "echo 0 > $dgpu_node" 2>/dev/null || true
        fi
    fi
    if [[ -e /sys/bus/pci/rescan ]] && ! dgpu_present_on_pci; then
        run_as_root bash -c "echo 1 > /sys/bus/pci/rescan" 2>/dev/null || true
    fi
}

decommission_supergfxctl() {
    log_info "Checking for deprecated supergfxctl / supergfxd.service..."
    if systemctl is-active --quiet supergfxd.service 2>/dev/null; then
        log_info "Stopping supergfxd.service (deprecated upstream; replaced by Cardwire eBPF)..."
        run_as_root systemctl stop supergfxd.service 2>/dev/null || true
    fi
    if systemctl is-enabled --quiet supergfxd.service 2>/dev/null; then
        run_as_root systemctl disable supergfxd.service 2>/dev/null || true
        run_as_root systemctl mask supergfxd.service 2>/dev/null || true
        log_success "supergfxd.service disabled and masked to eliminate PCI bus unbind conflicts."
    fi
}

install_asusctl() {
    local distro
    distro="$(detect_distro)"
    log_info "Verifying ASUS control suite (asusctl / asusd) on $distro..."

    case "$distro" in
        fedora)
            if ! command -v asusctl >/dev/null 2>&1 || ! command -v rog-control-center >/dev/null 2>&1; then
                log_info "Enabling Fedora Copr repo 'lukenukem/asus-linux'..."
                if ! dnf repolist 2>/dev/null | grep -qi "lukenukem:asus-linux"; then
                    run_as_root dnf copr enable -y lukenukem/asus-linux || log_warn "Could not enable copr lukenukem/asus-linux"
                fi
                log_info "Installing asusctl and asusctl-rog-gui (ASUS ROG Control Center GUI)..."
                if command -v pkcon >/dev/null 2>&1; then
                    pkcon install -y asusctl asusctl-rog-gui || run_as_root dnf install -y asusctl asusctl-rog-gui || run_as_root dnf install -y asusctl || log_warn "Failed to install asusctl"
                else
                    run_as_root dnf install -y asusctl asusctl-rog-gui || run_as_root dnf install -y asusctl || log_warn "Failed to install asusctl via dnf"
                fi
            else
                log_success "asusctl and asusctl-rog-gui packages already installed."
            fi
            ;;
        arch)
            if ! command -v asusctl >/dev/null 2>&1 || ! command -v rog-control-center >/dev/null 2>&1; then
                if command -v yay >/dev/null 2>&1; then
                    log_info "Installing asusctl and asusctl-rog-gui via yay..."
                    yay -S --noconfirm --needed asusctl asusctl-rog-gui || log_warn "yay failed to install asusctl"
                elif command -v paru >/dev/null 2>&1; then
                    log_info "Installing asusctl and asusctl-rog-gui via paru..."
                    paru -S --noconfirm --needed asusctl asusctl-rog-gui || log_warn "paru failed to install asusctl"
                else
                    # Configure g14 pacman repository if missing
                    if ! grep -q "^\[g14\]" /etc/pacman.conf 2>/dev/null; then
                        log_info "Configuring ASUS Linux g14 pacman repository..."
                        cat << 'EOF' | run_as_root tee -a /etc/pacman.conf >/dev/null

[g14]
SigLevel = DatabaseNever Optional TrustAll
Server = https://arch.asus-linux.org
EOF
                        run_as_root pacman -Sy || true
                    fi
                    log_info "Installing asusctl and asusctl-rog-gui via pacman..."
                    run_as_root pacman -S --noconfirm --needed asusctl asusctl-rog-gui || run_as_root pacman -S --noconfirm --needed asusctl || log_warn "pacman failed to install asusctl"
                fi
            else
                log_success "asusctl and asusctl-rog-gui packages already installed."
            fi
            ;;
        ubuntu)
            if ! command -v asusctl >/dev/null 2>&1; then
                log_info "Checking community PPA for asusctl (ppa:mitchellaugustin/asusctl)..."
                if command -v add-apt-repository >/dev/null 2>&1; then
                    run_as_root add-apt-repository -y ppa:mitchellaugustin/asusctl 2>/dev/null || true
                    run_as_root apt-get update 2>/dev/null || true
                    run_as_root apt-get install -y asusctl 2>/dev/null || log_warn "Community PPA install failed or not available for this release."
                fi
                if ! command -v asusctl >/dev/null 2>&1; then
                    log_warn "asusctl is not officially packaged for Ubuntu. To build from source:"
                    log_warn "  sudo apt install -y build-essential cmake clang libclang-dev libudev-dev pkg-config git"
                    log_warn "  git clone https://github.com/OpenGamingCollective/asusctl.git /tmp/asusctl && cd /tmp/asusctl && make && sudo make install"
                fi
            else
                log_success "asusctl already installed."
            fi
            ;;
        *)
            log_warn "Distro '$distro' not recognized for automatic asusctl packaging."
            ;;
    esac

    # Enable and start services
    if systemctl list-unit-files asusd.service &>/dev/null; then
        run_as_root systemctl daemon-reload 2>/dev/null || true
        run_as_root systemctl enable --now asusd.service 2>/dev/null || systemctl start asusd.service 2>/dev/null || true
        log_success "asusd.service active."
    fi

    # Configure asusd daemon policies to eliminate ACPI power-profile races
    configure_asusd_policies
}

configure_cardwire_policies() {
    if command -v cardwire >/dev/null 2>&1; then
        log_info "Configuring Cardwire daemon auto-switching policies..."
        # Disable cardwired's un-debounced battery-auto-switch so power-profile-switch.sh
        # acts as the single debounced GPU posture controller (avoids Integrated->Smart double-switch on AC connect)
        cardwire config battery-auto-switch false >/dev/null 2>&1 || true
        cardwire config battery-auto-switch-mode integrated >/dev/null 2>&1 || true
        cardwire config external-display-auto-switch true >/dev/null 2>&1 || true
        cardwire config save >/dev/null 2>&1 || true
        log_success "Cardwire configured (Single debounced controller via power-profile-switch.sh)"
    fi
}

install_cardwire() {
    if command -v cardwire >/dev/null 2>&1; then
        log_success "Cardwire binary already present: $(command -v cardwire) ($(cardwire --version 2>/dev/null || echo 'active'))"
        configure_cardwire_policies
        return 0
    fi

    local distro
    distro="$(detect_distro)"
    log_info "Cardwire not found. Initiating installation for distro: $distro..."

    # Verify BPF LSM prerequisite
    if [[ -r /sys/kernel/security/lsm ]] && ! grep -qw "bpf" /sys/kernel/security/lsm 2>/dev/null; then
        log_warn "Kernel LSM configuration does not list 'bpf'. Cardwire eBPF hooks require 'bpf' in LSM."
        log_warn "Add 'lsm=lockdown,capability,yama,selinux,bpf,landlock' to kernel bootloader arguments if cardwired fails to attach."
    fi

    local tag ver
    tag="$(curl -fsSL --connect-timeout 5 https://api.github.com/repos/OpenGamingCollective/cardwire/releases/latest 2>/dev/null | grep -Po '"tag_name":\s*"\K[^"]+' || echo "v0.12.3")"
    [[ -z "$tag" ]] && tag="v0.12.3"
    ver="${tag#v}"
    log_info "Target Cardwire release version: $tag ($ver)"

    case "$distro" in
        arch)
            if command -v yay >/dev/null 2>&1; then
                log_info "Installing cardwire-bin via yay..."
                yay -S --noconfirm --needed cardwire-bin || true
            elif command -v paru >/dev/null 2>&1; then
                log_info "Installing cardwire-bin via paru..."
                paru -S --noconfirm --needed cardwire-bin || true
            fi
            if ! command -v cardwire >/dev/null 2>&1; then
                local arch_pkg="https://github.com/OpenGamingCollective/cardwire/releases/download/${tag}/cardwire-${ver}-1-x86_64.pkg.tar.zst"
                local tmp_pkg="/tmp/cardwire-${ver}.pkg.tar.zst"
                log_info "Downloading Arch package: $arch_pkg..."
                if curl -fsSL --connect-timeout 10 --max-time 120 "$arch_pkg" -o "$tmp_pkg"; then
                    run_as_root pacman -U --noconfirm "$tmp_pkg" || log_warn "pacman -U cardwire failed"
                    rm -f "$tmp_pkg"
                fi
            fi
            ;;
        ubuntu)
            local deb_url="https://github.com/OpenGamingCollective/cardwire/releases/download/${tag}/cardwire_${ver}-1_amd64.deb"
            local tmp_deb="/tmp/cardwire_${ver}_amd64.deb"
            log_info "Downloading Ubuntu deb package: $deb_url..."
            if curl -fsSL --connect-timeout 10 --max-time 120 "$deb_url" -o "$tmp_deb"; then
                run_as_root dpkg -i "$tmp_deb" 2>/dev/null || run_as_root apt-get install -f -y "$tmp_deb" 2>/dev/null || log_warn "Failed to install cardwire deb package"
                rm -f "$tmp_deb"
            else
                log_warn "Failed to download Cardwire debian package."
            fi
            ;;
        fedora)
            if command -v dnf >/dev/null 2>&1; then
                if ! dnf repolist 2>/dev/null | grep -qi "terra"; then
                    log_info "Configuring Terra repository for Cardwire RPM packaging..."
                    run_as_root dnf config-manager --add-repo https://terra.fyralabs.com/terra.repo 2>/dev/null || true
                fi
                log_info "Attempting to install cardwire via DNF..."
                run_as_root dnf install -y cardwire cardwire-gui 2>/dev/null || log_info "DNF install not available; falling back to direct release package."
            fi
            if ! command -v cardwire >/dev/null 2>&1; then
                local tar_url="https://github.com/OpenGamingCollective/cardwire/releases/download/${tag}/cardwire-${ver}-1-x86_64.pkg.tar.zst"
                local tmp_tar="/tmp/cardwire-${ver}.pkg.tar.zst"
                local tmp_dir
                tmp_dir="$(mktemp -d /tmp/cardwire-install.XXXXXX)"
                log_info "Downloading Cardwire binary package: $tar_url..."
                if curl -fsSL --connect-timeout 10 --max-time 120 "$tar_url" -o "$tmp_tar"; then
                    tar --zstd -xf "$tmp_tar" -C "$tmp_dir" 2>/dev/null || tar -xf "$tmp_tar" -C "$tmp_dir"

                    run_as_root mkdir -p /usr/local/bin /etc/systemd/system /etc/dbus-1/system.d
                    if [[ -f "$tmp_dir/usr/bin/cardwire" ]]; then
                        run_as_root cp -f "$tmp_dir/usr/bin/cardwire" /usr/local/bin/cardwire
                        run_as_root chmod 755 /usr/local/bin/cardwire
                        [[ ! -e /usr/bin/cardwire ]] && run_as_root ln -sf /usr/local/bin/cardwire /usr/bin/cardwire 2>/dev/null || true
                    fi
                    if [[ -f "$tmp_dir/usr/bin/cardwired" ]]; then
                        run_as_root cp -f "$tmp_dir/usr/bin/cardwired" /usr/local/bin/cardwired
                        run_as_root chmod 755 /usr/local/bin/cardwired
                        [[ ! -e /usr/bin/cardwired ]] && run_as_root ln -sf /usr/local/bin/cardwired /usr/bin/cardwired 2>/dev/null || true
                    fi
                    if [[ -f "$tmp_dir/usr/bin/cardwire-gui" ]]; then
                        run_as_root cp -f "$tmp_dir/usr/bin/cardwire-gui" /usr/local/bin/cardwire-gui
                        run_as_root chmod 755 /usr/local/bin/cardwire-gui
                        [[ ! -e /usr/bin/cardwire-gui ]] && run_as_root ln -sf /usr/local/bin/cardwire-gui /usr/bin/cardwire-gui 2>/dev/null || true
                    fi

                    # D-Bus security policy
                    if [[ -f "$tmp_dir/usr/share/dbus-1/system.d/org.opengamingcollective.cardwire.conf" ]]; then
                        run_as_root cp -f "$tmp_dir/usr/share/dbus-1/system.d/org.opengamingcollective.cardwire.conf" /etc/dbus-1/system.d/
                        run_as_root chmod 644 /etc/dbus-1/system.d/org.opengamingcollective.cardwire.conf
                        command -v systemctl >/dev/null 2>&1 && run_as_root systemctl reload dbus 2>/dev/null || true
                    fi

                    # Systemd service unit
                    if [[ -f "$tmp_dir/usr/lib/systemd/system/cardwired.service" ]]; then
                        run_as_root cp -f "$tmp_dir/usr/lib/systemd/system/cardwired.service" /etc/systemd/system/cardwired.service
                        if [[ ! -x /usr/bin/cardwired && -x /usr/local/bin/cardwired ]]; then
                            run_as_root sed -i 's|ExecStart=/usr/bin/cardwired|ExecStart=/usr/local/bin/cardwired|g' /etc/systemd/system/cardwired.service
                        fi
                        run_as_root chmod 644 /etc/systemd/system/cardwired.service
                    fi

                    # Icons & desktop entry
                    if [[ -d "$tmp_dir/usr/share/icons" ]]; then
                        run_as_root cp -r "$tmp_dir/usr/share/icons/"* /usr/share/icons/ 2>/dev/null || true
                    fi
                    if [[ -f "$tmp_dir/usr/share/applications/cardwire-gui.desktop" ]]; then
                        run_as_root cp -f "$tmp_dir/usr/share/applications/cardwire-gui.desktop" /usr/share/applications/ 2>/dev/null || true
                    fi

                    rm -rf "$tmp_tar" "$tmp_dir"
                    log_success "Cardwire binaries and system integration files installed."
                else
                    log_warn "Failed to download Cardwire release package (network error or offline)."
                    rm -rf "$tmp_tar" "$tmp_dir"
                fi
            fi
            ;;
        *)
            local tar_url="https://github.com/OpenGamingCollective/cardwire/releases/download/${tag}/cardwire-${ver}-1-x86_64.pkg.tar.zst"
            local tmp_tar="/tmp/cardwire-${ver}.pkg.tar.zst"
            local tmp_dir
            tmp_dir="$(mktemp -d /tmp/cardwire-install.XXXXXX)"
            log_info "Downloading Cardwire binary package: $tar_url..."
            if curl -fsSL --connect-timeout 10 --max-time 120 "$tar_url" -o "$tmp_tar"; then
                tar --zstd -xf "$tmp_tar" -C "$tmp_dir" 2>/dev/null || tar -xf "$tmp_tar" -C "$tmp_dir"

                run_as_root mkdir -p /usr/local/bin /etc/systemd/system /etc/dbus-1/system.d
                if [[ -f "$tmp_dir/usr/bin/cardwire" ]]; then
                    run_as_root cp -f "$tmp_dir/usr/bin/cardwire" /usr/local/bin/cardwire
                    run_as_root chmod 755 /usr/local/bin/cardwire
                    [[ ! -e /usr/bin/cardwire ]] && run_as_root ln -sf /usr/local/bin/cardwire /usr/bin/cardwire 2>/dev/null || true
                fi
                if [[ -f "$tmp_dir/usr/bin/cardwired" ]]; then
                    run_as_root cp -f "$tmp_dir/usr/bin/cardwired" /usr/local/bin/cardwired
                    run_as_root chmod 755 /usr/local/bin/cardwired
                    [[ ! -e /usr/bin/cardwired ]] && run_as_root ln -sf /usr/local/bin/cardwired /usr/bin/cardwired 2>/dev/null || true
                fi
                if [[ -f "$tmp_dir/usr/bin/cardwire-gui" ]]; then
                    run_as_root cp -f "$tmp_dir/usr/bin/cardwire-gui" /usr/local/bin/cardwire-gui
                    run_as_root chmod 755 /usr/local/bin/cardwire-gui
                    [[ ! -e /usr/bin/cardwire-gui ]] && run_as_root ln -sf /usr/local/bin/cardwire-gui /usr/bin/cardwire-gui 2>/dev/null || true
                fi

                # D-Bus security policy
                if [[ -f "$tmp_dir/usr/share/dbus-1/system.d/org.opengamingcollective.cardwire.conf" ]]; then
                    run_as_root cp -f "$tmp_dir/usr/share/dbus-1/system.d/org.opengamingcollective.cardwire.conf" /etc/dbus-1/system.d/
                    run_as_root chmod 644 /etc/dbus-1/system.d/org.opengamingcollective.cardwire.conf
                    command -v systemctl >/dev/null 2>&1 && run_as_root systemctl reload dbus 2>/dev/null || true
                fi

                # Systemd service unit
                if [[ -f "$tmp_dir/usr/lib/systemd/system/cardwired.service" ]]; then
                    run_as_root cp -f "$tmp_dir/usr/lib/systemd/system/cardwired.service" /etc/systemd/system/cardwired.service
                    if [[ ! -x /usr/bin/cardwired && -x /usr/local/bin/cardwired ]]; then
                        run_as_root sed -i 's|ExecStart=/usr/bin/cardwired|ExecStart=/usr/local/bin/cardwired|g' /etc/systemd/system/cardwired.service
                    fi
                    run_as_root chmod 644 /etc/systemd/system/cardwired.service
                fi

                # Icons & desktop entry
                if [[ -d "$tmp_dir/usr/share/icons" ]]; then
                    run_as_root cp -r "$tmp_dir/usr/share/icons/"* /usr/share/icons/ 2>/dev/null || true
                fi
                if [[ -f "$tmp_dir/usr/share/applications/cardwire-gui.desktop" ]]; then
                    run_as_root cp -f "$tmp_dir/usr/share/applications/cardwire-gui.desktop" /usr/share/applications/ 2>/dev/null || true
                fi

                rm -rf "$tmp_tar" "$tmp_dir"
                log_success "Cardwire binaries and system integration files installed."
            else
                log_warn "Failed to download Cardwire release package (network error or offline)."
                rm -rf "$tmp_tar" "$tmp_dir"
            fi
            ;;
    esac

    # Enable and start cardwired service if installed
    if command -v cardwired >/dev/null 2>&1 || [[ -f /etc/systemd/system/cardwired.service || -f /usr/lib/systemd/system/cardwired.service ]]; then
        run_as_root systemctl daemon-reload 2>/dev/null || true
        run_as_root systemctl enable --now cardwired.service 2>/dev/null || true
        log_success "cardwired.service enabled and started."
    fi

    configure_cardwire_policies
}

# ------------------------------------------------------------------------------
# Verification Routine
# ------------------------------------------------------------------------------
verify_profile() {
    echo -e "\n${BOLD}=== ASUS ROG + NVIDIA Power Status Check ===${NC}\n"

    # Hardware check
    local board prod host_distro
    board="$(cat /sys/class/dmi/id/board_name 2>/dev/null || echo 'Unknown')"
    prod="$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'Unknown')"
    host_distro="$(detect_distro)"
    log_info "Machine DMI: $prod (Board: $board)"
    log_info "Detected Distro: $host_distro"

    if ! is_rog_machine; then
        log_warn "Host does not match ASUS ROG/TUF DMI signature."
    else
        log_success "Host matches ASUS ROG hardware profile."
    fi

    if ! has_nvidia_gpu; then
        log_warn "No NVIDIA discrete GPU found on this system."
    elif [[ -f /sys/devices/platform/asus-nb-wmi/dgpu_disable ]] && [[ "$(cat /sys/devices/platform/asus-nb-wmi/dgpu_disable 2>/dev/null)" == "1" ]]; then
        log_success "NVIDIA dGPU detected (ASUS MUX / Eco Mode active, dGPU currently in low-power sleep)."
    else
        log_success "NVIDIA GPU detected."
    fi

    # 1. Modprobe configuration
    local conf="/etc/modprobe.d/nvidia-power-management.conf"
    if [[ -f "$conf" ]]; then
        log_success "Modprobe config exists: $conf"
        grep -q "NVreg_TemporaryFilePath=/var/lib/systemd/sleep" "$conf" && \
            log_success "Temporary sleep path: /var/lib/systemd/sleep (SELinux standard)"
        grep -q "NVreg_DynamicPowerManagement=0x02" "$conf" && \
            log_success "DynamicPowerManagement: 0x02 (fine-grained D3cold)"
        grep -q "modeset=1" "$conf" && \
            log_success "nvidia-drm modeset: 1"
    else
        log_warn "Modprobe config NOT found at $conf"
    fi

    # 2. Kernel parameters
    if [[ -f /proc/driver/nvidia/params ]]; then
        local val
        val=$(grep "PreserveVideoMemoryAllocations:" /proc/driver/nvidia/params | awk '{print $2}')
        if [[ "$val" == "1" ]]; then
            log_success "Kernel parameter PreserveVideoMemoryAllocations is active: 1"
        else
            log_warn "Kernel parameter PreserveVideoMemoryAllocations is NOT 1 (current: $val)"
        fi
    fi
    if [[ -f /sys/module/nvidia/parameters/NVreg_DynamicPowerManagement ]]; then
        local dpm
        dpm=$(cat /sys/module/nvidia/parameters/NVreg_DynamicPowerManagement 2>/dev/null || echo "N/A")
        log_success "Active NVreg_DynamicPowerManagement: $dpm"
    fi

    # 3. Systemd power management services
    echo ""
    log_info "Checking NVIDIA systemd power management services:"
    local services=("nvidia-suspend.service" "nvidia-hibernate.service" "nvidia-resume.service")
    for s in "${services[@]}"; do
        local state
        state=$(systemctl is-enabled "$s" 2>/dev/null) || state="${state:-not-found}"
        if [[ "$state" == "enabled" ]]; then
            log_success "Unit $s: $state"
        else
            log_warn "Unit $s: $state"
        fi
    done

    # 4. GPU Management Stack (Cardwire -> supergfxctl -> sysfs)
    echo ""
    log_info "Checking GPU Management Stack:"

    # 4a. Cardwire (Primary: eBPF LSM dynamic isolation)
    if command -v cardwire >/dev/null 2>&1; then
        local cw_ver cw_state
        cw_ver="$(cardwire --version 2>/dev/null || echo 'installed')"
        cw_state="$(systemctl is-active cardwired.service 2>/dev/null || echo 'inactive')"
        log_success "Cardwire: $cw_ver (daemon cardwired: $cw_state)"
        
        # Check BPF LSM support
        if [[ -r /sys/kernel/security/lsm ]]; then
            if grep -qw "bpf" /sys/kernel/security/lsm 2>/dev/null; then
                log_success "eBPF LSM status: active (bpf module loaded in kernel LSM)"
            else
                log_warn "eBPF LSM status: 'bpf' missing from /sys/kernel/security/lsm (requires bpf LSM for eBPF hooks)"
            fi
        fi

        log_info "Cardwire active posture: $(cardwire get 2>/dev/null || echo 'unable to query')"
        local cw_auto
        cw_auto="$(cardwire config battery-auto-switch 2>/dev/null | awk '{print tolower($NF)}' | tr -d '[:space:]' || true)"
        if [[ "$cw_auto" == "false" ]]; then
            log_success "Cardwire battery-auto-switch: false (single debounced controller via power-profile-switch.sh)"
        elif [[ "$cw_auto" == "true" ]]; then
            log_warn "Cardwire battery-auto-switch: true (may race on AC connect; run setup.sh to set false)"
        fi
        log_info "Cardwire GPU devices:"
        cardwire list 2>/dev/null || true
    else
        log_warn "Cardwire: NOT installed (Primary eBPF dynamic isolation unavailable)"
    fi

    # 4b. Legacy supergfxctl status check
    if command -v supergfxctl >/dev/null 2>&1 || systemctl is-active --quiet supergfxd.service 2>/dev/null; then
        local sg_state
        sg_state="$(systemctl is-active supergfxd.service 2>/dev/null || echo 'inactive')"
        log_warn "Legacy supergfxctl detected (service: $sg_state). supergfxctl is deprecated upstream; run setup.sh to mask it and migrate to Cardwire."
    fi

    # 4c. ASUS WMI sysfs dgpu_disable (Hardware Fallback: Direct ACPI hardware cutoff)
    if [[ -f /sys/devices/platform/asus-nb-wmi/dgpu_disable ]]; then
        local dgpu_dis
        dgpu_dis="$(cat /sys/devices/platform/asus-nb-wmi/dgpu_disable 2>/dev/null || echo 'unknown')"
        log_success "ASUS WMI sysfs dgpu_disable: available (value: $dgpu_dis - Fallback)"
    else
        log_info "ASUS WMI sysfs dgpu_disable: not present on this motherboard"
    fi

    # 5. ASUS Control Utility (asusctl / asusd)
    echo ""
    log_info "Checking ASUS System Controls (asusctl / asusd):"
    if command -v asusctl >/dev/null 2>&1; then
        local asus_ver asusd_state
        asus_ver="$(asusctl info 2>/dev/null | awk '/asusctl v/{print $2}' || echo 'installed')"
        [[ -z "$asus_ver" ]] && asus_ver="installed"
        asusd_state="$(systemctl is-active asusd.service 2>/dev/null || echo 'inactive')"
        log_success "asusctl: $asus_ver (daemon asusd: $asusd_state)"
        
        if [[ -f /etc/asusd/asusd.ron ]]; then
            if grep -q "change_platform_profile_on_battery:[[:space:]]*false" /etc/asusd/asusd.ron 2>/dev/null; then
                log_success "asusd configuration: ACPI storm protection active (internal profile auto-switch disabled)"
            else
                log_warn "asusd configuration: /etc/asusd/asusd.ron has internal profile switching enabled (may conflict with power dispatch)"
            fi
            if grep -q "disable_nvidia_powerd_on_battery:[[:space:]]*false" /etc/asusd/asusd.ron 2>/dev/null; then
                log_success "asusd configuration: disable_nvidia_powerd_on_battery=false (no nvidia-powerd race with cardwired)"
            else
                log_warn "asusd configuration: disable_nvidia_powerd_on_battery=true in /etc/asusd/asusd.ron (run setup.sh to disable)"
            fi
        else
            log_info "asusd configuration: /etc/asusd/asusd.ron not created yet"
        fi
    else
        log_warn "asusctl: NOT installed (ASUS fan profiles, Aura RGB, AniMe Matrix, charging limit controls unavailable)"
    fi

    if command -v rog-control-center >/dev/null 2>&1; then
        log_success "ASUS ROG UI: installed (/usr/bin/rog-control-center)"
    else
        log_warn "ASUS ROG UI (rog-control-center): NOT installed (package: asusctl-rog-gui)"
    fi

    # 6. Power profiles & supply status
    echo ""
    log_info "Power Supply & Profile status:"
    if grep -qs 1 /sys/class/power_supply/*/online; then
        log_success "Power state: AC Connected"
    else
        log_info "Power state: Battery"
    fi
    if command -v powerprofilesctl >/dev/null 2>&1; then
        local prof
        prof=$(powerprofilesctl get 2>/dev/null || echo "N/A")
        log_success "Active Power Profile: $prof"
    elif command -v busctl >/dev/null 2>&1 && busctl introspect net.hadess.PowerProfiles /net/hadess/PowerProfiles >/dev/null 2>&1; then
        local prof
        prof=$(busctl get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile 2>/dev/null | awk -F'"' '{print $2}' || echo "N/A")
        log_success "Active Power Profile (via D-Bus): $prof"
    elif command -v tuned-adm >/dev/null 2>&1; then
        local prof
        prof=$(tuned-adm active 2>/dev/null | awk -F': ' '/: /{val=$2} END{print val}' || echo "N/A")
        log_success "Active Power Profile (via tuned): $prof"
    fi

    # 6b. TuneD ROG profile & tuned-ppd anti-bounce check
    if [[ -f /etc/tuned/ppd.conf ]]; then
        if grep -q "battery_detection=false" /etc/tuned/ppd.conf 2>/dev/null && \
           grep -q "sysfs_acpi_monitor=false" /etc/tuned/ppd.conf 2>/dev/null; then
            log_success "tuned-ppd config: battery_detection=false and sysfs_acpi_monitor=false"
        else
            log_warn "tuned-ppd config: battery_detection or sysfs_acpi_monitor not disabled in /etc/tuned/ppd.conf"
        fi
        if grep -q "power-saver=rog-powersave" /etc/tuned/ppd.conf 2>/dev/null && \
           grep -q "performance=rog-performance" /etc/tuned/ppd.conf 2>/dev/null; then
            log_success "tuned-ppd profile map: rog-powersave / rog-balanced / rog-performance active"
        else
            log_warn "tuned-ppd profile map: stock profiles still mapped in /etc/tuned/ppd.conf (run setup.sh to install rog-* profiles)"
        fi
    fi
    for prof in rog-powersave rog-balanced rog-performance; do
        if [[ -f "/etc/tuned/profiles/$prof/tuned.conf" ]]; then
            log_success "Installed TuneD profile: /etc/tuned/profiles/$prof/tuned.conf"
        elif [[ -d /etc/tuned ]]; then
            log_warn "Missing TuneD profile: /etc/tuned/profiles/$prof/tuned.conf"
        fi
    done

    # 7. Installed scripts, udev rules, and user-space drop-ins
    echo ""
    log_info "Checking installed automation files:"
    [[ -x /usr/local/bin/power-profile-switch.sh ]] && \
        log_success "Installed executable: /usr/local/bin/power-profile-switch.sh" || \
        log_warn "Missing /usr/local/bin/power-profile-switch.sh"
    [[ -f /etc/udev/rules.d/81-nvidia-pm-audio.rules ]] && \
        log_success "Installed udev rule: /etc/udev/rules.d/81-nvidia-pm-audio.rules" || \
        log_warn "Missing /etc/udev/rules.d/81-nvidia-pm-audio.rules"
    [[ -f /etc/udev/rules.d/99-laptop-power-dispatch.rules ]] && \
        log_success "Installed udev rule: /etc/udev/rules.d/99-laptop-power-dispatch.rules" || \
        log_warn "Missing /etc/udev/rules.d/99-laptop-power-dispatch.rules"

    local pd_dropin="$HOME/.config/systemd/user/plasma-powerdevil.service.d/override.conf"
    if [[ -f "$pd_dropin" ]] && grep -q "POWERDEVIL_NO_DDCUTIL=1" "$pd_dropin"; then
        log_success "Installed user drop-in: $pd_dropin (POWERDEVIL_NO_DDCUTIL=1)"
    else
        log_info "User drop-in: not installed at $pd_dropin"
    fi

    if [[ -x /usr/local/bin/acpi-storm-guard.sh ]]; then
        log_success "Installed ACPI storm guard: /usr/local/bin/acpi-storm-guard.sh ($(systemctl is-enabled acpi-storm-guard.service 2>/dev/null || echo 'unknown'))"
    else
        log_warn "Missing /usr/local/bin/acpi-storm-guard.sh (run hardware-linux/acpi/setup.sh)"
    fi
    echo ""
}

if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" || "${1:-}" == "verify" || "${1:-}" == "status" ]]; then
    verify_profile
    exit 0
fi

# ------------------------------------------------------------------------------
# Main Installation Routine
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}=== ASUS ROG + NVIDIA Hardware Profile Setup ===${NC}\n"

# Enforce hardware guard unless --force is given
if [[ "${1:-}" != "--force" ]]; then
    if ! is_rog_machine || ! has_nvidia_gpu; then
        log_info "Target hardware (ASUS ROG/TUF + NVIDIA dGPU) not detected on this system."
        log_info "Skipping hardware/rog-nvidia optimizations."
        exit 0
    fi
fi

log_success "Target hardware verified: ASUS ROG + NVIDIA dGPU detected."

# 1. Ensure /var/lib/systemd/sleep exists with secure permissions (SELinux standard)
log_info "Ensuring /var/lib/systemd/sleep exists..."
run_as_root mkdir -p /var/lib/systemd/sleep
run_as_root chmod 700 /var/lib/systemd/sleep
if command -v restorecon >/dev/null 2>&1; then
    run_as_root restorecon -v /var/lib/systemd/sleep || true
fi

# 2. Install modprobe configuration
CONF_SRC="$SCRIPT_DIR/nvidia-power-management.conf"
if [[ -f "$CONF_SRC" ]]; then
    log_info "Installing modprobe configuration..."
    run_as_root cp "$CONF_SRC" /etc/modprobe.d/nvidia-power-management.conf
    run_as_root chmod 644 /etc/modprobe.d/nvidia-power-management.conf
    log_success "Installed /etc/modprobe.d/nvidia-power-management.conf"
fi

# 3. Install Udev rules (Audio PM and Power Dispatcher)
if [[ -f "$SCRIPT_DIR/81-nvidia-pm-audio.rules" ]]; then
    log_info "Installing NVIDIA Audio PM udev rule..."
    run_as_root cp "$SCRIPT_DIR/81-nvidia-pm-audio.rules" /etc/udev/rules.d/81-nvidia-pm-audio.rules
    run_as_root chmod 644 /etc/udev/rules.d/81-nvidia-pm-audio.rules
    log_success "Installed /etc/udev/rules.d/81-nvidia-pm-audio.rules"
fi

if [[ -f "$SCRIPT_DIR/power-profile-switch.sh" ]]; then
    log_info "Installing power profile switcher..."
    run_as_root cp "$SCRIPT_DIR/power-profile-switch.sh" /usr/local/bin/power-profile-switch.sh
    run_as_root chmod 755 /usr/local/bin/power-profile-switch.sh
    log_success "Installed /usr/local/bin/power-profile-switch.sh"
fi

if [[ -f "$SCRIPT_DIR/99-laptop-power-dispatch.rules" ]]; then
    log_info "Installing AC/Battery power dispatch udev rule..."
    run_as_root cp "$SCRIPT_DIR/99-laptop-power-dispatch.rules" /etc/udev/rules.d/99-laptop-power-dispatch.rules
    run_as_root chmod 644 /etc/udev/rules.d/99-laptop-power-dispatch.rules
    log_success "Installed /etc/udev/rules.d/99-laptop-power-dispatch.rules"
fi

if command -v udevadm >/dev/null 2>&1; then
    log_info "Reloading udev rules..."
    run_as_root udevadm control --reload-rules || true
    run_as_root udevadm trigger --subsystem-match=pci || true
    run_as_root udevadm trigger --subsystem-match=power_supply || true
fi

# 4. Configure PowerDevil user-space override (disables libddcutil 400ms I2C bus locks)
target_user="${SUDO_USER:-$USER}"
user_home="$(getent passwd "$target_user" 2>/dev/null | cut -d: -f6 || echo "$HOME")"
if [[ -n "$user_home" && -d "$user_home/.config" ]]; then
    pd_dir="$user_home/.config/systemd/user/plasma-powerdevil.service.d"
    log_info "Configuring PowerDevil systemd user override ($pd_dir)..."
    mkdir -p "$pd_dir"
    cat << 'EOF' > "$pd_dir/override.conf"
[Service]
# Eliminate libddcutil 400ms I2C bus locks and KWin atomic commit stutter on laptops
Environment="POWERDEVIL_NO_DDCUTIL=1"
EOF
    if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
        chown -R "$target_user":"$target_user" "$pd_dir"
    fi
    log_success "Configured PowerDevil override (POWERDEVIL_NO_DDCUTIL=1)"
fi

# 5. Decommission deprecated supergfxctl and install/configure asusctl
decommission_supergfxctl
install_asusctl

# 6. Install & configure Cardwire eBPF GPU manager
install_cardwire

# 7. Enable systemd sleep services
if [[ -f /etc/fedora-release ]] && ! systemctl list-unit-files nvidia-suspend.service &>/dev/null; then
    if command -v dnf >/dev/null 2>&1; then
        log_info "NVIDIA sleep services not found. Attempting to install xorg-x11-drv-nvidia-power..."
        run_as_root dnf install -y xorg-x11-drv-nvidia-power || log_warn "Could not install xorg-x11-drv-nvidia-power"
    fi
fi

SERVICES=("nvidia-suspend.service" "nvidia-hibernate.service" "nvidia-resume.service")
if [[ -d /sys/module/nvidia ]] || systemctl list-unit-files nvidia-suspend.service &>/dev/null; then
    run_as_root systemctl daemon-reload
    for s in "${SERVICES[@]}"; do
        if systemctl list-unit-files "$s" &>/dev/null; then
            run_as_root systemctl enable "$s"
            log_success "Enabled systemd service: $s"
        else
            log_warn "Systemd unit $s not found (ensure NVIDIA driver/utils package is installed)"
        fi
    done
fi

# 8. Apply active power profile immediately
if [[ -x /usr/local/bin/power-profile-switch.sh ]]; then
    log_info "Applying active power profile switch..."
    run_as_root /usr/local/bin/power-profile-switch.sh || true
fi

# 9. Rebuild initramfs across all distros
rebuild_initramfs

# 10. Verify
verify_profile
