# ==============================================================================
# 01-history.zsh - Command history persistence & navigation options
# ==============================================================================

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "${HISTFILE:h}" 2>/dev/null || true
HISTSIZE=50000
SAVEHIST=50000

setopt SHARE_HISTORY          # Share history across open terminals in real time
setopt EXTENDED_HISTORY       # Record timestamps and elapsed duration
setopt HIST_IGNORE_ALL_DUPS   # Drop older duplicates
setopt HIST_REDUCE_BLANKS     # Trim extra whitespace
setopt HIST_IGNORE_SPACE      # Ignore commands starting with space
setopt HIST_VERIFY            # Verify history expansion before executing
setopt INC_APPEND_HISTORY     # Save immediately upon command execution

# Shell navigation
setopt AUTO_CD                # Type directory name to cd into it
setopt AUTO_PUSHD             # Push old directory onto stack
setopt PUSHD_IGNORE_DUPS      # Don't push duplicates
setopt PUSHD_SILENT           # Don't print directory stack after pushd/popd
