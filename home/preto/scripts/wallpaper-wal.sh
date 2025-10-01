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
wal -n -i "$IMG" --saturate 0.7

# Aus Pywal den finalen Bildpfad übernehmen
IMG="$(cat "$HOME/.cache/wal/wal")"
[[ -f "$IMG" ]] || { echo "[wall] Ungültiger Bildpfad: $IMG"; exit 1; }

# Hyprpaper starten, falls nicht aktiv
if ! pgrep -x hyprpaper >/dev/null; then
  hyprpaper & disown
fi

# Auf IPC warten (max. 6 Sekunden)
for _ in {1..30}; do
  hyprctl hyprpaper listpreloaded >/dev/null 2>&1 && break
  sleep 0.2
done

# Wallpaper auf allen Monitoren setzen
hyprctl hyprpaper preload "$IMG" || true
for mon in $(hyprctl monitors -j | jq -r '.[].name'); do
  hyprctl hyprpaper wallpaper "$mon,$IMG" || true
done

# Kitty live neu einfärben (falls Listener aktiv)
if command -v kitty >/dev/null; then
  kitty @ --to unix:/tmp/kitty set-colors --all "$HOME/.cache/wal/colors-kitty.conf" >/dev/null 2>&1 || true
fi
