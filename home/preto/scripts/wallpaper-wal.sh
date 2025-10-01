#!/usr/bin/env bash
set -euo pipefail

# 1) Wallpaper-Ordner finden
CANDIDATES=(
  "$HOME/Pictures/wallpapers"
  "$HOME/.config/wallpapers"
  "/etc/nixos/home/preto/wallpapers"
)
DIR=""
for d in "${CANDIDATES[@]}"; do
  [[ -d "$d" ]] && DIR="$d" && break
done
[[ -z "$DIR" ]] && { echo "Kein Wallpaper-Ordner gefunden."; exit 1; }

# 2) Zufälliges Bild wählen
mapfile -t FILES < <(find "$DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \))
[[ ${#FILES[@]} -eq 0 ]] && { echo "Keine Bilder in $DIR."; exit 1; }
IMG="${FILES[RANDOM % ${#FILES[@]}]}"

# 3) pywal-Farben generieren (setzt auch ~/.cache/wal/wal auf den Bildpfad)
wal -n -i "$IMG" --saturate 0.7

# 4) Tatsächlichen Bildpfad ermitteln/prüfen
IMG="$(cat "$HOME/.cache/wal/wal")"
[[ -f "$IMG" ]] || { echo "pywal hat keinen gültigen Bildpfad geliefert: $IMG"; exit 1; }

# 5) Hyprpaper nur starten, wenn nicht schon läuft
if ! pgrep -x hyprpaper >/dev/null; then
  hyprpaper & disown
  # kurz warten, bis IPC bereit ist
  sleep 0.4
fi

# 6) Wallpaper setzen (alle Monitore)
hyprctl hyprpaper preload "$IMG"
for mon in $(hyprctl monitors -j | jq -r '.[].name'); do
  hyprctl hyprpaper wallpaper "$mon,$IMG"
done
