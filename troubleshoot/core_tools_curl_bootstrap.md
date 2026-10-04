# Troubleshooting & Runbook: Distro-Agnostic Core Toolchain Bootstrap via Curl

## Problem
When bootstrapping `archConfig` across heterogeneous environments (Fedora, Arch Linux, Ubuntu Desktop, Ubuntu Server, macOS, and minimal containers):
1. **Package Drift & Availability**: Core developer tools like `starship`, `leaf`, `lazydocker`, `yazi`, `herdr`, and `uv` may either be missing from standard distro repositories (e.g. older Ubuntu LTS releases) or require multiple diverging third-party PPAs/COPRs/AUR helpers.
2. **Root & Permission Restrictions**: In restricted environments (servers, dev containers, managed machines), users lack `sudo` or package manager permissions.
3. **Running Binary Lockout (`ETXTBSY`)**: Attempting to update an active binary (e.g. `leaf` or `herdr`) with `cp` returns:
   ```text
   cp: cannot create regular file '~/.local/bin/leaf': Text file busy
   ```

---

## Architecture & Root Cause

1. **User-Space Isolation (`~/.local/bin`)**:
   - `core/home/.profile` guarantees `~/.local/bin` and `~/.fzf/bin` are prepended to `PATH` across all login shells.
   - Installing self-contained binaries into `~/.local/bin` ensures 100% platform agnosticism with zero sudo requirements.

2. **Agnostic Release Resolution**:
   - Rather than relying on unauthenticated GitHub API endpoints (which encounter HTTP 403 rate limits on shared networks), release redirects via `curl -sSI "https://github.com/<owner>/<repo>/releases/latest"` are inspected to resolve release tags safely.

3. **In-Use Binary Replacement**:
   - In Linux, overwriting an executable currently mapped into a process's virtual memory triggers `ETXTBSY`. Unlinking or moving the file (`rm -f "$BIN_DIR/<tool>"` or using `install -m 755`) unlinks the existing directory entry while the operating system retains the open inode for the running process until it terminates.

---

## Implemented Solution

The automated runner [`core/scripts/setup_shell_dependencies.sh`](file:///home/codesmith28/archConfig/core/scripts/setup_shell_dependencies.sh) handles universal unattended installation:

```bash
# Check and install all missing core tools
./core/scripts/setup_shell_dependencies.sh

# Force update all tools to latest upstream releases
./core/scripts/setup_shell_dependencies.sh --update

# Target specific utilities
./core/scripts/setup_shell_dependencies.sh starship leaf lazydocker
```

### Supported Agnostic Core Dependencies
| Tool | Purpose | Source / Installer Method |
| :--- | :--- | :--- |
| **starship** | Cross-shell prompt | `curl -fsSL https://starship.rs/install.sh \| sh -s -- --yes --bin-dir ~/.local/bin` |
| **leaf** | Terminal markdown previewer | `curl -fsSL https://leaf.rivolink.mg/install.sh \| sh -s -- ~/.local/bin` |
| **zoxide** | Smart directory navigation | `curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \| sh` |
| **fzf** | Command-line fuzzy finder | Shallow clone into `~/.fzf` with non-interactive binary installer |
| **herdr** | AI coding agent multiplexer | `HERDR_INSTALL_DIR=~/.local/bin curl -fsSL https://herdr.dev/install.sh \| sh` |
| **lazydocker** | Terminal UI for Docker | Official GitHub release tarball extracted to `~/.local/bin/lazydocker` |
| **lazygit** | Terminal UI for Git | Official GitHub release tarball extracted to `~/.local/bin/lazygit` |
| **uv** | Python package & project manager | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| **yazi** | Terminal file manager & `ya` CLI | Prebuilt static musl / macOS GitHub release zip extracted to `~/.local/bin` |
| **eza** | Modern replacement for `ls` | Prebuilt static musl Linux release binary / Homebrew on macOS |
| **fastfetch** | System information fetcher | Prebuilt GitHub release standalone binary extracted to `~/.local/bin` |

---

## Verification & Health Check

Verify all core dependencies with a single loop:
```bash
for cmd in starship leaf zoxide fzf herdr lazydocker lazygit uv yazi eza fastfetch; do
    printf "%-12s: %s\n" "$cmd" "$(command -v "$cmd" 2>/dev/null || echo 'NOT FOUND')"
done
```
