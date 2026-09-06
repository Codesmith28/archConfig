#!/usr/bin/env bash
# ==============================================================================
# omArchy Optimizations - Common Library
# ==============================================================================

# Color formatting (ANSI-C strings)
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
NC=$'\033[0m' # No Color

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

# ==============================================================================
# Validation Functions
# ==============================================================================

validate_script() {
    local script="$1"

    if [[ ! -f "$script" ]]; then
        log_error "Script file not found: $script"
        return 1
    fi

    if [[ ! -s "$script" ]]; then
        log_error "Script file is empty: $script"
        return 1
    fi

    local syntax_err
    if ! syntax_err=$(bash -n "$script" 2>&1); then
        log_error "Syntax error in shell script: $script"
        [[ -n "$syntax_err" ]] && log_error "$syntax_err"
        return 1
    fi

    return 0
}

validate_service() {
    local service="$1"

    if [[ ! -f "$service" ]]; then
        log_error "Service file not found: $service"
        return 1
    fi

    if [[ ! -s "$service" ]]; then
        log_error "Service file is empty: $service"
        return 1
    fi

    if ! grep -q '^[[:space:]]*\[Unit\]' "$service"; then
        log_error "Service file missing [Unit] section: $service"
        return 1
    fi

    if ! grep -q '^[[:space:]]*\[Service\]' "$service"; then
        log_error "Service file missing [Service] section: $service"
        return 1
    fi

    if ! grep -q '^[[:space:]]*ExecStart=' "$service"; then
        log_error "Service file missing ExecStart directive: $service"
        return 1
    fi

    return 0
}

validate_optimization_dir() {
    local dir="$1"
    local dir_name
    dir_name="$(basename "$dir")"

    if [[ ! -d "$dir" ]]; then
        log_error "Not a directory: $dir"
        return 1
    fi

    local scripts=()
    local services=()

    while IFS= read -r -d '' f; do
        scripts+=("$f")
    done < <(find "$dir" -maxdepth 1 -type f -name "*.sh" -print0)

    while IFS= read -r -d '' f; do
        services+=("$f")
    done < <(find "$dir" -maxdepth 1 -type f -name "*.service" -print0)

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_warn "[$dir_name] No .sh scripts found."
        return 1
    fi

    if [[ ${#services[@]} -eq 0 ]]; then
        log_warn "[$dir_name] No .service files found."
        return 1
    fi

    local has_errors=0

    for script in "${scripts[@]}"; do
        if ! validate_script "$script"; then
            has_errors=1
        fi
    done

    for service in "${services[@]}"; do
        if ! validate_service "$service"; then
            has_errors=1
        fi
    done

    return $has_errors
}

# ==============================================================================
# Installation & Service Management Functions
# ==============================================================================

install_optimization() {
    local dir="$1"
    local bin_dest="${2:-/usr/local/bin}"
    local service_dest="${3:-/etc/systemd/system}"

    local dir_name
    dir_name="$(basename "$dir")"

    local scripts=()
    local services=()

    while IFS= read -r -d '' f; do
        scripts+=("$f")
    done < <(find "$dir" -maxdepth 1 -type f -name "*.sh" -print0)

    while IFS= read -r -d '' f; do
        services+=("$f")
    done < <(find "$dir" -maxdepth 1 -type f -name "*.service" -print0)

    # 1. Install all scripts
    for script in "${scripts[@]}"; do
        local script_name
        script_name="$(basename "$script")"
        run_as_root cp "$script" "$bin_dest/$script_name"
        run_as_root chmod 755 "$bin_dest/$script_name"
        log_success "[$dir_name] Installed executable: $bin_dest/$script_name"
    done

    # 2. Process and install service files
    for service in "${services[@]}"; do
        local service_name
        service_name="$(basename "$service")"
        local target_service="$service_dest/$service_name"

        local content
        content="$(cat "$service")"

        # Auto-rewrite ExecStart paths to $bin_dest/<script_name>
        for script in "${scripts[@]}"; do
            local script_name
            script_name="$(basename "$script")"
            content="$(echo "$content" | sed -E "s|^([[:space:]]*ExecStart=[[:space:]]*)([^[:space:]]*/)?${script_name}([[:space:]]*.*)$|\1${bin_dest}/${script_name}\3|")"
        done

        # If there is only one script in this module and ExecStart did not match the script name,
        # replace the binary path with $bin_dest/$script_name
        if [[ ${#scripts[@]} -eq 1 ]]; then
            local single_script_name
            single_script_name="$(basename "${scripts[0]}")"
            if ! echo "$content" | grep -q "${bin_dest}/${single_script_name}"; then
                content="$(echo "$content" | sed -E "s|^([[:space:]]*ExecStart=[[:space:]]*)([^[:space:]]+)([[:space:]]*.*)$|\1${bin_dest}/${single_script_name}\3|")"
            fi
        fi

        echo "$content" | run_as_root tee "$target_service" >/dev/null
        run_as_root chmod 644 "$target_service"
        log_success "[$dir_name] Installed systemd unit: $target_service"

        # 3. Enable and start the service
        enable_and_start_service "$service_name"
    done
}

enable_and_start_service() {
    local service_name="$1"
    log_info "Reloading systemd daemon..."
    run_as_root systemctl daemon-reload

    log_info "Enabling and starting service: $service_name"
    if run_as_root systemctl enable --now "$service_name"; then
        log_success "Service $service_name is active and enabled."
    else
        log_error "Failed to enable/start service $service_name"
        return 1
    fi
}
