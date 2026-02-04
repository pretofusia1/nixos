{ pkgs, ... }:

{
  # ============================================
  # GEMEINSAME USER-PAKETE (Laptop + VM)
  # ============================================
  # Diese Datei wird von home.nix und home-vm.nix importiert

  home.packages = with pkgs; [
    # Editoren
    gedit

    # E-Mail-Client
    geary

    # Messenger
    signal-desktop-bin     # Offizielle Binary (immer aktuell)
    element-desktop

    # Media & Viewer
    spotify
    loupe                  # Bildbetrachter (GNOME)
    okular                 # PDF-Viewer
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
  ];
}
