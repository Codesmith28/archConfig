{ config, pkgs, lib, ... }:

{
  # Hardware optimization suite for ASUS ROG Strix G16 G614JV
  imports = [
    ./asus.nix
    ./nvidia.nix
    ./bluetooth.nix
    ./audio.nix
    ./power.nix
  ];
}
