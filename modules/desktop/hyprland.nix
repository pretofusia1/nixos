{ pkgs, ... }: {
  programs.hyprland = { enable = true; xwayland.enable = true; };
  environment.systemPackages = with pkgs; [
    hyprpaper
    waybar
    kitty
    xfce.thunar
    firefox
    wofi
    wl-clipboard
    grim
    slurp
    swappy
    # Programme aus hyprland.conf Keybindings
    swaylock        # SUPER+Escape (Bildschirmsperre)
    wlogout         # SUPER+SHIFT+E (Abmeldemanager)
    brightnessctl   # Media-Keys (Helligkeitssteuerung)
    dunst           # Notification Daemon
    networkmanagerapplet  # nm-applet
    blueman         # blueman-applet
    pavucontrol     # Volume-Control GUI
  ];
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
}
