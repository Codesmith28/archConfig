# ~/.bashrc.d/04-compilers.bash - Dynamic GCC/G++ compiler discovery
# Automatically picks the latest installed GCC/G++ version without manual specification

detect_compilers() {
    local latest_gcc=""
    local latest_gpp=""

    # Search for versioned gcc binaries (e.g. gcc-17 down to gcc-10)
    for v in 17 16 15 14 13 12 11 10; do
        if command -v "gcc-$v" >/dev/null 2>&1; then
            latest_gcc="gcc-$v"
            break
        fi
    done

    # Search for versioned g++ binaries (e.g. g++-17 down to g++-10)
    for v in 17 16 15 14 13 12 11 10; do
        if command -v "g++-$v" >/dev/null 2>&1; then
            latest_gpp="g++-$v"
            break
        fi
    done

    # Fallback to standard gcc/g++ or clang/clang++
    if [ -z "$latest_gcc" ]; then
        if command -v gcc >/dev/null 2>&1; then
            latest_gcc="gcc"
        elif command -v clang >/dev/null 2>&1; then
            latest_gcc="clang"
        fi
    fi

    if [ -z "$latest_gpp" ]; then
        if command -v g++ >/dev/null 2>&1; then
            latest_gpp="g++"
        elif command -v clang++ >/dev/null 2>&1; then
            latest_gpp="clang++"
        fi
    fi

    [ -n "$latest_gcc" ] && export CC="$latest_gcc"
    [ -n "$latest_gpp" ] && export CXX="$latest_gpp"

    # Alias gcc/g++ to the latest versioned compiler if one was detected
    if [ -n "$latest_gcc" ] && [ "$latest_gcc" != "gcc" ]; then
        alias gcc="$latest_gcc"
    fi
    if [ -n "$latest_gpp" ] && [ "$latest_gpp" != "g++" ]; then
        alias g++="$latest_gpp"
    fi
}

detect_compilers
