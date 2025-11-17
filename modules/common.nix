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
  ];

  # Drucker-Support (CUPS)
  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprint pkgs.hplip ];  # HP & allgemeine Drucker
  };

  # Scanner-Support (SANE)
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.hplipWithPlugin ];  # HP Scanner
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
}
