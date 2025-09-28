{ config, pkgs, ... }:

{
  home.username = "preto";
  home.homeDirectory = "/home/preto";
  home.stateVersion = "24.11";

  ## Basisprogramme
  programs.git.enable = true;
  programs.kitty.enable = true;

  ## Waybar
  xdg.configFile."waybar/config".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;

  ## Hyprland
  xdg.configFile."hypr/hyprland.conf".source = ./hypr/hyprland.conf;

  ## Hyprpaper
  xdg.configFile."hypr/hyprpaper.conf".source = ./hypr/hyprpaper.conf;

  ## Kitty-Konfiguration
  xdg.configFile."kitty/kitty.conf".source = ./kitty/kitty.conf;

  ## Wallpapers (landen unter ~/.config/wallpapers)
  xdg.configFile."wallpapers".source = ./wallpapers;

  ## Eigene Skripte (aus ~/.config/nixos/home/preto/scripts → ~/.local/bin)
  home.file.".local/bin/screenshot-area.sh" = {
    source = ./scripts/screenshot-area.sh;
    executable = true;
  };
  home.file.".local/bin/screenshot-full.sh" = {
    source = ./scripts/screenshot-full.sh;
    executable = true;
  };
  home.file.".local/bin/wallpaper-wal.sh" = {
    source = ./scripts/wallpaper-wal.sh;
    executable = true;
  };
  home.file.".local/bin/fastfetch-colored.sh" = {
    source = ./scripts/fastfetch-colored.sh;
    executable = true;
  };

  ## Autostart Waybar via systemd user service
  systemd.user.services."hypr-autostart" = {
    Unit = {
      Description = "Autostart for Hyprland session";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.bash}/bin/bash -lc 'waybar'";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  ## Optional: PATH-Ergänzung, falls ~/.local/bin nicht drin
  # home.sessionPath = [ "$HOME/.local/bin" ];
}
