# Battery Charging Limit & Deep Sleep Management

Configures the battery charging threshold and deep sleep for Linux:

1. **Deep Sleep (S3 Suspend-to-RAM)**:
   ```bash
   sudo grubby --update-kernel=ALL --args="mem_sleep_default=deep"
   ```
   (Injected into GRUB via grubby if GRUB is available on the system).

2. **Battery Charging Cap (85%)**:
   ```bash
   #!/bin/bash
   echo 85 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold
   ```
   Installed to `/usr/local/bin/set-battery-limit.sh` and enabled via systemd unit `battery-limit.service`.
