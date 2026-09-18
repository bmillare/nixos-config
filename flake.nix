{
  description = "Brent's standalone NixOS machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    codex-cli-nix.url = "github:sadjow/codex-cli-nix";
    claude-code.url = "github:sadjow/claude-code-nix";

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

      nixosConfigurations.dykestraw = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/dykestraw/configuration.nix
          home-manager.nixosModules.home-manager
          nixos-hardware.nixosModules.microsoft-surface-pro-intel
        ];
      };

      # A Surface-aware live environment. It contains the dykestraw system
      # closure so the final installation does not depend on compiling the
      # patched kernel (or even on having working networking) on the tablet.
      nixosConfigurations.dykestraw-installer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs self; };
        modules = [
          ./hosts/dykestraw/installer.nix
          nixos-hardware.nixosModules.microsoft-surface-pro-intel
        ];
      };

      packages.x86_64-linux.dykestraw-installer =
        self.nixosConfigurations.dykestraw-installer.config.system.build.isoImage;

      homeConfigurations."bmillare@blacksheep" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."x86_64-linux";

        # Pass inputs to modules just like specialArgs in nixosSystem
        extraSpecialArgs = { inherit inputs; };

        modules = [
          ./hosts/blacksheep/home.nix
        ];
      };

      homeConfigurations."bmillare@macbook" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."aarch64-darwin";
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./hosts/macbook/home.nix ];
      };

    };
}
