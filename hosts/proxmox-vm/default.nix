{ inputs, config, pkgs, lib, ... }:

{
  ## Unfreie Pakete erlauben
  nixpkgs.config.allowUnfree = true;

  ## Module importieren
  imports = [
    ./hardware-configuration.nix

    # Proxmox-spezifische Module
    ../../modules/proxmox/gpu.nix
    ../../modules/proxmox/sunshine.nix
    ../../modules/proxmox/bootloader.nix

    # Desktop-Module (gemeinsam mit Laptops)
    ../../modules/desktop/hyprland.nix
    ../../modules/desktop/greetd.nix

    # Netzwerk - VM-spezifisch mit eigener WireGuard-IP (10.10.0.12)
    ../../modules/network/wireguard-vm.nix

    # OPTIONAL: Performance-Modul kann für VM nützlich sein
    # ../../modules/performance.nix

    # NICHT inkludiert: security-advanced.nix (Fail2ban, Audit)
    # Grund: Übertrieben für lokale VM, siehe notes.md Sicherheitsempfehlungen

    # Home-Manager
    inputs.home-manager.nixosModules.home-manager
  ];

  ## Basis-Infos
  networking.hostName = "proxmox-vm";
  time.timeZone = "Europe/Berlin";
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };

  ## systemd-resolved für DNS-Verwaltung
  services.resolved = {
    enable = true;
    dnssec = "false";
    fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
  };

  ## Firmware & Microcode
  hardware.enableAllFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;

  ## Sound via PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;

    # Virtueller Audio-Sink für Headless-Streaming (Sunshine/Moonlight)
    # Ohne physisches Audio-Gerät braucht Sunshine einen Sink zum Capturen
    extraConfig.pipewire."91-null-sinks" = {
      "context.objects" = [{
        factory = "spa-node-factory";
        args = {
          "factory.name" = "support.null-audio-sink";
          "node.name" = "Headless-Sink";
          "media.class" = "Audio/Sink";
          "audio.position" = "FL,FR";
        };
      }];
    };
  };

  ## User 'preto'
  users.users.preto = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "input" "networkmanager" ];
  };

  ## uinput-Berechtigung für Sunshine/Moonlight Input (Maus/Tastatur)
  # Ohne diese Regel funktioniert die Fernsteuerung via Moonlight NICHT
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="input", SYMLINK+="uinput"
  '';

  ## SSH-Server (GEHÄRTET für VM)
  # VM braucht SSH für Remote-Zugriff
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;  # NUR SSH-Keys!
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
    };
    openFirewall = true;
  };

  ## Firewall - VM-spezifisch
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      # SSH wird automatisch von openssh.openFirewall geöffnet
      5900  # VNC (falls benötigt)
    ];
    allowedUDPPorts = [ ];
    # Sunshine-Ports werden automatisch von sunshine.nix geöffnet
    allowPing = true;
    logRefusedConnections = true;
  };

  ## SOPS - Secret Management
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;

    # FALSCH (alter Weg):
    # age.keyFile = "/etc/ssh/ssh_host_ed25519_key";

    # RICHTIG (für SSH-Keys):
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets."wireguard/proxmox-vm_private" = {
      mode = "0400";
      owner = "root";
      group = "root";
    };
  };
  ## Sudo-Konfiguration (wie Laptops)
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;

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

  ## Home-Manager an System anbinden
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.preto = import ../../home/preto/home-vm.nix;  # VM-spezifische Config!
    backupFileExtension = "backup";
  };

  ## CLI 'home-manager'
  environment.systemPackages = with pkgs; [
    (inputs.home-manager.packages.${pkgs.system}.home-manager)
  ];

  ## NixOS Versions-Flag
  system.stateVersion = "24.11";
}
