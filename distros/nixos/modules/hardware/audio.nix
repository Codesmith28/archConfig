{ config, pkgs, lib, ... }:

{
  # ============================================================================
  # PipeWire & WirePlumber Audio Configuration
  # Host: ASUS ROG Strix G16 (G614JV)
  # Low-latency, high-fidelity audio subsystem replacing PulseAudio / JACK.
  # ============================================================================

  # Real-time kit is required for PipeWire to acquire high-priority threads
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;

    # ALSA emulation with 32-bit library support (essential for Steam / Wine games)
    alsa = {
      enable = true;
      support32Bit = true;
    };

    # PulseAudio daemon replacement
    pulse.enable = true;

    # WirePlumber session manager
    wireplumber.enable = true;

    # JACK client emulation
    jack.enable = true;
  };

  # ----------------------------------------------------------------------------
  # WirePlumber Quality Architecture & Bluetooth Dynamic Routing Notes:
  #
  # In archConfig, system-wide audio is driven by PipeWire + WirePlumber 0.5.
  # The fine-grained audiophile and headset autoswitch configuration is maintained
  # in a single cross-distro source of truth:
  #   core/config/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf
  # which is linked by Home Manager (distros/nixos/home/links.nix) into:
  #   ~/.config/wireplumber/wireplumber.conf.d/50-bluetooth-quality.conf
  #
  # Architecture summary of the quality configuration:
  # 1. Seamless Dynamic Profile Switching:
  #    - When voice calls / mic capture streams are active: auto-switches to HFP (16kHz mSBC HD Voice).
  #    - When call stream terminates: restores pristine A2DP high-fidelity stereo playback.
  # 2. Anti-Headset Trap (Persistent Storage Disabled):
  #    - Disables profile persistence (`bluetooth.use-persistent-storage = false` and
  #      `device.restore-profile = false`) so wireless earbuds/headphones (AirPods,
  #      OnePlus Buds, Sony WH-1000XM) never reconnect trapped in degraded mono mode.
  # 3. High-Fidelity Bluetooth Codecs:
  #    - Prioritizes LDAC, aptX HD, aptX, AAC, and SBC-XQ (high-bitrate dual-channel SBC).
  # 4. Rogue Mic Stream Prevention:
  #    - Sets BlueZ mic capture priority (500) lower than laptop internal mic (2009)
  #      to prevent rogue background browser tabs or games from forcing headset mode.
  # ----------------------------------------------------------------------------

  # Sound management utilities
  environment.systemPackages = with pkgs; [
    pavucontrol
    pulseaudio # provides pactl for quick command-line volume / sink queries
    wireplumber
  ];
}
