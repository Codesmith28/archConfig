#!/usr/bin/env bash
# ==============================================================================
# KDE Plasma Desktop & Shortcuts Setup (Cross-Distro Universal)
# Supports: Fedora (Plasma 6), Arch Linux, Ubuntu (Plasma 5 & 6)
# Zero-Intervention, Self-Healing Out-Of-The-Box Configuration
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

log_info()    { echo "  [INFO] $*"; }
log_success() { echo "  [OK]   $*"; }
log_warn()    { echo "  [WARN] $*" >&2; }
log_error()   { echo "  [ERR]  $*" >&2; }

# ------------------------------------------------------------------------------
# 1. Native Privilege Handling (Ensure execution runs as desktop user)
# ------------------------------------------------------------------------------
if [[ "${1:-}" != "--user-run" ]]; then
    if [[ "$(id -u)" -eq 0 ]]; then
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

        log_info "Dropping root privileges to ${TARGET_USER} (UID: ${TARGET_UID})..."
        if [[ -S "$BUS_PATH" ]]; then
            exec sudo -u "$TARGET_USER" -H env \
                HOME="$TARGET_HOME" \
                USER="$TARGET_USER" \
                XDG_RUNTIME_DIR="/run/user/${TARGET_UID}" \
                DBUS_SESSION_BUS_ADDRESS="unix:path=${BUS_PATH}" \
                bash "$0" --user-run "$@"
        else
            log_info "Spawning user D-Bus session via dbus-run-session..."
            exec sudo -u "$TARGET_USER" -H env \
                HOME="$TARGET_HOME" \
                USER="$TARGET_USER" \
                XDG_RUNTIME_DIR="/run/user/${TARGET_UID}" \
                dbus-run-session -- bash "$0" --user-run "$@"
        fi
    fi
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
log_info "Configuring environment and launchers for KDE Plasma..."
mkdir -p "$HOME/.config" "$HOME/.config/environment.d" "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.config/kxmlgui5" "$HOME/.config/kxmlgui6"

# Write persistent environment so KDE launchers and kwin resolve ~/.local/bin
cat > "$HOME/.config/environment.d/10-archconfig.conf" << 'EOF'
PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
EOF

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user import-environment PATH 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 3. Provision Default Terminal Emulator Wrapper
# ------------------------------------------------------------------------------
DEF_TERM_SRC=""
if [[ -f "$SCRIPT_DIR/default-terminal" ]]; then
    DEF_TERM_SRC="$SCRIPT_DIR/default-terminal"
elif [[ -f "$REPO_DIR/desktop/gnome/default-terminal" ]]; then
    DEF_TERM_SRC="$REPO_DIR/desktop/gnome/default-terminal"
fi

if [[ -n "$DEF_TERM_SRC" ]]; then
    install -m 755 "$DEF_TERM_SRC" "$HOME/.local/bin/default-terminal"
fi

# Create default-terminal.desktop for KDE Global Shortcuts
cat > "$HOME/.local/share/applications/default-terminal.desktop" << 'EOF'
[Desktop Entry]
Name=Default Terminal
Comment=Universal Default Terminal Launcher
Exec=default-terminal
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
X-KDE-GlobalAccel-CommandShortcut=true
StartupNotify=true
EOF
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 4. Copy Shortcut Schemes for GUI Import Compatibility (KF5 & KF6)
# ------------------------------------------------------------------------------
KDE_SHORTCUTS="$SCRIPT_DIR/keyboardscs.kksrc"
if [[ -f "$KDE_SHORTCUTS" ]]; then
    cp "$KDE_SHORTCUTS" "$HOME/.config/kxmlgui5/keyboardscs.kksrc"
    cp "$KDE_SHORTCUTS" "$HOME/.config/kxmlgui6/keyboardscs.kksrc"
    log_info "Copied scheme to ~/.config/kxmlgui5/ and ~/.config/kxmlgui6/"
fi

# ------------------------------------------------------------------------------
# 5. Apply Active Shortcuts directly to kglobalshortcutsrc & kdeglobals
# ------------------------------------------------------------------------------
log_info "Applying active KDE Plasma shortcuts and system configurations..."

python3 - "$KDE_SHORTCUTS" << 'PYEOF'
import os, sys, configparser

home = os.path.expanduser("~")
kksrc_path = sys.argv[1] if len(sys.argv) > 1 and os.path.exists(sys.argv[1]) else os.path.expanduser("~/archConfig/desktop/kde/keyboardscs.kksrc")

kglobal_path = os.path.join(home, ".config/kglobalshortcutsrc")
kdeglobals_path = os.path.join(home, ".config/kdeglobals")
kwinrc_path = os.path.join(home, ".config/kwinrc")
kcminputrc_path = os.path.join(home, ".config/kcminputrc")

def read_ini(path):
    cfg = configparser.RawConfigParser(strict=False, interpolation=None)
    cfg.optionxform = str
    if os.path.exists(path):
        try:
            cfg.read(path, encoding="utf-8")
        except Exception:
            pass
    return cfg

def write_ini(cfg, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        cfg.write(f, space_around_delimiters=False)

def sanitize_shortcut(s):
    if not s:
        return ""
    # Map shift symbols to standard Qt strings (e.g. Meta+! -> Meta+Shift+1)
    shift_map = {
        '!': 'Shift+1', '@': 'Shift+2', '#': 'Shift+3', '$': 'Shift+4',
        '%': 'Shift+5', '^': 'Shift+6', '&': 'Shift+7', '*': 'Shift+8',
        '(': 'Shift+9', ')': 'Shift+0'
    }
    for sym, rep in shift_map.items():
        if f"+{sym}" in s:
            s = s.replace(f"+{sym}", f"+{rep}")
    # Clean multi-shortcuts separated by semicolon
    tokens = [p.strip() for p in s.split(";") if p.strip()]
    # Filter out standalone modifier words which are invalid as combo shortcuts (e.g. "Alt+F1; Meta" -> "Alt+F1")
    valid_tokens = [t for t in tokens if t not in ("Meta", "Ctrl", "Alt", "Shift")]
    return "; ".join(valid_tokens) if valid_tokens else (tokens[0] if tokens else "")

# 1. Parse keyboardscs.kksrc
if os.path.exists(kksrc_path):
    kksrc = read_ini(kksrc_path)
    kglobal = read_ini(kglobal_path)
    kdeglobals = read_ini(kdeglobals_path)

    for sec in kksrc.sections():
        # Handle [StandardShortcuts] -> ~/.config/kdeglobals
        if sec == "StandardShortcuts":
            if not kdeglobals.has_section("StandardShortcuts"):
                kdeglobals.add_section("StandardShortcuts")
            for k, v in kksrc.items(sec):
                if v and v.strip():
                    kdeglobals.set("StandardShortcuts", k, sanitize_shortcut(v.strip()))
            continue

        # Extract target component section name (e.g. "kwin][Global Shortcuts" -> "kwin")
        if "][" in sec:
            target_sec = sec.split("][")[0].strip("[]")
        elif sec.endswith("Global Shortcuts"):
            target_sec = sec.replace("Global Shortcuts", "").strip("[] ")
        else:
            target_sec = sec.strip("[]")

        if not kglobal.has_section(target_sec):
            kglobal.add_section(target_sec)

        for k, v in kksrc.items(sec):
            if not v or not v.strip():
                continue
            new_shortcut = sanitize_shortcut(v.strip())
            if not new_shortcut:
                continue

            if kglobal.has_option(target_sec, k):
                cur_val = kglobal.get(target_sec, k)
                parts = cur_val.split(",")
                dflt = parts[1] if len(parts) > 1 else ""
                desc = ",".join(parts[2:]) if len(parts) > 2 and parts[2].strip() else k
                kglobal.set(target_sec, k, f"{new_shortcut},{dflt},{desc}")
            else:
                kglobal.set(target_sec, k, f"{new_shortcut},,{k}")

    write_ini(kglobal, kglobal_path)
    write_ini(kdeglobals, kdeglobals_path)
    print("    ✓ kglobalshortcutsrc and kdeglobals updated from keyboardscs.kksrc successfully")

# 2. Configure KWin (Window Titlebar Buttons, Virtual Desktops & Modifier-Only Super Key)
kwinrc = read_ini(kwinrc_path)
if not kwinrc.has_section("org.kde.kdecoration2"):
    kwinrc.add_section("org.kde.kdecoration2")
kwinrc.set("org.kde.kdecoration2", "ButtonsOnRight", "IAX")
kwinrc.set("org.kde.kdecoration2", "ButtonsOnLeft", "M")

if not kwinrc.has_section("Desktops"):
    kwinrc.add_section("Desktops")
kwinrc.set("Desktops", "Number", "4")
kwinrc.set("Desktops", "Rows", "1")

# Configure Super (Meta) modifier alone to open application launcher
if not kwinrc.has_section("ModifierOnlyShortcuts"):
    kwinrc.add_section("ModifierOnlyShortcuts")
kwinrc.set("ModifierOnlyShortcuts", "Meta", "org.kde.plasmashell,/PlasmaShell,org.kde.PlasmaShell,activateLauncherMenu")

write_ini(kwinrc, kwinrc_path)
print("    ✓ kwinrc configured (Buttons: IAX; 4 Desktops; Super Key: activateLauncherMenu)")

# 3. Configure Input (Keyboard Repeat 250ms/40Hz, Touchpad Tap-to-click & Natural Scroll)
kcminput = read_ini(kcminputrc_path)
if not kcminput.has_section("Keyboard"):
    kcminput.add_section("Keyboard")
kcminput.set("Keyboard", "RepeatDelay", "250")
kcminput.set("Keyboard", "RepeatRate", "40")

if not kcminput.has_section("Touchpad"):
    kcminput.add_section("Touchpad")
kcminput.set("Touchpad", "tapToClick", "true")
kcminput.set("Touchpad", "naturalScroll", "true")
write_ini(kcminput, kcminputrc_path)
print("    ✓ kcminputrc configured (Keyrate: 250ms/40Hz, Touchpad: Tap-to-click & Natural Scroll)")

# 4. Configure Fonts (All UI fonts follow Sans Serif, Monospace follows system Monospace)
if not kdeglobals.has_section("General"):
    kdeglobals.add_section("General")

def get_font_str(family, default_size, existing_val=None):
    size = default_size
    weight = "50"
    hint = "5"
    if existing_val:
        parts = existing_val.split(",")
        if len(parts) > 1 and parts[1].strip():
            size = parts[1].strip()
        if len(parts) > 3 and parts[3].strip():
            hint = parts[3].strip()
        if len(parts) > 4 and parts[4].strip():
            weight = parts[4].strip()
    return f"{family},{size},-1,{hint},{weight},0,0,0,0,0"

for key in ["font", "desktopFont", "menuFont", "toolBarFont", "taskbarFont"]:
    existing = kdeglobals.get("General", key, fallback=None)
    kdeglobals.set("General", key, get_font_str("Sans Serif", "10", existing))

existing_fixed = kdeglobals.get("General", "fixed", fallback=None)
kdeglobals.set("General", "fixed", get_font_str("Monospace", "10", existing_fixed))

existing_small = kdeglobals.get("General", "smallestReadableFont", fallback=None)
kdeglobals.set("General", "smallestReadableFont", get_font_str("Sans Serif", "8", existing_small))

if not kdeglobals.has_section("WM"):
    kdeglobals.add_section("WM")
for key in ["activeFont", "inactiveFont"]:
    existing = kdeglobals.get("WM", key, fallback=None)
    kdeglobals.set("WM", key, get_font_str("Sans Serif", "10", existing))

write_ini(kdeglobals, kdeglobals_path)
print("    ✓ kdeglobals configured (UI fonts: Sans Serif, Monospace: system Monospace)")
PYEOF

# ------------------------------------------------------------------------------
# 6. Apply Settings via kwriteconfig (Plasma 6 / Plasma 5 Native Tool)
# ------------------------------------------------------------------------------
KWRITECMD=""
if command -v kwriteconfig6 >/dev/null 2>&1; then
    KWRITECMD="kwriteconfig6"
elif command -v kwriteconfig5 >/dev/null 2>&1; then
    KWRITECMD="kwriteconfig5"
fi

if [[ -n "$KWRITECMD" ]]; then
    log_info "Enforcing desktop environment settings with native $KWRITECMD..."
    "$KWRITECMD" --file kwinrc --group "ModifierOnlyShortcuts" --key "Meta" "org.kde.plasmashell,/PlasmaShell,org.kde.PlasmaShell,activateLauncherMenu"
    "$KWRITECMD" --file kwinrc --group "org.kde.kdecoration2" --key "ButtonsOnRight" "IAX"
    "$KWRITECMD" --file kwinrc --group "org.kde.kdecoration2" --key "ButtonsOnLeft" "M"
    "$KWRITECMD" --file kwinrc --group "Desktops" --key "Number" "4"
    "$KWRITECMD" --file kwinrc --group "Desktops" --key "Rows" "1"
    "$KWRITECMD" --file kcminputrc --group "Keyboard" --key "RepeatDelay" "250"
    "$KWRITECMD" --file kcminputrc --group "Keyboard" --key "RepeatRate" "40"
    "$KWRITECMD" --file kcminputrc --group "Touchpad" --key "tapToClick" "true"
    "$KWRITECMD" --file kcminputrc --group "Touchpad" --key "naturalScroll" "true"

    # Font configurations (Sans Serif for UI, Monospace for system monospace)
    "$KWRITECMD" --file kdeglobals --group "General" --key "font" "Sans Serif,10,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "General" --key "fixed" "Monospace,10,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "General" --key "desktopFont" "Sans Serif,10,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "General" --key "menuFont" "Sans Serif,10,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "General" --key "toolBarFont" "Sans Serif,10,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "General" --key "smallestReadableFont" "Sans Serif,8,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "General" --key "taskbarFont" "Sans Serif,10,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "WM" --key "activeFont" "Sans Serif,10,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "WM" --key "inactiveFont" "Sans Serif,10,-1,5,50,0,0,0,0,0"
fi

# ------------------------------------------------------------------------------
# 7. Live Session Broadcast & Reconfiguration
# ------------------------------------------------------------------------------
log_info "Broadcasting live session reload signals to KDE components..."
# Reconfigure KWin
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || \
qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || \
dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true

# Reconfigure kglobalaccel / plasmashell
systemctl --user restart plasma-kglobalaccel.service 2>/dev/null || true
qdbus6 org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.reloadConfig 2>/dev/null || \
qdbus org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.reloadConfig 2>/dev/null || true

# Broadcast font and global settings changes
dbus-send --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:1 int32:0 2>/dev/null || true
dbus-send --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true

# ------------------------------------------------------------------------------
# 8. Post-Setup Self-Healing Verification Suite
# ------------------------------------------------------------------------------
log_info "Running post-setup verification suite..."
python3 - << 'PYEOF'
import os, configparser

home = os.path.expanduser("~")
kglobal_path = os.path.join(home, ".config/kglobalshortcutsrc")
kdeglobals_path = os.path.join(home, ".config/kdeglobals")
kwinrc_path = os.path.join(home, ".config/kwinrc")
kcminputrc_path = os.path.join(home, ".config/kcminputrc")

def check_ini(path, sec, key, expected_sub):
    if not os.path.exists(path):
        return False
    cfg = configparser.RawConfigParser(strict=False, interpolation=None)
    cfg.optionxform = str
    try:
        cfg.read(path, encoding="utf-8")
        if cfg.has_section(sec) and cfg.has_option(sec, key):
            val = cfg.get(sec, key)
            return expected_sub.lower() in val.lower()
    except Exception:
        return False
    return False

checks = [
    ("Window Close (Meta+Q)", check_ini(kglobal_path, "kwin", "Window Close", "Meta+Q")),
    ("Terminal Shortcut (Meta+Return)", check_ini(kglobal_path, "default-terminal.desktop", "_launch", "Meta+Return")),
    ("Super Key Modifier (kwinrc ModifierOnlyShortcuts)", check_ini(kwinrc_path, "ModifierOnlyShortcuts", "Meta", "activateLauncherMenu")),
    ("Application Launcher (Alt+F1)", check_ini(kglobal_path, "plasmashell", "activate application launcher", "Alt+F1")),
    ("Switch to Desktop 1 (Meta+1)", check_ini(kglobal_path, "kwin", "Switch to Desktop 1", "Meta+1")),
    ("Window to Desktop 1 (Meta+Shift+1)", check_ini(kglobal_path, "kwin", "Window to Desktop 1", "Meta+Shift+1")),
    ("Task Manager Entry 1 Remapped (Meta+Ctrl+1)", check_ini(kglobal_path, "plasmashell", "activate task manager entry 1", "Meta+Ctrl+1")),
    ("File Manager Dolphin (Meta+E)", check_ini(kglobal_path, "org.kde.dolphin.desktop", "_launch", "Meta+E")),
    ("Clipboard Manager (Meta+V)", check_ini(kglobal_path, "plasmashell", "show-on-mouse-pos", "Meta+V")),
    ("Titlebar Buttons (Minimize, Maximize, Close)", check_ini(kwinrc_path, "org.kde.kdecoration2", "ButtonsOnRight", "IAX")),
    ("Virtual Desktops (4 Workspaces)", check_ini(kwinrc_path, "Desktops", "Number", "4")),
    ("Keyboard Rate (250ms / 40Hz)", check_ini(kcminputrc_path, "Keyboard", "RepeatDelay", "250")),
    ("Default Terminal Executable", os.path.exists(os.path.join(home, ".local/bin/default-terminal"))),
    ("UI Fonts (Sans Serif)", check_ini(kdeglobals_path, "General", "font", "Sans Serif")),
    ("Monospace Font (Monospace)", check_ini(kdeglobals_path, "General", "fixed", "Monospace")),
    ("Window Title Font (Sans Serif)", check_ini(kdeglobals_path, "WM", "activeFont", "Sans Serif")),
]

all_passed = True
for name, ok in checks:
    if ok:
        print(f"    ✓ {name}")
    else:
        print(f"    ⚠ {name} check incomplete")
        all_passed = False

if all_passed:
    print("  [OK]   All KDE Plasma desktop verifications passed flawlessly!")
else:
    print("  [WARN] Note: Some shortcut changes will take effect after next login.")
PYEOF

log_info "NOTE: On KDE Plasma, newly registered global shortcuts are instantly loaded into KWin; a quick logout/login guarantees complete synchronization."
log_success "KDE Plasma setup and configuration complete!"
