{ config, pkgs, ... }:

{
  home.username = "preto";
  home.homeDirectory = "/home/preto";

  # Passe das ggf. auf deine tatsächlich verwendete HM-Version an
  home.stateVersion = "24.11";

  programs.git.enable = true;
  programs.kitty.enable = true;

  # Waybar: Dateien aus dem Repo nach ~/.config/waybar verlinken
  xdg.configFile."waybar/config".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;

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

  # PATH ergänzen, damit ~/bin gefunden wird
  home.sessionPath = [ "$HOME/bin" ];

  # (Falls du Zsh/Bash nutzt und ~/bin einhängen willst, optional:)
  # programs.zsh.enable = true;
  # programs.bash.enable = true;
}
