{ config, pkgs, lib, ... }:

{
  home.username = "preto";
  home.homeDirectory = "/home/preto";
  home.stateVersion = "24.11";

  programs.git.enable = true;
  programs.kitty.enable = true;

  ################################
  ## Waybar (aus dem Repo)
  ################################
  xdg.configFile."waybar/config".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;

  ################################
  ## Hyprland: Configs & Skripte
  ################################
  xdg.configFile."hypr/hyprland.conf" = {
    source = ./hypr/hyprland.conf;
    force = true;   # überschreibt ggf. vorhandene Auto-Config
  };
  xdg.configFile."hypr/hyprpaper.conf" = {
    source = ./hypr/hyprpaper.conf;
    force = true;
  };
  xdg.configFile."hypr/scripts" = {
    source = ./scripts;   # enthält screenshot-*.sh, wallpaper-wal.sh, ...
    recursive = true;
    force = true;
  };

  ################################
  ## ~/bin: Skripte ausführbar
  ################################
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

  ################################
  ## Shell-Init (hm-session-vars)
  ################################
  programs.bash = {
    enable = true;
    initExtra = ''
      # Home-Manager Session-Variablen (inkl. PATH-Erweiterungen)
      if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      fi
    '';
  };
  # Optional, falls du zsh verwendest
  # programs.zsh = {
  #   enable = true;
  #   initExtra = ''
  #     if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  #       . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
  #     fi
  #   '';
  # };

  ################################
  ## Dark-Themes: GTK + Firefox
  ################################
  gtk = {
    enable = true;

    # GTK3 Theme (dunkel)
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    # Dunkles Icon-Theme (wirkt in Thunar & Co.)
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    # Dark-Preference und Icon-Name explizit für GTK3/4
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = 1;
      "gtk-icon-theme-name" = "Papirus-Dark";
    };
    gtk4.extraConfig = {
      "gtk-application-prefer-dark-theme" = 1;
      "gtk-icon-theme-name" = "Papirus-Dark";
    };
  };

  programs.firefox = {
    enable = true;
    profiles.default = {
      settings = {
        # 0=System, 1=Hell, 2=Dunkel
        "layout.css.prefers-color-scheme.content-override" = 2;
        "ui.systemUsesDarkTheme" = 1;
      };
    };
  };

  ################################
  ## Pakete
  ################################
  home.packages = with pkgs; [
    gedit
    adw-gtk3
    papirus-icon-theme
    papirus-folders        # für Ordnerfarb-Umstellung
    xfce.xfconf            # optional nützlich für xfconf-query
    xfce.xfce4-settings    # enthält xfsettingsd
  ];

  #########################################################
  ## XSettings-Daemon: setzt Theme/Icon live (optional)
  #########################################################
  systemd.user.services.xfsettingsd = {
    Unit.Description = "XFCE Settings Daemon";
    Service = {
      # Richtiger Pfad im Paket xfce4-settings:
      ExecStart = "${pkgs.xfce.xfce4-settings}/libexec/xfsettingsd";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  ####################################################################
  ## Deklarativ: Papirus-Ordnerfarbe dauerhaft auf "grey" umstellen
  ## - spiegelt Papirus-Dark ins User-Theme (~/.local/share/icons)
  ## - färbt Ordner mit papirus-folders (ohne sudo, idempotent)
  ####################################################################
  home.activation.setPapirusFolderColor =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      THEME_SRC="$HOME/.nix-profile/share/icons/Papirus-Dark"
      THEME_DST="$HOME/.local/share/icons/Papirus-Dark"

      if [ -d "$THEME_SRC" ]; then
        mkdir -p "$HOME/.local/share/icons"
        rsync -a --delete "$THEME_SRC/" "$THEME_DST/"
        ${pkgs.papirus-folders}/bin/papirus-folders -C grey -t Papirus-Dark -u || true
      else
        echo "Warnung: Papirus-Dark nicht im Nutzerprofil gefunden."
      fi
    '';

  ################################
  ## Home-Manager CLI (optional)
  ################################
  programs.home-manager.enable = true;
}

