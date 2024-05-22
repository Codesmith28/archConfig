# Make discord a startup app:

1. Make a directory for the user:

```
mkdir -p ~/.config/systemd/user
```

2. Create a file for discord:

```
nvim ~/.config/systemd/user/discord.service
```

3. Add the following content into the file and save:

```
[Unit]
Description=Discord
After=network.target

[Service]
ExecStart=/usr/bin/discord --start-minimized
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
```

4. Enable the service at login:

```
systemctl --user enable discord.service
```

```
systemctl --user start discord.service
```

5. Check the status by:

```
systemctl --user status discord.service
```
