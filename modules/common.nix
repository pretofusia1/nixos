{ config, pkgs, ... }: {
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";
  services.xserver.xkb.layout = "de";

  # NetworkManager-Dienst aktivieren (für nmcli & WLAN-Skript)
  networking.networkmanager.enable = true;
  # Optional (empfohlen für stabileres WLAN):
  # networking.networkmanager.wifi.backend = "iwd";
  # services.iwd.enable = true;

  environment.systemPackages = with pkgs; [
    # System-Tools
    git
    gnupg
    htop
    btop
    wget
    curl
    unzip
    ripgrep
    fd
    bat
    eza
    nil
    fastfetch

    # Desktop & UI
    pywal
    imagemagick
    jq
    file
    which
    dunst
    networkmanagerapplet
    wofi
    hyprpaper

    # Archive-Tools (für unzip_prompt.sh)
    p7zip                # für 7z-Archive
    libarchive           # liefert bsdtar (Fallback)
    zip                  # zum Erstellen von ZIPs
    unrar                # für RAR-Archive

    # Netzwerk
    networkmanager       # bringt nmcli fürs WLAN-Skript

    # Editoren
    gedit

    # Security
    sops                 # Secret Management
    age                  # Verschlüsselung für sops-nix

    # PDF & Bilder
    zathura              # minimaler PDF-Viewer (vim-keys)
    imv                  # Wayland-nativer Bildbetrachter

    # Clipboard-Manager
    wl-clipboard         # Wayland Clipboard (wl-copy/wl-paste)
    cliphist             # Clipboard-History für Hyprland

    # Drucker & Scanner
    system-config-printer  # GUI für Druckerverwaltung
    simple-scan            # Einfacher Scanner (GNOME)
  ];

  # Drucker-Support (CUPS)
  services.printing = {
    enable = true;
    drivers = [
      pkgs.gutenprint           # Allgemeine Drucker (Canon, Epson, etc.)
      pkgs.hplip                # HP Drucker
      pkgs.splix                # Samsung SPL-Drucker
      pkgs.samsung-unified-linux-driver  # Samsung proprietäre Treiber
    ];
  };

  # Avahi - Netzwerk-Drucker automatisch erkennen
  services.avahi = {
    enable = true;
    nssmdns4 = true;  # .local Domain Support
    openFirewall = true;
  };

  # Scanner-Support (SANE)
  hardware.sane = {
    enable = true;
    extraBackends = [
      pkgs.hplipWithPlugin           # HP Scanner
      pkgs.samsung-unified-linux-driver  # Samsung Scanner (CLX-6260FD)
    ];

    # Netzwerk-Scanner Konfiguration
    netConf = "192.168.178.72";  # Samsung CLX-6260FD

    # Zusätzliche Backend-Config für Samsung MFP
    extraConfig = {
      xerox_mfp = ''
        # Samsung CLX-6260FD über Netzwerk
        tcp 192.168.178.72
      '';
    };
  };

  # Benutzer in scanner & lp Gruppe
  users.users.preto.extraGroups = [ "scanner" "lp" ];

  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji  # Umbenannt in nixos-24.11
      (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" "NerdFontsSymbolsOnly" ]; })
    ];
    enableDefaultPackages = true;
  };

  # Fish Shell - Moderne Shell mit besserer Auto-Completion
  programs.fish.enable = true;
  users.users.preto.shell = pkgs.fish;
}
