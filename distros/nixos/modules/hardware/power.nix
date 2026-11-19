{ config, pkgs, lib, ... }:

let
  # Script to set the battery charging limit to 85%
  setBatteryLimit = pkgs.writeShellScript "set-battery-limit" ''
    # ASUS ROG Strix G16 (G614JV) Embedded Controller Battery Limit (85%)
    for node in /sys/class/power_supply/BAT*/charge_control_end_threshold; do
      if [ -w "$node" ]; then
        current=$(cat "$node" 2>/dev/null || echo "")
        if [ "$current" != "85" ]; then
          echo 85 > "$node" 2>/dev/null || true
        fi
      fi
    done

    # Fallback node on older/alternative kernel battery drivers
    for node in /sys/class/power_supply/BAT*/charge_stop_threshold; do
      if [ -w "$node" ]; then
        current=$(cat "$node" 2>/dev/null || echo "")
        if [ "$current" != "85" ]; then
          echo 85 > "$node" 2>/dev/null || true
        fi
      fi
    done
  '';

  # Script to isolate USB wake sources ("Hot Backpack Fix")
  isolateUsbWake = pkgs.writeShellScript "isolate-usb-wake" ''
    # 1. Disable USB controllers in /proc/acpi/wakeup (only if enabled, ACPI is a toggle)
    if [ -f /proc/acpi/wakeup ]; then
      while read -r dev _ status rest; do
        if echo "$dev" | grep -qE '^XHC|^USB|^EHC' && echo "$status" | grep -q 'enabled'; then
          echo "$dev" > /proc/acpi/wakeup 2>/dev/null || true
        fi
      done < /proc/acpi/wakeup
    fi

    # 2. Disable wakeup on all connected USB devices and root hubs
    for dev in /sys/bus/usb/devices/*/power/wakeup; do
      if [ -f "$dev" ]; then
        echo "disabled" > "$dev" 2>/dev/null || true
      fi
    done
  '';
in
{
  # ============================================================================
  # Power Management & Battery Health (ASUS ROG Strix G16 G614JV)
  # 1. 85% Battery Charging Threshold (hardware lifespan preservation)
  # 2. USB Wake Isolation / Hot Backpack Fix (blocks accidental mouse/dongle wake)
  # 3. Deep Sleep / S3 Suspend-to-RAM kernel and systemd configuration
  # ============================================================================

  # ----------------------------------------------------------------------------
  # 1. Battery Charging Threshold Service & Udev Dispatch
  # ----------------------------------------------------------------------------
  systemd.services.battery-charge-threshold = {
    description = "Set Battery Charging Threshold to 85%";
    wantedBy = [ "multi-user.target" "post-resume.target" ];
    after = [ "multi-user.target" "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${setBatteryLimit}";
    };
  };

  # ----------------------------------------------------------------------------
  # 2. USB Wake Isolation ("Hot Backpack Fix")
  # Disables spurious USB controllers and peripherals from waking the laptop in bags.
  # Power button wake remains fully functional.
  # ----------------------------------------------------------------------------
  systemd.services.disable-usb-wake = {
    description = "Disable USB Wake Controllers and Peripherals (Hot Backpack Fix)";
    wantedBy = [ "multi-user.target" "post-resume.target" "sleep.target" ];
    before = [ "sleep.target" ];
    after = [ "multi-user.target" "post-resume.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${isolateUsbWake}";
    };
  };

  # Udev rules for power supply transitions and USB wake isolation
  services.udev.extraRules = ''
    # Re-enforce 85% battery threshold whenever AC / USB-PD power supply status changes
    ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ENV{POWER_SUPPLY_ONLINE}=="?*", RUN+="${setBatteryLimit}"
    ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="USB", ENV{POWER_SUPPLY_ONLINE}=="?*", RUN+="${setBatteryLimit}"

    # Automatically disable wake for newly attached USB peripherals (mice, dongles)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{power/wakeup}=="enabled", ATTR{power/wakeup}="disabled"
  '';

  # ----------------------------------------------------------------------------
  # 3. Deep Sleep (S3 Suspend-to-RAM) Configuration
  # Configures memory sleep mode to deep across kernel command line, systemd-sleep,
  # and runtime tmpfiles.
  # ----------------------------------------------------------------------------
  boot.kernelParams = [
    "mem_sleep_default=deep"
  ];

  systemd.sleep.extraConfig = ''
    MemorySleepMode=deep
  '';

  systemd.tmpfiles.rules = [
    "w /sys/power/mem_sleep - - - - deep"
  ];
}
