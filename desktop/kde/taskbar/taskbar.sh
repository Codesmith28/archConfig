#!/usr/bin/env bash
# ==============================================================================
# taskbar.sh - KDE Plasma 6 Taskbar Preset Manager
# ==============================================================================
# Manages live application and file persistence for KDE Plasma panel/taskbar
# presets across Fedora, Arch Linux, and Ubuntu.
#
# Supports single-bar setups as well as GNOME-style two-bar layouts (status top,
# launcher + tasks bottom). All bars enforce height=42 and adaptive opacity.
#
# Usage:
#   taskbar.sh list                    List available presets and show active one
#   taskbar.sh current                 Show live taskbar configuration
#   taskbar.sh apply <preset-name>     Apply preset live and persist to config files
#   taskbar.sh verify [preset-name]    Verify if panel matches given preset
#   taskbar.sh save <new-preset-name>  Save live panel config as a new preset
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESETS_DIR="$SCRIPT_DIR/presets"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "  ${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "  ${GREEN}[OK]${NC}   $*"; }
log_warn()    { echo -e "  ${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "  ${RED}[ERR]${NC}  $*"; }

show_help() {
    cat << EOF
${BOLD}KDE Plasma 6 Taskbar Preset Manager${NC}

Usage:
  $(basename "$0") list                     List all presets and mark active
  $(basename "$0") current                  Show current live panel settings
  $(basename "$0") apply <name|file.json>   Apply preset live and persist
  $(basename "$0") verify [name|file.json]  Verify live panel matches preset
  $(basename "$0") save <new-preset-name>   Export live panel as a new preset
  $(basename "$0") help                     Show this help message

Presets:
  floating-compact   Modern 42px floating dock panel, adaptive opacity (Default)
  gnome              GNOME Two-Bar: Top status bar + Bottom launcher & tasks dock
  dock-mac           macOS style centered 42px floating dock, dodges windows
  classic-windows    Non-floating 42px edge-to-edge taskbar, active workspace apps
  minimal-autohide   Slim 42px floating autohide panel for maximal screen estate
  top-bar            Clean 42px top status bar, edge-to-edge
EOF
}

ACTION="${1:-list}"

case "$ACTION" in
    -h|--help|help)
        show_help
        exit 0
        ;;
    list|current|apply|verify|save|active)
        python3 - "$SCRIPT_DIR" "$PRESETS_DIR" "$@" << 'PYEOF'
import os, sys, json, configparser

script_dir = sys.argv[1]
presets_dir = sys.argv[2]
args = sys.argv[3:]
action = args[0] if len(args) > 0 else "list"
target_preset = args[1] if len(args) > 1 else ""

home = os.path.expanduser("~")
plasmashellrc_path = os.path.join(home, ".config/plasmashellrc")
appletsrc_path = os.path.join(home, ".config/plasma-org.kde.plasma.desktop-appletsrc")

def evaluate_plasma_script(script):
    # Try python dbus first
    try:
        import dbus
        bus = dbus.SessionBus()
        plasma = bus.get_object("org.kde.plasmashell", "/PlasmaShell")
        iface = dbus.Interface(plasma, "org.kde.PlasmaShell")
        return str(iface.evaluateScript(script))
    except Exception:
        pass

    # Fallback to qdbus / busctl
    import subprocess
    for cmd in ["qdbus-qt6", "qdbus6", "qdbus"]:
        try:
            res = subprocess.run([cmd, "org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript", script],
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
            return res.stdout.strip()
        except Exception:
            pass

    try:
        res = subprocess.run(["busctl", "--user", "call", "org.kde.plasmashell", "/PlasmaShell",
                              "org.kde.PlasmaShell", "evaluateScript", "s", script],
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        out = res.stdout.strip()
        if out.startswith('s "') and out.endswith('"'):
            return out[3:-1]
        return out
    except Exception:
        pass
    return None

def get_live_panel_config():
    query_script = """
let pList = panels();
if (pList.length === 0) {
    print(JSON.stringify({error: "no_panel", panelCount: 0}));
} else {
    let panelsData = [];
    for (let p of pList) {
        let wTypes = [];
        let hasTask = false;
        let taskCd = false;
        let taskCa = true;
        for (let w of p.widgets()) {
            wTypes.push(w.type);
            if (w.type.indexOf("tasks") !== -1) {
                hasTask = true;
                w.currentConfigGroup = ["General"];
                let cd = w.readConfig("showOnlyCurrentDesktop");
                let ca = w.readConfig("showOnlyCurrentActivity");
                taskCd = (cd === "true" || cd === true);
                taskCa = (ca === "true" || ca === true);
            }
        }
        panelsData.push({
            id: p.id,
            location: p.location,
            height: p.height,
            floating: p.floating,
            lengthMode: p.lengthMode,
            hiding: p.hiding,
            opacity: p.opacity,
            alignment: p.alignment,
            widgets: wTypes,
            showOnlyCurrentDesktop: taskCd,
            showOnlyCurrentActivity: taskCa
        });
    }

    let topP = null;
    let bottomP = null;
    for (let pd of panelsData) {
        if (pd.location === "top") topP = pd;
        if (pd.location === "bottom") bottomP = pd;
    }

    // Detect GNOME split layout
    let isGnome = false;
    if (panelsData.length === 2 && topP && bottomP) {
        let bWidgets = bottomP.widgets;
        let onlyLauncherAndTasks = true;
        for (let wt of bWidgets) {
            if (wt.indexOf("kicker") === -1 && wt.indexOf("kickoff") === -1 && wt.indexOf("tasks") === -1) {
                onlyLauncherAndTasks = false;
                break;
            }
        }
        let tWidgets = topP.widgets;
        let hasTrayOrClock = false;
        for (let wt of tWidgets) {
            if (wt.indexOf("tray") !== -1 || wt.indexOf("clock") !== -1) {
                hasTrayOrClock = true;
                break;
            }
        }
        if (onlyLauncherAndTasks && hasTrayOrClock) {
            isGnome = true;
        }
    }

    let primary = bottomP ? bottomP : panelsData[0];
    let result = {
        panelCount: panelsData.length,
        layoutType: isGnome ? "gnome-split" : "single",
        location: primary.location,
        height: primary.height,
        floating: primary.floating,
        lengthMode: primary.lengthMode,
        hiding: primary.hiding,
        opacity: primary.opacity,
        alignment: primary.alignment,
        showOnlyCurrentDesktop: primary.showOnlyCurrentDesktop,
        showOnlyCurrentActivity: primary.showOnlyCurrentActivity,
        panels: panelsData
    };
    print(JSON.stringify(result));
}
"""
    raw = evaluate_plasma_script(query_script)
    if raw:
        try:
            return json.loads(raw)
        except Exception:
            pass
    return None

def load_preset(name_or_path):
    if not name_or_path:
        return None
    import re
    name_or_path = re.sub(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])', '', str(name_or_path)).strip()
    candidate_path = name_or_path
    if not os.path.exists(candidate_path):
        if not candidate_path.endswith(".json"):
            candidate_path = os.path.join(presets_dir, f"{name_or_path}.json")
    if os.path.exists(candidate_path):
        try:
            with open(candidate_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            print(f"  \033[0;31m[ERR]\033[0m Failed to parse preset JSON: {e}")
            return None
    return None

def load_all_presets():
    presets = []
    if os.path.exists(presets_dir):
        for f in sorted(os.listdir(presets_dir)):
            if f.endswith(".json"):
                full_path = os.path.join(presets_dir, f)
                try:
                    with open(full_path, "r", encoding="utf-8") as fp:
                        data = json.load(fp)
                        if "id" not in data:
                            data["id"] = os.path.splitext(f)[0]
                        presets.append(data)
                except Exception:
                    pass
    return presets

def preset_matches_live(preset, live):
    if not live or not preset:
        return False

    p_layout = preset.get("layoutType", "single")
    l_layout = live.get("layoutType", "single")
    if p_layout != l_layout:
        return False

    if p_layout == "gnome-split":
        panels_data = live.get("panels", [])
        top_ok = False
        bottom_ok = False
        for p in panels_data:
            if p.get("location") == "top" and p.get("height", 0) <= 32 and p.get("opacity") == "adaptive":
                top_ok = True
            if p.get("location") == "bottom" and p.get("height", 0) == 42 and p.get("opacity") == "adaptive":
                bottom_ok = True
        return live.get("panelCount", 0) == 2 and top_ok and bottom_ok

    keys_to_compare = ["location", "height", "floating", "lengthMode", "hiding", "opacity", "showOnlyCurrentDesktop"]
    for k in keys_to_compare:
        if k in preset and k in live:
            if str(preset[k]).lower() != str(live[k]).lower():
                return False
    return True

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

def persist_preset_to_disk(preset):
    layout_type = preset.get("layoutType", "single")
    bottom_height = str(preset.get("height", 42) if preset.get("location") == "bottom" or layout_type == "gnome-split" else 42)
    top_height = str(preset.get("topHeight", 30) if layout_type == "gnome-split" else (preset.get("height", 30) if preset.get("location") == "top" else 30))

    length_mode_map = {"fill": "0", "fit": "1", "custom": "2"}
    hiding_map = {"none": "0", "autohide": "1", "dodgewindows": "2", "windowscover": "2", "windowsbelow": "3"}

    top_panel_ids = set()
    bottom_panel_ids = set()

    # 1. Update appletsrc
    if os.path.exists(appletsrc_path):
        applet_cfg = read_ini(appletsrc_path)
        for sec in applet_cfg.sections():
            if applet_cfg.has_option(sec, "plugin") and applet_cfg.get(sec, "plugin") == "org.kde.panel":
                cid = sec.split("][")[-1].replace("]", "").strip()
                loc = applet_cfg.get(sec, "location", fallback="")
                if loc == "3" or (layout_type != "gnome-split" and preset.get("location") == "top"): # Top bar
                    top_panel_ids.add(cid)
                    applet_cfg.set(sec, "thickness", top_height)
                    applet_cfg.set(sec, "floating", "0")
                    applet_cfg.set(sec, "panelLengthMode", "0")
                    applet_cfg.set(sec, "panelVisibility", "0")
                else: # Bottom bar
                    bottom_panel_ids.add(cid)
                    applet_cfg.set(sec, "thickness", bottom_height)
                    applet_cfg.set(sec, "floating", "1" if preset.get("floating", True) else "0")
                    applet_cfg.set(sec, "panelLengthMode", length_mode_map.get(preset.get("lengthMode", "fill"), "0"))
                    applet_cfg.set(sec, "panelVisibility", hiding_map.get(preset.get("hiding", "none"), "0"))
            elif "icontasks" in sec or "taskmanager" in sec:
                gen_sec = f"{sec}][Configuration][General" if not sec.endswith("Configuration][General") else sec
                if not applet_cfg.has_section(gen_sec):
                    applet_cfg.add_section(gen_sec)
                applet_cfg.set(gen_sec, "showOnlyCurrentDesktop", "true" if preset.get("showOnlyCurrentDesktop", False) else "false")
                applet_cfg.set(gen_sec, "showOnlyCurrentActivity", "true" if preset.get("showOnlyCurrentActivity", True) else "false")
        write_ini(applet_cfg, appletsrc_path)

    # 2. Update plasmashellrc
    ps_cfg = read_ini(plasmashellrc_path)
    for sec in ps_cfg.sections():
        if sec.startswith("PlasmaViews][Panel ") and not any(sub in sec for sub in ["Defaults", "Horizontal", "Vertical"]):
            pid = sec.split("Panel ")[-1].replace("]", "").strip()
            is_top = pid in top_panel_ids or (layout_type != "gnome-split" and preset.get("location") == "top")
            ps_cfg.set(sec, "floating", "0" if is_top else ("1" if preset.get("floating", True) else "0"))
            ps_cfg.set(sec, "panelLengthMode", "0" if is_top else length_mode_map.get(preset.get("lengthMode", "fill"), "0"))
            ps_cfg.set(sec, "panelVisibility", "0" if is_top else hiding_map.get(preset.get("hiding", "none"), "0"))
        if sec.startswith("PlasmaViews][Panel ") and "Defaults" in sec:
            pid = sec.split("Panel ")[-1].split("]")[0].strip()
            is_top = pid in top_panel_ids or (layout_type != "gnome-split" and preset.get("location") == "top")
            ps_cfg.set(sec, "thickness", top_height if is_top else bottom_height)

    write_ini(ps_cfg, plasmashellrc_path)

# --- Actions ---
live = get_live_panel_config()

if action == "list":
    presets = load_all_presets()
    print("Available Taskbar Presets:")
    for p in presets:
        is_active = preset_matches_live(p, live)
        marker = "  \033[1;32m* " if is_active else "    "
        active_tag = " \033[1;32m[ACTIVE]\033[0m" if is_active else ""
        name = p.get("name", p["id"])
        desc = p.get("description", "")
        h = p.get("height", 42)
        fl = "floating" if p.get("floating", True) else "docked"
        loc = p.get("location", "bottom")
        layout = p.get("layoutType", "single")
        layout_desc = "two-bar (top: 30px, bottom: 42px)" if layout == "gnome-split" else f"{loc}, {h}px, {fl}"
        print(f"{marker}\033[1m{p['id']:<18}\033[0m - {name} ({layout_desc}, adaptive){active_tag}")
        if desc:
            print(f"      \033[2m{desc}\033[0m")
    sys.exit(0)

elif action == "current":
    if not live:
        print("  \033[0;31m[ERR]\033[0m Could not query live panel from KDE Plasma session.")
        sys.exit(1)
    matched_preset = None
    for p in load_all_presets():
        if preset_matches_live(p, live):
            matched_preset = p
            break
    print("Current Live Taskbar State:")
    print(f"  Layout Type:          {live.get('layoutType', 'single')}")
    print(f"  Total Panels:         {live.get('panelCount', 1)}")
    for i, pinfo in enumerate(live.get("panels", [])):
        print(f"  Panel {i+1} ({pinfo.get('location')}):       height={pinfo.get('height')}px, opacity={pinfo.get('opacity')}, floating={pinfo.get('floating')}, hiding={pinfo.get('hiding')}")
        w_names = [w.replace("org.kde.plasma.", "") for w in pinfo.get("widgets", [])]
        print(f"    Widgets:            {', '.join(w_names)}")
    if matched_preset:
        print(f"  Matched Preset:       \033[1;32m{matched_preset['id']} ({matched_preset.get('name')})\033[0m")
    else:
        print("  Matched Preset:       \033[1;33mCustom / Unsaved\033[0m")
    sys.exit(0)

elif action == "apply":
    preset_name = target_preset if target_preset else "floating-compact"
    preset = load_preset(preset_name)
    if not preset:
        print(f"  \033[0;31m[ERR]\033[0m Preset '{preset_name}' not found in {presets_dir}")
        sys.exit(1)

    print(f"  \033[0;34m[INFO]\033[0m Applying taskbar preset: '\033[1m{preset.get('name', preset_name)}\033[0m' (Adaptive)...")

    layout_type = preset.get("layoutType", "single")

    if layout_type == "gnome-split":
        # GNOME Split: Bottom dock with ONLY launcher and tasks (42px); Top panel with status (30px)
        apply_script = """
let pList = panels();
let bottomP = pList[0];
bottomP.location = "bottom";
bottomP.height = 42;
bottomP.opacity = "adaptive";
bottomP.floating = true;
bottomP.lengthMode = "fit";
bottomP.hiding = "dodgewindows";
bottomP.alignment = "center";

// Clean bottom widgets to only launcher and tasks
for (let w of bottomP.widgets()) {
    if (w.type !== "org.kde.plasma.kicker" && w.type !== "org.kde.plasma.kickoff" && w.type !== "org.kde.plasma.icontasks" && w.type !== "org.kde.plasma.taskmanager") {
        w.remove();
    }
}
let hasKicker = false;
let hasTasks = false;
for (let w of bottomP.widgets()) {
    if (w.type.indexOf("kicker") !== -1 || w.type.indexOf("kickoff") !== -1) hasKicker = true;
    if (w.type.indexOf("tasks") !== -1) {
        hasTasks = true;
        w.currentConfigGroup = ["General"];
        w.writeConfig("showOnlyCurrentDesktop", false);
        w.writeConfig("showOnlyCurrentActivity", true);
    }
}
if (!hasKicker) bottomP.addWidget("org.kde.plasma.kicker");
if (!hasTasks) bottomP.addWidget("org.kde.plasma.icontasks");

// Top status bar (30px slim status bar)
let topP = null;
for (let i = 1; i < pList.length; i++) {
    if (pList[i].location === "top") {
        topP = pList[i];
        break;
    }
}
if (!topP) {
    topP = new Panel();
    topP.location = "top";
}
topP.height = 30;
topP.opacity = "adaptive";
topP.floating = false;
topP.lengthMode = "fill";
topP.hiding = "none";
topP.alignment = "center";

if (topP.widgets().length === 0) {
    topP.addWidget("org.kde.plasma.pager");
    topP.addWidget("org.kde.plasma.panelspacer");
    topP.addWidget("org.kde.plasma.digitalclock");
    topP.addWidget("org.kde.plasma.panelspacer");
    topP.addWidget("org.kde.plasma.systemtray");
}
print("applied-gnome");
"""
    else:
        # Single panel layout: clean up extra panels and restore standard full widgets
        loc = preset.get("location", "bottom")
        target_height = int(preset.get("height", 30 if loc == "top" else 42))
        fl = str(preset.get("floating", True)).lower()
        lm = preset.get("lengthMode", "fill")
        hd = preset.get("hiding", "none")
        align = preset.get("alignment", "center")
        cd = str(preset.get("showOnlyCurrentDesktop", False)).lower()
        ca = str(preset.get("showOnlyCurrentActivity", True)).lower()

        apply_script = f"""
let pList = panels();
let mainP = pList[0];

// Remove extra panels
for (let i = 1; i < pList.length; i++) {{
    pList[i].remove();
}}

mainP.location = "{loc}";
mainP.height = {target_height};
mainP.opacity = "adaptive";
mainP.floating = {fl};
mainP.lengthMode = "{lm}";
mainP.hiding = "{hd}";
mainP.alignment = "{align}";

let existing = {{}};
for (let w of mainP.widgets()) {{
    existing[w.type] = true;
    if (w.type.indexOf("tasks") !== -1) {{
        w.currentConfigGroup = ["General"];
        w.writeConfig("showOnlyCurrentDesktop", {cd});
        w.writeConfig("showOnlyCurrentActivity", {ca});
    }}
}}

if (!existing["org.kde.plasma.marginsseparator"]) mainP.addWidget("org.kde.plasma.marginsseparator");
if (!existing["org.kde.plasma.systemtray"]) mainP.addWidget("org.kde.plasma.systemtray");
if (!existing["org.kde.plasma.digitalclock"]) mainP.addWidget("org.kde.plasma.digitalclock");
if (!existing["org.kde.plasma.pager"]) mainP.addWidget("org.kde.plasma.pager");
if (!existing["org.kde.plasma.showdesktop"]) mainP.addWidget("org.kde.plasma.showdesktop");

print("applied-single");
"""
    res = evaluate_plasma_script(apply_script)
    if res and ("applied" in res):
        print("    ✓ Live panel layout updated via Plasma D-Bus interface")
    else:
        print("    ℹ Note: Live D-Bus injection deferred; writing config files for next login")

    persist_preset_to_disk(preset)
    print("    ✓ Persistent config files synchronized (~/.config/plasmashellrc & appletsrc)")
    print(f"  \033[0;32m[OK]\033[0m   Taskbar preset '\033[1m{preset.get('id', preset_name)}\033[0m' successfully applied!")
    sys.exit(0)

elif action == "verify":
    preset_name = target_preset if target_preset else "floating-compact"
    preset = load_preset(preset_name)
    if not preset:
        print(f"  \033[0;31m[ERR]\033[0m Preset '{preset_name}' not found.")
        sys.exit(2)
    if preset_matches_live(preset, live):
        print(f"  \033[0;32m[OK]\033[0m   Panel matches preset '{preset.get('name', preset_name)}'")
        sys.exit(0)
    else:
        print(f"  \033[1;33m[WARN]\033[0m Panel does not match preset '{preset.get('name', preset_name)}'")
        sys.exit(1)

elif action == "save":
    if not target_preset:
        print("  \033[0;31m[ERR]\033[0m Please provide a name for the new preset: taskbar.sh save <new-preset-name>")
        sys.exit(1)
    if not live:
        print("  \033[0;31m[ERR]\033[0m Cannot query live panel to export preset.")
        sys.exit(1)
    
    new_preset_id = target_preset.lower().replace(" ", "-")
    new_file = os.path.join(presets_dir, f"{new_preset_id}.json")
    save_data = {
        "id": new_preset_id,
        "name": target_preset.replace("-", " ").title(),
        "description": "Custom taskbar preset exported on live KDE session",
        "layoutType": live.get("layoutType", "single"),
        "location": live.get("location", "bottom"),
        "height": 42,
        "floating": live.get("floating", True),
        "lengthMode": live.get("lengthMode", "fill"),
        "hiding": live.get("hiding", "none"),
        "opacity": "adaptive",
        "alignment": live.get("alignment", "center"),
        "showOnlyCurrentDesktop": live.get("showOnlyCurrentDesktop", False),
        "showOnlyCurrentActivity": live.get("showOnlyCurrentActivity", True)
    }

    os.makedirs(presets_dir, exist_ok=True)
    with open(new_file, "w", encoding="utf-8") as fp:
        json.dump(save_data, fp, indent=2)
    print(f"  \033[0;32m[OK]\033[0m   Current panel state exported as preset: \033[1m{new_file}\033[0m")
    sys.exit(0)

elif action == "active":
    matched = None
    for p in load_all_presets():
        if preset_matches_live(p, live):
            matched = p.get("id")
            break
    if matched:
        print(matched)
    sys.exit(0)

PYEOF
        ;;
    *)
        log_error "Unknown command '$ACTION'. Use 'taskbar.sh help' for usage."
        exit 1
        ;;
esac
