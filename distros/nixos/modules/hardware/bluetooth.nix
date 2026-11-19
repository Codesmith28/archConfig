{ config, pkgs, lib, ... }:

{
  # ============================================================================
  # Bluetooth Configuration & Intel AX211 Hardware Optimization
  # Host: ASUS ROG Strix G16 (G614JV)
  # Hardware: Intel Wi-Fi 6E AX211 160MHz (PCIe CNVi + USB BT radio: 8087:0033)
  # ============================================================================

  hardware.bluetooth = {
    enable = true;
    # Automatically power on the Bluetooth controller at boot
    powerOnBoot = true;

    # High-Performance BlueZ Daemon Configuration (/etc/bluetooth/main.conf)
    settings = {
      General = {
        # Accelerates paging and inquiry scan parameters for fast device reconnection
        FastConnectable = "true";

        # Prevents pairing key corruption across reboots and dual-boot reconnects
        JustWorksRepairing = "always";

        # Enables Bluetooth Battery Reporting (DE system tray) and LE Audio features
        Experimental = "true";

        # Allows concurrent connection of A2DP audio, AVRCP media controls, and HFP telephony
        MultiProfile = "multiple";
      };

      Policy = {
        # Automatically power on controller on startup/resume
        AutoEnable = "true";

        # Aggressively re-attempt connection if peripheral drops out
        ReconnectAttempts = 7;
        ReconnectIntervals = "1, 2, 4, 8, 16, 32, 64";
      };
    };
  };

  # ----------------------------------------------------------------------------
  # Intel AX211 CNVi Bluetooth Controller Hardware Quirks:
  # 1. force_scofix=1: Resolves Intel AX211 firmware buffer misalignment that causes
  #    "corrupted SCO packet" kernel crashes, audio freezing, and mic dropouts on calls.
  # 2. enable_autosuspend=0: Prevents USB autosuspend race conditions during active streams.
  # 3. reset=1: Ensures clean controller state reset on module load.
  # ----------------------------------------------------------------------------
  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=0 force_scofix=1 reset=1
  '';

  # Intel AX211 USB Power Management udev rule:
  # Prevents USB autosuspend / ACPI sleep state race conditions on the Bluetooth radio (8087:0033).
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", ATTR{idProduct}=="0033", ATTR{power/control}="on"
  '';

  # ----------------------------------------------------------------------------
  # Clean Sleep & Resume Hook (translates hardware-linux/bluetooth/bluetooth-sleep.sh):
  # - Pre-suspend: Gracefully disconnects connected Bluetooth devices before USB root hub
  #   powers down to avoid AVDTP endpoint deadlocks and corrupted audio sessions.
  # - Post-resume: Restores radio power and initiates fast device reconnection.
  # ----------------------------------------------------------------------------
  powerManagement = {
    powerDownCommands = ''
      for dev in $(${pkgs.bluez}/bin/bluetoothctl devices Connected 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $2}'); do
        ${pkgs.bluez}/bin/bluetoothctl disconnect "$dev" >/dev/null 2>&1 || true
      done
    '';

    resumeCommands = ''
      ${pkgs.coreutils}/bin/sleep 2
      ${pkgs.bluez}/bin/bluetoothctl power on >/dev/null 2>&1 || true
    '';
  };
}
