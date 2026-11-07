#!/usr/bin/env bash
# ==============================================================================
# krohnkite.sh - Krohnkite Tiling Extension & State Persistence Manager
# ==============================================================================
# Manages installation, live dynamic resizing patch injection, window state
# persistence, and safe KWin 6 live session reloading for Krohnkite.
#
# Usage:
#   krohnkite.sh setup                 Full setup: install, patch, and live reload
#   krohnkite.sh install               Download and install Krohnkite v0.9.10.0
#   krohnkite.sh patch                 Inject surgical patches (resizing & persistence)
#   krohnkite.sh reload                Safely reload Krohnkite live via KWin D-Bus
#   krohnkite.sh status                Show live extension & KWin loading status
#   krohnkite.sh states                Print persisted window layouts from kwin.conf
#   krohnkite.sh verify                Run post-patch verification checks
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KROHNKITE_DIR="${HOME}/.local/share/kwin/scripts/krohnkite"
KROHNKITE_VER="0.9.10.0"
KROHNKITE_URL="https://codeberg.org/anametologin/Krohnkite/releases/download/${KROHNKITE_VER}/krohnkite.kwinscript"

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
    echo -e "${BOLD}Krohnkite Tiling Extension & State Persistence Manager${NC}

Usage:
  $(basename "$0") setup      Install, patch, and reload Krohnkite (Default)
  $(basename "$0") install    Ensure Krohnkite v${KROHNKITE_VER} is installed
  $(basename "$0") patch      Inject live resizing & layout persistence patches
  $(basename "$0") reload     Safely reload Krohnkite in KWin via D-Bus
  $(basename "$0") status     Check live script loading and patch integrity
  $(basename "$0") states     Display remembered window states from kwin.conf
  $(basename "$0") verify     Verify script loading, gaps, and shortcuts
  $(basename "$0") help       Show this help message"
}

cmd_install() {
    local needs_install=false
    if [[ ! -f "$KROHNKITE_DIR/metadata.json" ]]; then
        needs_install=true
    elif ! grep -q "\"Version\": \"${KROHNKITE_VER}\"" "$KROHNKITE_DIR/metadata.json" 2>/dev/null; then
        needs_install=true
    fi

    if [[ "$needs_install" == "true" ]]; then
        log_info "Installing Krohnkite tiling extension (v${KROHNKITE_VER})..."
        mkdir -p "${HOME}/.local/share/kwin/scripts"
        local tmp_dir="/tmp/krohnkite_install.$$"
        mkdir -p "$tmp_dir"
        if curl -fsSL -o "$tmp_dir/krohnkite.kwinscript" "$KROHNKITE_URL" 2>/dev/null; then
            if command -v kpackagetool6 >/dev/null 2>&1; then
                kpackagetool6 -t KWin/Script -u "$tmp_dir/krohnkite.kwinscript" >/dev/null 2>&1 || \
                kpackagetool6 -t KWin/Script -i "$tmp_dir/krohnkite.kwinscript" >/dev/null 2>&1 || true
            elif command -v kpackagetool5 >/dev/null 2>&1; then
                kpackagetool5 -t KWin/Script -u "$tmp_dir/krohnkite.kwinscript" >/dev/null 2>&1 || \
                kpackagetool5 -t KWin/Script -i "$tmp_dir/krohnkite.kwinscript" >/dev/null 2>&1 || true
            fi
            # Fallback if kpackagetool didn't extract or is missing:
            if [[ ! -f "$KROHNKITE_DIR/metadata.json" ]] && command -v unzip >/dev/null 2>&1; then
                mkdir -p "$KROHNKITE_DIR"
                unzip -qo "$tmp_dir/krohnkite.kwinscript" -d "$KROHNKITE_DIR"
            fi
            # Preserve pristine script.js.orig for deterministic patching
            if [[ -f "$KROHNKITE_DIR/contents/code/script.js" ]]; then
                cp "$KROHNKITE_DIR/contents/code/script.js" "$KROHNKITE_DIR/contents/code/script.js.orig"
            fi
            log_success "Krohnkite v${KROHNKITE_VER} installed into ${KROHNKITE_DIR}"
        else
            log_error "Failed to download Krohnkite package from ${KROHNKITE_URL}"
            rm -rf "$tmp_dir"
            return 1
        fi
        rm -rf "$tmp_dir"
    else
        log_info "Krohnkite v${KROHNKITE_VER} is already installed."
    fi
}

cmd_patch() {
    if [[ ! -d "$KROHNKITE_DIR" ]]; then
        log_warn "Krohnkite directory not found at ${KROHNKITE_DIR}. Running install first..."
        cmd_install
    fi

    # Ensure pristine upstream script.js.orig exists
    if [[ ! -f "$KROHNKITE_DIR/contents/code/script.js.orig" ]]; then
        if [[ -f "$KROHNKITE_DIR/contents/code/script.js" ]] && grep -q "class StackedLayout" "$KROHNKITE_DIR/contents/code/script.js" 2>/dev/null && ! grep -q "setRememberedState" "$KROHNKITE_DIR/contents/code/script.js" 2>/dev/null; then
            cp "$KROHNKITE_DIR/contents/code/script.js" "$KROHNKITE_DIR/contents/code/script.js.orig"
        else
            local tmp_dir="/tmp/krohnkite_orig.$$"
            mkdir -p "$tmp_dir"
            if curl -fsSL -o "$tmp_dir/krohnkite.kwinscript" "$KROHNKITE_URL" 2>/dev/null; then
                unzip -p "$tmp_dir/krohnkite.kwinscript" contents/code/script.js > "$KROHNKITE_DIR/contents/code/script.js.orig"
            fi
            rm -rf "$tmp_dir"
        fi
    fi

    python3 - "$KROHNKITE_DIR" << 'PYEOF'
import sys, os

krohnkite_dir = sys.argv[1]
qml_path = os.path.join(krohnkite_dir, "contents/ui/main.qml")
js_path = os.path.join(krohnkite_dir, "contents/code/script.js")
js_orig_path = os.path.join(krohnkite_dir, "contents/code/script.js.orig")

# --- 1. Patch main.qml for persistent window states & safe loader ordering ---
clean_qml = '''/*
    SPDX-FileCopyrightText: 2018 Eon S. Jeon <esjeon@hyunmu.am>
    SPDX-FileCopyrightText: 2024 Vjatcheslav V. Kolchkov <akl334@protonmail.ch>

    SPDX-License-Identifier: MIT
*/

import QtQuick 2.15
import QtCore
import org.kde.plasma.core as PlasmaCore;
import org.kde.plasma.components as Plasma;
import org.kde.kwin 3.0;
import org.kde.taskmanager as TaskManager
import "../code/script.js" as K

Item {
    id: scriptRoot
    property var runtime: null

    Loader {
        id: iconInstaller
        source: "iconinstaller.qml"

        onLoaded: item.install()
        onStatusChanged: {
            if (status === Loader.Error)
                console.warn("KROHNKITE: icon installer unavailable; "
                    + "install the Plasma5Support QML module or run install-icons.py manually");
        }
    }

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    Loader {
        id: popupDialog
        source: "popup.qml"

        function showNotification(text, duration) {
            var area = Workspace.clientArea(KWin.FullScreenArea, Workspace.activeScreen, Workspace.currentDesktop);
            this.item.show(text, area, duration);
        }
    }

    Loader {
        id: dragPreview
        source: "dragpreview.qml"

        function showRect(areaX, areaY, areaWidth, areaHeight, x, y, width, height, frameColor, borderColor) {
            if (this.item) this.item.showRect(areaX, areaY, areaWidth, areaHeight, x, y, width, height, frameColor, borderColor);
        }

        function hide() {
            if (this.item) this.item.hide();
        }
    }

    Loader {
        id: shortcutsLoader
        source: "shortcuts.qml"
    }

    Loader {
        id: dbusCallLoader
        source: "dbus.qml"
    }

    Settings {
        id: persistentStore
        category: "KrohnkiteWindowStates"
        property string rememberedStatesJson: "{}"

        function getStates() {
            try {
                return JSON.parse(rememberedStatesJson || "{}");
            } catch (e) {
                return {};
            }
        }

        function saveStates(statesObj) {
            try {
                rememberedStatesJson = JSON.stringify(statesObj);
            } catch (e) {
            }
        }
    }

    Component.onCompleted: {
        try {
            console.warn("KROHNKITE: initializing KWinRuntime...");
            const api = {
                "workspace": Workspace,
                // "options": Options,
                "kwin": KWin,
                "shortcuts": shortcutsLoader.item ? shortcutsLoader.item.shortcutList : [],
                "dbus": dbusCallLoader.item,
                "storage": persistentStore
            };

            runtime = new K.KWinRuntime(api);
            runtime.start();
            console.warn("KROHNKITE: KWinRuntime initialized and started successfully!");
        } catch (e) {
            console.error("KROHNKITE_ERROR during startup: " + e + "\\n" + e.stack);
        }
    }

    Component.onDestruction: {
        configReloadTimer.stop();
        if (runtime !== null) {
            runtime.dispose();
            runtime = null;
        }
    }

    Connections {
        target: Options

        function onConfigChanged() {
            configReloadTimer.restart();
        }
    }

    Timer {
        id: configReloadTimer
        interval: 100
        repeat: false

        onTriggered: {
            if (runtime !== null)
                runtime.reloadIfChanged();
        }
    }
}
'''
if os.path.isfile(qml_path):
    with open(qml_path, "r", encoding="utf-8") as f:
        curr_qml = f.read()
    if curr_qml.strip() != clean_qml.strip():
        with open(qml_path, "w", encoding="utf-8") as f:
            f.write(clean_qml)

# --- 2. Deterministic Surgical Patching of script.js from script.js.orig ---
source_path = js_orig_path if os.path.isfile(js_orig_path) else js_path
with open(source_path, "r", encoding="utf-8") as f:
    js = f.read()

# 1. KWinRuntime initStorage
t_init = '''        this._runningShortcutSequence = null;
        this.engine = new TilingEngine();
        this.control = new TilingController(this.engine);'''
r_init = '''        this._runningShortcutSequence = null;
        this.engine = new TilingEngine();
        this.engine.initStorage(api.storage);
        this.control = new TilingController(this.engine);'''
if t_init in js:
    js = js.replace(t_init, r_init)

# 2. interactiveMoveResizeStepped live layout adjustment
t_step = '''        this._connect(client.interactiveMoveResizeStepped, (geometry) => {
            if (!client || client.deleted)
                return;
            LOG === null || LOG === void 0 ? void 0 : LOG.send(LogModules.interactiveMoveResizeStepped, "eventFired", `window: caption:${client.caption} internalID:${client.internalId},interactiveMoveResizeStepped:${geometry}`, { winClass: [`${client.resourceClass}`] });
            if (client.resize)
                return;
            this.control.onWindowDragging(this, window, geometry, "windowInteractiveMoveResizeSteppedCB");
        });'''
r_step = '''        this._connect(client.interactiveMoveResizeStepped, (geometry) => {
            if (!client || client.deleted)
                return;
            LOG === null || LOG === void 0 ? void 0 : LOG.send(LogModules.interactiveMoveResizeStepped, "eventFired", `window: caption:${client.caption} internalID:${client.internalId},interactiveMoveResizeStepped:${geometry}`, { winClass: [`${client.resourceClass}`] });
            if (client.resize) {
                if (CONFIG.adjustLayout && CONFIG.adjustLayoutLive && window.isTiled) {
                    window.interactiveGeometry = toRect(geometry);
                    this.control.onWindowResize(this, window, "windowInteractiveMoveResizeSteppedCB");
                }
                return;
            }
            this.control.onWindowDragging(this, window, geometry, "windowInteractiveMoveResizeSteppedCB");
        });'''
if t_step in js:
    js = js.replace(t_step, r_step)

# 3. WindowClass interactiveGeometry property
t_wc = '''        this._dockTemplate = new Dock(DefaultDockCfg.instance);
        this._minSize = window.minSize;
        this._maxSize = window.maxSize;
    }'''
r_wc = '''        this._dockTemplate = new Dock(DefaultDockCfg.instance);
        this._minSize = window.minSize;
        this._maxSize = window.maxSize;
        this.interactiveGeometry = null;
    }'''
if t_wc in js:
    js = js.replace(t_wc, r_wc)

# 4. actualGeometry returns interactiveGeometry when live resizing
t_act = '''    get actualGeometry() {
        return this.window.geometry;
    }'''
r_act = '''    get actualGeometry() {
        if (this.interactiveGeometry)
            return this.interactiveGeometry;
        return this.window.geometry;
    }'''
if t_act in js:
    js = js.replace(t_act, r_act)

# 5. geometryDelta value equality check instead of identity
t_delta = '''    get geometryDelta() {
        if (this.geometry === this.actualGeometry)
            return null;
        return RectDelta.fromRects(this.geometry, this.actualGeometry);
    }'''
r_delta = '''    get geometryDelta() {
        if (!this.geometry || this.geometry.equals(this.actualGeometry))
            return null;
        return RectDelta.fromRects(this.geometry, this.actualGeometry);
    }'''
if t_delta in js:
    js = js.replace(t_delta, r_delta)

# 6. onWindowMoveOver float dragging with explicit override geometry
t_drag = '''            if (distance > 30) {
                window.floatGeometry = window.actualGeometry;
                window.state = WindowState.Floating;
                this.engine.arrange(ctx, reason, `${getMethodName()}:windowState=${window.state}:keepTilingOnDrag=${CONFIG.keepTilingOnDrag}`);
                return;
            }
        }
        window.commit(ctx);'''
r_drag = '''            if (distance > 30) {
                window.floatGeometry = window.actualGeometry;
                window.state = WindowState.Floating;
                this.engine.setRememberedState(window, WindowState.Floating, window.actualGeometry);
                this.engine.arrange(ctx, reason, `${getMethodName()}:windowState=${window.state}:keepTilingOnDrag=${CONFIG.keepTilingOnDrag}`);
                return;
            }
        }
        if (window.isFloating) {
            window.floatGeometry = window.actualGeometry;
            this.engine.setRememberedState(window, WindowState.Floating, window.actualGeometry);
        }
        window.commit(ctx);'''
if t_drag in js:
    js = js.replace(t_drag, r_drag)

# 7. onWindowResize and onWindowResizeOver handlers
t_res = '''    onWindowResize(ctx, window, reason) {
        if (CONFIG.adjustLayout &&
            CONFIG.adjustLayoutLive &&
            window.state === WindowState.Tiled) {
            this.engine.adjustLayout(window);
            this.engine.arrange(ctx, reason, `${getMethodName()}:windowState=${window.state}`);
        }
        else if (window.state === WindowState.Docked) {
            this.engine.adjustDock(window);
            this.engine.arrange(ctx, reason, `${getMethodName()}:windowState=${window.state}`);
        }
    }
    onWindowResizeOver(ctx, window, reason) {
        if (CONFIG.adjustLayout && window.isTiled) {
            this.engine.adjustLayout(window);
            this.engine.arrange(ctx, reason, `${getMethodName()}:windowState=${window.state}`);
        }
        else if (window.state === WindowState.Docked) {
            this.engine.adjustDock(window);
            this.engine.arrange(ctx, reason, `${getMethodName()}:windowState=${window.state}`);
        }
        else if (!CONFIG.adjustLayout)
            this.engine.enforceSize(ctx, window);
    }'''
r_res = '''    onWindowResize(ctx, window, reason) {
        if (CONFIG.adjustLayout &&
            CONFIG.adjustLayoutLive &&
            window.isTiled) {
            this.engine.adjustLayout(window);
            this.engine.arrange(ctx, reason, `${getMethodName()}:windowState=${window.state}`);
        }
        else if (window.state === WindowState.Docked) {
            this.engine.adjustDock(window);
            this.engine.arrange(ctx, reason, `${getMethodName()}:windowState=${window.state}`);
        }
    }
    onWindowResizeOver(ctx, window, reason) {
        window.interactiveGeometry = null;
        if (CONFIG.adjustLayout && window.isTiled) {
            this.engine.adjustLayout(window);
            this.engine.arrange(ctx, reason, `${getMethodName()}:windowState=${window.state}`);
        }
        else if (window.state === WindowState.Docked) {
            this.engine.adjustDock(window);
            this.engine.arrange(ctx, reason, `${getMethodName()}:windowState=${window.state}`);
        }
        else if (window.isFloating) {
            window.floatGeometry = window.actualGeometry;
            this.engine.setRememberedState(window, WindowState.Floating, window.actualGeometry);
        }
        else if (!CONFIG.adjustLayout)
            this.engine.enforceSize(ctx, window);
    }'''
if t_res in js:
    js = js.replace(t_res, r_res)

# 8. TilingEngine initStorage & setRememberedState (with tiled-geometry guard)
t_eng = '''        this._arrangePending = false;
        this._pendingExtraSurfaces = new Map();
        this._batchDepth = 0;
    }
    adjustLayout(basis) {'''
r_eng = '''        this._arrangePending = false;
        this._pendingExtraSurfaces = new Map();
        this._batchDepth = 0;
        this.rememberedStates = new Map();
        this.storage = null;
    }
    initStorage(storage) {
        this.storage = storage;
        if (storage && storage.getStates) {
            try {
                const saved = storage.getStates();
                if (saved && typeof saved === "object") {
                    for (const [key, val] of Object.entries(saved)) {
                        this.rememberedStates.set(key, val);
                    }
                }
            } catch (e) {
            }
        }
    }
    setRememberedState(window, state, overrideGeom) {
        if (!window || !window.windowClassName)
            return;
        const key = window.windowClassName;
        const existing = this.rememberedStates.get(key);
        let savedGeom = null;
        if (state === WindowState.Floating) {
            let candidate = null;
            if (overrideGeom && overrideGeom.width > 0 && overrideGeom.height > 0) {
                candidate = overrideGeom;
            } else if (window.isFloating && window.actualGeometry && window.actualGeometry.width > 0 && window.actualGeometry.height > 0) {
                const isTiledGeom = window.geometry && window.actualGeometry.equals(window.geometry);
                if (!isTiledGeom) {
                    candidate = window.actualGeometry;
                }
            }
            if (!candidate && window.floatGeometry && window.floatGeometry.width > 0 && window.floatGeometry.height > 0) {
                const isTiledGeom = window.geometry && window.floatGeometry.equals(window.geometry);
                if (!isTiledGeom) {
                    candidate = window.floatGeometry;
                }
            }
            if (!candidate && existing && existing.geometry && existing.geometry.width > 0) {
                candidate = existing.geometry;
            }
            if (candidate) {
                savedGeom = {
                    x: Math.round(candidate.x),
                    y: Math.round(candidate.y),
                    width: Math.round(candidate.width),
                    height: Math.round(candidate.height)
                };
            }
        } else if (state === WindowState.Tiled) {
            if (existing && existing.geometry && existing.geometry.width > 0) {
                savedGeom = existing.geometry;
            }
        }
        const entry = {
            state: state,
            geometry: savedGeom
        };
        this.rememberedStates.set(key, entry);
        if (this.storage && this.storage.saveStates) {
            try {
                const obj = {};
                for (const [k, v] of this.rememberedStates.entries()) {
                    obj[k] = v;
                }
                this.storage.saveStates(obj);
            } catch (e) {
            }
        }
    }
    adjustLayout(basis) {'''
if t_eng in js:
    js = js.replace(t_eng, r_eng)

# 9. DriverWindow windowClassName Wayland fallback
t_wcn = '''    get windowClassName() {
        return this.window.resourceClass;
    }'''
r_wcn = '''    get windowClassName() {
        return this.window.resourceClass || this.window.resourceName || this.window.desktopFileName || "";
    }'''
if t_wcn in js:
    js = js.replace(t_wcn, r_wcn)

# 9b. DriverWindow isSmallWindow heuristic & enhanced shouldFloat
t_sf = '''    get shouldFloat() {
        return (this.floatConfig.shouldFloat ||
            (CONFIG.floatSkipPager && this.window.skipPager) ||
            this.window.modal ||
            this.window.transient ||
            !this.window.resizeable ||
            (KWINCONFIG.floatUtility &&
                (this.window.dialog || this.window.splash || this.window.utility)));
    }'''
r_sf = '''    get isSmallWindow() {
        const geom = this._nativeFloatGeometry;
        if (!geom || geom.width <= 0 || geom.height <= 0)
            return false;

        const tileByDefaultClasses = [
            "ghostty", "konsole", "alacritty", "kitty", "foot", "wezterm", "xterm", "urxvt",
            "brave-browser", "google-chrome", "firefox", "chromium", "zen",
            "code", "codium", "kate", "neovim", "obsidian", "okular"
        ];
        const cls = (this.windowClassName || "").toLowerCase();
        for (const t of tileByDefaultClasses) {
            if (cls.indexOf(t) >= 0)
                return false;
        }

        const srf = this.surface;
        const area = srf ? srf.workingArea : toRect(this.resolvedOutput.geometry);
        if (!area || area.width <= 0 || area.height <= 0)
            return false;

        const w = geom.width;
        const h = geom.height;

        if (this.window.maxSize && this.window.maxSize.width > 0 && this.window.maxSize.height > 0) {
            if (this.window.maxSize.width <= 1100 && this.window.maxSize.height <= 850)
                return true;
        }

        const cap = (this.windowCaption || "").toLowerCase();
        const dialogKeywords = [
            "preferences", "settings", "configuration", "open file", "save file",
            "select file", "properties", "about ", "confirm", "authenticate",
            "password", "choose ", "rename ", "extract ", "dialog", "progress"
        ];
        for (const kw of dialogKeywords) {
            if (cap.indexOf(kw) >= 0)
                return true;
        }

        if (w <= 1000 && h <= 750)
            return true;

        if (w <= area.width * 0.55 && h <= area.height * 0.65 && (w * h) <= (area.width * area.height) * 0.35)
            return true;

        return false;
    }
    get shouldFloat() {
        return (this.floatConfig.shouldFloat ||
            (CONFIG.floatSkipPager && this.window.skipPager) ||
            this.window.modal ||
            this.window.transient ||
            (this.window.transientFor && this.window.transientFor !== null) ||
            !this.window.resizeable ||
            (this.window.minSize && this.window.maxSize &&
                this.window.maxSize.width > 0 && this.window.maxSize.height > 0 &&
                this.window.minSize.width === this.window.maxSize.width &&
                this.window.minSize.height === this.window.maxSize.height) ||
            (KWINCONFIG.floatUtility &&
                (this.window.dialog || this.window.splash || this.window.utility)) ||
            this.isSmallWindow);
    }'''
if t_sf in js:
    js = js.replace(t_sf, r_sf)

# 10. WindowClass state setter: allow Undecided -> Floating to set shouldCommitFloat
t_state = '''        if ((state === WindowState.Unmanaged || this.isTileable || this.isDocked) &&
            WindowClass.isFloatingState(value))
            this.shouldCommitFloat = true;'''
r_state = '''        if ((state === WindowState.Unmanaged || state === WindowState.Undecided || this.isTileable || this.isDocked) &&
            WindowClass.isFloatingState(value))
            this.shouldCommitFloat = true;'''
if t_state in js:
    js = js.replace(t_state, r_state)

# 11. getTileables restore remembered state and geometry
t_vis = '''        visibles.forEach((window) => {
            window.window.updateSrfTime(srf.id);
            if (!window.window.isCommittedEver && window.window.floatConfig.auto) {
                window.state = WindowState.Floating;
            }
            else if (window.state === WindowState.Undecided) {
                window.state = window.shouldFloat
                    ? WindowState.Floating
                    : WindowState.Tiled;
            }
        });'''
r_vis = '''        visibles.forEach((window) => {
            window.window.updateSrfTime(srf.id);
            if (window.state === WindowState.Undecided) {
                const remembered = this.rememberedStates.get(window.windowClassName);
                if (window.shouldFloat && (!remembered || remembered.geometry === null)) {
                    window.state = WindowState.Floating;
                    window.shouldCommitFloat = true;
                }
                else if (remembered !== undefined && (remembered.state === WindowState.Floating || remembered.state === WindowState.Tiled)) {
                    window.state = remembered.state;
                    if (remembered.state === WindowState.Floating) {
                        if (remembered.geometry && remembered.geometry.width > 0) {
                            window.floatGeometry = new Rect(
                                remembered.geometry.x,
                                remembered.geometry.y,
                                remembered.geometry.width,
                                remembered.geometry.height
                            );
                        }
                        window.shouldCommitFloat = true;
                    }
                }
                else if (!window.window.isCommittedEver && window.window.floatConfig.auto) {
                    window.state = WindowState.Floating;
                }
                else {
                    window.state = window.shouldFloat
                        ? WindowState.Floating
                        : WindowState.Tiled;
                }
            }
        });'''
if t_vis in js:
    js = js.replace(t_vis, r_vis)

# 12. unmanage multi-instance guard
t_unm = '''    unmanage(window) {
        if (window.state === WindowState.Docked) {
            this.docks.remove(window);
        }
        this.windows.remove(window);
    }'''
r_unm = '''    unmanage(window) {
        if (window.state === WindowState.Docked) {
            this.docks.remove(window);
        }
        if (window.windowClassName) {
            const isFloat = (window.isFloating || window.state === WindowState.Floating);
            const isTile = (window.isTiled || window.state === WindowState.Tiled);
            const otherWins = this.windows.list.filter((w) => w !== window && w.windowClassName === window.windowClassName);
            if (isFloat) {
                const geom = (window.actualGeometry && (!window.geometry || !window.actualGeometry.equals(window.geometry)))
                    ? window.actualGeometry
                    : window.floatGeometry;
                this.setRememberedState(window, WindowState.Floating, geom);
            } else if (isTile) {
                const hasFloatingOther = otherWins.some((w) => w.isFloating || w.state === WindowState.Floating);
                if (!hasFloatingOther) {
                    this.setRememberedState(window, WindowState.Tiled, null);
                }
            }
        }
        this.windows.remove(window);
    }'''
if t_unm in js:
    js = js.replace(t_unm, r_unm)

# 13. isToggleableState
t_togg = '''    static isToggleableState(state) {
        return (state === WindowState.Tiled ||
            state === WindowState.Floating ||
            state === WindowState.Docked);
    }'''
r_togg = '''    static isToggleableState(state) {
        return (state === WindowState.Tiled ||
            state === WindowState.Floating ||
            state === WindowState.TiledAfloat ||
            state === WindowState.Docked);
    }'''
if t_togg in js:
    js = js.replace(t_togg, r_togg)

# 14. toggleFloat (clean fallback to remembered/natural geometry, never tiled geometry)
t_tf = '''    toggleFloat(window) {
        if (WindowClass.isToggleableState(window.state)) {
            if (window.isFloating)
                window.state = window.previousState;
            else
                window.state = WindowState.Floating;
        }
    }'''
r_tf = '''    toggleFloat(window) {
        if (WindowClass.isToggleableState(window.state)) {
            if (window.isFloating) {
                const target = (window.previousState && window.previousState !== WindowState.Floating && window.previousState !== WindowState.Undecided)
                    ? window.previousState
                    : WindowState.Tiled;
                window.state = target;
                this.setRememberedState(window, target, null);
            }
            else {
                window.state = WindowState.Floating;
                const remembered = this.rememberedStates.get(window.windowClassName);
                let targetGeom = null;
                if (remembered && remembered.geometry && remembered.geometry.width > 0) {
                    targetGeom = new Rect(
                        remembered.geometry.x,
                        remembered.geometry.y,
                        remembered.geometry.width,
                        remembered.geometry.height
                    );
                } else if (window.floatGeometry && (!window.geometry || !window.floatGeometry.equals(window.geometry))) {
                    targetGeom = window.floatGeometry;
                } else {
                    const workingArea = window.surface ? window.surface.workingArea : null;
                    if (workingArea) {
                        const defW = Math.min(Math.round(workingArea.width * 0.6), Math.max(window.minSize.width || 0, 960));
                        const defH = Math.min(Math.round(workingArea.height * 0.7), Math.max(window.minSize.height || 0, 600));
                        const defX = workingArea.x + Math.round((workingArea.width - defW) / 2);
                        const defY = workingArea.y + Math.round((workingArea.height - defH) / 2);
                        targetGeom = new Rect(defX, defY, defW, defH);
                    }
                }
                if (targetGeom) {
                    window.floatGeometry = targetGeom;
                    window.shouldCommitFloat = true;
                    this.setRememberedState(window, WindowState.Floating, targetGeom);
                } else {
                    window.shouldCommitFloat = true;
                    this.setRememberedState(window, WindowState.Floating, null);
                }
            }
        }
    }'''
if t_tf in js:
    js = js.replace(t_tf, r_tf)

# 15. floatAll
t_fa = '''    floatAll(ctx, srf) {
        const windows = this.windows.getVisibleWindows(srf);
        const numFloats = windows.reduce((count, window) => {
            return window.state === WindowState.Floating ? count + 1 : count;
        }, 0);
        if (numFloats === 0) {
            windows.forEach((window) => {
                if (WindowClass.isToggleableState(window.state))
                    window.state = WindowState.Floating;
            });
            ctx.showNotification("Float All");
        }
        else {
            windows.forEach((window) => {
                if (WindowClass.isToggleableState(window.state))
                    window.state = window.previousState;
            });
            ctx.showNotification("Tile All");
        }
    }'''
r_fa = '''    floatAll(ctx, srf) {
        const windows = this.windows.getVisibleWindows(srf);
        const numFloats = windows.reduce((count, window) => {
            return (window.isFloating || window.state === WindowState.Floating) ? count + 1 : count;
        }, 0);
        if (numFloats === 0) {
            windows.forEach((window) => {
                if (WindowClass.isToggleableState(window.state)) {
                    window.state = WindowState.Floating;
                    window.shouldCommitFloat = true;
                    this.setRememberedState(window, WindowState.Floating);
                }
            });
            ctx.showNotification("Float All");
        }
        else {
            windows.forEach((window) => {
                if (WindowClass.isToggleableState(window.state)) {
                    window.state = WindowState.Tiled;
                    this.setRememberedState(window, WindowState.Tiled);
                }
            });
            ctx.showNotification("Tile All");
        }
    }'''
if t_fa in js:
    js = js.replace(t_fa, r_fa)

# 16. ToggleFloat shortcut notification
t_sc_tf = '''            case KrohnkiteAction.ToggleFloat:
                if (window)
                    this.engine.toggleFloat(window);
                break;'''
r_sc_tf = '''            case KrohnkiteAction.ToggleFloat:
                if (window) {
                    this.engine.toggleFloat(window);
                    ctx.showNotification(window.isFloating ? "Float Window" : "Tile Window");
                }
                break;'''
if t_sc_tf in js:
    js = js.replace(t_sc_tf, r_sc_tf)

# 17. resizeFloat shortcut updates floatGeometry and persists
t_rf = '''        const geometry = window.actualGeometry;
        const width = geometry.width + hStepSize * hStep;
        const height = geometry.height + vStepSize * vStep;
        window.forceSetGeometry(ctx, new Rect(geometry.x, geometry.y, width, height));
    }'''
r_rf = '''        const geometry = window.actualGeometry;
        const width = geometry.width + hStepSize * hStep;
        const height = geometry.height + vStepSize * vStep;
        const newGeom = new Rect(geometry.x, geometry.y, width, height);
        window.floatGeometry = newGeom;
        window.forceSetGeometry(ctx, newGeom);
        this.setRememberedState(window, WindowState.Floating, newGeom);
    }'''
if t_rf in js:
    js = js.replace(t_rf, r_rf)

# 18. _moveFloat shortcut updates floatGeometry and persists
t_mf = '''        if (CONFIG.movePointerOnFocus) {
            window.moveMouseToFocus();
        }
        window.forceSetGeometry(ctx, new Rect(x, y, geometry.width, geometry.height));
    }'''
r_mf = '''        if (CONFIG.movePointerOnFocus) {
            window.moveMouseToFocus();
        }
        const newGeom = new Rect(x, y, geometry.width, geometry.height);
        window.floatGeometry = newGeom;
        window.forceSetGeometry(ctx, newGeom);
        this.setRememberedState(window, WindowState.Floating, newGeom);
    }'''
if t_mf in js:
    js = js.replace(t_mf, r_mf)

# 19. enforceSize floating commit support for Wayland mapping
t_enf = '''    enforceSize(ctx, window) {
        if (window.isRelocationPending || window.isSendingToOutput)
            return;
        if (window.isTiled && !window.actualGeometry.equals(window.geometry)) {
            const srfId = window.surface.id;
            ctx.setTimeout(() => {
                if (window.isAlive() &&
                    !window.isRelocationPending &&
                    !window.isSendingToOutput &&
                    window.isTiled &&
                    window.surface.id === srfId)
                    window.commit(ctx);
            }, 10);
        }
    }'''
r_enf = '''    enforceSize(ctx, window) {
        if (window.isRelocationPending || window.isSendingToOutput)
            return;
        if (window.isTiled && !window.actualGeometry.equals(window.geometry)) {
            const srfId = window.surface.id;
            ctx.setTimeout(() => {
                if (window.isAlive() &&
                    !window.isRelocationPending &&
                    !window.isSendingToOutput &&
                    window.isTiled &&
                    window.surface.id === srfId)
                    window.commit(ctx);
            }, 10);
        }
        else if (window.isFloating && window.shouldCommitFloat) {
            ctx.setTimeout(() => {
                if (window.isAlive() &&
                    !window.isRelocationPending &&
                    !window.isSendingToOutput &&
                    window.isFloating &&
                    window.shouldCommitFloat)
                    window.commit(ctx);
            }, 20);
        }
    }'''
if t_enf in js:
    js = js.replace(t_enf, r_enf)

# 20. BinaryTreeLayout dynamic adjust, ratio preservation, and clone fix
t_bt = '''class BinaryTreeLayout {
    get description() {
        return "BTree";
    }
    constructor(capacity) {
        this.classID = BinaryTreeLayout.id;
        this.capacity = capacity !== undefined ? capacity : null;
        this.parts = new HalfSplitLayoutPart(new FillLayoutPart(), new FillLayoutPart());
        this.parts.angle = 0;
    }
    apply(ctx, tileables, area, gap) {
        tileables.forEach((tileable) => (tileable.state = WindowState.Tiled));
        this.create_parts(tileables.length);
        let rectangles = this.parts.apply(area, tileables, gap);
        rectangles.forEach((geometry, i) => {
            tileables[i].geometry = geometry;
        });
    }
    create_parts(tiles_len) {
        let head = this.get_head();
        head.angle = 0;'''
r_bt = '''class BinaryTreeLayout {
    get description() {
        return "BTree";
    }
    constructor(capacity) {
        this.classID = BinaryTreeLayout.id;
        this.capacity = capacity !== undefined ? capacity : null;
        this.parts = new HalfSplitLayoutPart(new FillLayoutPart(), new FillLayoutPart());
        this.parts.angle = 0;
        this.tiles_len = 0;
    }
    adjust(area, tiles, basis, delta, gap) {
        this.parts.adjust(area, tiles, basis, delta, gap);
    }
    apply(ctx, tileables, area, gap) {
        tileables.forEach((tileable) => (tileable.state = WindowState.Tiled));
        if (this.tiles_len !== tileables.length) {
            this.create_parts(tileables.length);
            this.tiles_len = tileables.length;
        }
        let rectangles = this.parts.apply(area, tileables, gap);
        rectangles.forEach((geometry, i) => {
            tileables[i].geometry = geometry;
        });
    }
    create_parts(tiles_len) {
        const prevRatio = this.parts ? this.parts.ratio : 0.5;
        let head = this.get_head();
        head.angle = 0;
        head.ratio = prevRatio;'''
if t_bt in js:
    js = js.replace(t_bt, r_bt)

t_btc = '''    clone() {
        const other = new StackedLayout();
        return other;
    }
    toString() {
        return "BTreeLayout()";
    }
}'''
r_btc = '''    clone() {
        const other = new BinaryTreeLayout(this.capacity);
        other.parts = this.parts;
        other.tiles_len = this.tiles_len;
        return other;
    }
    toString() {
        return "BTreeLayout()";
    }
}'''
if t_btc in js:
    js = js.replace(t_btc, r_btc)

with open(js_path, "w", encoding="utf-8") as f:
    f.write(js)

# Clean up stale 'Tiled' entries with no geometry for known small windows
stale_small_apps = [
    "org.kde.drkonqi.coredump.gui",
    "org.kde.kfontview",
    "org.kde.plasma-welcome",
    "org.kde.plasma.emojier",
    "org.opengamingcollective.rog-control-center"
]
conf_path = os.path.expanduser("~/.config/kde.org/kwin.conf")
if os.path.exists(conf_path):
    try:
        import configparser, json
        cfg = configparser.ConfigParser(strict=False)
        cfg.optionxform = str
        cfg.read(conf_path)
        if cfg.has_section("KrohnkiteWindowStates"):
            raw = cfg.get("KrohnkiteWindowStates", "rememberedStatesJson", fallback="{}")
            data = json.loads(raw)
            if isinstance(data, str):
                data = json.loads(data)
            changed = False
            for app in stale_small_apps:
                if app in data and isinstance(data[app], dict) and data[app].get("state") == "Tiled" and not data[app].get("geometry"):
                    del data[app]
                    changed = True
            if changed:
                cfg.set("KrohnkiteWindowStates", "rememberedStatesJson", json.dumps(data))
                with open(conf_path, "w", encoding="utf-8") as f:
                    cfg.write(f)
    except Exception:
        pass

print("    ✓ Patched Krohnkite for dynamic resizing, auto-floating small windows & state persistence")
PYEOF
}

cmd_reload() {
    python3 - "$KROHNKITE_DIR" << 'PYEOF'
import sys, os
try:
    import dbus
    bus = dbus.SessionBus()
    kwin_scripting = bus.get_object("org.kde.KWin", "/Scripting")
    s_iface = dbus.Interface(kwin_scripting, "org.kde.kwin.Scripting")
    krohnkite_dir = sys.argv[1]
    qml_path = os.path.join(krohnkite_dir, "contents/ui/main.qml")
    if os.path.exists(qml_path):
        if s_iface.isScriptLoaded("krohnkite"):
            s_iface.unloadScript("krohnkite")
        s_iface.loadDeclarativeScript(qml_path, "krohnkite", signature="ss")
    
    kwin = bus.get_object("org.kde.KWin", "/KWin")
    kwin.reconfigure(dbus_interface="org.kde.KWin")
    print("    ✓ Krohnkite live script reloaded via KWin D-Bus interface")
except Exception as e:
    print(f"    ℹ Note: Live D-Bus reload deferred ({e}); changes will activate on next login")
PYEOF
}

cmd_status() {
    echo -e "${BOLD}Krohnkite Status Overview:${NC}"
    if [[ -d "$KROHNKITE_DIR" ]]; then
        echo -e "  Installed Directory: ${GREEN}${KROHNKITE_DIR}${NC}"
        if [[ -f "$KROHNKITE_DIR/metadata.json" ]]; then
            local ver
            ver=$(grep -o '"Version": "[^"]*"' "$KROHNKITE_DIR/metadata.json" | cut -d'"' -f4 || echo "unknown")
            echo -e "  Package Version:     ${GREEN}v${ver}${NC}"
        fi
    else
        echo -e "  Installed Directory: ${RED}Not found${NC}"
    fi

    python3 - "$KROHNKITE_DIR" << 'PYEOF'
import sys, os
krohnkite_dir = sys.argv[1]
qml_path = os.path.join(krohnkite_dir, "contents/ui/main.qml")
js_path = os.path.join(krohnkite_dir, "contents/code/script.js")

qml_ok = False
if os.path.exists(qml_path):
    with open(qml_path, "r", encoding="utf-8") as f:
        c = f.read()
        qml_ok = "persistentStore" in c and "shortcutsLoader.item ? shortcutsLoader.item.shortcutList : []" in c

js_ok = False
if os.path.exists(js_path):
    with open(js_path, "r", encoding="utf-8") as f:
        c = f.read()
        js_ok = "interactiveGeometry" in c and "setRememberedState" in c and "WindowState.TiledAfloat" in c

print(f"  main.qml Patched:    {'✓ Yes' if qml_ok else '✗ No'}")
print(f"  script.js Patched:   {'✓ Yes' if js_ok else '✗ No'}")

try:
    import dbus
    bus = dbus.SessionBus()
    ks = bus.get_object("org.kde.KWin", "/Scripting")
    iface = dbus.Interface(ks, "org.kde.kwin.Scripting")
    loaded = iface.isScriptLoaded("krohnkite")
    print(f"  KWin Script Loaded:  {'✓ Yes (Active)' if loaded else '✗ No (Inactive)'}")
except Exception as e:
    print(f"  KWin Script Loaded:  ? Unable to query D-Bus ({e})")
PYEOF
}

cmd_states() {
    python3 - << 'PYEOF'
import os, configparser, json, sys
cfg = configparser.ConfigParser(strict=False)
cfg.optionxform = str
conf_path = os.path.expanduser("~/.config/kde.org/kwin.conf")
if not os.path.exists(conf_path):
    print("No kwin.conf found at ~/.config/kde.org/kwin.conf")
    sys.exit(0)

cfg.read(conf_path)
raw = cfg.get("KrohnkiteWindowStates", "rememberedStatesJson", fallback="{}")
try:
    data = json.loads(raw)
    if isinstance(data, str):
        data = json.loads(data)
    print(f"Persisted Window States ({len(data)} applications tracked):")
    for app_name, state_info in sorted(data.items()):
        if isinstance(state_info, dict):
            st = state_info.get("state", "Unknown")
            geom = state_info.get("geometry", None)
            if geom:
                lbl = "geom" if st == "Floating" else "cached float"
                geom_str = f" [{lbl}: {geom['width']}x{geom['height']}+{geom['x']}+{geom['y']}]"
            else:
                geom_str = ""
            print(f"  • {app_name:<40} -> {st}{geom_str}")
        else:
            print(f"  • {app_name:<40} -> {state_info}")
except Exception as e:
    print(f"Error parsing rememberedStatesJson: {e}\nRaw content:\n{raw}")
PYEOF
}

cmd_verify() {
    log_info "Verifying Krohnkite installation and active configuration..."
    local all_ok=true

    if [[ ! -d "$KROHNKITE_DIR" ]]; then
        log_error "Krohnkite extension directory missing"
        all_ok=false
    fi

    local kwinrc_path="${HOME}/.config/kwinrc"
    if [[ -f "$kwinrc_path" ]]; then
        if grep -q "krohnkiteEnabled=true" "$kwinrc_path" 2>/dev/null; then
            log_success "Krohnkite plugin enabled in kwinrc"
        else
            log_warn "Krohnkite plugin not enabled in kwinrc"
            all_ok=false
        fi
        if grep -q "binaryTreeLayoutOrder=1" "$kwinrc_path" 2>/dev/null; then
            log_success "BinaryTree layout enabled in kwinrc"
        else
            log_warn "BinaryTree layout not primary in kwinrc"
            all_ok=false
        fi
    fi

    # Check live D-Bus status
    python3 - << 'PYEOF'
import sys
try:
    import dbus
    bus = dbus.SessionBus()
    ks = bus.get_object("org.kde.KWin", "/Scripting")
    iface = dbus.Interface(ks, "org.kde.kwin.Scripting")
    loaded = iface.isScriptLoaded("krohnkite")
    if loaded:
        print("    ✓ Krohnkite is active in running KWin instance")
    else:
        print("    ⚠ Krohnkite is NOT loaded in running KWin instance")
        sys.exit(1)
except Exception as e:
    print(f"    ℹ D-Bus verification skipped: {e}")
PYEOF

    if [[ "$all_ok" == "true" ]]; then
        log_success "Krohnkite verification passed!"
    else
        log_warn "Some Krohnkite verification checks failed."
    fi
}

cmd_setup() {
    cmd_install
    cmd_patch
    cmd_reload
}

ACTION="${1:-setup}"

case "$ACTION" in
    -h|--help|help)
        show_help
        exit 0
        ;;
    setup)
        cmd_setup
        ;;
    install)
        cmd_install
        ;;
    patch)
        cmd_patch
        ;;
    reload)
        cmd_reload
        ;;
    status)
        cmd_status
        ;;
    states)
        cmd_states
        ;;
    verify)
        cmd_verify
        ;;
    *)
        log_error "Unknown action: $ACTION"
        show_help
        exit 1
        ;;
esac
