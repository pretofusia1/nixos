{ pkgs, ... }:

{
  # ============================================
  # GEMEINSAME USER-PAKETE (Laptop + VM)
  # ============================================
  # Diese Datei wird von home.nix und home-vm.nix importiert

  home.packages = with pkgs; [
    # Editoren
    gnome-text-editor

    # E-Mail-Client
    geary

    # Messenger
    # signal-desktop → jetzt via Flatpak (immer aktuell)
    element-desktop

    # GIMP Plugins (Photoshop-Feeling)
    gmic                   # G'MIC CLI
    gmic-qt                # G'MIC Plugin (600+ Filter)
    darktable              # RAW Editor

    # Media & Viewer
    spotify
    loupe                  # Bildbetrachter (GNOME)
    kdePackages.okular                 # PDF-Viewer
    rhythmbox              # Musik-Player
    mpv                    # Video-Player

    # Themes & Icons
    adw-gtk3
    papirus-icon-theme
    papirus-folders

    # Desktop-Tools
    xfce.xfconf
    xfce.xfce4-settings

    # Shell Plugins
    fishPlugins.bass
    pyprland

    # Dateimanager & Archive
    xfce.thunar
    xfce.thunar-archive-plugin
    xarchiver

    # Scanner
    simple-scan

    # DJ Setup
    mixxx
  ];
}
