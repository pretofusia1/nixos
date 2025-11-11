{
  description = "NixOS Flake Starter (Hyprland + Home-Manager)";
  inputs = {
    # Stable Branch für Produktiv-System (getestet, keine Breaking Changes)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # Home-Manager auf matching stable release
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # SOPS-nix (Secret Management)
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let mkSystem = host: system:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/${host}
          ./modules/common.nix
          inputs.sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
        ];
      };
    in {
      nixosConfigurations = {
        preto-laptop = mkSystem "preto-laptop" "x86_64-linux";
      };
    };
}
