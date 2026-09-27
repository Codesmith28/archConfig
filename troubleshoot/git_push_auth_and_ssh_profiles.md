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
- **Default Behavior**: Repositories across the system use `~/.ssh/id_rsa` and `~/.gitconfig.local` credentials.
- **Profile Scope**: Repositories located inside specific directories (e.g., `~/work`, `~/uni`) use isolated SSH keys and commit credentials.

### Directory Structure:
```text
~/.ssh/
├── id_rsa            # Default 4096-bit RSA key (personal/global)
├── id_rsa.pub
└── profiles/
    ├── work/
    │   ├── id_rsa    # Work 4096-bit RSA key
    │   └── id_rsa.pub
    └── uni/
        ├── id_rsa    # University 4096-bit RSA key
        └── id_rsa.pub
```

### Git Isolation Mechanism:
Inside `~/.gitconfig.local`:
```ini
[includeIf "gitdir:~/work/"]
	path = ~/work/.gitconfig
```

Inside `~/work/.gitconfig`:
```ini
[user]
	name = Work Engineer
	email = engineer@company.com

[core]
	sshCommand = ssh -i ~/.ssh/profiles/work/id_rsa -o IdentitiesOnly=yes
```
The `-o IdentitiesOnly=yes` flag ensures OpenSSH only presents the profile key and ignores default keys or ssh-agent identities, preventing accidental credential cross-contamination.

---

## Automation Script
Run the unified setup script from `archConfig`:
```bash
# Interactive setup:
./core/scripts/setup_git.sh

# Directory-scoped profile creation:
./core/scripts/setup_git.sh --profile work --profile-name "Work Name" --profile-email "name@work.com"
```
