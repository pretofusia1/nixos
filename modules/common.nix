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
    pywal
    imagemagick
    jq
    file
    which
    dunst
    networkmanagerapplet
    wofi
    hyprpaper
    p7zip
    libarchive           # liefert bsdtar (Fallback fürs Entpack-Skript)
    networkmanager       # bringt nmcli fürs WLAN-Skript
    gedit
    sops                 # Secret Management
    age                  # Verschlüsselung für sops-nix
  ];

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
