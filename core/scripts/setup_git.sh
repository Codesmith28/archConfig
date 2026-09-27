#!/usr/bin/env bash
# ==============================================================================
# archConfig Universal Cross-Distro Git & SSH Multi-Profile Setup
# ==============================================================================
# Manages vanilla Git configuration and RSA 4096-bit SSH keys across platforms.
# Supports directory-scoped profiles (e.g. ~/work, ~/uni) isolated with
# includeIf and sshCommand, while defaulting to ~/.ssh/id_rsa everywhere else.
# ==============================================================================
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# ------------------------------------------------------------------------------
# 1. Dependency Validation
# ------------------------------------------------------------------------------
if ! command -v git >/dev/null 2>&1; then
    echo "❌ Error: Git is not installed on this system." >&2
    echo "" >&2
    echo "Please install Git using your distribution package manager:" >&2
    echo "  • Fedora         : sudo dnf install git" >&2
    echo "  • Arch Linux     : sudo pacman -S git" >&2
    echo "  • Ubuntu/Debian  : sudo apt update && sudo apt install git" >&2
    echo "  • macOS          : brew install git (or xcode-select --install)" >&2
    exit 1
fi

if ! command -v ssh >/dev/null 2>&1 || ! command -v ssh-keygen >/dev/null 2>&1; then
    echo "❌ Error: OpenSSH client (ssh, ssh-keygen) is not installed." >&2
    echo "Please install openssh / openssh-client and re-run." >&2
    exit 1
fi

# ------------------------------------------------------------------------------
# 2. CLI Options
# ------------------------------------------------------------------------------
NON_INTERACTIVE=false
DEFAULT_NAME=""
DEFAULT_EMAIL=""
PROFILE_INPUT=""
PROFILE_NAME=""
PROFILE_EMAIL=""
PROFILE_DIR=""

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --name <name>            Default Git user name
  --email <email>          Default Git user email
  --profile <label>        Create a directory-scoped profile (e.g. work, uni)
  --profile-name <name>    Git user name for the specified profile
  --profile-email <email>  Git user email for the specified profile
  --profile-dir <path>     Directory path for profile (default: ~/<label>)
  --non-interactive        Run without interactive prompts
  -h, --help               Show this help message

Examples:
  # Interactive setup (guided prompts for default and profiles):
  ./core/scripts/setup_git.sh

  # Non-interactive default setup:
  ./core/scripts/setup_git.sh --non-interactive --name "John Doe" --email "john@example.com"

  # Non-interactive profile setup:
  ./core/scripts/setup_git.sh --non-interactive --profile work --profile-name "John Doe" --profile-email "john@work.com"
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)
            DEFAULT_NAME="$2"
            shift 2
            ;;
        --email)
            DEFAULT_EMAIL="$2"
            shift 2
            ;;
        --profile)
            PROFILE_INPUT="$2"
            shift 2
            ;;
        --profile-name)
            PROFILE_NAME="$2"
            shift 2
            ;;
        --profile-email)
            PROFILE_EMAIL="$2"
            shift 2
            ;;
        --profile-dir)
            PROFILE_DIR="$2"
            shift 2
            ;;
        --non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use -h or --help for usage details." >&2
            exit 1
            ;;
    esac
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 archConfig Universal Git & SSH Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ------------------------------------------------------------------------------
# 3. Base .gitconfig Symlink & Local Config Initialization
# ------------------------------------------------------------------------------
CORE_GITCONFIG="$REPO_DIR/core/home/.gitconfig"
HOST_GITCONFIG="$HOME/.gitconfig"
LOCAL_GITCONFIG="$HOME/.gitconfig.local"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# If host .gitconfig is a regular file and .gitconfig.local does not exist,
# extract any existing user.name / user.email before symlinking
if [ -f "$HOST_GITCONFIG" ] && [ ! -L "$HOST_GITCONFIG" ]; then
    EXISTING_NAME="$(git config --file "$HOST_GITCONFIG" user.name 2>/dev/null || true)"
    EXISTING_EMAIL="$(git config --file "$HOST_GITCONFIG" user.email 2>/dev/null || true)"
    if [ ! -f "$LOCAL_GITCONFIG" ]; then
        touch "$LOCAL_GITCONFIG"
        [ -n "$EXISTING_NAME" ] && git config --file "$LOCAL_GITCONFIG" user.name "$EXISTING_NAME"
        [ -n "$EXISTING_EMAIL" ] && git config --file "$LOCAL_GITCONFIG" user.email "$EXISTING_EMAIL"
        echo "  📦 Migrated existing identity from ~/.gitconfig to ~/.gitconfig.local"
    fi
    BACKUP_PATH="$HOST_GITCONFIG.bak.$(date +'%Y%m%d_%H%M%S')"
    mv "$HOST_GITCONFIG" "$BACKUP_PATH"
    echo "  📦 Backed up existing ~/.gitconfig to $BACKUP_PATH"
fi

touch "$LOCAL_GITCONFIG"

# Symlink core/home/.gitconfig -> ~/.gitconfig
if [ -L "$HOST_GITCONFIG" ]; then
    CURRENT_TARGET="$(readlink "$HOST_GITCONFIG" 2>/dev/null || true)"
    if [ "$CURRENT_TARGET" != "$CORE_GITCONFIG" ]; then
        ln -snf "$CORE_GITCONFIG" "$HOST_GITCONFIG"
        echo "  → Updated symlink: $HOST_GITCONFIG -> $CORE_GITCONFIG"
    else
        echo "  ✓ Base .gitconfig already linked: $HOST_GITCONFIG -> $CORE_GITCONFIG"
    fi
else
    ln -snf "$CORE_GITCONFIG" "$HOST_GITCONFIG"
    echo "  → Linked: $HOST_GITCONFIG -> $CORE_GITCONFIG"
fi

# ------------------------------------------------------------------------------
# 4. Default Git Identity
# ------------------------------------------------------------------------------
CURRENT_NAME="$(git config --file "$LOCAL_GITCONFIG" user.name 2>/dev/null || git config --global user.name 2>/dev/null || echo "$USER")"
CURRENT_EMAIL="$(git config --file "$LOCAL_GITCONFIG" user.email 2>/dev/null || git config --global user.email 2>/dev/null || true)"

if [ -z "$DEFAULT_NAME" ]; then
    if [ "$NON_INTERACTIVE" = true ]; then
        DEFAULT_NAME="$CURRENT_NAME"
    else
        read -rp "Enter default Git username [$CURRENT_NAME]: " INPUT_VAL
        DEFAULT_NAME="${INPUT_VAL:-$CURRENT_NAME}"
    fi
fi

if [ -z "$DEFAULT_EMAIL" ]; then
    if [ "$NON_INTERACTIVE" = true ]; then
        DEFAULT_EMAIL="$CURRENT_EMAIL"
    else
        PROMPT_EMAIL="$CURRENT_EMAIL"
        [ -z "$PROMPT_EMAIL" ] && PROMPT_EMAIL="user@example.com"
        read -rp "Enter default Git email [$PROMPT_EMAIL]: " INPUT_VAL
        DEFAULT_EMAIL="${INPUT_VAL:-$CURRENT_EMAIL}"
    fi
fi

if [ -n "$DEFAULT_NAME" ]; then
    git config --file "$LOCAL_GITCONFIG" user.name "$DEFAULT_NAME"
fi
if [ -n "$DEFAULT_EMAIL" ]; then
    git config --file "$LOCAL_GITCONFIG" user.email "$DEFAULT_EMAIL"
fi

echo "  ✓ Default Git identity configured in ~/.gitconfig.local:"
echo "      name : $(git config --file "$LOCAL_GITCONFIG" user.name)"
echo "      email: $(git config --file "$LOCAL_GITCONFIG" user.email)"

# ------------------------------------------------------------------------------
# 5. Default SSH Key (RSA 4096-bit)
# ------------------------------------------------------------------------------
DEFAULT_KEY="$HOME/.ssh/id_rsa"
echo ""
echo "==> Verifying Default SSH Key (~/.ssh/id_rsa)..."

if [ -f "$DEFAULT_KEY" ]; then
    echo "  ✓ Default SSH key already exists at: $DEFAULT_KEY"
else
    echo "  🔑 Generating new 4096-bit RSA default SSH key..."
    ssh-keygen -t rsa -b 4096 -C "${DEFAULT_EMAIL:-$USER@$(hostname)}" -f "$DEFAULT_KEY" -N ""
    chmod 600 "$DEFAULT_KEY"
    chmod 644 "$DEFAULT_KEY.pub"
    echo "  ✓ Generated default key at $DEFAULT_KEY"
fi

# Add default key to ssh-agent if running
if [ -n "$SSH_AUTH_SOCK" ]; then
    ssh-add "$DEFAULT_KEY" 2>/dev/null || true
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📋 Default SSH Public Key (copy to GitHub / GitLab):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$DEFAULT_KEY.pub"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ------------------------------------------------------------------------------
# 6. Profile Configuration Function
# ------------------------------------------------------------------------------
configure_profile() {
    local prof_label="$1"
    local prof_name="$2"
    local prof_email="$3"
    local prof_dir="$4"

    # Normalize label to lowercase alphanumeric + hyphen
    prof_label="$(echo "$prof_label" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_-')"
    if [ -z "$prof_label" ]; then
        echo "  ⚠️ Empty profile name provided. Skipping."
        return 0
    fi

    # Target directory defaults to ~/<profile>
    local target_dir="${prof_dir:-$HOME/$prof_label}"
    mkdir -p "$target_dir"

    # Profile identity
    [ -z "$prof_name" ] && prof_name="$DEFAULT_NAME"
    if [ -z "$prof_email" ]; then
        if [ "$NON_INTERACTIVE" = false ]; then
            read -rp "  Enter Git email for profile '$prof_label': " prof_email
        fi
    fi
    [ -z "$prof_email" ] && prof_email="$DEFAULT_EMAIL"

    # SSH key storage inside ~/.ssh/profiles/<profile>/
    local ssh_profile_dir="$HOME/.ssh/profiles/$prof_label"
    mkdir -p "$ssh_profile_dir"
    chmod 700 "$HOME/.ssh/profiles" "$ssh_profile_dir"
    local profile_key="$ssh_profile_dir/id_rsa"

    if [ -f "$profile_key" ]; then
        echo "  ✓ SSH key for '$prof_label' already exists at: $profile_key"
    else
        echo "  🔑 Generating 4096-bit RSA SSH key for profile '$prof_label'..."
        ssh-keygen -t rsa -b 4096 -C "$prof_email" -f "$profile_key" -N ""
        chmod 600 "$profile_key"
        chmod 644 "$profile_key.pub"
        echo "  ✓ Generated key at $profile_key"
    fi

    # Profile-specific .gitconfig inside the profile directory
    local profile_config="$target_dir/.gitconfig"
    cat > "$profile_config" <<EOF
# Profile-specific Git configuration for: $prof_label
[user]
	name = $prof_name
	email = $prof_email

[core]
	sshCommand = ssh -i $profile_key -o IdentitiesOnly=yes
EOF
    chmod 644 "$profile_config"

    # Register includeIf directive in ~/.gitconfig.local
    local gitdir_pattern="$target_dir/"
    # Remove any existing includeIf for this directory to prevent duplicates
    git config --file "$LOCAL_GITCONFIG" --unset-all "includeIf.gitdir:$gitdir_pattern.path" 2>/dev/null || true
    git config --file "$LOCAL_GITCONFIG" --add "includeIf.gitdir:$gitdir_pattern.path" "$profile_config"

    echo ""
    echo "  ✅ Profile '$prof_label' configured successfully!"
    echo "      • Directory   : $target_dir"
    echo "      • Git Config  : $profile_config"
    echo "      • SSH Key     : $profile_key"
    echo "      • Scope       : Repositories inside $target_dir use this SSH key and identity."
    echo "                      Everywhere else continues using default ~/.ssh/id_rsa."
    echo ""
    echo "  📋 Profile SSH Public Key (copy to GitHub/GitLab for $prof_label):"
    echo "  ────────────────────────────────────────────────────────────"
    cat "$profile_key.pub"
    echo "  ────────────────────────────────────────────────────────────"
}

# ------------------------------------------------------------------------------
# 7. Specialized Profiles Prompt & Processing
# ------------------------------------------------------------------------------
echo ""
echo "==> Specialized Profiles (Directory-Scoped Git & SSH Keys)..."

if [ -n "$PROFILE_INPUT" ]; then
    configure_profile "$PROFILE_INPUT" "$PROFILE_NAME" "$PROFILE_EMAIL" "$PROFILE_DIR"
elif [ "$NON_INTERACTIVE" = false ]; then
    echo "Specialized profiles allow isolated SSH keys and emails for dedicated"
    echo "directories (e.g., 'work' -> ~/work, 'uni' -> ~/uni)."
    echo "If no profile is specified, your default SSH key is used everywhere."
    echo ""
    read -rp "Configure a specialized profile? Enter name (e.g. work, uni) or press Enter to skip: " USER_PROF
    while [ -n "$USER_PROF" ]; do
        read -rp "Enter Git name for profile '$USER_PROF' [$DEFAULT_NAME]: " PROF_NAME_IN
        [ -z "$PROF_NAME_IN" ] && PROF_NAME_IN="$DEFAULT_NAME"

        read -rp "Enter Git email for profile '$USER_PROF': " PROF_EMAIL_IN
        configure_profile "$USER_PROF" "$PROF_NAME_IN" "$PROF_EMAIL_IN" ""

        echo ""
        read -rp "Configure another profile? Enter name or press Enter to finish: " USER_PROF
    done
else
    echo "  ✓ Non-interactive mode with no --profile flag: using default SSH key everywhere."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Git & SSH setup completed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
