{ pkgs, inputs, ... }: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # Option A: Stabile Version aus NixOS 24.11 (v0.45.2 - getestet!)
    package = pkgs.hyprland;

    # Option B: Gepinnte Version vom Hyprland-Repo (nur bei Problemen mit Option A)
    # package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };
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
    hyprlock        # Bildschirmsperre (nativer Hyprland-Lockscreen)
    hypridle        # Idle-Management (Auto-Lock, DPMS, Suspend)
    wlogout         # SUPER+SHIFT+E (Abmeldemanager)
    brightnessctl   # Media-Keys (Helligkeitssteuerung)
    dunst           # Notification Daemon
    networkmanagerapplet  # nm-applet
    blueman         # blueman-applet
    pavucontrol     # Volume-Control GUI
  ];
  # Blueman D-Bus Service (nötig damit blueman-applet im Hyprland-Autostart funktioniert)
  services.blueman.enable = true;

  # libinput - Pflicht für Touchpad-Gesten unter Wayland/Hyprland
  services.libinput.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
}
