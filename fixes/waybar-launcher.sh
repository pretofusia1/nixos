#!/usr/bin/env bash
# ========================================
# Waybar Launcher Script
# Startet Waybar mit Fehlerbehandlung
# ========================================

# Beende alte Waybar-Instanzen
pkill waybar 2>/dev/null
sleep 0.3

# Waybar-Konfigurationspfade
CONFIG="$HOME/.config/waybar/config.jsonc"
STYLE="$HOME/.config/waybar/style.css"

# Prüfe ob Konfigurationsdateien existieren
if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Waybar config not found: $CONFIG" >&2
    exit 1
fi

if [ ! -f "$STYLE" ]; then
    echo "ERROR: Waybar style not found: $STYLE" >&2
    exit 1
fi

# Starte Waybar im Hintergrund
waybar --config "$CONFIG" --style "$STYLE" &>/dev/null & disown

echo "Waybar started successfully"
