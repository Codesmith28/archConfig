# Bluetooth Configuration (Reverted to Stock Defaults)

All custom Bluetooth kernel parameters (`btusb.conf`), sleep hooks (`bluetooth-sleep.sh`), BlueZ configuration modifications (`/etc/bluetooth/main.conf`), and WirePlumber audio profile overrides (`wireplumber.conf.d/`) have been **completely reverted and eliminated** in favor of 100% upstream Fedora / Linux stock drivers.

---

## Revert & Verify

To ensure all legacy files and systemd overrides are purged:

```bash
# Revert & clean:
sudo ./setup.sh

# Verify status:
./setup.sh --verify
```
