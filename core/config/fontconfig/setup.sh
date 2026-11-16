#!/usr/bin/env bash
# ==============================================================================
# Fontconfig Setup & Global Override Script
# ==============================================================================
# Configures system-wide (/etc/fonts/local.conf) and user-space (~/.config/fontconfig)
# font preferences and overrides. Symlinks /etc/fonts/local.conf to fonts.conf
# so changes in fonts.conf take effect immediately across system & user queries.
#
# Usage:
#   ./setup.sh          # Symlinks system-wide & user-space (auto-elevates via sudo)
#   ./setup.sh --user   # User-space only (~/.config/fontconfig, no sudo required)
#   ./setup.sh --system # Explicit system-wide symlink and user-space sync (default)
# ==============================================================================
set -euo pipefail


# ------------------------------------------------------------------------------
# Environment & Path Resolution
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
FONTS_CONF="${SCRIPT_DIR}/fonts.conf"

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "${TARGET_USER}" 2>/dev/null | cut -d: -f6)"
TARGET_HOME="${TARGET_HOME:-$HOME}"

USER_CONFIG_DIR="${TARGET_HOME}/.config/fontconfig"
USER_FONTS_DIR="${TARGET_HOME}/.local/share/fonts"
SYSTEM_FONTS_DIR="/etc/fonts"
SYSTEM_LOCAL_CONF="${SYSTEM_FONTS_DIR}/local.conf"


# ------------------------------------------------------------------------------
# Output Styling & Helpers
# ------------------------------------------------------------------------------

if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    COLOR_RESET="\033[0m"
    COLOR_BOLD="\033[1m"
    COLOR_GREEN="\033[32m"
    COLOR_YELLOW="\033[33m"
    COLOR_BLUE="\033[34m"
else
    COLOR_RESET=""
    COLOR_BOLD=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_BLUE=""
fi

log_step()    { echo -e "\n${COLOR_BLUE}==>${COLOR_RESET} ${COLOR_BOLD}$*${COLOR_RESET}"; }
log_ok()      { echo -e "    ${COLOR_GREEN}✓${COLOR_RESET} $*"; }
log_warn()    { echo -e "    ${COLOR_YELLOW}⚠️  ${COLOR_RESET}$*"; }
log_error()   { echo -e "    \033[31m✗${COLOR_RESET} $*" >&2; }


# ------------------------------------------------------------------------------
# CLI Help & Parsing
# ------------------------------------------------------------------------------

print_usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Fontconfig Setup & Global Override Script

Options:
  -u, --user    Apply in user-space only (~/.config/fontconfig, no sudo required)
  --system      Apply system-wide (/etc/fonts/local.conf) & user-space (default)
  -h, --help    Show this help message
EOF
}


# ------------------------------------------------------------------------------
# Configuration Steps
# ------------------------------------------------------------------------------

print_banner() {
    local scope="$1"
    echo "=================================================="
    echo "  Fontconfig Setup & Verification"
    echo "=================================================="
    echo "  Target User : ${TARGET_USER}"
    echo "  Config Path : ${FONTS_CONF}"
    echo "  Scope       : ${scope}"
    echo "=================================================="
}


setup_system_config() {
    log_step "[1/3] Ensuring system-wide configuration symlink (${SYSTEM_LOCAL_CONF})..."
    mkdir -p "${SYSTEM_FONTS_DIR}"

    if [[ -L "${SYSTEM_LOCAL_CONF}" ]] && [[ "$(readlink -f "${SYSTEM_LOCAL_CONF}")" == "${FONTS_CONF}" ]]; then
        log_ok "Symlink verified: ${SYSTEM_LOCAL_CONF} -> ${FONTS_CONF}"
    else
        ln -sfn "${FONTS_CONF}" "${SYSTEM_LOCAL_CONF}"
        log_ok "Created symlink: ${SYSTEM_LOCAL_CONF} -> ${FONTS_CONF}"
    fi
}


setup_user_config() {
    local step_label="$1"
    log_step "${step_label} Ensuring user-level fontconfig symlink..."
    mkdir -p "${TARGET_HOME}/.config" "${USER_FONTS_DIR}"

    if [[ -L "${USER_CONFIG_DIR}" ]]; then
        local current_target
        current_target="$(readlink -f "${USER_CONFIG_DIR}" 2>/dev/null || true)"
        if [[ "${current_target}" == "${SCRIPT_DIR}" ]]; then
            log_ok "Symlink verified: ${USER_CONFIG_DIR} -> ${SCRIPT_DIR}"
        else
            echo "    Updating symlink: ${USER_CONFIG_DIR} -> ${SCRIPT_DIR}"
            ln -sfn "${SCRIPT_DIR}" "${USER_CONFIG_DIR}"
            log_ok "Updated symlink: ${USER_CONFIG_DIR} -> ${SCRIPT_DIR}"
        fi
    elif [[ -d "${USER_CONFIG_DIR}" ]]; then
        local backup_path="${USER_CONFIG_DIR}.bak_$(date +%s)"
        echo "    Backing up existing directory ${USER_CONFIG_DIR} -> ${backup_path}"
        mv "${USER_CONFIG_DIR}" "${backup_path}"
        ln -s "${SCRIPT_DIR}" "${USER_CONFIG_DIR}"
        log_ok "Created symlink: ${USER_CONFIG_DIR} -> ${SCRIPT_DIR}"
    else
        ln -s "${SCRIPT_DIR}" "${USER_CONFIG_DIR}"
        log_ok "Created symlink: ${USER_CONFIG_DIR} -> ${SCRIPT_DIR}"
    fi

    # Fix ownership when invoked via sudo for a standard user
    if [[ "${EUID}" -eq 0 ]] && [[ -n "${SUDO_USER:-}" ]] && [[ "${SUDO_USER}" != "root" ]]; then
        chown -h "${TARGET_USER}:" "${USER_CONFIG_DIR}" 2>/dev/null || true
        chown -R "${TARGET_USER}:" "${USER_FONTS_DIR}" 2>/dev/null || true
    fi
}


refresh_font_caches() {
    local step_label="$1"
    log_step "${step_label} Refreshing font caches..."

    if [[ "${EUID}" -eq 0 ]]; then
        fc-cache -f 2>/dev/null || true
        if [[ -n "${SUDO_USER:-}" ]] && [[ "${SUDO_USER}" != "root" ]]; then
            sudo -u "${TARGET_USER}" fc-cache -f 2>/dev/null || true
        fi
    else
        fc-cache -f 2>/dev/null || true
    fi
    log_ok "Font caches updated."
}


match_font() {
    local query="$1"
    if [[ "${EUID}" -eq 0 ]] && [[ -n "${SUDO_USER:-}" ]] && [[ "${SUDO_USER}" != "root" ]]; then
        sudo -u "${TARGET_USER}" fc-match "${query}"
    else
        fc-match "${query}"
    fi
}


verify_font_resolutions() {
    echo ""
    echo -e "${COLOR_BLUE}==>${COLOR_RESET} ${COLOR_BOLD}Verifying font resolutions:${COLOR_RESET}"
    echo "    --- Browser Default Overrides ---"

    local -a test_mono_fonts=(
        "monospace"
        "Liberation Mono"
        "Courier"
        "Courier New"
        "TeX Gyre Cursor"
    )

    local target_mono
    target_mono="$(match_font "monospace" | sed -n 's/.*: "\([^"]*\)".*/\1/p')"
    target_mono="${target_mono:-AdwaitaMono Nerd Font}"

    local all_mono_ok=true
    for t in "${test_mono_fonts[@]}"; do
        local res
        res="$(match_font "${t}")"
        printf "    %-20s -> %s\n" "${t}" "${res}"
        if [[ "${res}" != *"${target_mono}"* ]]; then
            all_mono_ok=false
        fi
    done

    echo ""
    echo "    --- System Default Families ---"
    local -a test_generic_fonts=(
        "sans-serif"
        "sans"
        "system-ui"
        "serif"
    )
    for t in "${test_generic_fonts[@]}"; do
        local res
        res="$(match_font "${t}")"
        printf "    %-20s -> %s\n" "${t}" "${res}"
    done

    echo ""
    if [[ "${all_mono_ok}" == true ]]; then
        echo -e "✨ ${COLOR_GREEN}Configuration complete! Monospace queries resolve to ${target_mono}.${COLOR_RESET}"
    else
        log_warn "Some monospace queries resolved to fallback fonts. Check installed fonts in ~/.local/share/fonts."
    fi
}


# ------------------------------------------------------------------------------
# Main Entry Point
# ------------------------------------------------------------------------------

main() {
    local apply_system=true

    for arg in "$@"; do
        case "${arg}" in
            --user|-u)
                apply_system=false
                ;;
            --system)
                apply_system=true
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: ${arg}"
                print_usage >&2
                exit 1
                ;;
        esac
    done

    # If system-wide installation requested and non-root, auto-elevate
    if [[ "${apply_system}" == true && "${EUID}" -ne 0 ]]; then
        if command -v sudo >/dev/null 2>&1; then
            exec sudo "${SCRIPT_DIR}/setup.sh" "$@"
        else
            log_warn "'sudo' not available; proceeding with user-space configuration only."
            apply_system=false
        fi
    fi

    local scope_text="System-Wide & User-Space"
    if [[ "${apply_system}" == false ]]; then
        scope_text="User-Space Only"
    fi

    print_banner "${scope_text}"

    if [[ "${apply_system}" == true ]]; then
        setup_system_config
        setup_user_config "[2/3]"
        refresh_font_caches "[3/3]"
    else
        setup_user_config "[1/2]"
        refresh_font_caches "[2/2]"
    fi

    verify_font_resolutions
}

main "$@"
