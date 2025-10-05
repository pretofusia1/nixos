{ config, pkgs, ... }:

{
  home.username = "preto";
  home.homeDirectory = "/home/preto";
  home.stateVersion = "24.11";

  programs.git.enable = true;
  programs.kitty.enable = true;

  ############################
  ## Waybar (aus Repo)
  ############################
  xdg.configFile."waybar/config".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;

  ############################
  ## Hyprland: Configs & Skripte
  ############################
  xdg.configFile."hypr/hyprland.conf" = {
    source = ./hypr/hyprland.conf;
    force = true;    # überschreibt evtl. vorhandene Auto-Config
  };
  xdg.configFile."hypr/hyprpaper.conf" = {
    source = ./hypr/hyprpaper.conf;
    force = true;
  };
  xdg.configFile."hypr/scripts" = {
    source = ./scripts;   # enthält screenshot-area.sh, screenshot-full.sh, …
    recursive = true;
    force = true;
  };

  ############################
  ## ~/bin: Skripte ausführbar
  ############################
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

  ############################
  ## Shell-Init: HM-Variablen laden (inkl. PATH)
  ############################
  programs.bash = {
    enable = true;
    initExtra = ''
      # Home-Manager Session-Variablen (inkl. PATH-Erweiterungen)
      if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      fi
    '';
  };

  # (Optional, falls du zsh nutzt)
  # programs.zsh = {
  #   enable = true;
  #   initExtra = ''
  #     if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  #       . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
  #     fi
  #   '';
  # };

  ############################
  ## Dark-Themes: GTK + Firefox
  ############################
  gtk = {
    enable = true;

    # GTK3 Theme
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    # Dunkles Icon-Theme (wirkt auch in Thunar)
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    # WICHTIG: Dark-Preference und Icon-Namen auch in GTK3/4 setzen
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = 1;
      "gtk-icon-theme-name" = "Papirus-Dark";
    };
    gtk4.extraConfig = {
      "gtk-application-prefer-dark-theme" = 1;
      "gtk-icon-theme-name" = "Papirus-Dark";
    };
  };

  # GTK4/Libadwaita: zusätzlich settings.ini schreiben
  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-application-prefer-dark-theme=1
    gtk-icon-theme-name=Papirus-Dark
  '';

  programs.firefox = {
    enable = true;
    profiles.default = {
      settings = {
        "layout.css.prefers-color-scheme.content-override" = 2; # 0=System, 1=Hell, 2=Dunkel
        "ui.systemUsesDarkTheme" = 1;
      };
    };
  };

  # benötigte Pakete (gedit, Themes/Icons)
  home.packages = with pkgs; [
    gedit
    adw-gtk3
    papirus-icon-theme
  ];

  ############################################
  ## XSettings für GTK/Icons: xfsettingsd (neu)
  ############################################
  systemd.user.services.xfsettingsd = {
    Unit.Description = "XFCE Settings Daemon";
    Service = {
      ExecStart = "${pkgs.xfce.xfsettingsd}/bin/xfsettingsd";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}

