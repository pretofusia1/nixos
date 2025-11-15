#!/usr/bin/env bash

# Waybar Launcher - Robuster Start mit Pywal-Wartemechanismus
# EXTREM WICHTIG: Wartet auf BEIDE Pywal-Dateien (Kitty + Waybar)

LOGFILE="/tmp/waybar-launcher.log"
exec > >(tee "$LOGFILE") 2>&1

echo "=== Waybar Launcher gestartet $(date) ==="

# Die BEIDEN wichtigen Pywal-Dateien
PYWAL_KITTY="$HOME/.cache/wal/colors-kitty.conf"
PYWAL_WAYBAR="$HOME/.cache/wal/colors-waybar.css"
WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"

MAX_WAIT=60  # 60 * 0.2s = 12 Sekunden (schnellere Polls)
ELAPSED=0

echo "[1/5] Warte auf Pywal-Initialisierung..."

# Warten bis BEIDE Pywal-Dateien existieren
while [ $ELAPSED -lt $MAX_WAIT ]; do
    if [ -f "$PYWAL_KITTY" ] && [ -f "$PYWAL_WAYBAR" ]; then
        echo "[2/5] ✅ Pywal-Farben gefunden! (${ELAPSED}x0.2s)"
        echo "  - Kitty:  $PYWAL_KITTY"
        echo "  - Waybar: $PYWAL_WAYBAR"
        break
    fi

    if [ $ELAPSED -eq 25 ]; then  # Nach 5 Sekunden
        echo "  ⏳ Immer noch am Warten... (5s)"
    fi

    sleep 0.2  # Schnellere Polls (war 0.5s)
    ELAPSED=$((ELAPSED + 1))
done

# Falls Pywal-Farben IMMER NOCH nicht da sind
if [ ! -f "$PYWAL_WAYBAR" ]; then
    echo "[2/5] ⚠️  WARNUNG: Pywal-Waybar-Farben fehlen nach ${ELAPSED}x0.2s!"
    echo "  Starte Waybar trotzdem - könnte fehlschlagen..."
fi

# Prüfe ob Waybar-Configs existieren
echo "[3/5] Prüfe Waybar-Konfigurationsdateien..."
if [ ! -f "$WAYBAR_CONFIG" ]; then
    echo "  ❌ FEHLER: config.jsonc nicht gefunden: $WAYBAR_CONFIG"
    exit 1
fi
if [ ! -f "$WAYBAR_STYLE" ]; then
    echo "  ❌ FEHLER: style.css nicht gefunden: $WAYBAR_STYLE"
    exit 1
fi
echo "  ✅ Alle Config-Dateien vorhanden"

# Prüfe ob Waybar bereits läuft
echo "[4/5] Prüfe ob Waybar bereits läuft..."
if pgrep -x waybar >/dev/null; then
    echo "  ⚠️  Waybar läuft bereits! Beende alten Prozess..."
    killall waybar
    sleep 0.5
fi

# WAYBAR STARTEN
echo "[5/5] 🚀 Starte Waybar..."
echo "  Command: waybar --config $WAYBAR_CONFIG --style $WAYBAR_STYLE"

# Starte Waybar und leite Output in Log um
exec waybar --config "$WAYBAR_CONFIG" --style "$WAYBAR_STYLE" 2>&1 | tee -a "$LOGFILE"
