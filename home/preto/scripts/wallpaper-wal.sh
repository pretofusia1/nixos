#!/usr/bin/env bash
set -euo pipefail

# Log-Funktion für besseres Debugging
log() {
  echo "[wall] $*" | tee -a /tmp/wallpaper-wal.log
}

log "=== Script gestartet um $(date) ==="

# Wallpaper-Ordner suchen (erster gefundener wird genommen)
CANDIDATES=(
  "$HOME/Pictures/wallpapers"
  "$HOME/.config/wallpapers"
  "/etc/nixos/home/preto/wallpapers"
)
DIR=""
for d in "${CANDIDATES[@]}"; do
  if [[ -d "$d" ]]; then
    DIR="$d"
    log "Wallpaper-Ordner gefunden: $DIR"
    break
  fi
done

if [[ -z "$DIR" ]]; then
  log "FEHLER: Kein Wallpaper-Ordner gefunden!"
  log "Gesuchte Pfade: ${CANDIDATES[*]}"
  exit 1
fi

# Zufälliges Bild auswählen
mapfile -t FILES < <(find "$DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \))

if [[ ${#FILES[@]} -eq 0 ]]; then
  log "FEHLER: Keine Bilder in $DIR gefunden!"
  exit 1
fi

IMG="${FILES[RANDOM % ${#FILES[@]}]}"
log "Ausgewähltes Bild: $IMG"

# Prüfe ob Bild existiert und lesbar ist
if [[ ! -f "$IMG" ]]; then
  log "FEHLER: Bild existiert nicht: $IMG"
  exit 1
fi

if [[ ! -r "$IMG" ]]; then
  log "FEHLER: Bild nicht lesbar: $IMG"
  exit 1
fi

# Pywal-Farben generieren
log "Generiere Pywal-Farben aus: $(basename "$IMG")"
if ! wal -n -i "$IMG" --backend colorz 2>&1 | tee -a /tmp/wallpaper-wal.log; then
  log "FEHLER: Pywal konnte keine Farben generieren!"
  exit 1
fi

# Prüfe ob Pywal erfolgreich war
if [[ ! -f "$HOME/.cache/wal/colors.sh" ]]; then
  log "FEHLER: Pywal-Farbdatei wurde nicht erstellt: $HOME/.cache/wal/colors.sh"
  exit 1
fi

# Pywal-Sequenzen für Terminal exportieren
if [[ -f "$HOME/.cache/wal/sequences" ]]; then
  cat "$HOME/.cache/wal/sequences" &
  log "Terminal-Farben exportiert"
fi

log "Pywal-Farben erfolgreich generiert"

# Aus Pywal den finalen Bildpfad übernehmen
if [[ -f "$HOME/.cache/wal/wal" ]]; then
  IMG="$(cat "$HOME/.cache/wal/wal")"
  log "Finaler Bildpfad aus Pywal: $IMG"
fi

if [[ ! -f "$IMG" ]]; then
  log "FEHLER: Ungültiger Bildpfad von Pywal: $IMG"
  exit 1
fi

# Hyprpaper starten, falls nicht aktiv
if ! pgrep -x hyprpaper >/dev/null; then
  log "Starte hyprpaper..."
  hyprpaper & disown
  sleep 1  # Gib hyprpaper Zeit zum Starten
else
  log "hyprpaper läuft bereits"
fi

# Auf IPC warten (max. 5 Sekunden)
log "Warte auf hyprpaper IPC..."
READY=false
for i in {1..25}; do
  if hyprctl hyprpaper listpreloaded >/dev/null 2>&1; then
    READY=true
    log "hyprpaper IPC bereit nach $((i * 200))ms"
    break
  fi
  sleep 0.2
done

# Abbruch wenn hyprpaper nicht bereit
if [[ "$READY" != "true" ]]; then
  log "FEHLER: hyprpaper nicht bereit nach 5 Sekunden"
  log "Prüfe ob hyprpaper läuft: $(pgrep -x hyprpaper || echo 'NICHT AKTIV')"
  exit 1
fi

# Wallpaper preloaden
log "Preloade Wallpaper: $IMG"
if ! hyprctl hyprpaper preload "$IMG" 2>&1 | tee -a /tmp/wallpaper-wal.log; then
  log "FEHLER: Konnte Wallpaper nicht preloaden"
  exit 1
fi

# Wallpaper auf allen Monitoren setzen
MONITORS=$(hyprctl monitors -j | jq -r '.[].name')
log "Gefundene Monitore: $MONITORS"

for mon in $MONITORS; do
  log "Setze Wallpaper auf Monitor: $mon"
  if ! hyprctl hyprpaper wallpaper "$mon,$IMG" 2>&1 | tee -a /tmp/wallpaper-wal.log; then
    log "WARNUNG: Konnte Wallpaper nicht auf Monitor $mon setzen"
  fi
done

# Kitty live neu einfärben (falls Listener aktiv)
if command -v kitty >/dev/null && [[ -f "$HOME/.cache/wal/colors-kitty.conf" ]]; then
  if kitty @ --to unix:/tmp/kitty set-colors --all "$HOME/.cache/wal/colors-kitty.conf" >/dev/null 2>&1; then
    log "Kitty-Farben live aktualisiert"
  else
    log "Kitty-Farben konnten nicht aktualisiert werden (normal wenn kein Socket)"
  fi
fi

log "✅ Wallpaper & Pywal erfolgreich initialisiert!"
log "=== Script beendet um $(date) ==="

# WAYBAR NEUSTART ENTFERNT!
# Waybar wird vom waybar-launcher.sh gestartet, der auf Pywal-Farben wartet
# Das verhindert Race Conditions beim Boot
