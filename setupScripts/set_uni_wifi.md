- go to `/etc/NetworkManager/conf.d`
- setup the following files init:

  - `wifi_backend.conf`:
    ```
    [device]
    wifi.backend=iwd
    ```
  - `wifi_rand_mac.conf`:
    ```
    [device]
    wifi.scan-rand-mac-address=no
    ```

- then in `/etc/NetworkManager/system-connections`

  - create a new Wifi entry using `nm-connection-editor`
  - create the file `{name}.nmconnection`

    ````
    // this will pre-filled as we create using nm-connection-editor
    [connection]
    id=
    uuid=
    type=wifi
    interface-name=wlan0
    permissions=

        [wifi]
        mode=infrastructure
        ssid=AU_Connect

        [wifi-security]
        auth-alg=open
        key-mgmt=wpa-eap

        [802-1x]
        anonymous-identity=
        eap=peap;
        identity=
        password=
        phase2-auth=mschapv2

        [ipv4]
        method=auto

        [ipv6]
        addr-gen-mode=stable-privacy
        method=auto

        [proxy]

        ```
    ````

- then in `var/lib/iwd`

  - create the following file `{name}.8021x`

  ```
  [IPv6]
  Enabled=true

  [Security]
  EAP-Method=PEAP
  EAP-Identity=
  EAP-PEAP-Phase2-Method=MSCHAPV2
  EAP-PEAP-Phase2-Identity=
  EAP-PEAP-Phase2-Password=
  ```
