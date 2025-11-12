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

  ## SOPS - Secret Management
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/home/preto/.config/sops/age/keys.txt";

    secrets."wireguard/laptop_private" = {
      mode = "0400";
      owner = "root";
      group = "root";
    };
  };

  ## Sudo-Konfiguration (explizit und sicher)
  security.sudo = {
    enable = true;
    # Wheel-Gruppe braucht Passwort (außer für spezifische Befehle)
    wheelNeedsPassword = true;

    # Ausnahmen: Diese Befehle ohne Passwort (Komfort beim Entwickeln)
    # SICHERHEITSHINWEIS: Nur mit spezifischen Argumenten erlauben
    extraRules = [{
      users = [ "preto" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild switch";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nixos-rebuild boot";
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

  ## Kernel-Härtung (Security Hardening)
  boot.kernelParams = [
    # Verhindert Kernel-Memory-Merging (Schutz gegen Seitenkanalangriffe)
    "slab_nomerge"
    # Initialisiert Speicher beim Allokieren/Freigeben (verhindert Info-Leaks)
    "init_on_alloc=1"
    "init_on_free=1"
    # Randomisiert Seitenallokation (erschwert Exploits)
    "page_alloc.shuffle=1"
  ];

  # Verhindert das Laden neuer Kernel-Module nach dem Boot
  # ACHTUNG: Deaktiviere dies, falls du Hardware hot-pluggen möchtest (USB-Geräte sind OK)
  security.lockKernelModules = false; # Auf true setzen für maximale Sicherheit

  ## Firewall - Sichere Standardkonfiguration
  networking.firewall = {
    enable = true;
    # Keine offenen Ports standardmäßig
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
    # Ping erlauben (für Netzwerk-Troubleshooting)
    allowPing = true;
    # Logging aktivieren (für Sicherheitsanalyse)
    logRefusedConnections = true;
    logRefusedPackets = false; # Zu viel Output, nur bei Debug aktivieren
  };

  ## SSH-Härtung (falls SSH aktiviert wird)
  services.openssh = {
    enable = false; # Auf true setzen, falls SSH benötigt wird
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
    };
    # Nur über WireGuard erreichbar (siehe wireguard.nix Firewall-Regeln)
    openFirewall = false; # Manuelle Firewall-Regeln in wireguard.nix
  };

  ## System-Monitoring & Security
  # Fail2ban: Automatisches Blocken von Brute-Force-Angriffen
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
  };

  # Audit-System: Protokolliert Systemzugriffe
  security.audit.enable = true;
  security.auditd.enable = true;

  # Journald-Konfiguration: Begrenzt Log-Speicher
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1month
  '';

  ## Automatische System-Updates (Flake-basiert)
  system.autoUpgrade = {
    enable = true;
    flake = "/home/preto/nixos"; # Pfad zu deinem lokalen Flake
    flags = [
      "--update-input" "nixpkgs"
      "--update-input" "home-manager"
      "--commit-lock-file"
    ];
    dates = "weekly"; # Jeden Sonntag
    allowReboot = false; # Manuelle Neustarts empfohlen
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
