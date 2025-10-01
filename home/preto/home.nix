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

  ## Eigene Skripte: gesamter scripts/-Ordner nach ~/.config/hypr/scripts
  xdg.configFile."hypr/scripts" = {
    source = ./scripts;
    recursive = true;   # alle Dateien & Unterordner
    force = true;       # überschreibt evtl. vorhandene
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

  ## Optional: PATH-Ergänzung, falls du Skripte in ~/.config/hypr/scripts
  ## ohne Pfad starten willst:
  # home.sessionPath = [ "$HOME/.config/hypr/scripts" ];
}
  # --- Skripte nach ~/bin verlinken (aus dem Repo) ---
  home.file."bin/unzip_prompt.sh" = {
    source = ./scripts/unzip_prompt.sh;
    executable = true;
  };
  home.file."bin/wlan_connect.sh" = {
    source = ./scripts/wlan_connect.sh;
    executable = true;
  };
  home.file."bin/git_commit_push_rebuild.sh" = {
    source = ./scripts/git_commit_push_rebuild.sh;
    executable = true;
  };
  home.file."bin/git_commit_push_rebuild_gc.sh" = {
    source = ./scripts/git_commit_push_rebuild_gc.sh;
    executable = true;
  };
  home.file."bin/update_system.sh" = {
    source = ./scripts/update_system.sh;
    executable = true;
  };

  # Damit ~/bin im PATH ist
  home.sessionPath = [ "$HOME/bin" ];
