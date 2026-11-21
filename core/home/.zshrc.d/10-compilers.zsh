# ==============================================================================
# 10-compilers.zsh - Dynamic GCC/G++ compiler discovery
# ==============================================================================
# Automatically discovers and selects the newest installed GCC/G++ version without hardcoding

detect_compilers() {
    local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/archconfig/compilers.env"
    if [ "${1:-}" != "--force" ] && [ -f "$cache_file" ]; then
        # Fast path: load cached compiler configuration
        . "$cache_file"
        [ -n "${CC:-}" ] && [ "$CC" != "gcc" ] && alias gcc="$CC" 2>/dev/null || true
        [ -n "${CXX:-}" ] && [ "$CXX" != "g++" ] && alias g++="$CXX" 2>/dev/null || true
        return 0
    fi

    # Helper: return 0 if version v1 > version v2, 1 otherwise
    _compiler_ver_gt() {
        [ -z "$1" ] && return 1
        [ -z "$2" ] && return 0
        [ "$1" = "$2" ] && return 1

        local v1="$1." v2="$2."
        while [ -n "$v1" ] || [ -n "$v2" ]; do
            local p1="${v1%%.*}" p2="${v2%%.*}"
            v1="${v1#*.}"
            v2="${v2#*.}"
            p1="${p1//[^0-9]/}"
            p2="${p2//[^0-9]/}"
            [ -z "$p1" ] && p1=0
            [ -z "$p2" ] && p2=0
            if [ "$p1" -gt "$p2" ]; then
                return 0
            elif [ "$p1" -lt "$p2" ]; then
                return 1
            fi
        done
        return 1
    }

    local search_dirs=""
    local dir

    # Gather unique directories to inspect from PATH and standard compiler locations
    local orig_ifs="$IFS"
    IFS=:
    for dir in $PATH /opt/homebrew/bin /usr/local/bin /usr/bin; do
        [ -d "$dir" ] || continue
        dir="${dir%/}"
        case ":$search_dirs:" in
            *":$dir:"*) ;;
            *) search_dirs="${search_dirs:+$search_dirs:}$dir" ;;
        esac
    done
    IFS="$orig_ifs"

    local latest_gcc=""
    local latest_gcc_ver=""
    local latest_gpp=""
    local latest_gpp_ver=""

    setopt local_options null_glob 2>/dev/null

    local d bin name ver raw_ver
    local orig_ifs="$IFS"
    IFS=:
    for d in $search_dirs; do
        # Dynamically discover versioned gcc binaries (e.g. gcc-14, gcc-15, gcc-16...)
        for bin in "$d"/gcc-[0-9]*; do
            [ -x "$bin" ] && [ -f "$bin" ] || continue
            name="${bin##*/}"
            ver="${name#gcc-}"
            case "$ver" in *[!0-9.]* | "") continue ;; esac
            if [ -z "$latest_gcc_ver" ] || _compiler_ver_gt "$ver" "$latest_gcc_ver"; then
                latest_gcc_ver="$ver"
                if command -v "$name" >/dev/null 2>&1; then
                    latest_gcc="$name"
                else
                    latest_gcc="$bin"
                fi
            fi
        done

        # Dynamically discover versioned g++ binaries (e.g. g++-14, g++-15, g++-16...)
        for bin in "$d"/g++-[0-9]*; do
            [ -x "$bin" ] && [ -f "$bin" ] || continue
            name="${bin##*/}"
            ver="${name#g++-}"
            case "$ver" in *[!0-9.]* | "") continue ;; esac
            if [ -z "$latest_gpp_ver" ] || _compiler_ver_gt "$ver" "$latest_gpp_ver"; then
                latest_gpp_ver="$ver"
                if command -v "$name" >/dev/null 2>&1; then
                    latest_gpp="$name"
                else
                    latest_gpp="$bin"
                fi
            fi
        done
    done
    IFS="$orig_ifs"

    # Check unversioned gcc if present
    if command -v gcc >/dev/null 2>&1; then
        raw_ver=$(gcc -dumpversion 2>/dev/null)
        case "$raw_ver" in *[!0-9.]* | "") raw_ver="" ;; esac
        if [ -n "$raw_ver" ]; then
            if [ -z "$latest_gcc_ver" ] || _compiler_ver_gt "$raw_ver" "$latest_gcc_ver"; then
                latest_gcc="gcc"
                latest_gcc_ver="$raw_ver"
            fi
        elif [ -z "$latest_gcc" ]; then
            latest_gcc="gcc"
        fi
    fi

    # Check unversioned g++ if present
    if command -v g++ >/dev/null 2>&1; then
        raw_ver=$(g++ -dumpversion 2>/dev/null)
        case "$raw_ver" in *[!0-9.]* | "") raw_ver="" ;; esac
        if [ -n "$raw_ver" ]; then
            if [ -z "$latest_gpp_ver" ] || _compiler_ver_gt "$raw_ver" "$latest_gpp_ver"; then
                latest_gpp="g++"
                latest_gpp_ver="$raw_ver"
            fi
        elif [ -z "$latest_gpp" ]; then
            latest_gpp="g++"
        fi
    fi

    # Fallback to clang / clang++
    if [ -z "$latest_gcc" ]; then
        if command -v clang >/dev/null 2>&1; then
            latest_gcc="clang"
        fi
    fi
    if [ -z "$latest_gpp" ]; then
        if command -v clang++ >/dev/null 2>&1; then
            latest_gpp="clang++"
        fi
    fi

    [ -n "$latest_gcc" ] && export CC="$latest_gcc"
    [ -n "$latest_gpp" ] && export CXX="$latest_gpp"

    # Save to user cache for fast shell startup
    if [ -n "$latest_gcc" ] || [ -n "$latest_gpp" ]; then
        mkdir -p "${cache_file%/*}" 2>/dev/null || true
        cat <<EOF > "$cache_file" 2>/dev/null || true
export CC="${latest_gcc:-}"
export CXX="${latest_gpp:-}"
EOF
    fi

    # Alias gcc/g++ to the latest versioned compiler if one was detected
    if [ -n "$latest_gcc" ] && [ "$latest_gcc" != "gcc" ]; then
        alias gcc="$latest_gcc"
    fi
    if [ -n "$latest_gpp" ] && [ "$latest_gpp" != "g++" ]; then
        alias g++="$latest_gpp"
    fi

    unset -f _compiler_ver_gt
}

detect_compilers
unset -f detect_compilers
