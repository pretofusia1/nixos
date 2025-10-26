{ inputs, config, pkgs, lib, ... }:

{
  ## erlaubt unfreie Pakete (z. B. für einige Treiber/Programme)
  nixpkgs.config.allowUnfree = true;

  ## Module importieren
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/desktop/greetd.nix
    ../../modules/network/wireguard.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  ## Basis-Infos
  networking.hostName = "preto-laptop";
  time.timeZone = "Europe/Berlin";
  networking.networkmanager.enable = true;

  ## Firmware & Microcode
  hardware.enableAllFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
  # Bei AMD statt Intel: hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

  ## Sound via PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  ## User 'preto'
  users.users.preto = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "input" "networkmanager" ];
  };

  ## Bootloader (UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ## Firewall
  networking.firewall.enable = true;

  ## Home-Manager an System anbinden
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.preto = import ../../home/preto/home.nix;
    # extraSpecialArgs = { inherit inputs; }; # nur nötig, falls Inputs in home.nix gebraucht werden
  };

  ## CLI 'home-manager' als Paket installieren (optional, aber praktisch)
  environment.systemPackages = with pkgs; [
    (inputs.home-manager.packages.${pkgs.system}.home-manager)
  ];

  ## NixOS Versions-Flag
  system.stateVersion = "24.11";
}
