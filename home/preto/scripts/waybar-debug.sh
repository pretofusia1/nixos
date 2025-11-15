#!/usr/bin/env bash

echo "=== WAYBAR DEBUG REPORT ==="
echo ""

# 1. Läuft Waybar?
echo "1️⃣  WAYBAR-PROZESS:"
if pgrep -a waybar; then
    echo "  ✅ Waybar läuft!"
else
    echo "  ❌ Waybar läuft NICHT!"
fi
echo ""

# 2. Pywal-Farben vorhanden?
echo "2️⃣  PYWAL-FARBEN:"
KITTY_COLORS="$HOME/.cache/wal/colors-kitty.conf"
WAYBAR_COLORS="$HOME/.cache/wal/colors-waybar.css"

if [ -f "$KITTY_COLORS" ]; then
    echo "  ✅ Kitty-Farben:  $KITTY_COLORS"
else
    echo "  ❌ Kitty-Farben fehlen!"
fi

if [ -f "$WAYBAR_COLORS" ]; then
    echo "  ✅ Waybar-Farben: $WAYBAR_COLORS"
    echo "  → Inhalt (erste 5 Zeilen):"
    head -5 "$WAYBAR_COLORS" | sed 's/^/      /'
else
    echo "  ❌ Waybar-Farben fehlen!"
fi
echo ""

# 3. Waybar-Configs vorhanden?
echo "3️⃣  WAYBAR-KONFIGURATION:"
CONFIG="$HOME/.config/waybar/config.jsonc"
STYLE="$HOME/.config/waybar/style.css"

if [ -f "$CONFIG" ]; then
    echo "  ✅ config.jsonc vorhanden"
else
    echo "  ❌ config.jsonc fehlt: $CONFIG"
fi

if [ -f "$STYLE" ]; then
    echo "  ✅ style.css vorhanden"
    echo "  → @import Zeile:"
    grep "@import" "$STYLE" | sed 's/^/      /'
else
    echo "  ❌ style.css fehlt: $STYLE"
fi
echo ""

# 4. Launcher-Log
echo "4️⃣  WAYBAR-LAUNCHER LOG:"
LOGFILE="/tmp/waybar-launcher.log"
if [ -f "$LOGFILE" ]; then
    echo "  📄 Log-Datei: $LOGFILE"
    echo "  → Letzte 15 Zeilen:"
    tail -15 "$LOGFILE" | sed 's/^/      /'
else
    echo "  ⚠️  Kein Log gefunden - Launcher wurde noch nicht ausgeführt?"
fi
echo ""

# 5. Hyprland-Log durchsuchen
echo "5️⃣  HYPRLAND-LOG (waybar-bezogen):"
HYPR_LOG="$HOME/.cache/hyprland/hyprland.log"
if [ -f "$HYPR_LOG" ]; then
    echo "  📄 Suche nach 'waybar' in: $HYPR_LOG"
    grep -i waybar "$HYPR_LOG" | tail -10 | sed 's/^/      /'
else
    echo "  ⚠️  Hyprland-Log nicht gefunden"
fi
echo ""

# 6. Manueller Start-Test
echo "6️⃣  MANUELLER START-TEST:"
echo "  Du kannst Waybar manuell starten mit:"
echo ""
echo "    waybar --config ~/.config/waybar/config.jsonc --style ~/.config/waybar/style.css"
echo ""
echo "  Oder den Launcher testen mit:"
echo ""
echo "    ~/.config/hypr/scripts/waybar-launcher.sh"
echo ""
echo "=== DEBUG REPORT ENDE ==="
