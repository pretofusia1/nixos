#!/usr/bin/env bash
set -euo pipefail

# Sucht Archive im ~/Downloads, Auswahl per Nummer, entpackt nach ~/unzip/<name>
DOWNLOADS="$HOME/Downloads"
TARGET_BASE="$HOME/unzip"

shopt -s nullglob
archives=("$DOWNLOADS"/*.zip "$DOWNLOADS"/*.tar "$DOWNLOADS"/*.tar.gz "$DOWNLOADS"/*.tgz "$DOWNLOADS"/*.tar.bz2 "$DOWNLOADS"/*.7z)
shopt -u nullglob

if [ ${#archives[@]} -eq 0 ]; then
  echo "Keine Archivdateien in $DOWNLOADS gefunden."
  exit 1
fi

echo "Gefundene Archive in $DOWNLOADS:"
i=1
for a in "${archives[@]}"; do
  echo "  $i) $(basename "$a")"
  ((i++))
done
echo

read -rp "Nummer wählen (Enter = 1): " num
num="${num:-1}"
if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt "${#archives[@]}" ]; then
  echo "Ungültige Auswahl."; exit 1
fi

archive="${archives[$((num-1))]}"
name="$(basename "$archive")"
base="${name%.*}"
target="$TARGET_BASE/$base"

mkdir -p "$target"
echo "Entpacke '$name' nach '$target' ..."

case "$archive" in
  *.zip)
    if command -v unzip >/dev/null 2>&1; then unzip -o "$archive" -d "$target"
    else bsdtar -xf "$archive" -C "$target"; fi
    ;;
  *.7z)
    if command -v 7z >/dev/null 2>&1; then 7z x "$archive" -o"$target"
    else echo "p7zip (7z) fehlt."; exit 1; fi
    ;;
  *.tar|*.tar.gz|*.tgz|*.tar.bz2)
    tar -xvf "$archive" -C "$target"
    ;;
  *)
    echo "Unbekanntes Format."; exit 1
    ;;
esac

echo "Fertig. Inhalt:"
ls -lah "$target"
