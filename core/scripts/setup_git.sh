#!/usr/bin/env bash
# ==============================================================================
# archConfig Universal Cross-Distro Git & SSH Multi-Profile Setup
# ==============================================================================
# Manages vanilla Git configuration and SSH keys (Ed25519 / RSA) across platforms.
# Supports directory-scoped profiles (e.g. ~/work, ~/uni) isolated with
# includeIf and sshCommand, while keeping all keys directly in ~/.ssh without nesting.
#
# Key naming convention:
#   • default : ~/.ssh/id_ed25519 (or id_rsa) - no suffix
#   • work    : ~/.ssh/id_ed25519_work (or id_rsa_work) - _work suffix
#   • uni     : ~/.ssh/id_ed25519_uni (or id_rsa_uni) - _uni suffix
#   • <custom>: ~/.ssh/id_ed25519_<custom> - _<custom> suffix
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
CLI_PROFILE=""
CLI_NAME=""
CLI_EMAIL=""
CLI_DIR=""
KEY_TYPE="ed25519"
KEY_TYPE_EXPLICIT=false

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Revamped cross-distro Git & SSH multi-profile setup. All SSH keys are stored
directly inside ~/.ssh/ with suffix matching the profile (e.g. id_ed25519_work).

Options:
  --profile <type>         Profile type: default, uni, work, or custom label
  --name <name>            Git user name / alias for the profile
  --profile-name <name>    Alias for --name
  --email <email>          Git user email for the profile
  --profile-email <email>  Alias for --email
  --dir <path>             Workspace directory for profile (default: ~/<type>)
  --profile-dir <path>     Alias for --dir
  --key-type <ed25519|rsa> SSH key algorithm to generate (default: ed25519)
  -t <ed25519|rsa>         Alias for --key-type
  --non-interactive        Run without interactive prompts
  -h, --help               Show this help message

Examples:
  # Interactive setup (prompts for profile type, name/email, and generates keys):
  ./core/scripts/setup_git.sh

  # Non-interactive default profile setup:
  ./core/scripts/setup_git.sh --non-interactive --profile default --name "Codesmith" --email "user@example.com"

  # Non-interactive work profile setup:
  ./core/scripts/setup_git.sh --non-interactive --profile work --name "Real Name" --email "name@work.com"

  # Non-interactive university profile setup:
  ./core/scripts/setup_git.sh --non-interactive --profile uni --name "Real Name" --email "student@uni.edu"
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)
            CLI_PROFILE="$2"
            shift 2
            ;;
        --name|--profile-name)
            CLI_NAME="$2"
            shift 2
            ;;
        --email|--profile-email)
            CLI_EMAIL="$2"
            shift 2
            ;;
        --dir|--profile-dir)
            CLI_DIR="$2"
            shift 2
            ;;
        --key-type|-t)
            KEY_TYPE="$2"
            KEY_TYPE_EXPLICIT=true
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
        echo "  ✓ Base .gitconfig linked: $HOST_GITCONFIG -> $CORE_GITCONFIG"
    fi
else
    ln -snf "$CORE_GITCONFIG" "$HOST_GITCONFIG"
    echo "  → Linked: $HOST_GITCONFIG -> $CORE_GITCONFIG"
fi

# ------------------------------------------------------------------------------
# 4. Profile Configuration Function
# ------------------------------------------------------------------------------
configure_profile() {
    local target_profile="$1"
    local input_name="$2"
    local input_email="$3"
    local input_dir="$4"

    # Normalize profile label: lowercase alphanumeric + underscores/hyphens
    target_profile="$(echo "$target_profile" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_-')"
    [ -z "$target_profile" ] && target_profile="default"

    local is_default=false
    [ "$target_profile" = "default" ] && is_default=true

    # Current default values from ~/.gitconfig.local or global git config
    local default_name
    default_name="$(git config --file "$LOCAL_GITCONFIG" user.name 2>/dev/null || git config --global user.name 2>/dev/null || echo "$USER")"
    local default_email
    default_email="$(git config --file "$LOCAL_GITCONFIG" user.email 2>/dev/null || git config --global user.email 2>/dev/null || true)"

    echo ""
    echo "────────────────────────────────────────────────────────────"
    if [ "$is_default" = true ]; then
        echo "  ⚙️  Configuring Profile: [default] (Global Identity)"
    else
        echo "  ⚙️  Configuring Profile: [$target_profile] (Directory-Scoped)"
    fi
    echo "────────────────────────────────────────────────────────────"

    # Determine default directory and check if existing config exists for this profile
    local target_dir=""
    local profile_config=""
    local existing_prof_name=""
    local existing_prof_email=""

    if [ "$is_default" = true ]; then
        existing_prof_name="$default_name"
        existing_prof_email="$default_email"
    else
        # Tentative location to inspect previous values
        local tentative_dir="${input_dir:-$HOME/$target_profile}"
        tentative_dir="${tentative_dir/#\~/$HOME}"
        if [ -f "$tentative_dir/.gitconfig" ]; then
            existing_prof_name="$(git config --file "$tentative_dir/.gitconfig" user.name 2>/dev/null || true)"
            existing_prof_email="$(git config --file "$tentative_dir/.gitconfig" user.email 2>/dev/null || true)"
        fi
    fi

    # Step 2: Prompt for Name (alias for default, real name for work/uni)
    local final_name="$input_name"
    if [ -z "$final_name" ]; then
        if [ "$NON_INTERACTIVE" = true ]; then
            final_name="${existing_prof_name:-$default_name}"
        else
            if [ "$is_default" = true ]; then
                read -rp "Enter Git username/alias for [default] [${existing_prof_name:-$default_name}]: " prompt_name || true
                final_name="${prompt_name:-${existing_prof_name:-$default_name}}"
            else
                if [ -n "$existing_prof_name" ]; then
                    read -rp "Enter Git real name for '$target_profile' [$existing_prof_name]: " prompt_name || true
                    final_name="${prompt_name:-$existing_prof_name}"
                else
                    read -rp "Enter Git real name for '$target_profile': " prompt_name || true
                    while [ -z "$prompt_name" ]; do
                        echo "  ⚠️ Name is required for '$target_profile' profile."
                        read -rp "Enter Git real name for '$target_profile': " prompt_name || break
                    done
                    final_name="$prompt_name"
                fi
            fi
        fi
    fi

    # Step 2 (cont): Prompt for Email (differentiates personal and work/uni)
    local final_email="$input_email"
    if [ -z "$final_email" ]; then
        if [ "$NON_INTERACTIVE" = true ]; then
            final_email="${existing_prof_email:-$default_email}"
        else
            if [ "$is_default" = true ]; then
                local email_hint="${existing_prof_email:-${default_email:-user@example.com}}"
                read -rp "Enter Git email for [default] [$email_hint]: " prompt_email || true
                final_email="${prompt_email:-$email_hint}"
            else
                if [ -n "$existing_prof_email" ]; then
                    read -rp "Enter Git email for '$target_profile' [$existing_prof_email]: " prompt_email || true
                    final_email="${prompt_email:-$existing_prof_email}"
                else
                    read -rp "Enter Git email for '$target_profile' (e.g. user@$target_profile.com): " prompt_email || true
                    while [ -z "$prompt_email" ]; do
                        echo "  ⚠️ Email is required for the '$target_profile' profile."
                        read -rp "Enter Git email for '$target_profile': " prompt_email || break
                    done
                    final_email="$prompt_email"
                fi
            fi
        fi
    fi

    # Workspace directory resolution for non-default profiles
    if [ "$is_default" = false ]; then
        if [ -n "$input_dir" ]; then
            target_dir="${input_dir/#\~/$HOME}"
        elif [ "$NON_INTERACTIVE" = true ]; then
            target_dir="$HOME/$target_profile"
        else
            read -rp "Enter workspace directory for '$target_profile' [~/$target_profile]: " prompt_dir || true
            if [ -n "$prompt_dir" ]; then
                target_dir="${prompt_dir/#\~/$HOME}"
            else
                target_dir="$HOME/$target_profile"
            fi
        fi
        mkdir -p "$target_dir"
        profile_config="$target_dir/.gitconfig"
    fi

    # Step 3: Determine Key Filename and Suffix:
    # All keys are stored directly inside ~/.ssh/ with NO nesting:
    #   default : no suffix -> id_ed25519 or id_rsa
    #   other   : _<profile> suffix -> id_ed25519_<profile> or id_rsa_<profile>
    local key_suffix=""
    [ "$is_default" = false ] && key_suffix="_${target_profile}"

    # Check for legacy nested key in ~/.ssh/profiles/<profile>/id_rsa and migrate if found
    local legacy_key="$HOME/.ssh/profiles/$target_profile/id_rsa"
    if [ "$is_default" = false ] && [ -f "$legacy_key" ] && [ ! -f "$HOME/.ssh/id_rsa${key_suffix}" ] && [ ! -f "$HOME/.ssh/id_ed25519${key_suffix}" ]; then
        echo "  📦 Found legacy nested key at: $legacy_key"
        cp -p "$legacy_key" "$HOME/.ssh/id_rsa${key_suffix}"
        [ -f "$legacy_key.pub" ] && cp -p "$legacy_key.pub" "$HOME/.ssh/id_rsa${key_suffix}.pub"
        echo "  ✓ Migrated key to flat structure: $HOME/.ssh/id_rsa${key_suffix}"
    fi

    # Check if an existing key already exists for this profile
    local key_path=""
    if [ -f "$HOME/.ssh/id_ed25519${key_suffix}" ]; then
        key_path="$HOME/.ssh/id_ed25519${key_suffix}"
    elif [ -f "$HOME/.ssh/id_rsa${key_suffix}" ]; then
        key_path="$HOME/.ssh/id_rsa${key_suffix}"
    fi

    # Generate key if not found
    if [ -n "$key_path" ]; then
        echo "  ✓ Existing SSH key found at: $key_path"
    else
        local chosen_algo="$KEY_TYPE"
        if [ "$KEY_TYPE_EXPLICIT" = false ] && [ "$NON_INTERACTIVE" = false ]; then
            read -rp "Select SSH key algorithm [ed25519 (recommended) / rsa] (default: ed25519): " prompt_algo || true
            prompt_algo="$(echo "$prompt_algo" | tr '[:upper:]' '[:lower:]')"
            if [ "$prompt_algo" = "rsa" ]; then
                chosen_algo="rsa"
            else
                chosen_algo="ed25519"
            fi
        fi

        key_path="$HOME/.ssh/id_${chosen_algo}${key_suffix}"
        echo "  🔑 Generating SSH key ($chosen_algo) for profile '$target_profile'..."
        if [ "$chosen_algo" = "rsa" ]; then
            ssh-keygen -t rsa -b 4096 -C "$final_email" -f "$key_path" -N ""
        else
            ssh-keygen -t ed25519 -C "$final_email" -f "$key_path" -N ""
        fi
        chmod 600 "$key_path"
        chmod 644 "$key_path.pub"
        echo "  ✓ Generated SSH key at: $key_path"
    fi

    # Add default key to ssh-agent if running
    if [ "$is_default" = true ] && [ -n "$SSH_AUTH_SOCK" ]; then
        ssh-add "$key_path" 2>/dev/null || true
    fi

    # Configure Git
    if [ "$is_default" = true ]; then
        git config --file "$LOCAL_GITCONFIG" user.name "$final_name"
        git config --file "$LOCAL_GITCONFIG" user.email "$final_email"
    else
        cat > "$profile_config" <<EOF
# Profile-specific Git configuration for: $target_profile
[user]
	name = $final_name
	email = $final_email

[core]
	sshCommand = ssh -i $key_path -o IdentitiesOnly=yes
EOF
        chmod 644 "$profile_config"

        # Register includeIf directive in ~/.gitconfig.local
        local gitdir_pattern="${target_dir%/}/"
        git config --file "$LOCAL_GITCONFIG" --unset-all "includeIf.gitdir:$gitdir_pattern.path" 2>/dev/null || true
        git config --file "$LOCAL_GITCONFIG" --add "includeIf.gitdir:$gitdir_pattern.path" "$profile_config"
    fi

    # Summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✅ Profile '$target_profile' configured successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • Profile Type  : $target_profile"
    echo "  • Git User Name : $final_name"
    echo "  • Git Email     : $final_email"
    echo "  • SSH Key       : $key_path"
    if [ "$is_default" = true ]; then
        echo "  • Git Config    : $LOCAL_GITCONFIG (Global default)"
        echo "  • Scope         : System-wide default for all repositories."
    else
        echo "  • Git Config    : $profile_config"
        echo "  • Workspace Dir : $target_dir"
        echo "  • Scope         : Repositories in $target_dir use this key and identity."
        echo "                    Everywhere else continues using default identity."
    fi
    echo ""
    echo "  📋 Public SSH Key (copy to GitHub / GitLab):"
    echo "  ────────────────────────────────────────────────────────────"
    cat "$key_path.pub"
    echo "  ────────────────────────────────────────────────────────────"
    echo "  💡 Test authentication with:"
    echo "     ssh -T -i $key_path git@github.com"
    echo ""
}

# ------------------------------------------------------------------------------
# 5. Main Execution Flow
# ------------------------------------------------------------------------------
if [ -n "$CLI_PROFILE" ] || [ "$NON_INTERACTIVE" = true ]; then
    # Non-interactive or direct CLI invocation
    target_prof="${CLI_PROFILE:-default}"
    configure_profile "$target_prof" "$CLI_NAME" "$CLI_EMAIL" "$CLI_DIR"
else
    # Interactive mode: prompt for profile type upfront on every run
    while true; do
        echo ""
        echo "Choose Git & SSH profile type to configure:"
        echo "  1) default  [Global identity, default SSH key (no suffix)]"
        echo "  2) uni      [University identity, scoped to ~/uni, key suffix: _uni]"
        echo "  3) work     [Work identity, scoped to ~/work, key suffix: _work]"
        echo "  4) custom   [Custom directory-scoped identity]"
        echo ""
        read -rp "Select profile type [1-4, or type default/uni/work/custom] (default: default): " USER_CHOICE || break

        SELECTED_PROFILE=""
        case "$USER_CHOICE" in
            1|default|"")
                SELECTED_PROFILE="default"
                ;;
            2|uni)
                SELECTED_PROFILE="uni"
                ;;
            3|work)
                SELECTED_PROFILE="work"
                ;;
            4|custom)
                read -rp "Enter custom profile name: " CUSTOM_NAME || break
                SELECTED_PROFILE="$(echo "$CUSTOM_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_-')"
                while [ -z "$SELECTED_PROFILE" ]; do
                    echo "  ⚠️ Profile name cannot be empty."
                    read -rp "Enter custom profile name: " CUSTOM_NAME || break
                    SELECTED_PROFILE="$(echo "$CUSTOM_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_-')"
                done
                ;;
            *)
                # Direct entry of a profile name like 'work', 'uni', 'client', etc.
                SELECTED_PROFILE="$(echo "$USER_CHOICE" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_-')"
                ;;
        esac

        configure_profile "$SELECTED_PROFILE" "$CLI_NAME" "$CLI_EMAIL" "$CLI_DIR"

        echo ""
        read -rp "Would you like to configure another profile? [y/N]: " ANOTHER_CHOICE || break
        case "$ANOTHER_CHOICE" in
            [yY]|[yY][eE][sS])
                CLI_NAME=""
                CLI_EMAIL=""
                CLI_DIR=""
                ;;
            *)
                break
                ;;
        esac
    done
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🎉 Git & SSH setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
