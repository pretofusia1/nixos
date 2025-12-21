{ config, pkgs, lib, ... }:

{
  home.username = "preto";
  home.homeDirectory = "/home/preto";
  home.stateVersion = "24.11";

  programs.git.enable = true;
  programs.kitty.enable = true;

  ################################
  ## Direnv - Auto-Dev-Environments
  ################################
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
  };

  ################################
  ## Kitty Terminal
  ################################
  xdg.configFile."kitty/kitty.conf" = {
    source = ./kitty/kitty.conf;
    force = true;
  };

  ################################
  ## Waybar
  ################################
  xdg.configFile."waybar/config.jsonc".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;

  ################################
  ## Dunst Notification Daemon
  ################################
  xdg.configFile."dunst/dunstrc".source = ./dunst/dunstrc;

  ################################
  ## Hyprland: Dynamisch generierte Config (VM Headless)
  ################################
  xdg.configFile."hypr/hyprland.conf".text =
    # VM Virtual Display Setup
    ''
      # Virtual Display für Headless Streaming
      monitor=WL-1,1920x1080@60,0x0,1

      # Headless Backend Environment
      env = WLR_BACKENDS,headless
      env = WLR_RENDERER_ALLOW_SOFTWARE,1
      env = XCURSOR_SIZE,24
      env = QT_QPA_PLATFORMTHEME,qt5ct

    ''
    # Gemeinsame Config aus shared file (identisch mit Laptop!)
    + (builtins.readFile ./hypr/hyprland-shared.conf);

  ################################
  ## Fish Shell
  ################################
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
    '';
  };

  ################################
  ## Bash
  ################################
  programs.bash = {
    enable = true;
    initExtra = ''
      # Pywal colors laden (falls vorhanden)
      if [ -f ~/.cache/wal/sequences ]; then
        cat ~/.cache/wal/sequences
      fi
    '';
  };

  programs.home-manager.enable = true;
}
