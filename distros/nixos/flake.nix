{
  description = "archConfig NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      userConfig =
        if builtins.pathExists ./user-config.nix then
          import ./user-config.nix
        else
          import ./user-config.nix.template;

      hostName = userConfig.hostname or "nixos";

      systemConfig = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs userConfig; };
        modules = [
          ./hosts/default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
    in
    {
      nixosConfigurations = {
        ${hostName} = systemConfig;
        default = systemConfig;
      };
    };
}
