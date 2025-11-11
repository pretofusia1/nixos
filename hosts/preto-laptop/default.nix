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

  ## Sudo-Konfiguration (explizit und sicher)
  security.sudo = {
    enable = true;
    # Wheel-Gruppe braucht Passwort (außer für spezifische Befehle)
    wheelNeedsPassword = true;

    # Ausnahmen: Diese Befehle ohne Passwort (Komfort beim Entwickeln)
    extraRules = [{
      users = [ "preto" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nix-collect-garbage";
          options = [ "NOPASSWD" ];
        }
      ];
    }];
  };

  ## Bootloader (UEFI)
  boot.loader.systemd-boot = {
    enable = true;
    # Behalte nur letzte 10 Generationen (spart Platz auf /boot)
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  ## Firewall - Sichere Standardkonfiguration
  networking.firewall = {
    enable = true;
    # Keine offenen Ports standardmäßig (WireGuard-Modul setzt trustedInterfaces)
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
    # Ping erlauben (für Netzwerk-Troubleshooting)
    allowPing = true;
  };

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
