{ config, pkgs, lib, ... }:

{
  # ============================================================================
  # ASUS ROG Hardware Control Module (ASUS ROG Strix G16 G614JV)
  # Provides daemon (asusd), CLI (asusctl), and user-session services for
  # anime matrix, keyboard Aura RGB LED, fan curves, and profile integration.
  # GPU switching is delegated to Cardwire (eBPF GPU manager).
  # ============================================================================

  services.asusd = {
    enable = true;
    enableUserService = true;
  };

  # ----------------------------------------------------------------------------
  # Power Profiles & Daemon Conflict Resolution:
  # asusd integrates with power-profiles-daemon via D-Bus for platform profile
  # switching (Performance, Balanced, Quiet).
  #
  # GPU Management:
  # GPU switching is managed exclusively by Cardwire (eBPF) and PRIME offload.
  # The legacy supergfxd / supergfxctl daemon is deprecated upstream and is
  # explicitly disabled and masked to eliminate PCI bus unbind conflicts.
  # ----------------------------------------------------------------------------
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = lib.mkDefault false;
  services.supergfxd.enable = lib.mkDefault false;

  # Explicitly mask deprecated supergfxd service
  systemd.maskedUnits = [ "supergfxd.service" ];

  # ACPI Storm Protection: prevent asusd internal profile auto-switch race with power-profiles-daemon
  systemd.services.asusd-acpi-storm-prevention = {
    description = "Disable asusd Internal Profile Auto-Switch (Prevent ACPI Storms)";
    after = [ "asusd.service" ];
    wants = [ "asusd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "asusd-acpi-storm-prevent" ''
        if ${pkgs.systemd}/bin/busctl introspect xyz.ljones.Asusd /xyz/ljones xyz.ljones.Platform >/dev/null 2>&1; then
          ${pkgs.systemd}/bin/busctl set-property xyz.ljones.Asusd /xyz/ljones xyz.ljones.Platform ChangePlatformProfileOnBattery b false 2>/dev/null || true
          ${pkgs.systemd}/bin/busctl set-property xyz.ljones.Asusd /xyz/ljones xyz.ljones.Platform ChangePlatformProfileOnAc b false 2>/dev/null || true
        fi
      '';
      RemainAfterExit = true;
    };
  };

  # CLI tools for ASUS ROG system management
  environment.systemPackages = with pkgs; [
    asusctl
  ];
}
