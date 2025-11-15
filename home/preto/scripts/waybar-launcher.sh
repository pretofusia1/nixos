#!/usr/bin/env bash

# Waybar Launcher - Wartet auf Pywal-Initialisierung
# Verhindert Crashes beim Hyprland-Start durch fehlende Farben

PYWAL_COLORS="$HOME/.cache/wal/colors-kitty.conf"
MAX_WAIT=10  # Maximal 10 Sekunden warten
ELAPSED=0

echo "[waybar-launcher] Warte auf Pywal-Farben..."

while [ ! -f "$PYWAL_COLORS" ] && [ $ELAPSED -lt $MAX_WAIT ]; do
    sleep 0.5
    ELAPSED=$((ELAPSED + 1))
done

if [ -f "$PYWAL_COLORS" ]; then
    echo "[waybar-launcher] Pywal-Farben gefunden, starte Waybar..."
else
    echo "[waybar-launcher] WARNUNG: Pywal-Farben nicht gefunden, starte Waybar trotzdem..."
fi

# Waybar starten
exec waybar --config ~/.config/waybar/config.jsonc --style ~/.config/waybar/style.css
