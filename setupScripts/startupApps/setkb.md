Change the printscr key to insert key:

```bash
sudo pacman -S keyd
```

```bash
sudo systemctl enable keyd
sudo systemctl start keyd
```

Add the following content in `/etc/keyd/default.conf`:

```
[ids]
*

[main]
sysrq = insert
capslock = esc

```

```bash
sudo systemctl restart keyd

```