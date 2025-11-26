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
    ../../modules/performance.nix        # Performance-Optimierungen
    ../../modules/security-advanced.nix  # Erweiterte Security
    ../../modules/workflow.nix           # Workflow-Verbesserungen
    inputs.home-manager.nixosModules.home-manager
  ];

  ## Basis-Infos
  networking.hostName = "preto-laptop";
  time.timeZone = "Europe/Berlin";
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };

  ## systemd-resolved für DNS-Verwaltung
  services.resolved = {
    enable = true;
    dnssec = "false";  # DNSSEC ausgeschaltet für Kompatibilität
    fallbackDns = [ "1.1.1.1" "8.8.8.8" ];  # Cloudflare & Google als Fallback
  };

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

  ## TLP - Laptop Power Management
  services.tlp = {
    enable = true;
    settings = {
      # CPU Scaling Governor
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # CPU Turbo Boost
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # WiFi Power Saving
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # Battery Care (verhindert ständiges Laden auf 100%)
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;

      # Runtime Power Management für PCI(e) Geräte
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
    };
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
  ## DEAKTIVIERT: Hyprland-Updates können unstabil sein
  ## Manuelles Update empfohlen: cd /home/preto/nixos && nix flake update && sudo nixos-rebuild switch --flake .#preto-laptop
  system.autoUpgrade = {
    enable = false; # War: true - deaktiviert wegen Hyprland-Instabilität
    flake = "/home/preto/nixos"; # Pfad zu deinem lokalen Flake
    flags = [
      "--update-input" "nixpkgs"
      "--update-input" "home-manager"
      # NICHT mehr: "--update-input" "hyprland" (manuell kontrollieren)
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

    # Automatisches Backup bei Dateikonflikten
    backupFileExtension = "backup";
  };

  ## CLI 'home-manager' als Paket installieren (optional, aber praktisch)
  environment.systemPackages = with pkgs; [
    (inputs.home-manager.packages.${pkgs.system}.home-manager)
  ];

  ## NixOS Versions-Flag
  system.stateVersion = "24.11";
}
