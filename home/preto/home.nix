{ config, pkgs, ... }:

{
  home.username = "preto";
  home.homeDirectory = "/home/preto";

  # Passe ggf. an deine eingesetzte HM-Version an
  home.stateVersion = "24.11";

  programs.git.enable = true;
  programs.kitty.enable = true;

  # Waybar: Dateien aus dem Repo verlinken
  xdg.configFile."waybar/config".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;

  xdg.configFile."hypr/hyperland.conf".source = ./hyper/hyperland.conf;

  # Skripte aus dem Repo nach ~/bin verlinken (mit Executable-Bit)
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

  # ~/bin in den PATH aufnehmen
  home.sessionPath = [ "$HOME/bin" ];
}
