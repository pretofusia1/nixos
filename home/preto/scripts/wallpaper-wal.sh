#!/usr/bin/env bash
set -euo pipefail

# Wallpaper-Ordner suchen (erster gefundener wird genommen)
CANDIDATES=(
  "$HOME/Pictures/wallpapers"
  "$HOME/.config/wallpapers"
  "/etc/nixos/home/preto/wallpapers"
)
DIR=""
for d in "${CANDIDATES[@]}"; do
  [[ -d "$d" ]] && DIR="$d" && break
done
[[ -z "$DIR" ]] && { echo "[wall] Kein Wallpaper-Ordner gefunden."; exit 1; }

# Zufälliges Bild auswählen
mapfile -t FILES < <(find "$DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \))
[[ ${#FILES[@]} -eq 0 ]] && { echo "[wall] Keine Bilder in $DIR."; exit 1; }
IMG="${FILES[RANDOM % ${#FILES[@]}]}"

# Pywal-Farben generieren
echo "[wall] Generiere Pywal-Farben..."
wal -n -i "$IMG"

# Prüfe ob Pywal erfolgreich war
if [ ! -f "$HOME/.cache/wal/colors.sh" ]; then
  echo "[wall] FEHLER: Pywal konnte keine Farben generieren"
  exit 1
fi

# Pywal-Sequenzen für Fastfetch exportieren
# Die Sequenzen setzen Terminal-Farben, die Fastfetch automatisch nutzt
cat "$HOME/.cache/wal/sequences" &

echo "[wall] Pywal-Farben erfolgreich generiert"

# Aus Pywal den finalen Bildpfad übernehmen
IMG="$(cat "$HOME/.cache/wal/wal")"
[[ -f "$IMG" ]] || { echo "[wall] Ungültiger Bildpfad: $IMG"; exit 1; }

# Hyprpaper starten, falls nicht aktiv
if ! pgrep -x hyprpaper >/dev/null; then
  hyprpaper & disown
fi

# Auf IPC warten (max. 6 Sekunden)
READY=false
for _ in {1..30}; do
  if hyprctl hyprpaper listpreloaded >/dev/null 2>&1; then
    READY=true
    break
  fi
  sleep 0.2
done

# Abbruch wenn hyprpaper nicht bereit
if [ "$READY" != "true" ]; then
  echo "[wall] FEHLER: hyprpaper nicht bereit nach 6 Sekunden"
  exit 1
fi

# Wallpaper auf allen Monitoren setzen
if ! hyprctl hyprpaper preload "$IMG"; then
  echo "[wall] FEHLER: Konnte Wallpaper nicht preloaden"
  exit 1
fi

for mon in $(hyprctl monitors -j | jq -r '.[].name'); do
  if ! hyprctl hyprpaper wallpaper "$mon,$IMG"; then
    echo "[wall] WARNUNG: Konnte Wallpaper nicht auf Monitor $mon setzen"
  fi
done

# Kitty live neu einfärben (falls Listener aktiv)
if command -v kitty >/dev/null; then
  kitty @ --to unix:/tmp/kitty set-colors --all "$HOME/.cache/wal/colors-kitty.conf" >/dev/null 2>&1 || true
fi

# Waybar mit neuen Pywal-Farben neustarten
if pgrep -x waybar >/dev/null; then
  killall waybar
  sleep 0.5
  waybar --config "$HOME/.config/waybar/config.jsonc" --style "$HOME/.config/waybar/style.css" & disown
fi
