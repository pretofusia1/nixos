{ pkgs, ... }: {
  programs.hyprland = { enable = true; xwayland.enable = true; };
  environment.systemPackages = with pkgs; [ hyprpaper waybar kitty thunar firefox wofi wl-clipboard grim slurp swappy ];
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
}