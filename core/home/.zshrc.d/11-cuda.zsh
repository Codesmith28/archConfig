# ==============================================================================
# 11-cuda.zsh - Modular CUDA Environment Configuration
# ==============================================================================
# Safely configures CUDA paths without polluting global C/C++ include/library search paths.

configure_cuda() {
    local cuda_candidate=""
    local dir=""

    setopt local_options null_glob 2>/dev/null

    # 1. Inspect existing CUDA_HOME / CUDA_PATH or standard locations
    if [ -n "${CUDA_HOME:-}" ] && [ -d "$CUDA_HOME" ]; then
        cuda_candidate="$CUDA_HOME"
    elif [ -n "${CUDA_PATH:-}" ] && [ -d "$CUDA_PATH" ]; then
        cuda_candidate="$CUDA_PATH"
    elif [ -d "/usr/local/cuda" ]; then
        cuda_candidate="/usr/local/cuda"
    elif [ -d "/opt/cuda" ]; then
        cuda_candidate="/opt/cuda"
    else
        # Search for versioned installations (e.g. /usr/local/cuda-12.*, /usr/local/cuda-13.*)
        for dir in /usr/local/cuda-[0-9]*; do
            [ -d "$dir" ] && cuda_candidate="$dir"
        done
    fi

    # 2. Export environment if a valid CUDA installation was found
    if [ -n "$cuda_candidate" ] && [ -d "$cuda_candidate" ]; then
        export CUDA_HOME="$cuda_candidate"
        export CUDA_PATH="$cuda_candidate"

        # Prepend bin to PATH safely (avoiding duplicates)
        if [ -d "$CUDA_HOME/bin" ]; then
            case ":$PATH:" in
                *":$CUDA_HOME/bin:"*) ;;
                *) export PATH="$CUDA_HOME/bin:$PATH" ;;
            esac
        fi

        # Prepend lib64 to LD_LIBRARY_PATH safely (avoiding duplicates)
        if [ -d "$CUDA_HOME/lib64" ]; then
            case ":${LD_LIBRARY_PATH:-}:" in
                *":$CUDA_HOME/lib64:"*) ;;
                *) export LD_LIBRARY_PATH="$CUDA_HOME/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ;;
            esac
        fi

        # Scoped directory variables for explicit use in Makefiles, CMake, or Clangd.
        [ -d "$CUDA_HOME/include" ] && export CUDA_INC_DIR="$CUDA_HOME/include"
        [ -d "$CUDA_HOME/lib64" ] && export CUDA_LIB_DIR="$CUDA_HOME/lib64"
    fi
}

configure_cuda
unset -f configure_cuda

# Optional convenience helper for checking GPU driver and CUDA compiler status
cuda-status() {
    echo "=== GPU Hardware & Driver ==="
    if command -v nvidia-smi >/dev/null 2>&1; then
        nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
    else
        echo "nvidia-smi: not found (driver not installed or not in PATH)"
    fi

    echo ""
    echo "=== CUDA Development Toolkit ==="
    if command -v nvcc >/dev/null 2>&1; then
        nvcc --version | tail -n 2
    else
        echo "nvcc: not installed (CUDA Toolkit missing)"
        echo "CUDA_HOME: ${CUDA_HOME:-not set}"
    fi
}
