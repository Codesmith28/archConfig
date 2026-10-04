# Fedora AppStream & Software Store Integration

Enables **RPM Fusion AppStream metadata** and configures **PackageKit** so that native RPM packages from RPM Fusion (such as VLC, OBS Studio, MPV, Audacity, Steam RPM, Discord, multimedia codecs, etc.) appear alongside Flatpaks in graphical app stores like **GNOME Software** and **KDE Discover**.

---

## The Problem

- By default, Fedora Workstation enables Flatpak and the Flathub repository out of the box in GNOME Software.
- While the base Fedora repositories (`fedora` and `updates`) supply their own AppStream metadata, **RPM Fusion** ships AppStream XML descriptions in separate metadata RPM packages (`rpmfusion-free-appstream-data` and `rpmfusion-nonfree-appstream-data`).
- Prior to Fedora 41, running `sudo dnf groupupdate core` implicitly pulled in these packages. Starting with **DNF5 in Fedora 41+**, group extensions from external repositories are disabled by default.
- Without these metadata packages, graphical software centers only discover Flatpaks for third-party software, completely hiding the RPM versions from search and category listings.

---

## Why Restarting PackageKit Alone Isn't Always Sufficient

1. **Repository Dependency**: `rpmfusion-free-appstream-data` and `rpmfusion-nonfree-appstream-data` live inside RPM Fusion. If `rpmfusion-free-release` and `rpmfusion-nonfree-release` are not installed beforehand, the `dnf install` command fails.
2. **PackageKit Cache Sync**: PackageKit maintains a disk cache (`/var/cache/PackageKit/`). Calling `pkcon refresh force -y` triggers an immediate re-indexing of the AppStream catalog rather than waiting for scheduled daily timers.
3. **GNOME Software Background Daemon**: GNOME Software runs as a persistent background daemon (`gnome-software --gapplication-service`) and caches AppStream XML and PackageKit state in `~/.cache/gnome-software`. Restarting the `packagekit.service` system daemon does not notify the user's running `gnome-software` process. Terminating the background process (`pkill -f gnome-software`) forces it to reload the newly generated catalog when reopened.
4. **KDE Discover Backend Requirement**: For KDE Plasma users, Discover requires the `plasma-discover-packagekit` backend to talk to PackageKit and search RPMs. Without it, Discover only queries the Flatpak backend even if PackageKit is active.
5. **AppStream Scope**: AppStream metadata is specifically curated for applications with graphical desktop interfaces (`.desktop` entries). Non-GUI packages, developer tools, and system libraries continue to be managed through the command line via `dnf`.

---

## How It Works

`distros/fedora/optimizations/appstream/setup.sh` performs the following steps:
1. Validates that the system is running Fedora/DNF.
2. Ensures the full RPM Fusion Free & Nonfree repositories are enabled.
3. Installs `rpmfusion-free-appstream-data` and `rpmfusion-nonfree-appstream-data`.
4. Checks if KDE Plasma / Discover is installed; if detected, installs `plasma-discover-packagekit`.
5. Restarts `packagekit.service` to load the new metadata providers.
6. Invokes `pkcon refresh force -y` to immediately rebuild the PackageKit local cache.
7. Gracefully terminates any background `gnome-software` and `plasma-discover` instances and clears Discover cache so the refreshed catalog is loaded on next launch.

---

## Manual Verification

```bash
# Verify packages are installed
rpm -q rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data

# Verify PackageKit service status
systemctl status packagekit

# Launch GNOME Software and search for RPM applications (e.g., VLC, OBS Studio)
gnome-software
```
In GNOME Software, on an application's details page, you will now see a source dropdown allowing you to select between **Fedora Linux (RPM)**, **RPM Fusion (RPM)**, and **Flathub (Flatpak)**.
