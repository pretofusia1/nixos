#!/usr/bin/env bash
# ROBUSTES Toggle Scratchpad Script für Hyprland
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

# Prüfe aktuellen Zustand des Scratchpads
CURRENT_WORKSPACE=$(hyprctl activewindow -j 2>/dev/null | jq -r '.workspace.name' 2>/dev/null)
SCRATCHPAD_VISIBLE=$(hyprctl workspaces -j | jq -r ".[] | select(.name == \"special:$WORKSPACE\") | .windows" 2>/dev/null)

# Prüfe ob Fenster im special workspace existiert
if hyprctl clients -j | jq -e ".[] | select(.workspace.name == \"special:$WORKSPACE\")" &>/dev/null; then
    # Fenster existiert
    if [ "$CURRENT_WORKSPACE" = "special:$WORKSPACE" ]; then
        # Scratchpad ist aktiv - verstecke es UND gib Fokus an vorheriges Fenster
        hyprctl dispatch togglespecialworkspace "$WORKSPACE"
        # Gib explizit Fokus an das letzte normale Fenster
        sleep 0.05
        hyprctl dispatch focuswindow "$(hyprctl clients -j | jq -r '[.[] | select(.workspace.name != "special:'"$WORKSPACE"'")] | .[0].address' 2>/dev/null)"
    else
        # Scratchpad ist versteckt - zeige es
        # Schließe ALLE anderen Scratchpads zuerst (verhindert Überlagerung)
        hyprctl workspaces -j | jq -r '.[] | select(.name | startswith("special:")) | .name' | while read -r ws; do
            [ "$ws" != "special:$WORKSPACE" ] && hyprctl dispatch togglespecialworkspace "${ws#special:}" &>/dev/null
        done
        sleep 0.05
        hyprctl dispatch togglespecialworkspace "$WORKSPACE"
        sleep 0.05
        # Gib explizit Fokus an das Scratchpad-Fenster
        hyprctl dispatch focuswindow "$(hyprctl clients -j | jq -r '.[] | select(.workspace.name == "special:'"$WORKSPACE"'") | .address' | head -n1)"
    fi
else
    # Fenster existiert nicht - starte es (mit Lock gegen Doppelstart)
    if [ -n "$START_CMD" ]; then
        # Lock-Mechanismus (verhindert Race Conditions)
        if [ -f "$LOCKFILE" ]; then
            LOCK_AGE=$(($(date +%s) - $(stat -c %Y "$LOCKFILE" 2>/dev/null || echo 0)))
            if [ $LOCK_AGE -gt 5 ]; then
                rm -f "$LOCKFILE"
            else
                echo "Start bereits in Gange (Lock Age: ${LOCK_AGE}s)..."
                exit 0
            fi
        fi

        touch "$LOCKFILE"

        # Schließe ALLE anderen Scratchpads vor dem Start
        hyprctl workspaces -j | jq -r '.[] | select(.name | startswith("special:")) | .name' | while read -r ws; do
            hyprctl dispatch togglespecialworkspace "${ws#special:}" &>/dev/null
        done

        # Starte Programm
        eval "$START_CMD" &
        PROG_PID=$!

        # Warte intelligent: Prüfe ob Fenster erscheint (max 3 Sekunden)
        for i in {1..30}; do
            if hyprctl clients -j | jq -e ".[] | select(.workspace.name == \"special:$WORKSPACE\")" &>/dev/null; then
                rm -f "$LOCKFILE"
                sleep 0.1  # Kurze Pause für Window-Rendering
                hyprctl dispatch togglespecialworkspace "$WORKSPACE"
                sleep 0.05
                # Fokus explizit setzen
                hyprctl dispatch focuswindow "$(hyprctl clients -j | jq -r '.[] | select(.workspace.name == "special:'"$WORKSPACE"'") | .address' | head -n1)"
                exit 0
            fi
            sleep 0.1
        done

        # Timeout - Cleanup
        rm -f "$LOCKFILE"
        echo "WARNUNG: Fenster nicht erschienen nach 3s (PID: $PROG_PID)"
        # Versuche trotzdem das Workspace zu zeigen (falls es doch da ist)
        hyprctl dispatch togglespecialworkspace "$WORKSPACE"
    else
        echo "Fehler: Kein Start-Command angegeben!"
        exit 1
    fi
fi
