{ inputs, config, pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/desktop/greetd.nix
  ];
  networking.hostName = "preto-laptop";
  time.timeZone = "Europe/Berlin";
  networking.networkmanager.enable = true;
  hardware.enableAllFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
  services.pipewire = { enable = true; alsa.enable = true; pulse.enable = true; wireplumber.enable = true; };
  users.users.preto = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "input" "networkmanager" ];
    initialPassword = "changeme";
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.firewall.enable = true;
  system.stateVersion = "24.11";
}