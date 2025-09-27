{ config, pkgs, ... }: {
  home.username = "preto";
  home.homeDirectory = "/home/preto";
  home.stateVersion = "24.11";
  programs.git.enable = true;
  programs.kitty.enable = true;
  xdg.configFile."waybar/config".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;
  xdg.configFile."hypr/hyprland.conf".source = ./hypr/hyprland.conf;
  xdg.configFile."kitty/kitty.conf".source = ./kitty/kitty.conf;
  systemd.user.services."hypr-autostart" = {
    Unit = { Description = "Autostart for Hyprland session"; After = [ "graphical-session.target" ]; };
    Service = { ExecStart = "${pkgs.bash}/bin/bash -lc 'waybar'"; Restart = "on-failure"; };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
}