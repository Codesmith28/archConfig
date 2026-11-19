{ config, pkgs, lib, ... }:

{
  # ============================================================================
  # NVIDIA Hybrid Graphics Module
  # Hardware: Intel 13th Gen Core iGPU + NVIDIA GeForce RTX 4060 Mobile dGPU
  # Uses official proprietary driver without overriding standard system defaults.
  # GPU Switching: Cardwire eBPF Manager + PRIME Render Offload
  # ============================================================================

  # Enable modern graphics subsystem with 32-bit compatibility and VA-API acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [ pkgs.nvidia-vaapi-driver ];
  };

  # Load NVIDIA driver in Xserver and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting required for Wayland compositors
    modesetting.enable = true;

    # Dynamic power management natively handled by NixOS
    powerManagement = {
      enable = true;
      finegrained = true;
    };

    # Use stable proprietary NVIDIA drivers
    open = false;

    # Expose nvidia-settings control panel
    nvidiaSettings = true;

    # PRIME Render Offload
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      # Bus IDs for Intel iGPU and NVIDIA dGPU
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # ----------------------------------------------------------------------------
  # Cardwire eBPF GPU Management (OpenGamingCollective):
  # Primary GPU switcher replacing deprecated supergfxctl.
  # 1. Kernel LSM: Includes 'bpf' so Cardwire eBPF hooks attach cleanly.
  # 2. cardwired daemon: Systemd service managing dynamic GPU posture
  #    (Integrated on battery, Smart / Auto-switch on AC / external displays).
  # 3. D-Bus policy: Grants access to org.opengamingcollective.cardwire.
  # ----------------------------------------------------------------------------
  boot.kernelParams = [
    # Enable BPF in Linux Security Modules (LSM) for Cardwire eBPF hooks
    "lsm=landlock,lockdown,yama,integrity,apparmor,bpf"
  ];

  # Cardwire system daemon
  systemd.services.cardwired = {
    description = "Cardwire eBPF GPU Management Daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "dbus.service" "systemd-udevd.service" ];
    wants = [ "dbus.service" ];
    serviceConfig = {
      Type = "dbus";
      BusName = "org.opengamingcollective.cardwire";
      ExecStart = if pkgs ? cardwire
        then "${pkgs.cardwire}/bin/cardwired"
        else "/run/current-system/sw/bin/cardwired";
      Restart = "on-failure";
      RestartSec = "2s";
    };
  };

  # D-Bus security policy for Cardwire
  services.dbus.packages = lib.optional (pkgs ? cardwire) pkgs.cardwire;
  environment.etc."dbus-1/system.d/org.opengamingcollective.cardwire.conf".text = ''
    <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
     "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
    <busconfig>
      <policy user="root">
        <allow own="org.opengamingcollective.cardwire"/>
        <allow send_destination="org.opengamingcollective.cardwire"/>
        <allow receive_sender="org.opengamingcollective.cardwire"/>
      </policy>
      <policy context="default">
        <allow send_destination="org.opengamingcollective.cardwire"/>
        <allow receive_sender="org.opengamingcollective.cardwire"/>
      </policy>
    </busconfig>
  '';

  # Cardwire CLI and tools
  environment.systemPackages = lib.optional (pkgs ? cardwire) pkgs.cardwire;
}
