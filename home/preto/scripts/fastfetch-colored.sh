#!/usr/bin/env bash

# Pywal-Farben laden (falls vorhanden)
if [ -f "$HOME/.cache/wal/sequences" ]; then
    cat "$HOME/.cache/wal/sequences"
fi

# Fastfetch mit Pywal-Farben starten
fastfetch

# NixOS Flake Update Check
FLAKE_LOCK="/etc/nixos/flake.lock"
UPDATE_THRESHOLD_DAYS=30

if [ -f "$FLAKE_LOCK" ]; then
    # Berechne Alter der flake.lock in Tagen
    LAST_MODIFIED=$(stat -c %Y "$FLAKE_LOCK" 2>/dev/null || stat -f %m "$FLAKE_LOCK" 2>/dev/null)
    CURRENT_TIME=$(date +%s)
    DAYS_OLD=$(( (CURRENT_TIME - LAST_MODIFIED) / 86400 ))

    # Warnung anzeigen, wenn älter als Schwellenwert
    if [ $DAYS_OLD -ge $UPDATE_THRESHOLD_DAYS ]; then
        echo ""
        echo -e "\033[1;33m╔════════════════════════════════════════════════════════╗\033[0m"
        echo -e "\033[1;33m║\033[0m  ⚠️  NixOS Flake Update empfohlen!                   \033[1;33m║\033[0m"
        echo -e "\033[1;33m║\033[0m                                                        \033[1;33m║\033[0m"
        echo -e "\033[1;33m║\033[0m  Deine flake.lock ist \033[1;31m$DAYS_OLD Tage\033[0m alt.                \033[1;33m║\033[0m"
        echo -e "\033[1;33m║\033[0m                                                        \033[1;33m║\033[0m"
        echo -e "\033[1;33m║\033[0m  \033[1;36mAktualisieren mit:\033[0m                                 \033[1;33m║\033[0m"
        echo -e "\033[1;33m║\033[0m  cd /etc/nixos && nix flake update                   \033[1;33m║\033[0m"
        echo -e "\033[1;33m║\033[0m  sudo nixos-rebuild switch --flake .#preto-laptop   \033[1;33m║\033[0m"
        echo -e "\033[1;33m╚════════════════════════════════════════════════════════╝\033[0m"
        echo ""
    fi
fi
