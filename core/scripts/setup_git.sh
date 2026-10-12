#!/usr/bin/env bash
# ==============================================================================
# archConfig Universal Cross-Distro Git & SSH Multi-Profile Setup
# ==============================================================================
# Manages vanilla Git configuration and SSH keys (Ed25519 / RSA) across platforms.
# Supports directory-scoped profiles (e.g. ~/work, ~/uni) isolated with
# includeIf and sshCommand, while keeping all keys directly in ~/.ssh without nesting.
#
# Key naming convention:
#   • default : ~/.ssh/id_ed25519 (or id_rsa, id_personal) - no suffix
#   • work    : ~/.ssh/id_ed25519_work (or id_rsa_work, id_work) - _work suffix
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
CLI_KEY=""
CLI_SCAN_KEYS=false
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
  --key <path>             Explicit SSH private key to associate with profile
  --profile-key <path>     Alias for --key
  --key-type <ed25519|rsa> SSH key algorithm to generate (default: ed25519)
  -t <ed25519|rsa>         Alias for --key-type
  --scan-keys              Scan ~/.ssh/ for keys and show profile assignments
  --non-interactive        Run without interactive prompts
  -h, --help               Show this help message

Examples:
  # Interactive setup (prompts for profile type, name/email, and generates keys):
  ./core/scripts/setup_git.sh

  # Scan ~/.ssh/ and list/assign discovered SSH keys:
  ./core/scripts/setup_git.sh --scan-keys

  # Non-interactive default profile setup:
  ./core/scripts/setup_git.sh --non-interactive --profile default --name "Codesmith" --email "user@example.com"

  # Non-interactive work profile setup with explicit key:
  ./core/scripts/setup_git.sh --non-interactive --profile work --key ~/.ssh/id_work --name "Real Name" --email "name@work.com"

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
        --key|--profile-key)
            CLI_KEY="$2"
            shift 2
            ;;
        --scan-keys)
            CLI_SCAN_KEYS=true
            shift
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

# Re-orders ~/.gitconfig.local so all [includeIf] directives remain at the end,
# guaranteeing directory-scoped profile overrides take precedence over global defaults.
reorder_local_gitconfig() {
    [ ! -f "$LOCAL_GITCONFIG" ] && return 0
    local tmp_file="$LOCAL_GITCONFIG.tmp.$$"
    awk '
        /^\[/ {
            if (/^\[includeIf/) { in_include=1 } else { in_include=0 }
        }
        {
            if (in_include) { include_buf = include_buf $0 "\n" }
            else { base_buf = base_buf $0 "\n" }
        }
        END {
            sub(/\n+$/, "", base_buf);
            sub(/\n+$/, "", include_buf);
            if (base_buf != "") print base_buf;
            if (base_buf != "" && include_buf != "") print "";
            if (include_buf != "") print include_buf;
        }
    ' "$LOCAL_GITCONFIG" > "$tmp_file" && mv "$tmp_file" "$LOCAL_GITCONFIG"
}

# ------------------------------------------------------------------------------
# SSH Key Discovery & Profile Mapping Helpers
# ------------------------------------------------------------------------------
resolve_symlink() {
    local target="$1"
    while [ -L "$target" ]; do
        local link
        link="$(readlink "$target")"
        if [[ "$link" = /* ]]; then
            target="$link"
        else
            target="$(dirname "$target")/$link"
        fi
    done
    echo "$target"
}

get_key_profile() {
    local key_path="$1"
    local real_key
    real_key="$(resolve_symlink "$key_path")"
    local base_name
    base_name="$(basename "$real_key")"
    local ssh_config="$HOME/.ssh/config"

    # 1. Check ~/.ssh/config directory Match rules
    if [ -f "$ssh_config" ]; then
        local cur_match=""
        while IFS= read -r line; do
            if [[ "$line" =~ ^Match\ host\ github\.com\ exec\ .*grep\ -q\ \'\^([^\']+)\' ]]; then
                cur_match="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^Host\  ]]; then
                cur_match=""
            elif [[ "$line" =~ IdentityFile\ (.*) ]]; then
                local id_path="${BASH_REMATCH[1]}"
                id_path="${id_path/#\~/$HOME}"
                id_path="$(resolve_symlink "$id_path")"
                if [ "$id_path" = "$real_key" ] || [ "$(basename "$id_path")" = "$base_name" ]; then
                    if [ -n "$cur_match" ]; then
                        echo "$(basename "$cur_match") [scoped to $cur_match]"
                        return 0
                    fi
                fi
            fi
        done < "$ssh_config"

        # 2. Check Host github.com block in ~/.ssh/config
        local in_gh=false
        while IFS= read -r line; do
            if [[ "$line" =~ ^Host\ github\.com$ ]]; then
                in_gh=true
            elif [[ "$line" =~ ^Host\  ]]; then
                in_gh=false
            elif [ "$in_gh" = true ] && [[ "$line" =~ IdentityFile\ (.*) ]]; then
                local id_path="${BASH_REMATCH[1]}"
                id_path="${id_path/#\~/$HOME}"
                id_path="$(resolve_symlink "$id_path")"
                if [ "$id_path" = "$real_key" ] || [ "$(basename "$id_path")" = "$base_name" ]; then
                    echo "default [global identity]"
                    return 0
                fi
            fi
        done < "$ssh_config"
    fi

    # 3. Check includeIf in ~/.gitconfig.local
    if [ -f "$LOCAL_GITCONFIG" ]; then
        local inc_paths
        inc_paths="$(git config --file "$LOCAL_GITCONFIG" --get-regexp '^includeif\.gitdir:' 2>/dev/null || true)"
        if [ -n "$inc_paths" ]; then
            while read -r _ prof_cfg; do
                prof_cfg="${prof_cfg/#\~/$HOME}"
                if [ -f "$prof_cfg" ]; then
                    local prof_ssh
                    prof_ssh="$(git config --file "$prof_cfg" core.sshCommand 2>/dev/null || true)"
                    if [[ "$prof_ssh" == *"$base_name"* ]]; then
                        local prof_dir
                        prof_dir="$(dirname "$prof_cfg")"
                        echo "$(basename "$prof_dir") [scoped to $prof_dir]"
                        return 0
                    fi
                fi
            done <<< "$inc_paths"
        fi
    fi

    # 4. Check if standard id_ed25519, id_rsa, or id_personal when default identity configured
    if [ -f "$LOCAL_GITCONFIG" ] && [ -n "$(git config --file "$LOCAL_GITCONFIG" user.name 2>/dev/null || true)" ]; then
        if [ "$real_key" = "$(resolve_symlink "$HOME/.ssh/id_ed25519" 2>/dev/null || true)" ] || \
           [ "$real_key" = "$(resolve_symlink "$HOME/.ssh/id_rsa" 2>/dev/null || true)" ] || \
           [ "$real_key" = "$HOME/.ssh/id_personal" ]; then
            echo "default [global identity]"
            return 0
        fi
    fi

    echo "unassigned"
}

DISCOVERED_KEYS=()
DISCOVERED_REAL_KEYS=()
DISCOVERED_ALGOS=()
DISCOVERED_COMMENTS=()
DISCOVERED_PROFILES=()

scan_ssh_keys() {
    DISCOVERED_KEYS=()
    DISCOVERED_REAL_KEYS=()
    DISCOVERED_ALGOS=()
    DISCOVERED_COMMENTS=()
    DISCOVERED_PROFILES=()

    local seen_real=" "
    for pub_file in "$HOME/.ssh"/*.pub; do
        [ ! -f "$pub_file" ] && continue
        local priv_file="${pub_file%.pub}"
        [ ! -f "$priv_file" ] && continue

        local real_priv
        real_priv="$(resolve_symlink "$priv_file")"

        if [[ "$seen_real" == *" $real_priv "* ]]; then
            continue
        fi
        seen_real="$seen_real$real_priv "

        local algo="ed25519"
        if ssh-keygen -l -f "$pub_file" 2>/dev/null | grep -qi "RSA"; then
            algo="rsa"
        elif ssh-keygen -l -f "$pub_file" 2>/dev/null | grep -qi "ECDSA"; then
            algo="ecdsa"
        fi

        local comment
        comment="$(awk 'NF>2{$1=$2=""; sub(/^  */,""); print}' "$pub_file" 2>/dev/null || true)"

        local assigned_prof
        assigned_prof="$(get_key_profile "$priv_file")"

        DISCOVERED_KEYS+=("$priv_file")
        DISCOVERED_REAL_KEYS+=("$real_priv")
        DISCOVERED_ALGOS+=("$algo")
        DISCOVERED_COMMENTS+=("$comment")
        DISCOVERED_PROFILES+=("$assigned_prof")
    done
}

display_discovered_keys() {
    scan_ssh_keys
    local count=${#DISCOVERED_KEYS[@]}
    if [ "$count" -eq 0 ]; then
        echo "  ℹ️  No existing SSH keys found in ~/.ssh/."
        return 0
    fi

    echo ""
    echo "────────────────────────────────────────────────────────────"
    echo "  🔍 Discovered Existing SSH Keys (~/.ssh/):"
    echo "────────────────────────────────────────────────────────────"
    for ((i=0; i<count; i++)); do
        local key="${DISCOVERED_KEYS[$i]}"
        local algo="${DISCOVERED_ALGOS[$i]}"
        local comment="${DISCOVERED_COMMENTS[$i]}"
        local prof="${DISCOVERED_PROFILES[$i]}"
        local status_icon="✓"
        [ "$prof" = "unassigned" ] && status_icon="⚠️"

        echo "  [$((i+1))] $status_icon $(basename "$key") ($algo) [${comment:-no comment}]"
        echo "      Path     : $key"
        if [ "$prof" = "unassigned" ]; then
            echo "      Profile  : ⚠️  UNASSIGNED (not linked to any Git profile)"
        else
            echo "      Profile  : Assigned to $prof"
        fi
    done
    echo "────────────────────────────────────────────────────────────"
}

assign_unassigned_keys_interactive() {
    scan_ssh_keys
    local count=${#DISCOVERED_KEYS[@]}
    local unassigned_indices=()

    for ((i=0; i<count; i++)); do
        if [ "${DISCOVERED_PROFILES[$i]}" = "unassigned" ]; then
            unassigned_indices+=("$i")
        fi
    done

    if [ ${#unassigned_indices[@]} -eq 0 ]; then
        return 0
    fi

    echo ""
    echo "Found ${#unassigned_indices[@]} unassigned SSH key(s)."
    read -rp "Would you like to assign them to Git profiles now? [Y/n]: " DO_ASSIGN || true
    case "$DO_ASSIGN" in
        [nN]|[nN][oO])
            return 0
            ;;
    esac

    for idx in "${unassigned_indices[@]}"; do
        local key="${DISCOVERED_KEYS[$idx]}"
        local algo="${DISCOVERED_ALGOS[$idx]}"
        local comment="${DISCOVERED_COMMENTS[$idx]}"

        echo ""
        echo "────────────────────────────────────────────────────────────"
        echo "  Assign Key: $(basename "$key") ($algo)"
        echo "  Comment   : ${comment:-None}"
        echo "────────────────────────────────────────────────────────────"
        echo "Choose Git profile to assign to this key:"
        echo "  1) default  [Global identity, active everywhere by default]"
        echo "  2) work     [Work identity, scoped to ~/work]"
        echo "  3) uni      [University identity, scoped to ~/uni]"
        echo "  4) custom   [Custom directory-scoped identity]"
        echo "  5) skip     [Leave unassigned]"
        echo ""
        read -rp "Select profile [1-5, default: skip]: " PROF_CHOICE || continue

        local chosen_prof=""
        case "$PROF_CHOICE" in
            1|default)
                chosen_prof="default"
                ;;
            2|work)
                chosen_prof="work"
                ;;
            3|uni)
                chosen_prof="uni"
                ;;
            4|custom)
                read -rp "Enter custom profile name: " CUST_NAME || continue
                chosen_prof="$(echo "$CUST_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_-')"
                while [ -z "$chosen_prof" ]; do
                    echo "  ⚠️ Profile name cannot be empty."
                    read -rp "Enter custom profile name: " CUST_NAME || break
                    chosen_prof="$(echo "$CUST_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_-')"
                done
                ;;
            *)
                echo "  → Skipping key: $(basename "$key")"
                continue
                ;;
        esac

        local email_hint=""
        if [[ "$comment" == *"@"* ]]; then
            email_hint="$comment"
        fi

        configure_profile "$chosen_prof" "" "$email_hint" "" "$key"
    done
}

# ------------------------------------------------------------------------------
# 4. Profile Configuration Function
# ------------------------------------------------------------------------------
configure_profile() {
    local target_profile="$1"
    local input_name="$2"
    local input_email="$3"
    local input_dir="$4"
    local explicit_key="$5"

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

    # Check if an explicit key was provided or if an existing key already exists for this profile
    local key_path=""
    if [ -n "$explicit_key" ] && [ -f "${explicit_key/#\~/$HOME}" ]; then
        key_path="${explicit_key/#\~/$HOME}"
    elif [ -f "$HOME/.ssh/id_ed25519${key_suffix}" ]; then
        key_path="$HOME/.ssh/id_ed25519${key_suffix}"
    elif [ -f "$HOME/.ssh/id_rsa${key_suffix}" ]; then
        key_path="$HOME/.ssh/id_rsa${key_suffix}"
    elif [ "$is_default" = true ] && [ -f "$HOME/.ssh/id_personal" ]; then
        key_path="$HOME/.ssh/id_personal"
    elif [ "$is_default" = true ] && [ -f "$HOME/.ssh/id_ed25519_personal" ]; then
        key_path="$HOME/.ssh/id_ed25519_personal"
    elif [ "$is_default" = true ] && [ -f "$HOME/.ssh/id_rsa_personal" ]; then
        key_path="$HOME/.ssh/id_rsa_personal"
    elif [ -f "$HOME/.ssh/id_${target_profile}" ]; then
        key_path="$HOME/.ssh/id_${target_profile}"
    fi

    # If key still not found and interactive, prompt user to pick from existing keys in ~/.ssh/
    if [ -z "$key_path" ] && [ "$NON_INTERACTIVE" = false ]; then
        scan_ssh_keys
        local count=${#DISCOVERED_KEYS[@]}
        if [ "$count" -gt 0 ]; then
            echo ""
            echo "Select an SSH key to use for profile '$target_profile':"
            for ((k=0; k<count; k++)); do
                echo "  $((k+1))) ${DISCOVERED_KEYS[$k]} (${DISCOVERED_ALGOS[$k]}) [${DISCOVERED_COMMENTS[$k]:-no comment}] - ${DISCOVERED_PROFILES[$k]}"
            done
            echo "  $((count+1))) Generate a new SSH key"
            echo ""
            read -rp "Select key [1-$((count+1)), default: $((count+1))]: " KEY_CHOICE || true
            if [[ "$KEY_CHOICE" =~ ^[0-9]+$ ]] && [ "$KEY_CHOICE" -ge 1 ] && [ "$KEY_CHOICE" -le "$count" ]; then
                key_path="${DISCOVERED_KEYS[$((KEY_CHOICE-1))]}"
            fi
        fi
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

    # Create canonical compatibility symlinks if needed (e.g. id_personal -> id_ed25519)
    if [ "$is_default" = true ]; then
        if [ ! -e "$HOME/.ssh/id_ed25519" ]; then
            ln -snf "$key_path" "$HOME/.ssh/id_ed25519"
            [ -f "$key_path.pub" ] && ln -snf "$key_path.pub" "$HOME/.ssh/id_ed25519.pub"
            echo "  ✓ Linked standard key: ~/.ssh/id_ed25519 -> $key_path"
        fi
    else
        local canonical_link="$HOME/.ssh/id_ed25519_${target_profile}"
        if ssh-keygen -l -f "$key_path" 2>/dev/null | grep -q "RSA"; then
            canonical_link="$HOME/.ssh/id_rsa_${target_profile}"
        fi
        if [ ! -e "$canonical_link" ]; then
            ln -snf "$key_path" "$canonical_link"
            [ -f "$key_path.pub" ] && ln -snf "$key_path.pub" "$canonical_link.pub"
            echo "  ✓ Linked standard key: $canonical_link -> $key_path"
        fi
    fi

    # Add default key to ssh-agent if running
    if [ "$is_default" = true ] && [ -n "$SSH_AUTH_SOCK" ]; then
        ssh-add "$key_path" 2>/dev/null || true
    fi

    # Configure Git
    if [ "$is_default" = true ]; then
        git config --file "$LOCAL_GITCONFIG" user.name "$final_name"
        git config --file "$LOCAL_GITCONFIG" user.email "$final_email"

        # Ensure ~/.ssh/config routes github.com to default personal key with IdentitiesOnly yes
        local ssh_config="$HOME/.ssh/config"
        touch "$ssh_config"
        chmod 600 "$ssh_config"
        if ! grep -q "Host github.com" "$ssh_config" 2>/dev/null; then
            cat >> "$ssh_config" <<EOF

Host github.com
        IdentityFile $key_path
        IdentitiesOnly yes
EOF
            echo "  ✓ Added Host github.com block in $ssh_config -> $key_path"
        fi
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

        # Configure ~/.ssh/config directory match rule so git clone and SSH in the entire directory use this key
        local ssh_config="$HOME/.ssh/config"
        touch "$ssh_config"
        chmod 600 "$ssh_config"
        local match_rule="Match host github.com exec \"pwd | grep -q '^$target_dir'\""
        if ! grep -Fq "$match_rule" "$ssh_config" 2>/dev/null; then
            if grep -q "Host github.com" "$ssh_config" 2>/dev/null; then
                awk -v rule="$match_rule" -v key="$key_path" '
                    /^Host github\.com$/ && !inserted {
                        print rule;
                        print "        IdentityFile " key;
                        print "        IdentitiesOnly yes\n";
                        inserted = 1;
                    }
                    { print }
                ' "$ssh_config" > "$ssh_config.tmp" && mv "$ssh_config.tmp" "$ssh_config"
            else
                cat >> "$ssh_config" <<EOF

$match_rule
        IdentityFile $key_path
        IdentitiesOnly yes
EOF
            fi
            echo "  ✓ Added directory-scoped SSH rule for $target_dir -> $key_path"
        fi
    fi

    # Reorder ~/.gitconfig.local so includeIf directives are always at the bottom,
    # ensuring directory-scoped profile overrides take precedence over global defaults
    reorder_local_gitconfig

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
if [ "$CLI_SCAN_KEYS" = true ]; then
    display_discovered_keys
    if [ "$NON_INTERACTIVE" = false ]; then
        assign_unassigned_keys_interactive
    fi
    exit 0
fi

if [ -n "$CLI_PROFILE" ] || [ "$NON_INTERACTIVE" = true ]; then
    # Non-interactive or direct CLI invocation
    target_prof="${CLI_PROFILE:-default}"
    configure_profile "$target_prof" "$CLI_NAME" "$CLI_EMAIL" "$CLI_DIR" "$CLI_KEY"
else
    # Interactive mode: scan and display existing keys upfront, offer to assign unassigned keys
    display_discovered_keys
    assign_unassigned_keys_interactive

    while true; do
        echo ""
        echo "Choose Git & SSH profile type to configure:"
        echo "  1) default  [Global identity, active everywhere by default]"
        echo "  2) uni      [University identity, scoped to ~/uni]"
        echo "  3) work     [Work identity, scoped to ~/work]"
        echo "  4) custom   [Custom directory-scoped identity]"
        echo "  5) scan     [Scan ~/.ssh/ and assign existing SSH keys to profiles]"
        echo ""
        read -rp "Select option [1-5, or type default/uni/work/custom/scan] (default: default): " USER_CHOICE || break

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
            5|scan)
                display_discovered_keys
                assign_unassigned_keys_interactive
                continue
                ;;
            *)
                # Direct entry of a profile name like 'work', 'uni', 'client', etc.
                SELECTED_PROFILE="$(echo "$USER_CHOICE" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_-')"
                ;;
        esac

        configure_profile "$SELECTED_PROFILE" "$CLI_NAME" "$CLI_EMAIL" "$CLI_DIR" "$CLI_KEY"

        echo ""
        read -rp "Would you like to configure another profile? [y/N]: " ANOTHER_CHOICE || break
        case "$ANOTHER_CHOICE" in
            [yY]|[yY][eE][sS])
                CLI_NAME=""
                CLI_EMAIL=""
                CLI_DIR=""
                CLI_KEY=""
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
