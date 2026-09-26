#!/usr/bin/env bash
# ==============================================================================
# GNOME Desktop & Terminal Optimizations Setup
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
else
    log_info()    { echo "[INFO] $*"; }
    log_success() { echo "[OK]   $*"; }
    log_warn()    { echo "[WARN] $*" >&2; }
    log_error()   { echo "[ERR]  $*" >&2; }
fi

# If invoked as root without --user-run, drop privileges to the desktop session user
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

    if [[ ! -S "$BUS_PATH" ]]; then
        log_warn "D-Bus session bus not found at $BUS_PATH. GNOME session might not be active for $TARGET_USER."
    fi

    log_info "Running GNOME configuration as user ${TARGET_USER} (UID: ${TARGET_UID})..."
    sudo -u "$TARGET_USER" -H env \
        HOME="$TARGET_HOME" \
        USER="$TARGET_USER" \
        XDG_RUNTIME_DIR="/run/user/${TARGET_UID}" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=${BUS_PATH}" \
        bash "$0" --user-run
    exit $?
fi

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
# Notifications Management
# ==============================================================================
gsettings set org.gnome.shell.keybindings focus-active-notification "[]"
gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>n']"

# ==============================================================================
# Unbind Dash-to-Dock shortcuts that conflict with Super+Q and workspace switching
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

# ==============================================================================
# Window Management
# ==============================================================================
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q', '<Alt>F4']"
gsettings set org.gnome.desktop.wm.keybindings move-to-side-w '[]'
gsettings set org.gnome.desktop.wm.keybindings move-to-side-e '[]'
gsettings set org.gnome.desktop.wm.keybindings move-to-center "['<Super>c']"

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
# Font Settings
# ==============================================================================
gsettings set org.gnome.desktop.interface font-name 'Ubuntu Nerd Font 11' 2>/dev/null || true
gsettings set org.gnome.desktop.interface document-font-name 'Ubuntu Nerd Font 11' 2>/dev/null || true

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

# Default terminal preference & launcher
gsettings set org.gnome.desktop.default-applications.terminal exec 'ghostty' 2>/dev/null || true

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.local/share/dbus-1/services"

# Install default-terminal launcher script
if [[ -f "$SCRIPT_DIR/default-terminal" ]]; then
    install -m 755 "$SCRIPT_DIR/default-terminal" "$HOME/.local/bin/default-terminal"
fi

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
# Clipboard Indicator Extension
# ==============================================================================
CLIPBOARD_SCHEMAS="$HOME/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com/schemas"
if [[ -d "$CLIPBOARD_SCHEMAS" ]]; then
    gsettings --schemadir "$CLIPBOARD_SCHEMAS" set org.gnome.shell.extensions.clipboard-indicator toggle-menu "['<Super>v']" 2>/dev/null || true
    gsettings --schemadir "$CLIPBOARD_SCHEMAS" set org.gnome.shell.extensions.clipboard-indicator enable-keybindings true 2>/dev/null || true
fi
dconf write /org/gnome/shell/extensions/clipboard-indicator/toggle-menu "['<Super>v']" 2>/dev/null || true

log_success "GNOME desktop settings applied successfully!"
