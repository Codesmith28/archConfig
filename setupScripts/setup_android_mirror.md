install the following packages:

- scrcpy
- adb

main link : https://www.androidpolice.com/use-wireless-adb-android-phone/

on your android device

- enable developer options
- then under debugging
  - enable wireless debugging
  - pair your device to your linux machine using abd packages
  - the neccessary information will be provided under wireless debugging menu on android

abd commands:

```bash
adb pair {full_address:port} # after clicking on pair a new device
adb connect {full_address:port} # from the main menu
```

you can list your connected devices using:

```bash
abd devices
```

then launch scrcpy for mirroring
