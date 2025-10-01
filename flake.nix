{
  description = "NixOS Flake Starter (Hyprland + Home-Manager)";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let mkSystem = host: system:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/${host} ./modules/common.nix home-manager.nixosModules.home-manager ];
      };
    in {
      nixosConfigurations = {
        preto-laptop = mkSystem "preto-laptop" "x86_64-linux";
      };
    };
}
