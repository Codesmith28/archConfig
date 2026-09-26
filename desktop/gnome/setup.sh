#!/usr/bin/env bash
# ==============================================================================
# GNOME Desktop & Terminal Optimizations Setup (Cross-Distro Universal)
# Supports: Fedora, Ubuntu/Debian, Arch Linux
# Zero-Intervention, Self-Healing Out-Of-The-Box Configuration
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
else
    log_info()    { echo "  [INFO] $*"; }
    log_success() { echo "  [OK]   $*"; }
    log_warn()    { echo "  [WARN] $*" >&2; }
    log_error()   { echo "  [ERR]  $*" >&2; }
fi

# ------------------------------------------------------------------------------
# 1. Privileges & DBus Session Resilience
# ------------------------------------------------------------------------------
# Ensure non-interactive / SSH / sudo invocations attach to user's DBus session
if [[ "$(id -u)" -eq 0 && "${1:-}" != "--user-run" ]]; then
    TARGET_USER="${SUDO_USER:-}"
    if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
        TARGET_USER="$(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $3}' | grep -v 'root' | head -n 1 || true)"
        if [[ -z "$TARGET_USER" ]]; then
            TARGET_USER="$(who | awk '$1 != "root" {print $1; exit}' || true)"
        fi
        if [[ -z "$TARGET_USER" ]]; then
            TARGET_USER="codesmith28"
        fi
    fi

    TARGET_UID=$(id -u "$TARGET_USER")
    TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    BUS_PATH="/run/user/${TARGET_UID}/bus"

    log_info "Dropping privileges to ${TARGET_USER} (UID: ${TARGET_UID})..."
    if [[ -S "$BUS_PATH" ]]; then
        sudo -u "$TARGET_USER" -H env \
            HOME="$TARGET_HOME" \
            USER="$TARGET_USER" \
            XDG_RUNTIME_DIR="/run/user/${TARGET_UID}" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=${BUS_PATH}" \
            bash "$0" --user-run
    else
        log_info "Active DBus session bus not found. Spawning via dbus-run-session..."
        sudo -u "$TARGET_USER" -H env \
            HOME="$TARGET_HOME" \
            USER="$TARGET_USER" \
            XDG_RUNTIME_DIR="/run/user/${TARGET_UID}" \
            dbus-run-session -- bash "$0" --user-run
    fi
    exit $?
fi

# If running as normal user but DBUS_SESSION_BUS_ADDRESS is missing, check runtime bus
if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    USER_BUS="/run/user/$(id -u)/bus"
    if [[ -S "$USER_BUS" ]]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=${USER_BUS}"
    elif command -v dbus-run-session >/dev/null 2>&1 && [[ "${1:-}" != "--dbus-wrapped" ]]; then
        exec dbus-run-session -- bash "$0" --dbus-wrapped "$@"
    fi
fi

# ------------------------------------------------------------------------------
# 2. Systemd User Environment & PATH Persistence
# ------------------------------------------------------------------------------
log_info "Configuring systemd user session environment for GUI launchers..."
mkdir -p "$HOME/.config/environment.d" "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.local/share/dbus-1/services"

# Write persistent environment so GNOME Shell always resolves custom launchers (default-terminal)
cat > "$HOME/.config/environment.d/10-archconfig.conf" << 'EOF'
PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
EOF

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user import-environment PATH 2>/dev/null || true
fi

# Install default-terminal launcher script
if [[ -f "$SCRIPT_DIR/default-terminal" ]]; then
    install -m 755 "$SCRIPT_DIR/default-terminal" "$HOME/.local/bin/default-terminal"
    # Also install to /usr/local/bin if root/sudo is available without password prompt
    if sudo -n true 2>/dev/null; then
        sudo install -m 755 "$SCRIPT_DIR/default-terminal" "/usr/local/bin/default-terminal" 2>/dev/null || true
    fi
fi

# ------------------------------------------------------------------------------
# 3. Distro Utility Package Installation (gnome-tweaks & extension-manager)
# ------------------------------------------------------------------------------
install_distro_packages() {
    log_info "Verifying required GNOME utility packages..."
    
    local os_id=""
    if [[ -f /etc/os-release ]]; then
        os_id="$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')"
    fi

    local can_sudo=false
    if sudo -n true 2>/dev/null || [[ -n "${SUDO_USER:-}" ]]; then
        can_sudo=true
    fi

    case "$os_id" in
        fedora|rhel|centos)
            if ! rpm -q gnome-tweaks >/dev/null 2>&1; then
                if [ "$can_sudo" = true ]; then
                    log_info "Installing gnome-tweaks via dnf..."
                    sudo dnf install -y gnome-tweaks 2>/dev/null || true
                fi
            fi
            if command -v flatpak >/dev/null 2>&1; then
                if ! flatpak list 2>/dev/null | grep -q "com.mattjakeman.ExtensionManager"; then
                    log_info "Installing Extension Manager via flatpak..."
                    flatpak install -y flathub com.mattjakeman.ExtensionManager 2>/dev/null || true
                fi
            fi
            if ! rpm -q gnome-extensions-app >/dev/null 2>&1 && [ "$can_sudo" = true ]; then
                sudo dnf install -y gnome-extensions-app 2>/dev/null || true
            fi
            ;;
        ubuntu|debian|pop|linuxmint)
            local missing_pkgs=()
            if ! dpkg -s gnome-tweaks >/dev/null 2>&1; then
                missing_pkgs+=("gnome-tweaks")
            fi
            if ! dpkg -s gnome-shell-extension-manager >/dev/null 2>&1; then
                missing_pkgs+=("gnome-shell-extension-manager")
            fi
            if [[ ${#missing_pkgs[@]} -gt 0 ]] && [ "$can_sudo" = true ]; then
                log_info "Installing ${missing_pkgs[*]} via apt..."
                sudo apt-get update -qq 2>/dev/null || true
                sudo apt-get install -y "${missing_pkgs[@]}" 2>/dev/null || true
            fi
            ;;
        arch|manjaro|endeavouros)
            local missing_pkgs=()
            if ! pacman -Qi gnome-tweaks >/dev/null 2>&1; then
                missing_pkgs+=("gnome-tweaks")
            fi
            if ! pacman -Qi extension-manager >/dev/null 2>&1; then
                missing_pkgs+=("extension-manager")
            fi
            if [[ ${#missing_pkgs[@]} -gt 0 ]] && [ "$can_sudo" = true ]; then
                log_info "Installing ${missing_pkgs[*]} via pacman..."
                sudo pacman -S --needed --noconfirm "${missing_pkgs[@]}" 2>/dev/null || true
            fi
            ;;
        *)
            log_warn "Unrecognized distro: $os_id. Skipping automatic package manager check."
            ;;
    esac
}

install_distro_packages

# ------------------------------------------------------------------------------
# 4. Extension Compatibility & Master Controls
# ------------------------------------------------------------------------------
# Prevent GNOME from disabling extensions after point releases or shell crashes
log_info "Hardening GNOME extension compatibility settings..."
gsettings set org.gnome.shell disable-user-extensions false 2>/dev/null || true
gsettings set org.gnome.shell disable-extension-version-validation true 2>/dev/null || true
dconf write /org/gnome/shell/disable-user-extensions false 2>/dev/null || true
dconf write /org/gnome/shell/disable-extension-version-validation true 2>/dev/null || true

# Ubuntu Dock deduplication: prevent double docks on Ubuntu
if gsettings list-schemas 2>/dev/null | grep -q "org.gnome.shell.extensions.ubuntu-dock"; then
    log_info "Ubuntu detected: disabling redundant ubuntu-dock to prevent conflicts with dash-to-dock..."
    gnome-extensions disable ubuntu-dock@ubuntu.com 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 5. Key GNOME Extensions Installation & Auto-Compilation
# ------------------------------------------------------------------------------
# 1. Blur my Shell
# 2. Clipboard Indicator
# 3. Compiz alike magic lamp effect
# 4. Dash to Dock
# 5. Rounded Window Corners Reborn
install_key_extensions() {
    log_info "Verifying and provisioning the 5 key GNOME extensions..."
    
    python3 - << 'PYEOF'
import urllib.request, json, zipfile, io, os, subprocess

EXTENSIONS = [
    ("blur-my-shell@aunetx", "Blur my Shell"),
    ("clipboard-indicator@tudmotu.com", "Clipboard Indicator"),
    ("compiz-alike-magic-lamp-effect@hermes83.github.com", "Compiz alike magic lamp effect"),
    ("dash-to-dock@micxgx.gmail.com", "Dash to Dock"),
    ("rounded-window-corners@fxgn", "Rounded Window Corners Reborn")
]

def get_shell_version():
    try:
        out = subprocess.run(["gnome-shell", "--version"], capture_output=True, text=True).stdout
        return out.strip().split()[-1].split(".")[0]
    except Exception:
        return "50"

shell_ver = get_shell_version()

for uuid, name in EXTENSIONS:
    user_ext_dir = os.path.expanduser(f"~/.local/share/gnome-shell/extensions/{uuid}")
    sys_ext_dir = f"/usr/share/gnome-shell/extensions/{uuid}"
    
    if os.path.exists(user_ext_dir) or os.path.exists(sys_ext_dir):
        print(f"    ✓ {name} ({uuid}) is installed")
    else:
        print(f"    📦 Installing {name} ({uuid}) for GNOME {shell_ver}...")
        url = f"https://extensions.gnome.org/extension-info/?uuid={uuid}&shell_version={shell_ver}"
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req) as resp:
                data = json.loads(resp.read().decode())
                dl_path = data.get("download_url")
                if not dl_path:
                    # Fallback to general unversioned query
                    alt_url = f"https://extensions.gnome.org/extension-info/?uuid={uuid}"
                    alt_req = urllib.request.Request(alt_url, headers={'User-Agent': 'Mozilla/5.0'})
                    alt_data = json.loads(urllib.request.urlopen(alt_req).read().decode())
                    ver_map = alt_data.get("shell_version_map", {})
                    if ver_map:
                        latest_pk = max(ver_map.values(), key=lambda x: x.get("version", 0))["pk"]
                        dl_path = f"/download-extension/{uuid}.shell-extension.zip?version_tag={latest_pk}"

                if dl_path:
                    full_dl_url = "https://extensions.gnome.org" + dl_path
                    dl_req = urllib.request.Request(full_dl_url, headers={'User-Agent': 'Mozilla/5.0'})
                    with urllib.request.urlopen(dl_req) as dl_resp:
                        z = zipfile.ZipFile(io.BytesIO(dl_resp.read()))
                        os.makedirs(user_ext_dir, exist_ok=True)
                        z.extractall(user_ext_dir)
                        schemas_dir = os.path.join(user_ext_dir, "schemas")
                        if os.path.isdir(schemas_dir):
                            subprocess.run(["glib-compile-schemas", schemas_dir], capture_output=True)
                        print(f"    ✓ Successfully installed {name}!")
        except Exception as e:
            print(f"    ⚠ Automatic download for {name} failed: {e}")

    # Ensure extension is marked enabled
    try:
        subprocess.run(["gnome-extensions", "enable", uuid], capture_output=True)
    except Exception:
        pass
PYEOF

    # Compile schemas for ALL installed extensions to guarantee no schema missing errors
    log_info "Compiling GSettings schemas for user extensions..."
    for schema_dir in "$HOME/.local/share/gnome-shell/extensions"/*/schemas; do
        if [[ -d "$schema_dir" ]]; then
            glib-compile-schemas "$schema_dir" 2>/dev/null || true
        fi
    done

    # Ensure enabled-extensions list in gsettings/dconf includes all 5 extensions
    log_info "Ensuring extensions are active in GNOME Shell session..."
    python3 - << 'PYEOF'
import subprocess

uuids = [
    "dash-to-dock@micxgx.gmail.com",
    "clipboard-indicator@tudmotu.com",
    "blur-my-shell@aunetx",
    "compiz-alike-magic-lamp-effect@hermes83.github.com",
    "rounded-window-corners@fxgn"
]

res = subprocess.run(["gsettings", "get", "org.gnome.shell", "enabled-extensions"], capture_output=True, text=True).stdout.strip()
if not res or res in ['@as []', '[]']:
    existing = []
else:
    existing = [x.strip(" '\"[]") for x in res.split(',') if x.strip(" '\"[]")]

modified = False
for u in uuids:
    if u not in existing:
        existing.append(u)
        modified = True

if modified:
    formatted = "[" + ", ".join(f"'{u}'" for u in existing) + "]"
    subprocess.run(["gsettings", "set", "org.gnome.shell", "enabled-extensions", formatted])
    subprocess.run(["dconf", "write", "/org/gnome/shell/enabled-extensions", formatted])
PYEOF
}

install_key_extensions

# ------------------------------------------------------------------------------
# 6. Apply Saved Dconf Profile (Whole-System State)
# ------------------------------------------------------------------------------
DCONF_FILE="$SCRIPT_DIR/dconf/gnome-settings.dconf"
if [[ -f "$DCONF_FILE" ]] && command -v dconf >/dev/null 2>&1; then
    log_info "Applying saved dconf settings from $DCONF_FILE..."
    dconf load / < "$DCONF_FILE" || true
fi

# ------------------------------------------------------------------------------
# 7. Live Gsettings Enforcement (Zero-Latency Application)
# ------------------------------------------------------------------------------
log_info "Applying GNOME keybindings, keyrate, shortcuts, and terminal optimizations..."

# ==============================================================================
# Workspace Navigation & Management Shortcuts
# ==============================================================================
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Super>Page_Up']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super>Page_Down']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['<Super>Page_Up']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['<Super>Page_Down']"

gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Super><Shift>Page_Up']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Super><Shift>Page_Down']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "['<Super><Shift>Page_Up']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "['<Super><Shift>Page_Down']"

gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last "['<Super>End']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-last "['<Super><Shift>End']"

# Workspace switching & window moving: Super + [1-9] / Super + Shift + [1-9]
for i in {1..9}; do
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Super>$i']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Super><Shift>$i']"
    # Unbind GNOME Shell default app-switching shortcuts that conflict with Super + [1-9]
    gsettings set org.gnome.shell.keybindings switch-to-application-$i "[]"
done

# ==============================================================================
# Screenshots
# ==============================================================================
gsettings set org.gnome.shell.keybindings screenshot "['<Super><Shift>a']"
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Super><Shift>s', 'Print']"
gsettings set org.gnome.shell.keybindings screenshot-window "['<Super><Shift>w']"

# ==============================================================================
# Notifications Management (Free Super+V for Clipboard Indicator)
# ==============================================================================
gsettings set org.gnome.shell.keybindings focus-active-notification "[]"
gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>n']"

# ==============================================================================
# Dash-to-Dock Configuration & Shortcut Conflict Elimination
# ==============================================================================
DASH_TO_DOCK_USER="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas"
if [[ -d "$DASH_TO_DOCK_USER" ]]; then
    gsettings --schemadir "$DASH_TO_DOCK_USER" set org.gnome.shell.extensions.dash-to-dock shortcut "[]" 2>/dev/null || true
    gsettings --schemadir "$DASH_TO_DOCK_USER" set org.gnome.shell.extensions.dash-to-dock shortcut-text "''" 2>/dev/null || true
    gsettings --schemadir "$DASH_TO_DOCK_USER" set org.gnome.shell.extensions.dash-to-dock hot-keys false 2>/dev/null || true
fi

if gsettings list-schemas 2>/dev/null | grep -q "^org\.gnome\.shell\.extensions\.dash-to-dock$"; then
    gsettings set org.gnome.shell.extensions.dash-to-dock shortcut "[]" 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock shortcut-text "''" 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false 2>/dev/null || true
fi

# Ensure direct dconf write disables hot-keys and all app hotkeys that conflict with Super / Super+Shift
dconf write /org/gnome/shell/extensions/dash-to-dock/hot-keys false 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/shortcut "@as []" 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/shortcut-text "''" 2>/dev/null || true
for i in {1..9}; do
    dconf write /org/gnome/shell/extensions/dash-to-dock/app-shift-hotkey-$i "@as []" 2>/dev/null || true
    dconf write /org/gnome/shell/extensions/dash-to-dock/app-hotkey-$i "@as []" 2>/dev/null || true
done
dconf write /org/gnome/shell/extensions/dash-to-dock/app-shift-hotkey-10 "@as []" 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/app-hotkey-10 "@as []" 2>/dev/null || true

# Dock aesthetics & placement
dconf write /org/gnome/shell/extensions/dash-to-dock/dock-position "'BOTTOM'" 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/dock-fixed false 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/intellihide-mode "'ALL_WINDOWS'" 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/extend-height false 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/always-center-icons true 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size 40 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/background-opacity 0.8 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/click-action "'minimize-or-overview'" 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/running-indicator-style "'DOTS'" 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/running-indicator-dominant-color true 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/disable-overview-on-startup true 2>/dev/null || true
dconf write /org/gnome/shell/extensions/dash-to-dock/multi-monitor true 2>/dev/null || true

# ==============================================================================
# Window Management & Titlebar Controls
# ==============================================================================
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q', '<Alt>F4']"
gsettings set org.gnome.desktop.wm.keybindings minimize "['<Super>m']"
gsettings set org.gnome.desktop.wm.keybindings move-to-side-w '[]'
gsettings set org.gnome.desktop.wm.keybindings move-to-side-e '[]'
gsettings set org.gnome.desktop.wm.keybindings move-to-center "['<Super>c']"
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.mutter dynamic-workspaces true

# ==============================================================================
# Application Launchers & Media Keys
# ==============================================================================
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"
gsettings set org.gnome.settings-daemon.plugins.media-keys www "['<Super><Shift>b']"

if gsettings list-schemas 2>/dev/null | grep -q "org.gnome.shell.extensions.tiling-assistant"; then
    gsettings set org.gnome.shell.extensions.tiling-assistant center-window "['<Super>c']" 2>/dev/null || true
    dconf write /org/gnome/shell/extensions/tiling-assistant/center-window "['<Super>c']" 2>/dev/null || true
fi

# ==============================================================================
# Font Settings: Adwaita Sans for UI, JetBrainsMono for monospace
# ==============================================================================
gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11' 2>/dev/null || true
gsettings set org.gnome.desktop.interface document-font-name 'Adwaita Sans 11' 2>/dev/null || true
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10' 2>/dev/null || true
gsettings set org.gnome.desktop.interface font-antialiasing 'rgba' 2>/dev/null || true
gsettings set org.gnome.desktop.interface font-hinting 'slight' 2>/dev/null || true

# ==============================================================================
# Appearance & Interface Settings
# ==============================================================================
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface accent-color 'blue' 2>/dev/null || true
gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
gsettings set org.gnome.desktop.interface clock-show-seconds false 2>/dev/null || true
gsettings set org.gnome.desktop.interface clock-show-weekday false 2>/dev/null || true
gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true 2>/dev/null || true

# ==============================================================================
# Keyboard Keyrate & Repeat (250ms delay, 25ms repeat-interval ~40Hz)
# ==============================================================================
gsettings set org.gnome.desktop.peripherals.keyboard repeat true
gsettings set org.gnome.desktop.peripherals.keyboard delay 250
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 25

dconf write /org/gnome/desktop/peripherals/keyboard/repeat true
dconf write /org/gnome/desktop/peripherals/keyboard/delay "uint32 250"
dconf write /org/gnome/desktop/peripherals/keyboard/repeat-interval "uint32 25"

# ==============================================================================
# Touchpad Settings (Disable While Typing / Tap-to-click)
# ==============================================================================
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true

dconf write /org/gnome/desktop/peripherals/touchpad/disable-while-typing true
dconf write /org/gnome/desktop/peripherals/touchpad/tap-to-click true
dconf write /org/gnome/desktop/peripherals/touchpad/natural-scroll true

# Default terminal preference
gsettings set org.gnome.desktop.default-applications.terminal exec 'ghostty' 2>/dev/null || true

# ==============================================================================
# Terminal Shortcut: Super + Return -> Default Terminal Emulator
# ==============================================================================
python3 - << 'PYEOF'
import subprocess

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout.strip()

bindings_raw = run(['gsettings', 'get', 'org.gnome.settings-daemon.plugins.media-keys', 'custom-keybindings'])
if not bindings_raw or bindings_raw in ['@as []', '[]']:
    existing = []
else:
    existing = [x.strip(" '\"[]") for x in bindings_raw.split(',') if x.strip(" '\"[]")]

target_path = None
for p in existing:
    name = run(['gsettings', 'get', f'org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:{p}', 'name'])
    binding = run(['gsettings', 'get', f'org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:{p}', 'binding'])
    if 'Terminal' in name or '<Super>Return' in binding:
        target_path = p
        break

if not target_path:
    idx = 0
    while f"/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom{idx}/" in existing:
        idx += 1
    target_path = f"/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom{idx}/"
    existing.append(target_path)
    val = "[" + ", ".join(f"'{p}'" for p in existing) + "]"
    subprocess.run(['gsettings', 'set', 'org.gnome.settings-daemon.plugins.media-keys', 'custom-keybindings', val])
    subprocess.run(['dconf', 'write', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings', val])

subprocess.run(['gsettings', 'set', f'org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:{target_path}', 'name', 'Default Terminal'])
subprocess.run(['gsettings', 'set', f'org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:{target_path}', 'command', 'default-terminal'])
subprocess.run(['gsettings', 'set', f'org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:{target_path}', 'binding', '<Super>Return'])

subprocess.run(['dconf', 'write', f'{target_path}name', "'Default Terminal'"])
subprocess.run(['dconf', 'write', f'{target_path}command', "'default-terminal'"])
subprocess.run(['dconf', 'write', f'{target_path}binding', "'<Super>Return'"])
PYEOF

# ==============================================================================
# Ptyxis Optimizations
# ==============================================================================
if gsettings list-schemas 2>/dev/null | grep -q "org.gnome.Ptyxis"; then
    gsettings set org.gnome.Ptyxis use-system-font true 2>/dev/null || true
    dconf write /org/gnome/Ptyxis/Shortcuts/move-next-tab "'<Control>Tab'" 2>/dev/null || true
    dconf write /org/gnome/Ptyxis/Shortcuts/move-previous-tab "'<Control><Shift>Tab'" 2>/dev/null || true
fi

# Prevent waking discrete NVIDIA GPU from D3cold suspend on terminal launch
if [[ -d "$SCRIPT_DIR/ptyxis" ]]; then
    install -m 755 "$SCRIPT_DIR/ptyxis/ptyxis" "$HOME/.local/bin/ptyxis"
    sed "s|@HOME@|$HOME|g" "$SCRIPT_DIR/ptyxis/org.gnome.Ptyxis.service" > "$HOME/.local/share/dbus-1/services/org.gnome.Ptyxis.service"
    install -m 644 "$SCRIPT_DIR/ptyxis/org.gnome.Ptyxis.desktop" "$HOME/.local/share/applications/org.gnome.Ptyxis.desktop"
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

# ==============================================================================
# Clipboard Indicator Extension Configuration
# ==============================================================================
CLIPBOARD_SCHEMAS="$HOME/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com/schemas"
if [[ -d "$CLIPBOARD_SCHEMAS" ]]; then
    gsettings --schemadir "$CLIPBOARD_SCHEMAS" set org.gnome.shell.extensions.clipboard-indicator toggle-menu "['<Super>v']" 2>/dev/null || true
    gsettings --schemadir "$CLIPBOARD_SCHEMAS" set org.gnome.shell.extensions.clipboard-indicator enable-keybindings true 2>/dev/null || true
fi
dconf write /org/gnome/shell/extensions/clipboard-indicator/toggle-menu "['<Super>v']" 2>/dev/null || true
dconf write /org/gnome/shell/extensions/clipboard-indicator/enable-keybindings true 2>/dev/null || true

# ------------------------------------------------------------------------------
# 8. Post-Setup Verification Suite
# ------------------------------------------------------------------------------
log_info "Running post-setup self-healing verification..."
python3 - << 'PYEOF'
import subprocess, os

checks = [
    ("Close Window (<Super>q)", ["gsettings", "get", "org.gnome.desktop.wm.keybindings", "close"], lambda v: "<Super>q" in v),
    ("Minimize (<Super>m)", ["gsettings", "get", "org.gnome.desktop.wm.keybindings", "minimize"], lambda v: "<Super>m" in v),
    ("Center Window (<Super>c)", ["gsettings", "get", "org.gnome.desktop.wm.keybindings", "move-to-center"], lambda v: "<Super>c" in v),
    ("Titlebar Buttons", ["gsettings", "get", "org.gnome.desktop.wm.preferences", "button-layout"], lambda v: "minimize,maximize,close" in v),
    ("Dark Mode", ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"], lambda v: "prefer-dark" in v),
    ("UI Font (Adwaita Sans)", ["gsettings", "get", "org.gnome.desktop.interface", "font-name"], lambda v: "Adwaita" in v),
    ("Mono Font (JetBrainsMono)", ["gsettings", "get", "org.gnome.desktop.interface", "monospace-font-name"], lambda v: "JetBrains" in v),
    ("Default Terminal Executable", ["which", "default-terminal"], lambda v: len(v.strip()) > 0),
]

all_passed = True
for name, cmd, validator in checks:
    try:
        val = subprocess.run(cmd, capture_output=True, text=True).stdout.strip()
        if validator(val):
            print(f"    ✓ {name}")
        else:
            print(f"    ⚠ {name} (current value: {val})")
            all_passed = False
    except Exception as e:
        print(f"    ✗ {name} failed check: {e}")
        all_passed = False

if all_passed:
    print("  [OK]   All GNOME desktop verifications passed flawlessly!")
else:
    print("  [WARN] Some settings may require GNOME Shell reload to display in UI.")
PYEOF

log_success "GNOME desktop setup and verification complete!"
