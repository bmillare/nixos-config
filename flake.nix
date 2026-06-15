{
  description = "Brent's standalone NixOS machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    codex-cli-nix.url = "github:sadjow/codex-cli-nix";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs =
    { self, nixpkgs, home-manager, lanzaboote, nixos-hardware, ... }@inputs:
    {
      nixosConfigurations.crayfish = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/framework-desktop/configuration.nix
          home-manager.nixosModules.home-manager
          lanzaboote.nixosModules.lanzaboote
          nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
        ];
      };
    };
}
