# Troubleshooting: Git Push Credential Prompts & Multi-Profile SSH Isolation

## Problem
Running `git push` prompts for interactive credentials in the terminal:
```text
$ git push
Username for 'https://github.com':
Password for 'https://...':
```
Even if an SSH key exists in `~/.ssh/` and identity is configured in `~/.gitconfig`.

---

## Root Cause
1. **Protocol Mismatch (HTTPS vs SSH)**: The repository remote was cloned or initialized using HTTPS (`https://github.com/user/repo.git`) rather than SSH (`git@github.com:user/repo.git`).
2. **GitHub Deprecation of Password Authentication**: GitHub removed support for account password authentication for Git operations in August 2021. Pushing over HTTPS requires either a Personal Access Token (PAT) or a Git Credential Manager.
3. **SSH Keys Ignored for HTTPS**: Having `~/.ssh/id_rsa` registered on GitHub does not assist HTTPS operations unless Git is configured to push via SSH.

---

## Solutions

### 1. Automated Global Fix (Configured in `archConfig`)
In `core/home/.gitconfig`, Git is configured to automatically rewrite GitHub pushes from HTTPS to SSH:
```ini
[url "git@github.com:"]
	pushInsteadOf = "https://github.com/"
	pushInsteadOf = "http://github.com/"
```
This allows repositories cloned anonymously or via HTTPS to push seamlessly over SSH using your registered SSH keys without prompting for usernames or tokens.

### 2. Manual Fix per Repository
To explicitly convert a repository's remote from HTTPS to SSH:
```bash
# Verify current remote
git remote -v

# Update origin URL to SSH
git remote set-url origin git@github.com:<username>/<repository>.git

# Verify SSH authentication to GitHub
ssh -T git@github.com
```

---

## Directory-Scoped Profiles & SSH Isolation

When working with multiple identities (e.g. personal, work, university):
- **Default Behavior**: Repositories everywhere across the system use personal identity (`~/.ssh/id_ed25519` / `~/.ssh/id_personal`) and `~/.gitconfig.local` credentials.
- **Profile Scope**: The entire work directory (e.g., `~/work/`) uses isolated work SSH keys (`~/.ssh/id_work` / `~/.ssh/id_rsa_work`) and work commit credentials.

### Root Cause of Key Bleeding (Agent Collision)
When multiple keys (e.g. personal and work) are loaded into `ssh-agent` or the macOS Keychain:
1. OpenSSH queries `ssh-agent` keys **before** checking identity files on disk.
2. If the work key was loaded first in the agent, OpenSSH offers the work key to GitHub.
3. GitHub authenticates the session as the work user, which causes pushes to personal repositories to fail with:
   ```text
   ERROR: Permission to <user>/<repo>.git denied to <work-user>.
   fatal: Could not read from remote repository.
   ```
4. Furthermore, running `git clone` or `git ls-remote` inside `~/work/` prior to repository initialization fails if Git only isolates via repository-level `includeIf.gitdir`.

### Flat Key Structure
All keys live directly inside `~/.ssh/` with suffix matching the profile (no nested directories):
```text
~/.ssh/
├── id_ed25519            # Default personal key (or id_personal)
├── id_ed25519.pub
├── id_rsa_work           # Work RSA key (or id_work)
├── id_rsa_work.pub
├── id_ed25519_uni        # University key (or id_uni)
└── id_ed25519_uni.pub
```

### Dual-Layer Isolation Mechanism

#### 1. SSH Client Layer: `~/.ssh/config` (Covers Entire `~/work/`, including `git clone`)
Using OpenSSH's `Match host ... exec`:
```sshconfig
Host *
        AddKeysToAgent yes
        UseKeychain yes
        ForwardAgent yes

# Activates work key across the ENTIRE ~/work/ workspace (git clone, fetch, direct ssh)
Match host github.com exec "pwd | grep -q '^/Users/<user>/work'"
        IdentityFile ~/.ssh/id_work
        IdentitiesOnly yes

# Personal key applies everywhere else across the system
Host github.com
        IdentityFile ~/.ssh/id_personal
        IdentitiesOnly yes
```
The `IdentitiesOnly yes` flag ensures OpenSSH ignores extraneous keys in `ssh-agent`, eliminating credential collisions entirely.

#### 2. Git Layer: `includeIf` in `~/.gitconfig.local`
Inside `~/.gitconfig.local`:
```ini
[user]
	name = Personal Name
	email = user@example.com

[includeIf "gitdir:~/work/"]
	path = ~/work/.gitconfig
```

Inside `~/work/.gitconfig`:
```ini
[user]
	name = Work Engineer
	email = engineer@company.com

[core]
	sshCommand = ssh -i ~/.ssh/id_rsa_work -o IdentitiesOnly=yes
```

---

## Automation Script
Run the unified setup script from `archConfig`:
```bash
# Interactive setup (auto-detects existing keys and prompts for profile):
./core/scripts/setup_git.sh

# Directory-scoped profile creation:
./core/scripts/setup_git.sh --profile work --profile-name "Work Name" --profile-email "name@work.com"
```
