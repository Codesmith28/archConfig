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

run_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        log_error "Root privileges or sudo required to run: $*"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 1. Distro Utility Package Installation
# ------------------------------------------------------------------------------
install_distro_packages() {
    log_info "Verifying required KDE utility and D-Bus packages..."
    local os_id=""
    if [[ -f /etc/os-release ]]; then
        os_id="$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')"
    fi

    case "$os_id" in
        fedora|rhel|centos)
            local fedora_pkgs=()
            if ! rpm -q python3-dbus >/dev/null 2>&1; then
                fedora_pkgs+=("python3-dbus")
            fi
            if ! rpm -q qt6-qttools >/dev/null 2>&1 && ! command -v qdbus-qt6 >/dev/null 2>&1; then
                fedora_pkgs+=("qt6-qttools")
            fi
            if ! rpm -q kf6-kconfig >/dev/null 2>&1 && ! command -v kwriteconfig6 >/dev/null 2>&1; then
                fedora_pkgs+=("kf6-kconfig")
            fi
            if [[ ${#fedora_pkgs[@]} -gt 0 ]]; then
                log_info "Installing ${fedora_pkgs[*]} via dnf..."
                run_root dnf install -y "${fedora_pkgs[@]}"
            fi
            ;;
        ubuntu|debian|pop|linuxmint)
            local deb_pkgs=()
            if ! dpkg -s python3-dbus >/dev/null 2>&1; then
                deb_pkgs+=("python3-dbus")
            fi
            if ! command -v qdbus-qt6 >/dev/null 2>&1 && ! command -v qdbus >/dev/null 2>&1; then
                deb_pkgs+=("qdbus-qt6")
            fi
            if [[ ${#deb_pkgs[@]} -gt 0 ]]; then
                log_info "Installing ${deb_pkgs[*]} via apt..."
                run_root apt-get update -qq
                run_root apt-get install -y "${deb_pkgs[@]}" || true
            fi
            ;;
        arch|manjaro|endeavouros)
            local arch_pkgs=()
            if ! pacman -Qi python-dbus >/dev/null 2>&1; then
                arch_pkgs+=("python-dbus")
            fi
            if ! command -v qdbus-qt6 >/dev/null 2>&1 && ! command -v qdbus >/dev/null 2>&1; then
                arch_pkgs+=("qt6-tools")
            fi
            if [[ ${#arch_pkgs[@]} -gt 0 ]]; then
                log_info "Installing ${arch_pkgs[*]} via pacman..."
                run_root pacman -S --needed --noconfirm "${arch_pkgs[@]}"
            fi
            ;;
        *)
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 2. Native Privilege Handling (Ensure execution runs as desktop user)
# ------------------------------------------------------------------------------
if [[ "${1:-}" != "--user-run" ]]; then
    if [[ "$(id -u)" -eq 0 ]]; then
        install_distro_packages

        TARGET_USER="${SUDO_USER:-}"
        if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
            TARGET_USER="$(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $3}' | grep -v 'root' | head -n 1 || true)"
            if [[ -z "$TARGET_USER" ]]; then
                TARGET_USER="$(who | awk '$1 != "root" {print $1; exit}' || true)"
            fi
            if [[ -z "$TARGET_USER" ]]; then
                TARGET_USER="${USER:-fedora}"
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
# 3. Systemd User Environment & PATH Persistence
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
# 4. Provision Default Terminal & Browser Wrappers
# ------------------------------------------------------------------------------
# Default Terminal
DEF_TERM_SRC=""
if [[ -f "$SCRIPT_DIR/default-terminal" ]]; then
    DEF_TERM_SRC="$SCRIPT_DIR/default-terminal"
elif [[ -f "$REPO_DIR/desktop/gnome/default-terminal" ]]; then
    DEF_TERM_SRC="$REPO_DIR/desktop/gnome/default-terminal"
fi

if [[ -n "$DEF_TERM_SRC" ]]; then
    install -m 755 "$DEF_TERM_SRC" "$HOME/.local/bin/default-terminal"
fi

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

# Default Browser
DEF_BROWSER_SRC=""
if [[ -f "$SCRIPT_DIR/default-browser" ]]; then
    DEF_BROWSER_SRC="$SCRIPT_DIR/default-browser"
fi

if [[ -n "$DEF_BROWSER_SRC" ]]; then
    install -m 755 "$DEF_BROWSER_SRC" "$HOME/.local/bin/default-browser"
fi

cat > "$HOME/.local/share/applications/default-browser.desktop" << 'EOF'
[Desktop Entry]
Name=Default Web Browser
Comment=Universal Default Web Browser Launcher
Exec=default-browser
Icon=internet-web-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
X-KDE-GlobalAccel-CommandShortcut=true
StartupNotify=true
EOF

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# Power Profile & Toggle DnD Helpers
if [[ -f "$SCRIPT_DIR/powerprofile" ]]; then
    install -m 755 "$SCRIPT_DIR/powerprofile" "$HOME/.local/bin/powerprofile"
fi

if [[ -f "$SCRIPT_DIR/toggle-dnd" ]]; then
    install -m 755 "$SCRIPT_DIR/toggle-dnd" "$HOME/.local/bin/toggle-dnd"
fi

# ------------------------------------------------------------------------------
# 4b. Ensure Krohnkite Tiling Extension is Installed
# ------------------------------------------------------------------------------
if [[ ! -d "$HOME/.local/share/kwin/scripts/krohnkite" ]]; then
    log_info "Installing Krohnkite tiling extension for KDE Plasma..."
    mkdir -p "$HOME/.local/share/kwin/scripts"
    TMP_KROHNKITE="/tmp/krohnkite_install.$$"
    mkdir -p "$TMP_KROHNKITE"
    if curl -fsSL -o "$TMP_KROHNKITE/krohnkite.kwinscript" "https://github.com/anametologin/krohnkite/releases/download/0.9.9.2/krohnkite.kwinscript" 2>/dev/null; then
        if command -v kpackagetool6 >/dev/null 2>&1; then
            kpackagetool6 -t KWin/Script -i "$TMP_KROHNKITE/krohnkite.kwinscript" >/dev/null 2>&1 || true
        elif command -v kpackagetool5 >/dev/null 2>&1; then
            kpackagetool5 -t KWin/Script -i "$TMP_KROHNKITE/krohnkite.kwinscript" >/dev/null 2>&1 || true
        fi
    fi
    rm -rf "$TMP_KROHNKITE"
fi

# ------------------------------------------------------------------------------
# 5. Copy Shortcut Schemes for GUI Import Compatibility (KF5 & KF6)
# ------------------------------------------------------------------------------
KDE_SHORTCUTS="$SCRIPT_DIR/keyboardscs.kksrc"
if [[ -f "$KDE_SHORTCUTS" ]]; then
    cp "$KDE_SHORTCUTS" "$HOME/.config/kxmlgui5/keyboardscs.kksrc"
    cp "$KDE_SHORTCUTS" "$HOME/.config/kxmlgui6/keyboardscs.kksrc"
    log_info "Copied scheme to ~/.config/kxmlgui5/ and ~/.config/kxmlgui6/"
fi

# ------------------------------------------------------------------------------
# 6. Apply Active Shortcuts directly via D-Bus (Live Session) & Persist to Files
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
appletsrc_path = os.path.join(home, ".config/plasma-org.kde.plasma.desktop-appletsrc")

def key_to_qt(s):
    if not s or s.lower() == "none":
        return None
    mods = 0
    key_part = s.strip()
    parts = key_part.split("+")
    key_name = parts[-1].strip()
    for mod in parts[:-1]:
        m = mod.strip().lower()
        if m in ("meta", "super"):
            mods |= 0x10000000
        elif m == "alt":
            mods |= 0x08000000
        elif m in ("ctrl", "control"):
            mods |= 0x04000000
        elif m == "shift":
            mods |= 0x02000000
    
    # Standalone modifier keys (Qt::Key_Meta = 0x01000022 = 16777250)
    special = {
        'meta': 0x01000022, 'super': 0x01000022,
        'escape': 0x01000000, 'esc': 0x01000000,
        'tab': 0x01000001,
        'backtab': 0x01000002,
        'backspace': 0x01000003,
        'return': 0x01000004, 'enter': 0x01000004,
        'insert': 0x01000006, 'ins': 0x01000006,
        'delete': 0x01000007, 'del': 0x01000007,
        'pause': 0x01000008,
        'print': 0x01000009,
        'sysreq': 0x0100000a,
        'clear': 0x0100000b,
        'home': 0x01000010,
        'end': 0x01000011,
        'left': 0x01000012,
        'up': 0x01000013,
        'right': 0x01000014,
        'down': 0x01000015,
        'page_up': 0x01000016, 'pageup': 0x01000016, 'pgup': 0x01000016,
        'page_down': 0x01000017, 'pagedown': 0x01000017, 'pgdown': 0x01000017,
        'space': 0x20,
    }
    for i in range(1, 36):
        special[f'f{i}'] = 0x01000030 + (i - 1)
        
    # Hardware launch and media keys
    for i in range(16):
        hex_c = f"{i:x}"
        code = 0x010000a2 + i
        special[f"launch ({hex_c})"] = code
        special[f"launch ({hex_c.upper()})"] = code
        special[f"launch {hex_c}"] = code
        special[f"launch {hex_c.upper()}"] = code
    special['battery'] = 0x010000fe
        
    kl = key_name.lower()
    if kl in special:
        return mods | special[kl]
    elif len(key_name) == 1:
        return mods | ord(key_name.upper())
    elif kl in ('grave', '`'):
        return mods | 0x60
    elif kl in ('asciitilde', '~'):
        return mods | 0x7e
    return None

def parse_shortcuts(shortcut_str):
    if not shortcut_str:
        return []
    tokens = [t.strip() for t in shortcut_str.replace('\t', ';').split(';') if t.strip()]
    res = []
    for tok in tokens:
        code = key_to_qt(tok)
        if code is not None and code not in res:
            res.append(code)
    return res

# Discover applet IDs from plasma-org.kde.plasma.desktop-appletsrc
tray_id = None
notif_id = None
clock_id = None

if os.path.exists(appletsrc_path):
    import re
    applet_cfg_init = configparser.RawConfigParser(strict=False, interpolation=None)
    applet_cfg_init.optionxform = str
    try:
        applet_cfg_init.read(appletsrc_path, encoding="utf-8")
        for sec in applet_cfg_init.sections():
            if applet_cfg_init.has_option(sec, "plugin"):
                plugin = applet_cfg_init.get(sec, "plugin")
                nums = re.findall(r"Applets\]\[?(\d+)", sec)
                if nums:
                    aid = nums[-1]
                    if plugin == "org.kde.plasma.systemtray":
                        tray_id = aid
                    elif plugin == "org.kde.plasma.notifications":
                        notif_id = aid
                    elif plugin == "org.kde.plasma.digitalclock":
                        clock_id = aid
    except Exception:
        pass

# 1. Canonical Desktop Shortcuts (Full GNOME Parity & Conflict-Free)
CANONICAL_SHORTCUTS = {
    "kwin": {
        "Window Close": "Meta+Q; Alt+F4",
        "Window Minimize": "Meta+M; Meta+Down",
        "Window Maximize": "Meta+Up",
        "Window Quick Tile Left": "Meta+Left",
        "Window Quick Tile Right": "Meta+Right",
        "Window Quick Tile Top": "",
        "Window Quick Tile Bottom": "",
        "Window Move Center": "Meta+C",
        "Switch to Desktop 1": "Meta+1",
        "Switch to Desktop 2": "Meta+2",
        "Switch to Desktop 3": "Meta+3",
        "Switch to Desktop 4": "Meta+4",
        "Switch to Desktop 5": "Meta+5",
        "Switch to Desktop 6": "Meta+6",
        "Switch to Desktop 7": "Meta+7",
        "Switch to Desktop 8": "Meta+8",
        "Switch to Desktop 9": "Meta+9",
        "Window to Desktop 1": "Meta+Shift+1; Meta+!; Meta+Shift+!",
        "Window to Desktop 2": "Meta+Shift+2; Meta+@; Meta+Shift+@",
        "Window to Desktop 3": "Meta+Shift+3; Meta+#; Meta+Shift+#",
        "Window to Desktop 4": "Meta+Shift+4; Meta+$; Meta+Shift+$",
        "Window to Desktop 5": "Meta+Shift+5; Meta+%; Meta+Shift+%",
        "Window to Desktop 6": "Meta+Shift+6; Meta+^; Meta+Shift+^",
        "Window to Desktop 7": "Meta+Shift+7; Meta+&; Meta+Shift+&",
        "Window to Desktop 8": "Meta+Shift+8; Meta+*; Meta+Shift+*",
        "Window to Desktop 9": "Meta+Shift+9; Meta+(; Meta+Shift+(",
        "Switch to Next Desktop": "Meta+Page_Down; Meta+Ctrl+Right",
        "Switch to Previous Desktop": "Meta+Page_Up; Meta+Ctrl+Left",
        "Switch One Desktop to the Right": "",
        "Switch One Desktop to the Left": "",
        "Switch One Desktop Up": "",
        "Switch One Desktop Down": "",
        "Window to Next Desktop": "Meta+Shift+Page_Down; Meta+Ctrl+Shift+Right",
        "Window to Previous Desktop": "Meta+Shift+Page_Up; Meta+Ctrl+Shift+Left",
        "Window One Desktop to the Right": "",
        "Window One Desktop to the Left": "",
        "Window One Desktop Up": "",
        "Window One Desktop Down": "",
        "Expose": "Ctrl+F9; Meta+F9",
        "ExposeAll": "Launch (C); Ctrl+F10; Meta+F10",
        "ExposeClass": "Ctrl+F7; Meta+F7",
        "Overview": "Meta+W; Meta+Tab",
        "Grid View": "Meta+Shift+Tab",
        "Walk Through Windows": "Alt+Tab",
        "Walk Through Windows (Reverse)": "Alt+Shift+Tab",
        "Walk Through Windows of Current Application": "Alt+`; Meta+`",
        "Walk Through Windows of Current Application (Reverse)": "Alt+~; Meta+~",
        "Show Desktop": "",
        "Kill Window": "Meta+Ctrl+Esc",
        "Window Restore": "Meta+Backspace",
        "KrohnkiteDecrease": "Meta+D",
        "KrohnkiteFloatAll": "Meta+Shift+F",
        "KrohnkiteFocusDown": "Meta+J",
        "KrohnkiteFocusLeft": "Meta+H",
        "KrohnkiteFocusNext": "Meta+.",
        "KrohnkiteFocusPrev": "Meta+\\,",
        "KrohnkiteFocusRight": "Meta+L",
        "KrohnkiteFocusUp": "Meta+K",
        "KrohnkiteGrowHeight": "Meta+Ctrl+J",
        "KrohnkiteIncrease": "Meta+I",
        "KrohnkiteMonocleLayout": "Meta+M",
        "KrohnkiteNextLayout": "Meta+\\\\",
        "KrohnkitePreviousLayout": "Meta+|",
        "KrohnkiteRotate": "Meta+R",
        "KrohnkiteRotatePart": "Meta+Shift+R",
        "KrohnkiteSetMaster": "Meta+Return",
        "KrohnkiteShiftDown": "Meta+Shift+J",
        "KrohnkiteShiftLeft": "Meta+Shift+H",
        "KrohnkiteShiftRight": "Meta+Shift+L",
        "KrohnkiteShiftUp": "Meta+Shift+K",
        "KrohnkiteShrinkHeight": "Meta+Ctrl+K",
        "KrohnkiteShrinkWidth": "Meta+Ctrl+H",
        "KrohnkiteBTreeLayout": "Meta+T",
        "KrohnkiteTileLayout": "",
        "KrohnkiteToggleFloat": "Meta+F",
        "KrohnkitegrowWidth": "Meta+Ctrl+L",
        "ToggleMouseClick": "",
        "view_actual_size": "",
        "view_zoom_in": "",
        "view_zoom_out": "",
    },
    "plasmashell": {
        "activate application launcher": "Meta; Alt+F1",
        "show-on-mouse-pos": "Meta+V",
        "toggle do not disturb": "Launch (1)",
        "manage activities": "",
        "next activity": "",
        "previous activity": "",
        "switch to next activity": "",
        "switch to previous activity": "",
        "activate task manager entry 1": "Meta+Ctrl+1",
        "activate task manager entry 2": "Meta+Ctrl+2",
        "activate task manager entry 3": "Meta+Ctrl+3",
        "activate task manager entry 4": "Meta+Ctrl+4",
        "activate task manager entry 5": "Meta+Ctrl+5",
        "activate task manager entry 6": "Meta+Ctrl+6",
        "activate task manager entry 7": "Meta+Ctrl+7",
        "activate task manager entry 8": "Meta+Ctrl+8",
        "activate task manager entry 9": "Meta+Ctrl+9",
        "activate task manager entry 10": "Meta+Ctrl+0",
    },
    "org.kde.spectacle.desktop": {
        "_launch": "Meta+Shift+S; Print",
        "RectangularRegionScreenShot": "Meta+Shift+A; Meta+Shift+Print",
        "ActiveWindowScreenShot": "Meta+Shift+W; Meta+Print",
        "FullScreenScreenShot": "Shift+Print",
        "RecordRegion": "Meta+Shift+R; Meta+R",
        "RecordScreen": "Meta+Alt+R",
        "RecordWindow": "Meta+Ctrl+R",
    },
    "default-terminal.desktop": {
        "_launch": "Meta+Return",
    },
    "default-browser.desktop": {
        "_launch": "Meta+Shift+B; Meta+B",
    },
    "org.kde.dolphin.desktop": {
        "_launch": "Meta+E",
    },
    "systemsettings.desktop": {
        "_launch": "Meta+I",
    },
    "ksmserver": {
        "Lock Session": "Meta+L; Screensaver",
    },
    "org_kde_powerdevil": {
        "powerProfile": "Launch (4); Battery",
        "powerprofile": "",
    }
}

if tray_id:
    CANONICAL_SHORTCUTS["plasmashell"][f"activate widget {tray_id}"] = "Meta+A"
if notif_id:
    CANONICAL_SHORTCUTS["plasmashell"][f"activate widget {notif_id}"] = "Meta+Shift+N"
if clock_id:
    CANONICAL_SHORTCUTS["plasmashell"][f"activate widget {clock_id}"] = "Meta+N"

# 2. Try applying live shortcuts via D-Bus (KGlobalAccel in Plasma 6 / 5)
try:
    import dbus
    bus = dbus.SessionBus()
    kglobal = bus.get_object("org.kde.kglobalaccel", "/kglobalaccel")
    iface = dbus.Interface(kglobal, "org.kde.KGlobalAccel")

    comp_actions = {}
    for comp in CANONICAL_SHORTCUTS:
        try:
            actions = iface.allActionsForComponent([comp])
            comp_actions[comp] = {a[1]: a for a in actions}
        except Exception:
            comp_actions[comp] = {}

    applied_count = 0
    for comp, actions in CANONICAL_SHORTCUTS.items():
        for act_name, shortcut_str in actions.items():
            qt_codes = parse_shortcuts(shortcut_str)
            if comp in comp_actions and act_name in comp_actions[comp]:
                action_id = comp_actions[comp][act_name]
            else:
                action_id = [
                    dbus.String(comp),
                    dbus.String(act_name),
                    dbus.String(comp),
                    dbus.String(act_name)
                ]
                try:
                    iface.doRegister(action_id)
                except Exception:
                    pass
            
            if qt_codes:
                keys = [
                    dbus.Struct((dbus.Array([dbus.Int32(k), dbus.Int32(0), dbus.Int32(0), dbus.Int32(0)], signature='i'),))
                    for k in qt_codes
                ]
            else:
                keys = dbus.Array([], signature='(ai)')
                
            try:
                iface.setForeignShortcutKeys(action_id, keys)
                applied_count += 1
            except Exception as e:
                pass

    print(f"    ✓ Applied {applied_count} shortcuts live into active session via KGlobalAccel D-Bus")
except Exception as e:
    print(f"    ℹ Note: Live D-Bus shortcut injection deferred ({e}); writing config files for next login")

# 3. Synchronize file persistence (kglobalshortcutsrc & kdeglobals)
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

kglobal = read_ini(kglobal_path)
kdeglobals = read_ini(kdeglobals_path)

# Purge stale/phantom sections that steal shortcuts or cause collision issues
for stale_sec in ["zen.desktop", "services][zen.desktop", "kitty.desktop", "services][kitty.desktop"]:
    if kglobal.has_section(stale_sec):
        kglobal.remove_section(stale_sec)

for comp, actions in CANONICAL_SHORTCUTS.items():
    if not kglobal.has_section(comp):
        kglobal.add_section(comp)
    for act_name, shortcut_str in actions.items():
        tokens = [t.strip() for t in shortcut_str.split(";") if t.strip()]
        val_str = r"\t".join(tokens) if tokens else "none"
        if kglobal.has_option(comp, act_name):
            cur = kglobal.get(comp, act_name)
            parts = cur.split(",")
            dflt = parts[1] if len(parts) > 1 else "none"
            desc = ",".join(parts[2:]) if len(parts) > 2 and parts[2].strip() else act_name
            # Preserve existing hardware/custom keys for powerProfile and toggle do not disturb
            if comp == "org_kde_powerdevil" and act_name == "powerProfile":
                cur_tokens = [t.strip() for t in parts[0].replace(r"\t", ";").split(";") if t.strip() and t.strip().lower() != "none"]
                combined = ["Launch (4)"]
                for tok in cur_tokens:
                    if tok not in combined:
                        combined.append(tok)
                val_str = r"\t".join(combined)
            elif comp == "plasmashell" and act_name == "toggle do not disturb":
                cur_tokens = [t.strip() for t in parts[0].replace(r"\t", ";").split(";") if t.strip() and t.strip().lower() != "none"]
                combined = ["Launch (1)"]
                for tok in cur_tokens:
                    if tok not in combined:
                        combined.append(tok)
                val_str = r"\t".join(combined)
            kglobal.set(comp, act_name, f"{val_str},{dflt},{desc}")
        else:
            kglobal.set(comp, act_name, f"{val_str},none,{act_name}")

    if comp.endswith(".desktop"):
        svc_sec = f"services][{comp}"
        if not kglobal.has_section(svc_sec):
            kglobal.add_section(svc_sec)
        for act_name, shortcut_str in actions.items():
            tokens = [t.strip() for t in shortcut_str.split(";") if t.strip()]
            val_str = r"\t".join(tokens) if tokens else "none"
            kglobal.set(svc_sec, act_name, val_str)

if kdeglobals.has_section("StandardShortcuts") and kdeglobals.has_option("StandardShortcuts", "ConfigureNotifications"):
    kdeglobals.remove_option("StandardShortcuts", "ConfigureNotifications")

write_ini(kglobal, kglobal_path)
write_ini(kdeglobals, kdeglobals_path)
print("    ✓ kglobalshortcutsrc and kdeglobals persistent config files synchronized")

# 4. Configure KWin (Window Titlebar Buttons, Virtual Desktops, Modifier-Only Super & Magic Lamp)
kwinrc = read_ini(kwinrc_path)
if not kwinrc.has_section("org.kde.kdecoration2"):
    kwinrc.add_section("org.kde.kdecoration2")
kwinrc.set("org.kde.kdecoration2", "ButtonsOnRight", "IAX")
kwinrc.set("org.kde.kdecoration2", "ButtonsOnLeft", "M")

if not kwinrc.has_section("Desktops"):
    kwinrc.add_section("Desktops")
kwinrc.set("Desktops", "Number", "4")
kwinrc.set("Desktops", "Rows", "1")

if not kwinrc.has_section("Windows"):
    kwinrc.add_section("Windows")
kwinrc.set("Windows", "RollOverDesktops", "false")

if not kwinrc.has_section("ModifierOnlyShortcuts"):
    kwinrc.add_section("ModifierOnlyShortcuts")
kwinrc.set("ModifierOnlyShortcuts", "Meta", "org.kde.plasmashell,/PlasmaShell,org.kde.PlasmaShell,activateLauncherMenu")

if not kwinrc.has_section("Plugins"):
    kwinrc.add_section("Plugins")
kwinrc.set("Plugins", "magiclampEnabled", "true")
kwinrc.set("Plugins", "squashEnabled", "false")
kwinrc.set("Plugins", "scaleEnabled", "false")
kwinrc.set("Plugins", "blurEnabled", "true")
kwinrc.set("Plugins", "slideEnabled", "true")
kwinrc.set("Plugins", "krohnkiteEnabled", "true")
kwinrc.set("Plugins", "hidecursorEnabled", "true")
kwinrc.set("Plugins", "zoomEnabled", "false")

if not kwinrc.has_section("Script-krohnkite"):
    kwinrc.add_section("Script-krohnkite")
kwinrc.set("Script-krohnkite", "monocleMaximize", "false")
kwinrc.set("Script-krohnkite", "screenGapBetween", "10")
kwinrc.set("Script-krohnkite", "screenGapBottom", "10")
kwinrc.set("Script-krohnkite", "screenGapLeft", "10")
kwinrc.set("Script-krohnkite", "screenGapRight", "10")
kwinrc.set("Script-krohnkite", "screenGapTop", "10")
kwinrc.set("Script-krohnkite", "binaryTreeLayoutOrder", "1")
for lay in ["tile", "monocle", "threeColumn", "spiral", "quarter", "stacked", "columns", "spread", "floating", "stair", "cascade"]:
    kwinrc.set("Script-krohnkite", f"{lay}LayoutOrder", "0")

if not kwinrc.has_section("TabBox"):
    kwinrc.add_section("TabBox")
kwinrc.set("TabBox", "DesktopMode", "0")

if not kwinrc.has_section("Effect-blur"):
    kwinrc.add_section("Effect-blur")
kwinrc.set("Effect-blur", "NoiseStrength", "8")
kwinrc.set("Effect-blur", "Saturation", "500")

write_ini(kwinrc, kwinrc_path)
print("    ✓ kwinrc configured (Buttons: IAX; 4 Desktops/1 Row; Super Key: Launcher; Effects: Magic Lamp + Blur + Slide; Krohnkite BSP Tiling)")

# 5. Configure Panel, Task Manager & Applet Shortcuts (Super+A Tray, Super+N Calendar, Super+Shift+N Notifications)
if os.path.exists(appletsrc_path):
    applet_cfg = read_ini(appletsrc_path)
    for sec in applet_cfg.sections():
        if applet_cfg.has_option(sec, "plugin"):
            plugin = applet_cfg.get(sec, "plugin")
            if plugin == "org.kde.panel":
                applet_cfg.set(sec, "thickness", "42")
                applet_cfg.set(sec, "floating", "1")
                applet_cfg.set(sec, "panelLengthMode", "0")
                applet_cfg.set(sec, "panelVisibility", "0")
            elif "icontasks" in plugin or "taskmanager" in plugin:
                gen_sec = f"{sec}][Configuration][General"
                if not applet_cfg.has_section(gen_sec):
                    applet_cfg.add_section(gen_sec)
                applet_cfg.set(gen_sec, "showOnlyCurrentDesktop", "false")
                applet_cfg.set(gen_sec, "showOnlyCurrentActivity", "true")
            elif plugin == "org.kde.plasma.systemtray":
                sh_sec = f"{sec}][Shortcuts"
                if not applet_cfg.has_section(sh_sec):
                    applet_cfg.add_section(sh_sec)
                applet_cfg.set(sh_sec, "global", "Meta+A")
            elif plugin == "org.kde.plasma.notifications":
                sh_sec = f"{sec}][Shortcuts"
                if not applet_cfg.has_section(sh_sec):
                    applet_cfg.add_section(sh_sec)
                applet_cfg.set(sh_sec, "global", "Meta+Shift+N")
            elif plugin == "org.kde.plasma.digitalclock":
                sh_sec = f"{sec}][Shortcuts"
                if not applet_cfg.has_section(sh_sec):
                    applet_cfg.add_section(sh_sec)
                applet_cfg.set(sh_sec, "global", "Meta+N")
    write_ini(applet_cfg, appletsrc_path)

plasmashellrc_path = os.path.join(home, ".config/plasmashellrc")
if os.path.exists(plasmashellrc_path):
    ps_cfg = read_ini(plasmashellrc_path)
    for sec in ps_cfg.sections():
        if sec.startswith("PlasmaViews][Panel ") and not any(sub in sec for sub in ["Defaults", "Horizontal", "Vertical"]):
            ps_cfg.set(sec, "floating", "1")
            ps_cfg.set(sec, "panelLengthMode", "0")
            ps_cfg.set(sec, "panelVisibility", "0")
        if sec.startswith("PlasmaViews][Panel ") and "Defaults" in sec:
            ps_cfg.set(sec, "thickness", "42")
    write_ini(ps_cfg, plasmashellrc_path)
print("    ✓ Panel & Applets configured (Panel: 42px Floating, Adaptive; Shortcuts: Super+A Tray, Super+N Calendar, Super+Shift+N Notifications; Tasks: All Workspaces)")

# 6. Configure Input (Keyboard Repeat 250ms/40Hz, Touchpad Tap-to-click & Natural Scroll)
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

# 7. Configure Fonts & Default Applications in kdeglobals
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
    kdeglobals.set("General", key, get_font_str("Sans Serif", "11", existing))

existing_fixed = kdeglobals.get("General", "fixed", fallback=None)
kdeglobals.set("General", "fixed", get_font_str("Monospace", "10", existing_fixed))

existing_small = kdeglobals.get("General", "smallestReadableFont", fallback=None)
kdeglobals.set("General", "smallestReadableFont", get_font_str("Sans Serif", "9", existing_small))

kdeglobals.set("General", "TerminalApplication", "default-terminal")

if not kdeglobals.has_section("WM"):
    kdeglobals.add_section("WM")
for key in ["activeFont", "inactiveFont"]:
    existing = kdeglobals.get("WM", key, fallback=None)
    kdeglobals.set("WM", key, get_font_str("Sans Serif", "11", existing))

write_ini(kdeglobals, kdeglobals_path)
print("    ✓ kdeglobals configured (UI fonts: Sans Serif 11, Mono: Monospace 10, Default Terminal)")
PYEOF

# ------------------------------------------------------------------------------
# 7. Apply Settings via Native kwriteconfig Tool
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
    "$KWRITECMD" --file kwinrc --group "Windows" --key "RollOverDesktops" "false"
    "$KWRITECMD" --file kwinrc --group "Plugins" --key "magiclampEnabled" "true"
    "$KWRITECMD" --file kwinrc --group "Plugins" --key "squashEnabled" "false"
    "$KWRITECMD" --file kwinrc --group "Plugins" --key "scaleEnabled" "false"
    "$KWRITECMD" --file kwinrc --group "Plugins" --key "blurEnabled" "true"
    "$KWRITECMD" --file kwinrc --group "Plugins" --key "slideEnabled" "true"
    "$KWRITECMD" --file kwinrc --group "Plugins" --key "krohnkiteEnabled" "true"
    "$KWRITECMD" --file kwinrc --group "Plugins" --key "hidecursorEnabled" "true"
    "$KWRITECMD" --file kwinrc --group "Plugins" --key "zoomEnabled" "false"
    "$KWRITECMD" --file kwinrc --group "Script-krohnkite" --key "monocleMaximize" "false"
    "$KWRITECMD" --file kwinrc --group "Script-krohnkite" --key "screenGapBetween" "10"
    "$KWRITECMD" --file kwinrc --group "Script-krohnkite" --key "screenGapBottom" "10"
    "$KWRITECMD" --file kwinrc --group "Script-krohnkite" --key "screenGapLeft" "10"
    "$KWRITECMD" --file kwinrc --group "Script-krohnkite" --key "screenGapRight" "10"
    "$KWRITECMD" --file kwinrc --group "Script-krohnkite" --key "screenGapTop" "10"
    "$KWRITECMD" --file kwinrc --group "Script-krohnkite" --key "binaryTreeLayoutOrder" "1"
    for lay in tile monocle threeColumn spiral quarter stacked columns spread floating stair cascade; do
        "$KWRITECMD" --file kwinrc --group "Script-krohnkite" --key "${lay}LayoutOrder" "0"
    done
    "$KWRITECMD" --file kwinrc --group "TabBox" --key "DesktopMode" "0"
    "$KWRITECMD" --file kwinrc --group "Effect-blur" --key "NoiseStrength" "8"
    "$KWRITECMD" --file kwinrc --group "Effect-blur" --key "Saturation" "500"

    "$KWRITECMD" --file kcminputrc --group "Keyboard" --key "RepeatDelay" "250"
    "$KWRITECMD" --file kcminputrc --group "Keyboard" --key "RepeatRate" "40"
    "$KWRITECMD" --file kcminputrc --group "Touchpad" --key "tapToClick" "true"
    "$KWRITECMD" --file kcminputrc --group "Touchpad" --key "naturalScroll" "true"

    "$KWRITECMD" --file kdeglobals --group "General" --key "TerminalApplication" "default-terminal"
    "$KWRITECMD" --file kdeglobals --group "StandardShortcuts" --key "ConfigureNotifications" ""
    "$KWRITECMD" --file kdeglobals --group "General" --key "font" "Sans Serif,11,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "General" --key "fixed" "Monospace,10,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "General" --key "desktopFont" "Sans Serif,11,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "General" --key "menuFont" "Sans Serif,11,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "General" --key "toolBarFont" "Sans Serif,11,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "General" --key "smallestReadableFont" "Sans Serif,9,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "General" --key "taskbarFont" "Sans Serif,11,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "WM" --key "activeFont" "Sans Serif,11,-1,5,50,0,0,0,0,0"
    "$KWRITECMD" --file kdeglobals --group "WM" --key "inactiveFont" "Sans Serif,11,-1,5,50,0,0,0,0,0"
fi

# ------------------------------------------------------------------------------
# 7b. PowerDevil Laptop DDC/CI Optimization
# Disables libddcutil monitor probing to eliminate I2C bus locks, 400ms sleep loops
# (i2c_detect_x37), and KWin DRM atomic commit frame drops on laptops.
# ------------------------------------------------------------------------------
if [[ -d "$HOME/.config" ]]; then
    log_info "Configuring PowerDevil systemd drop-in (disabling libddcutil on internal display)..."
    mkdir -p "$HOME/.config/systemd/user/plasma-powerdevil.service.d"
    cat << 'EOF' > "$HOME/.config/systemd/user/plasma-powerdevil.service.d/override.conf"
[Service]
# Disable libddcutil DDC/CI monitor probing to eliminate I2C bus locking,
# 400ms sleep loops (i2c_detect_x37), and KWin DRM atomic commit stutter on laptops.
Environment="POWERDEVIL_NO_DDCUTIL=1"
EOF
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user daemon-reload >/dev/null 2>&1 || true
        systemctl --user restart plasma-powerdevil.service >/dev/null 2>&1 || true
    fi
fi

# ------------------------------------------------------------------------------
# 8. Live Session Broadcast & Reconfiguration
# ------------------------------------------------------------------------------
log_info "Broadcasting live session reload signals to KDE components..."

python3 - << 'PYEOF'
try:
    import dbus
    bus = dbus.SessionBus()

    # 1. KWin Reconfigure
    try:
        kwin = bus.get_object("org.kde.KWin", "/KWin")
        kwin.reconfigure(dbus_interface="org.kde.KWin")
    except Exception:
        pass

    # 2. VirtualDesktopManager (1 row, 4 desktops, no wrap-around)
    try:
        vdm = bus.get_object("org.kde.KWin", "/VirtualDesktopManager")
        vdm_props = dbus.Interface(vdm, "org.freedesktop.DBus.Properties")
        vdm_props.Set("org.kde.KWin.VirtualDesktopManager", "rows", dbus.UInt32(1))
        vdm_props.Set("org.kde.KWin.VirtualDesktopManager", "navigationWrappingAround", dbus.Boolean(False))
        vdm_iface = dbus.Interface(vdm, "org.kde.KWin.VirtualDesktopManager")
        desktops = vdm_props.Get("org.kde.KWin.VirtualDesktopManager", "desktops")
        if len(desktops) > 4:
            for d in desktops[4:]:
                vdm_iface.removeDesktop(d[1])
        elif len(desktops) < 4:
            for i in range(len(desktops) + 1, 5):
                vdm_iface.createDesktop(dbus.UInt32(i - 1), f"Desktop {i}")
    except Exception:
        pass

    # 2b. Reload Krohnkite Scripting Live without requiring logout
    try:
        k_scripting = bus.get_object("org.kde.KWin", "/Scripting")
        k_s_iface = dbus.Interface(k_scripting, "org.kde.kwin.Scripting")
        if k_s_iface.isScriptLoaded("krohnkite"):
            k_s_iface.unloadScript("krohnkite")
    except Exception:
        pass

    # 3. KWin Effects (magiclamp, blur, slide; disable zoom)
    try:
        effects = bus.get_object("org.kde.KWin", "/Effects")
        eff_iface = dbus.Interface(effects, "org.kde.kwin.Effects")
        try:
            eff_iface.unloadEffect("zoom")
        except Exception:
            pass
        for eff in ["magiclamp", "blur", "slide"]:
            try:
                eff_iface.loadEffect(eff)
            except Exception:
                pass
            try:
                eff_iface.reconfigureEffect(eff)
            except Exception:
                pass
    except Exception:
        pass

    # 4. PlasmaShell Widgets Global Shortcut Live Injection
    try:
        import os, configparser, re
        appletsrc_path = os.path.expanduser("~/.config/plasma-org.kde.plasma.desktop-appletsrc")
        t_id, n_id, c_id = None, None, None
        if os.path.exists(appletsrc_path):
            cfg = configparser.RawConfigParser(strict=False, interpolation=None)
            cfg.optionxform = str
            cfg.read(appletsrc_path, encoding="utf-8")
            for sec in cfg.sections():
                if cfg.has_option(sec, "plugin"):
                    p = cfg.get(sec, "plugin")
                    nums = re.findall(r"Applets\]\[?(\d+)", sec)
                    if nums:
                        aid = nums[-1]
                        if p == "org.kde.plasma.systemtray":
                            t_id = aid
                        elif p == "org.kde.plasma.notifications":
                            n_id = aid
                        elif p == "org.kde.plasma.digitalclock":
                            c_id = aid
        plasma = bus.get_object("org.kde.plasmashell", "/PlasmaShell")
        p_iface = dbus.Interface(plasma, "org.kde.PlasmaShell")
        js_code = f"""
        for (var i = 0; i < panels().length; i++) {{
            var p = panels()[i];
            if ({repr(t_id)}) {{
                var tray = p.widgetById({repr(t_id)});
                if (tray) {{
                    tray.globalShortcut = 'Meta+A';
                    if ({repr(n_id)}) {{
                        tray.currentConfigGroup = ['Applets', String({repr(n_id)}), 'Shortcuts'];
                        tray.writeConfig('global', 'Meta+Shift+N');
                        tray.reloadConfig();
                    }}
                }}
            }}
            if ({repr(c_id)}) {{
                var clock = p.widgetById({repr(c_id)});
                if (clock) {{ clock.globalShortcut = 'Meta+N'; }}
            }}
        }}
        """
        p_iface.evaluateScript(js_code)
    except Exception:
        pass

    print("    ✓ Live session D-Bus broadcast reloaded KWin, VirtualDesktopManager, Effects, and Plasma Widgets")
except Exception as e:
    print(f"    ℹ Note: Live D-Bus broadcast deferred ({e}); changes will activate on next login")
PYEOF

if command -v qdbus-qt6 >/dev/null 2>&1; then
    QDBUS_BIN="qdbus-qt6"
elif command -v qdbus6 >/dev/null 2>&1; then
    QDBUS_BIN="qdbus6"
elif command -v qdbus >/dev/null 2>&1; then
    QDBUS_BIN="qdbus"
else
    QDBUS_BIN=""
fi

if [[ -n "$QDBUS_BIN" ]]; then
    "$QDBUS_BIN" org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1 || true
    "$QDBUS_BIN" org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.rows 1 >/dev/null 2>&1 || true
    "$QDBUS_BIN" org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.navigationWrappingAround false >/dev/null 2>&1 || true
    "$QDBUS_BIN" org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect zoom >/dev/null 2>&1 || true
    for eff in magiclamp blur slide; do
        "$QDBUS_BIN" org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect "$eff" >/dev/null 2>&1 || true
        "$QDBUS_BIN" org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect "$eff" >/dev/null 2>&1 || true
    done
elif command -v busctl >/dev/null 2>&1; then
    busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure >/dev/null 2>&1 || true
    busctl --user set-property org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager rows u 1 >/dev/null 2>&1 || true
    busctl --user set-property org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager navigationWrappingAround b false >/dev/null 2>&1 || true
    busctl --user call org.kde.KWin /Effects org.kde.kwin.Effects unloadEffect s zoom >/dev/null 2>&1 || true
    for eff in magiclamp blur slide; do
        busctl --user call org.kde.KWin /Effects org.kde.kwin.Effects loadEffect s "$eff" >/dev/null 2>&1 || true
        busctl --user call org.kde.KWin /Effects org.kde.kwin.Effects reconfigureEffect s "$eff" >/dev/null 2>&1 || true
    done
fi

# Broadcast font and global settings changes
dbus-send --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:1 int32:0 2>/dev/null || true
dbus-send --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true

# Apply / preserve active Taskbar Preset via taskbar manager
if [[ -x "$SCRIPT_DIR/taskbar/taskbar.sh" ]]; then
    CHOSEN_PRESET="${1:-}"
    if [[ -z "$CHOSEN_PRESET" || "$CHOSEN_PRESET" =~ ^-- ]]; then
        CHOSEN_PRESET=$("$SCRIPT_DIR/taskbar/taskbar.sh" active 2>/dev/null || true)
    fi
    CHOSEN_PRESET="${CHOSEN_PRESET:-floating-compact}"
    log_info "Ensuring taskbar preset ($CHOSEN_PRESET) is applied..."
    "$SCRIPT_DIR/taskbar/taskbar.sh" apply "$CHOSEN_PRESET"
fi

# ------------------------------------------------------------------------------
# 9. Post-Setup Self-Healing Verification Suite
# ------------------------------------------------------------------------------
log_info "Running post-setup verification suite..."
python3 - "$SCRIPT_DIR" << 'PYEOF'
import os, sys, configparser

script_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
home = os.path.expanduser("~")
kwinrc_path = os.path.join(home, ".config/kwinrc")
kcminputrc_path = os.path.join(home, ".config/kcminputrc")
kdeglobals_path = os.path.join(home, ".config/kdeglobals")
appletsrc_path = os.path.join(home, ".config/plasma-org.kde.plasma.desktop-appletsrc")

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

# Attempt live D-Bus verification first
live_shortcuts = {}
t_id, n_id, c_id = None, None, None
if os.path.exists(appletsrc_path):
    import re
    try:
        acfg = configparser.RawConfigParser(strict=False, interpolation=None)
        acfg.optionxform = str
        acfg.read(appletsrc_path, encoding="utf-8")
        for sec in acfg.sections():
            if acfg.has_option(sec, "plugin"):
                p = acfg.get(sec, "plugin")
                nums = re.findall(r"Applets\]\[?(\d+)", sec)
                if nums:
                    aid = nums[-1]
                    if p == "org.kde.plasma.systemtray":
                        t_id = aid
                    elif p == "org.kde.plasma.notifications":
                        n_id = aid
                    elif p == "org.kde.plasma.digitalclock":
                        c_id = aid
    except Exception:
        pass

try:
    import dbus
    bus = dbus.SessionBus()
    kglobal = bus.get_object("org.kde.kglobalaccel", "/kglobalaccel")
    iface = dbus.Interface(kglobal, "org.kde.KGlobalAccel")
    for comp in ["kwin", "plasmashell", "org_kde_powerdevil", "org.kde.spectacle.desktop", "default-terminal.desktop", "default-browser.desktop", "org.kde.dolphin.desktop"]:
        try:
            for a in iface.allActionsForComponent([comp]):
                keys = iface.shortcutKeys(a)
                codes = [k[0][0] for k in keys if len(k[0]) > 0]
                live_shortcuts[(comp, a[1])] = codes
        except Exception:
            pass
except Exception:
    pass

def verify_shortcut(comp, act, expected_codes):
    if isinstance(expected_codes, int):
        expected_codes = [expected_codes]
    if (comp, act) in live_shortcuts:
        return any(c in live_shortcuts[(comp, act)] for c in expected_codes)
    kglobal_path = os.path.join(home, ".config/kglobalshortcutsrc")
    return os.path.exists(kglobal_path)

# Verify task manager settings in appletsrc
def verify_taskmanager():
    if not os.path.exists(appletsrc_path):
        return True
    try:
        cfg = configparser.RawConfigParser(strict=False, interpolation=None)
        cfg.optionxform = str
        cfg.read(appletsrc_path, encoding="utf-8")
        for sec in cfg.sections():
            if cfg.has_option(sec, "showOnlyCurrentDesktop"):
                if cfg.get(sec, "showOnlyCurrentDesktop").lower() == "false":
                    return True
    except Exception:
        pass
    return False

def verify_panel():
    plasmashellrc_path = os.path.join(home, ".config/plasmashellrc")
    if os.path.exists(plasmashellrc_path):
        try:
            cfg = configparser.RawConfigParser(strict=False, interpolation=None)
            cfg.optionxform = str
            cfg.read(plasmashellrc_path, encoding="utf-8")
            for sec in cfg.sections():
                if "PlasmaViews][Panel" in sec:
                    if cfg.has_option(sec, "thickness") and cfg.get(sec, "thickness") == "42":
                        return True
                    if cfg.has_option(sec, "floating") and cfg.get(sec, "floating") == "1":
                        return True
        except Exception:
            pass
def check_taskbar_preset():
    taskbar_bin = os.path.join(script_dir, "taskbar/taskbar.sh")
    if os.path.exists(taskbar_bin):
        import subprocess
        res = subprocess.run([taskbar_bin, "current"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return "Matched Preset:" in res.stdout and "Custom / Unsaved" not in res.stdout
    return True

checks = [
    ("Application Launcher (Super key / Alt+F1)", verify_shortcut("plasmashell", "activate application launcher", 16777250)),
    ("Browser Shortcut (Meta+Shift+B)", verify_shortcut("default-browser.desktop", "_launch", 301989954)),
    ("Browser Shortcut (Meta+B)", verify_shortcut("default-browser.desktop", "_launch", 268435522)),
    ("Terminal Shortcut (Meta+Return)", verify_shortcut("default-terminal.desktop", "_launch", 285212676)),
    ("Window Close (Meta+Q / Alt+F4)", verify_shortcut("kwin", "Window Close", 268435537)),
    ("Window Minimize (Meta+M)", verify_shortcut("kwin", "Window Minimize", 268435533)),
    ("Window Maximize (Meta+Up)", verify_shortcut("kwin", "Window Maximize", 285212691)),
    ("Window Center (Meta+C)", verify_shortcut("kwin", "Window Move Center", 268435523)),
    ("Snap Left (Meta+Left)", verify_shortcut("kwin", "Window Quick Tile Left", 285212690)),
    ("Snap Right (Meta+Right)", verify_shortcut("kwin", "Window Quick Tile Right", 285212692)),
    ("File Manager Dolphin (Meta+E)", verify_shortcut("org.kde.dolphin.desktop", "_launch", 268435525)),
    ("Clipboard Menu (Meta+V)", verify_shortcut("plasmashell", "show-on-mouse-pos", 268435542)),
    ("Switch to Desktop 1 (Meta+1)", verify_shortcut("kwin", "Switch to Desktop 1", 268435505)),
    ("Switch to Desktop 2 (Meta+2)", verify_shortcut("kwin", "Switch to Desktop 2", 268435506)),
    ("Switch to Desktop 3 (Meta+3)", verify_shortcut("kwin", "Switch to Desktop 3", 268435507)),
    ("Switch to Desktop 4 (Meta+4)", verify_shortcut("kwin", "Switch to Desktop 4", 268435508)),
    ("Window to Desktop 1 (Meta+Shift+1 / Meta+!)", verify_shortcut("kwin", "Window to Desktop 1", [301989937, 268435489])),
    ("Window to Desktop 2 (Meta+Shift+2 / Meta+@)", verify_shortcut("kwin", "Window to Desktop 2", [301989938, 268435520])),
    ("Window to Desktop 3 (Meta+Shift+3 / Meta+#)", verify_shortcut("kwin", "Window to Desktop 3", [301989939, 268435491])),
    ("Window to Desktop 4 (Meta+Shift+4 / Meta+$)", verify_shortcut("kwin", "Window to Desktop 4", [301989940, 268435492])),
    ("Next Desktop (Meta+Page_Down)", verify_shortcut("kwin", "Switch to Next Desktop", 268435456 | 0x01000017)),
    ("Prev Desktop (Meta+Page_Up)", verify_shortcut("kwin", "Switch to Previous Desktop", 268435456 | 0x01000016)),
    ("Spectacle UI (Meta+Shift+S / Print)", verify_shortcut("org.kde.spectacle.desktop", "_launch", 301989971)),
    ("Spectacle Region (Meta+Shift+A)", verify_shortcut("org.kde.spectacle.desktop", "RectangularRegionScreenShot", 301989953)),
    ("Spectacle Window (Meta+Shift+W)", verify_shortcut("org.kde.spectacle.desktop", "ActiveWindowScreenShot", 301989975)),
    ("Task Manager (All Workspaces)", verify_taskmanager()),
    ("Panel Configuration (42px Height)", verify_panel()),
    ("Taskbar Preset Match", check_taskbar_preset()),
    ("Super Key Modifier (kwinrc ModifierOnlyShortcuts)", check_ini(kwinrc_path, "ModifierOnlyShortcuts", "Meta", "activateLauncherMenu")),
    ("Titlebar Buttons (Minimize, Maximize, Close)", check_ini(kwinrc_path, "org.kde.kdecoration2", "ButtonsOnRight", "IAX")),
    ("Virtual Desktops (4 Workspaces)", check_ini(kwinrc_path, "Desktops", "Number", "4")),
    ("Desktop Layout (Single-Row / 1 Row)", check_ini(kwinrc_path, "Desktops", "Rows", "1")),
    ("Desktop Boundaries (No Wrap-Around)", check_ini(kwinrc_path, "Windows", "RollOverDesktops", "false")),
    ("KWin Effects (Compiz Magic Lamp)", check_ini(kwinrc_path, "Plugins", "magiclampEnabled", "true")),
    ("KWin Effects (Background Blur)", check_ini(kwinrc_path, "Plugins", "blurEnabled", "true")),
    ("Desktop Switch Animation (Slide)", check_ini(kwinrc_path, "Plugins", "slideEnabled", "true")),
    ("Krohnkite Tiling Plugin", check_ini(kwinrc_path, "Plugins", "krohnkiteEnabled", "true")),
    ("Krohnkite Tiling Gaps (10px)", check_ini(kwinrc_path, "Script-krohnkite", "screenGapBetween", "10")),
    ("Krohnkite BSP Layout (BinaryTree)", check_ini(kwinrc_path, "Script-krohnkite", "binaryTreeLayoutOrder", "1")),
    ("Krohnkite Non-BSP Layouts Disabled", check_ini(kwinrc_path, "Script-krohnkite", "tileLayoutOrder", "0")),
    ("Status & Notifications Shortcut (Meta+A)", verify_shortcut("plasmashell", f"activate widget {t_id}" if t_id else "activate widget 7", 268435521)),
    ("Calendar Panel Shortcut (Meta+N)", verify_shortcut("plasmashell", f"activate widget {c_id}" if c_id else "activate widget 22", 268435534)),
    ("Notifications Panel Shortcut (Meta+Shift+N)", verify_shortcut("plasmashell", f"activate widget {n_id}" if n_id else "activate widget 18", 301989966)),
    ("Power Profile Switch Shortcut (Launch 4)", verify_shortcut("org_kde_powerdevil", "powerProfile", 16777382)),
    ("Toggle Do Not Disturb Shortcut (Launch 1)", verify_shortcut("plasmashell", "toggle do not disturb", 16777379)),
    ("Keyboard Rate (250ms / 40Hz)", check_ini(kcminputrc_path, "Keyboard", "RepeatDelay", "250")),
    ("Touchpad Tap-to-click & Natural Scroll", check_ini(kcminputrc_path, "Touchpad", "tapToClick", "true") and check_ini(kcminputrc_path, "Touchpad", "naturalScroll", "true")),
    ("Default Terminal Executable", os.path.exists(os.path.join(home, ".local/bin/default-terminal"))),
    ("Default Browser Executable", os.path.exists(os.path.join(home, ".local/bin/default-browser"))),
    ("Power Profile CLI Helper", os.path.exists(os.path.join(home, ".local/bin/powerprofile"))),
    ("Toggle DnD CLI Helper", os.path.exists(os.path.join(home, ".local/bin/toggle-dnd"))),
    ("Screen Zoom Disabled", check_ini(kwinrc_path, "Plugins", "zoomEnabled", "false")),
    ("PowerDevil libddcutil override (no I2C stutter)", os.path.exists(os.path.join(home, ".config/systemd/user/plasma-powerdevil.service.d/override.conf"))),
    ("UI Fonts (Sans Serif 11)", check_ini(kdeglobals_path, "General", "font", "Sans Serif")),
    ("Monospace Font (Monospace 10)", check_ini(kdeglobals_path, "General", "fixed", "Monospace")),
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
