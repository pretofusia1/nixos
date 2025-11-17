#!/usr/bin/env bash
# Toggle Scratchpad Script für Hyprland
# Usage: toggle-scratchpad.sh <workspace-name> <command-to-start>
# Beispiel: toggle-scratchpad.sh term "kitty --class scratchpad-term"

WORKSPACE="$1"
START_CMD="$2"
LOCKFILE="/tmp/scratchpad-${WORKSPACE}.lock"

if [ -z "$WORKSPACE" ]; then
    echo "Fehler: Kein Workspace-Name angegeben!"
    echo "Usage: $0 <workspace-name> <command-to-start>"
    exit 1
fi

# Prüfe, ob das Scratchpad-Fenster bereits existiert
if hyprctl clients | grep -q "workspace: special:$WORKSPACE"; then
    # Fenster existiert - toggle visibility (kein Lock nötig)
    hyprctl dispatch togglespecialworkspace "$WORKSPACE"
else
    # Fenster existiert nicht - starte es (mit Lock gegen Doppelstart)
    if [ -n "$START_CMD" ]; then
        # Prüfe Lock (verhindert mehrfaches Starten)
        if [ -f "$LOCKFILE" ]; then
            # Lock existiert - prüfe ob er älter als 5 Sekunden ist
            if [ $(($(date +%s) - $(stat -c %Y "$LOCKFILE" 2>/dev/null || echo 0))) -gt 5 ]; then
                # Alter Lock - entfernen und neu starten
                rm -f "$LOCKFILE"
            else
                # Frischer Lock - Start bereits in Gang
                echo "Start bereits in Gange..."
                exit 0
            fi
        fi

        # Lock setzen
        touch "$LOCKFILE"

        # Programm starten
        eval "$START_CMD" &

        # Warte bis das Fenster im special workspace erscheint (max 5 Sekunden)
        for i in {1..50}; do
            if hyprctl clients | grep -q "workspace: special:$WORKSPACE"; then
                rm -f "$LOCKFILE"
                hyprctl dispatch togglespecialworkspace "$WORKSPACE"
                exit 0
            fi
            sleep 0.1
        done

        # Timeout - Lock entfernen und Warnung
        rm -f "$LOCKFILE"
        echo "Warnung: Fenster nicht gefunden nach 5 Sekunden"
        hyprctl dispatch togglespecialworkspace "$WORKSPACE"
    else
        echo "Fehler: Kein Start-Command angegeben!"
        exit 1
    fi
fi
