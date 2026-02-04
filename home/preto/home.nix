{ config, pkgs, lib, ... }:

let
  # PhotoGIMP - Photoshop-Look für GIMP
  # https://github.com/Diolinux/PhotoGIMP
  photogimp = pkgs.fetchFromGitHub {
    owner = "Diolinux";
    repo = "PhotoGIMP";
    rev = "1.1";
    sha256 = "sha256-5AK/4mrbKp8fqgbEDxBrfcHS9myIGgF5bFauYCxvZ6c";
  };
in
{
  imports = [ ./packages-shared.nix ];

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
    # Falls du zsh nutzt:
    # enableZshIntegration = true;
  };

  ################################
  ## Kitty Terminal (mit Pywal)
  ################################
  xdg.configFile."kitty/kitty.conf" = {
    source = ./kitty/kitty.conf;
    force = true;
  };

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
  ## Hyprland: Dynamisch generierte Config
  ################################
  xdg.configFile."hypr/hyprland.conf".text =
    # Laptop Monitor-Setup
    ''
      monitor=,preferred,auto,1

      env = XCURSOR_SIZE,24
      env = QT_QPA_PLATFORMTHEME,qt5ct

    ''
    # Gemeinsame Config aus shared file
    + (builtins.readFile ./hypr/hyprland-shared.conf);
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
  home.file."bin/unzip_prompt.sh" = {
    source = ./scripts/unzip_prompt.sh;
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

    # Shell-Aliases für besseren Workflow
    shellAliases = {
      # NixOS Rebuild
      rebuild = "sudo nixos-rebuild switch --flake .#preto-laptop";
      rebuild-boot = "sudo nixos-rebuild boot --flake .#preto-laptop";
      rebuild-test = "sudo nixos-rebuild test --flake .#preto-laptop";

      # Nix Maintenance
      nix-clean = "sudo nix-collect-garbage -d && sudo nix-store --optimise";
      nix-update = "nix flake update";
      nix-search = "nix search nixpkgs";

      # System Info
      nix-gen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      nix-size = "nix path-info -Sh /run/current-system";

      # Git Shortcuts
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline";

      # WireGuard (zusätzlich zu den bestehenden)
      wg-check = "ip a show wg0";

      # Unzip mit interaktivem Prompt
      uz = "$HOME/bin/unzip_prompt.sh";
    };

    initExtra = ''
      # Home-Manager Session-Variablen (inkl. PATH-Erweiterungen)
      if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      fi
    '';
  };

  ################################
  ## Fish Shell (mit Pywal)
  ################################
  programs.fish = {
    enable = true;

    # Gleiche Aliases wie Bash für Konsistenz
    shellAliases = {
      # NixOS Rebuild
      rebuild = "sudo nixos-rebuild switch --flake .#preto-laptop";
      rebuild-boot = "sudo nixos-rebuild boot --flake .#preto-laptop";
      rebuild-test = "sudo nixos-rebuild test --flake .#preto-laptop";

      # Nix Maintenance
      nix-clean = "sudo nix-collect-garbage -d && sudo nix-store --optimise";
      nix-update = "nix flake update";
      nix-search = "nix search nixpkgs";

      # System Info
      nix-gen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      nix-size = "nix path-info -Sh /run/current-system";

      # Git Shortcuts
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline";

      # WireGuard
      wg-check = "ip a show wg0";

      # Unzip mit interaktivem Prompt
      uz = "$HOME/bin/unzip_prompt.sh";

      # Modern ls replacements (optional, falls installiert)
      ls = "eza";
      ll = "eza -la";
      tree = "eza --tree";
    };

    interactiveShellInit = ''
      # Pywal-Farben in Fish-Shell laden
      if test -e ~/.cache/wal/sequences
        cat ~/.cache/wal/sequences
      end

      # Home-Manager Session-Variablen
      if test -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
        bass source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      end
    '';
  };

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

        # Hardware-Acceleration (VAAPI)
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.enabled" = true;
        "gfx.webrender.all" = true;
        "media.navigator.mediadatadecoder_vpx_enabled" = true;

        # Performance
        "layers.acceleration.force-enabled" = true;
        "gfx.webrender.compositor" = true;
      };
    };
  };

  programs.chromium = {
    enable = true;
    commandLineArgs = [
      # Wayland-native
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"

      # Hardware-Acceleration
      "--enable-features=VaapiVideoDecoder"
      "--use-gl=egl"

      # Performance
      "--enable-gpu-rasterization"
      "--enable-zero-copy"
    ];
  };

  ################################
  ## E-Mail-Client: Geary (schlank & modern)
  ################################
  # Thunderbird entfernt - ersetzt durch Geary
  # programs.thunderbird = {
  #   enable = true;
  #   profiles.default = {
  #     isDefault = true;
  #   };
  # };

  # Pakete: siehe packages-shared.nix (gemeinsam mit VM)

  #########################################################
  ## GNOME Keyring: Secret Service für Geary, etc.
  #########################################################
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };

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

  #########################################################
  ## Cliphist: Clipboard-History Daemon
  #########################################################
  systemd.user.services.cliphist = {
    Unit.Description = "Clipboard History Daemon";
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  ################################
  ## XDG MIME-Zuordnungen für Thunar
  ################################
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # E-Mail
      "x-scheme-handler/mailto" = "org.gnome.Geary.desktop";

      # Bilder
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/png" = "org.gnome.Loupe.desktop";
      "image/gif" = "org.gnome.Loupe.desktop";
      "image/webp" = "org.gnome.Loupe.desktop";
      "image/svg+xml" = "org.gnome.Loupe.desktop";
      "image/bmp" = "org.gnome.Loupe.desktop";

      # PDFs
      "application/pdf" = "org.kde.okular.desktop";

      # Dokumente (OnlyOffice)
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "onlyoffice-desktopeditors.desktop";  # .docx
      "application/vnd.oasis.opendocument.text" = "onlyoffice-desktopeditors.desktop";  # .odt
      "application/msword" = "onlyoffice-desktopeditors.desktop";  # .doc
      "text/plain" = "org.gnome.gedit.desktop";  # .txt

      # Tabellen (OnlyOffice)
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "onlyoffice-desktopeditors.desktop";  # .xlsx
      "application/vnd.oasis.opendocument.spreadsheet" = "onlyoffice-desktopeditors.desktop";  # .ods
      "application/vnd.ms-excel" = "onlyoffice-desktopeditors.desktop";  # .xls
      "text/csv" = "onlyoffice-desktopeditors.desktop";  # .csv

      # Präsentationen (OnlyOffice)
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "onlyoffice-desktopeditors.desktop";  # .pptx
      "application/vnd.oasis.opendocument.presentation" = "onlyoffice-desktopeditors.desktop";  # .odp

      # Audio (Rhythmbox)
      "audio/mpeg" = "rhythmbox.desktop";  # .mp3
      "audio/flac" = "rhythmbox.desktop";
      "audio/x-wav" = "rhythmbox.desktop";
      "audio/ogg" = "rhythmbox.desktop";
      "audio/aac" = "rhythmbox.desktop";

      # Video (MPV)
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";  # .mkv
      "video/webm" = "mpv.desktop";
      "video/avi" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";  # .mov
    };
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
  ## GIMP - Photoshop-Style Konfiguration (PhotoGIMP)
  ################################
  # PhotoGIMP bringt:
  # - Photoshop-ähnliches Layout (Werkzeuge links, Ebenen rechts)
  # - Photoshop-Shortcuts (Ctrl+D = Deselect, etc.)
  # - Dunkles Theme
  # - Angepasste Splash-Screens
  #
  # Hinweis: Beim ersten GIMP-Start werden die Konfigurationen angewendet.
  # Falls GIMP bereits konfiguriert war, vorher ~/.config/GIMP/2.10 löschen.
  xdg.configFile."GIMP/2.10" = {
    source = "${photogimp}/.var/app/org.gimp.GIMP/config/GIMP/2.10";
    recursive = true;
  };

  ################################
  ## LibreOffice - Word-Look Konfiguration
  ################################
  # Hinweis: LibreOffice speichert Konfiguration in ~/.config/libreoffice/4/user/
  # Die registrymodifications.xcu wird beim ersten Start automatisch erstellt.
  # Diese Einstellungen werden dann gemerged.
  #
  # Für vollständige Word-Look Konfiguration:
  # 1. LibreOffice öffnen
  # 2. Ansicht → Benutzeroberfläche → "Tabbed" wählen
  # 3. Extras → Optionen → Laden/Speichern → Allgemein:
  #    - "Immer speichern als" → "Microsoft Word 2007-365 (.docx)"
  # 4. Extras → Optionen → LibreOffice Writer → Grundschriften:
  #    - Standard: Calibri, Größe 11
  #
  # Diese Einstellungen werden in registrymodifications.xcu gespeichert.
  # Bei Bedarf kann die Datei von einem konfigurierten System kopiert werden.

  ################################
  ## Home-Manager CLI (optional)
  ################################
  programs.home-manager.enable = true;
}
