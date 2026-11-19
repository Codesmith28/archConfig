{ config, pkgs, lib, ... }:

{
  networking = {
    # NetworkManager handles network interfaces, Wi-Fi, and VPNs
    networkmanager = {
      enable = true;
    };

    # Firewall configuration
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };
}
