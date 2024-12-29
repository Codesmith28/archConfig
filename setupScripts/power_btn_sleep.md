# Configure power button

go to /etc/systemd/logind.conf

uncomment and modify this line:

```
HandlePowerKey=suspend
```

Reload to apply configrations as follows:

```bash
sudo systemctl systemd-logind.service
```
