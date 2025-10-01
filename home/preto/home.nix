kk{ config, pkgs, ... }:

{
  home.username = "preto";
  home.homeDirectory = "/home/preto";
  home.stateVersion = "24.11";

  programs.git.enable = true;
  programs.kitty.enable = true;

  # Waybar: Dateien aus dem Repo nach ~/.config/waybar verlinken
  xdg.configFile."waybar/config".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;

  # --- Skripte als ausführbare Tools installieren ---
  home.packages = with pkgs; [
    (writeShellScriptBin "unzip_prompt.sh" ''
      #!/usr/bin/env bash
      set -euo pipefail

      DOWNLOADS="$HOME/Downloads"
      TARGET_BASE="$HOME/unzip"

      shopt -s nullglob
      archives=("$DOWNLOADS"/*.zip "$DOWNLOADS"/*.tar "$DOWNLOADS"/*.tar.gz "$DOWNLOADS"/*.tgz "$DOWNLOADS"/*.tar.bz2 "$DOWNLOADS"/*.7z)
      shopt -u nullglob

      if [ ''\${#archives[@]} -eq 0 ]; then
        echo "Keine Archivdateien in $DOWNLOADS gefunden."
        exit 1
      fi

      echo "Gefundene Archive in $DOWNLOADS:"
      i=1
      for a in "''\${archives[@]}"; do
        echo "  $i) $(basename "$a")"
        ((i++))
      done
      echo

      read -rp "Nummer wählen (Enter = 1): " num
      num="''\${num:-1}"
      if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt "''\${#archives[@]}" ]; then
        echo "Ungültige Auswahl."; exit 1
      fi

      archive="''\${archives[$((num-1))]}"
      name="$(basename "$archive")"
      base="''\${name%.*}"
      target="$TARGET_BASE/$base"

      mkdir -p "$target"
      echo "Entpacke '$name' nach '$target' ..."

      case "$archive" in
        *.zip)
          if command -v unzip >/dev/null 2>&1; then unzip -o "$archive" -d "$target"
          else bsdtar -xf "$archive" -C "$target"; fi
          ;;
        *.7z)
          if command -v 7z >/dev/null 2>&1; then 7z x "$archive" -o"$target"
          else echo "p7zip (7z) fehlt."; exit 1; fi
          ;;
        *.tar|*.tar.gz|*.tgz|*.tar.bz2)
          tar -xvf "$archive" -C "$target"
          ;;
        *)
          echo "Unbekanntes Format."; exit 1
          ;;
      esac

      echo "Fertig. Inhalt:"
      ls -lah "$target"
    '')

    (writeShellScriptBin "wlan_connect.sh" ''
      #!/usr/bin/env bash
      set -euo pipefail

      if ! command -v nmcli >/dev/null 2>&1; then
        echo "nmcli (NetworkManager) nicht gefunden. Bitte NetworkManager aktivieren."
        exit 1
      fi

      echo "Scanne WLANs ..."
      nmcli device wifi rescan >/dev/null 2>&1 || true
      sleep 1
      mapfile -t rows < <(nmcli -f SSID,SECURITY,SIGNAL,BARS device wifi list | sed '1d')

      if [ ''\${#rows[@]} -eq 0 ]; then
        echo "Keine WLANs gefunden."; exit 1
      fi

      echo "Verfügbare WLANs:"
      i=1
      for r in "''\${rows[@]}"; do
        printf "  %2d) %s\n" "$i" "$r"
        ((i++))
      done

      read -rp "Nummer wählen: " num
      if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt "''\${#rows[@]}" ]; then
        echo "Ungültige Auswahl."; exit 1
      fi

      line="''\${rows[$((num-1))]}"
      ssid="$(echo "$line" | awk '{for(i=1;i<=NF-3;i++) printf $i (i<NF-3?" ":"");}')"
      security="$(echo "$line" | awk '{print $(NF-2)}')"

      echo "Ausgewählt: ''\"$ssid\"'' (Sicherheit: $security)"
      if [[ "$security" == "--" || "$security" == "NONE" ]]; then
        sudo nmcli device wifi connect "$ssid" && { echo "Verbunden."; exit 0; }
        echo "Verbindung fehlgeschlagen."; exit 1
      else
        read -rsp "Passwort: " pw; echo
        sudo nmcli device wifi connect "$ssid" password "$pw" && { echo "Verbunden."; exit 0; }
        echo "Verbindung fehlgeschlagen."; exit 1
      fi
    ''')

    (writeShellScriptBin "git_commit_push_rebuild.sh" ''
      #!/usr/bin/env bash
      set -euo pipefail

      REPO_DIR="''\${1:-.}"
      FLAKE_TARGET="''\${2:-.}"   # z.B. .#preto-laptop
      shift 2 || true
      COMMIT_MSG="''\${*:-Auto update $(date +'%F %T')}"

      cd "$REPO_DIR"
      if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Kein Git-Repo."; exit 1
      fi

      echo "Repository: $(pwd)"
      read -rp "git add/commit/push + rebuild ausführen? (j/N) " ok
      [[ "$ok" =~ ^[JjYy]$ ]] || { echo "Abbruch."; exit 1; }

      git add -A
      if git diff --staged --quiet; then
        echo "Keine Änderungen zum Commit."
      else
        git commit -m "$COMMIT_MSG"
        git push
      fi

      if [ -f flake.nix ]; then
        sudo nixos-rebuild switch --flake "$FLAKE_TARGET"
      else
        sudo nixos-rebuild switch
      fi
      echo "Fertig."
    ''')

    (writeShellScriptBin "git_commit_push_rebuild_gc.sh" ''
      #!/usr/bin/env bash
      set -euo pipefail

      REPO_DIR="''\${1:-.}"
      FLAKE_TARGET="''\${2:-.}"

      cd "$REPO_DIR"
      if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Kein Git-Repo."; exit 1
      fi

      read -rp "Commit/Push/Rebuild + GC ausführen? (j/N) " ok
      [[ "$ok" =~ ^[JjYy]$ ]] || { echo "Abbruch."; exit 1; }

      git add -A
      if git diff --staged --quiet; then
        echo "Keine Änderungen zum Commit."
      else
        read -rp "Commit-Nachricht: " msg
        msg="''\${msg:-Update $(date +'%F %T')}"
        git commit -m "$msg"
        git push
      fi

      if [ -f flake.nix ]; then
        sudo nixos-rebuild switch --flake "$FLAKE_TARGET"
      else
        sudo nixos-rebuild switch
      fi

      read -rp "Alle alten Generationen löschen (nix-collect-garbage -d)? (j/N) " gcok
      if [[ "$gcok" =~ ^[JjYy]$ ]]; then
        sudo nix-collect-garbage -d
      fi
      echo "Fertig."
    ''')

    (writeShellScriptBin "update_system.sh" ''
      #!/usr/bin/env bash
      set -euo pipefail

      REPO_DIR="''\${1:-.}"
      FLAKE_TARGET="''\${2:-.}"

      cd "$REPO_DIR"
      git pull --rebase || true

      if [ -f flake.nix ] && command -v nix >/dev/null 2>&1; then
        echo "flake.nix gefunden -> nix flake update ..."
        nix flake update || echo "flake update fehlgeschlagen (weiter mit Rebuild)."
      fi

      git add -A
      if git diff --staged --quiet; then
        echo "Keine Änderungen zum Commit."
      else
        read -rp "Commit-Nachricht (leer = Auto): " msg
        msg="''\${msg:-Automatisches Update $(date +'%F %T')}"
        git commit -m "$msg"
        git push
      fi

      if [ -f flake.nix ]; then
        sudo nixos-rebuild switch --flake "$FLAKE_TARGET"
      else
        sudo nixos-rebuild switch
      fi

      read -rp "GC ausführen (nix-collect-garbage -d)? (j/N) " gcok
      if [[ "$gcok" =~ ^[JjYy]$ ]]; then
        sudo nix-collect-garbage -d
      fi

      echo "Update beendet."
    ''')
  ];

  # Optional: ~/bin zusätzlich in PATH (falls du dort eigene Sachen hast)
  home.sessionPath = [ "$HOME/bin" ];
}

