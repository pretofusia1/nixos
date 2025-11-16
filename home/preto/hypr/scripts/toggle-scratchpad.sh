#!/usr/bin/env bash
# Toggle Scratchpad Script für Hyprland
# Usage: toggle-scratchpad.sh <workspace-name> <command-to-start>
# Beispiel: toggle-scratchpad.sh term "kitty --class scratchpad-term"

WORKSPACE="$1"
START_CMD="$2"

if [ -z "$WORKSPACE" ]; then
    echo "Fehler: Kein Workspace-Name angegeben!"
    echo "Usage: $0 <workspace-name> <command-to-start>"
    exit 1
fi

# Prüfe, ob das Scratchpad-Fenster bereits existiert
if hyprctl clients | grep -q "workspace: special:$WORKSPACE"; then
    # Fenster existiert - toggle visibility
    hyprctl dispatch togglespecialworkspace "$WORKSPACE"
else
    # Fenster existiert nicht - starte es
    if [ -n "$START_CMD" ]; then
        eval "$START_CMD" &
        # Warte kurz, damit das Fenster erscheint
        sleep 0.3
        hyprctl dispatch togglespecialworkspace "$WORKSPACE"
    else
        echo "Fehler: Kein Start-Command angegeben!"
        exit 1
    fi
fi
