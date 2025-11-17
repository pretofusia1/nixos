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
  xdg.configFile."waybar/config.jsonc".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;

  ################################
  ## Dunst Notification Daemon
  ################################
  xdg.configFile."dunst/dunstrc".source = ./dunst/dunstrc;

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
  xdg.configFile."hypr/pyprland.toml" = {
    source = ./hypr/pyprland.toml;
    force = true;
  };

  # Hyprland-Skripte einzeln (ausführbar)
  home.file.".config/hypr/scripts/toggle-scratchpad.sh" = {
    source = ./hypr/scripts/toggle-scratchpad.sh;
    executable = true;
  };
  home.file.".config/hypr/scripts/ha-kiosk.sh" = {
    source = ./hypr/scripts/ha-kiosk.sh;
    executable = true;
  };
  home.file.".config/hypr/scripts/wallpaper-wal.sh" = {
    source = ./scripts/wallpaper-wal.sh;
    executable = true;
  };
  home.file.".config/hypr/scripts/screenshot-area.sh" = {
    source = ./scripts/screenshot-area.sh;
    executable = true;
  };
  home.file.".config/hypr/scripts/screenshot-full.sh" = {
    source = ./scripts/screenshot-full.sh;
    executable = true;
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

  ################################
  ## ~/scripts: Fastfetch Script
  ################################
  home.file."scripts/fastfetch-colored.sh" = {
    source = ./scripts/fastfetch-colored.sh;
    executable = true;
  };

  ################################
  ## Claude Launcher Scripts
  ################################
  home.file.".config/hypr/scripts/claude-launcher.sh" = {
    source = ./scripts/claude-launcher.sh;
    executable = true;
  };
  home.file.".config/hypr/scripts/get-wallpaper-colors.sh" = {
    source = ./scripts/get-wallpaper-colors.sh;
    executable = true;
  };
  home.file.".config/hypr/scripts/waybar-launcher.sh" = {
    source = ./scripts/waybar-launcher.sh;
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
  };

  # Modern: dconf für GTK-Theme-Einstellungen (ersetzt deprecated gtk3/gtk4.extraConfig)
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Papirus-Dark";
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
    chromium               # für HA-Dashboard Kiosk-Mode (optimal ohne UI)
    spotify                # für Music Scratchpad (MOD+M)
    adw-gtk3
    papirus-icon-theme
    papirus-folders        # für Ordnerfarb-Umstellung
    xfce.xfconf            # optional nützlich für xfconf-query
    xfce.xfce4-settings    # enthält xfsettingsd
    pyprland               # Scratchpad-Manager für Hyprland
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
