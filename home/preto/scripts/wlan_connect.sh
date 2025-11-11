#!/usr/bin/env bash
set -euo pipefail

# Listet WLANs via nmcli, Auswahl per Nummer, Passwort abfragen und verbinden

if ! command -v nmcli >/dev/null 2>&1; then
  echo "nmcli (NetworkManager) nicht gefunden. Bitte NetworkManager aktivieren."
  exit 1
fi

echo "Scanne WLANs ..."
nmcli device wifi rescan >/dev/null 2>&1 || true
sleep 1
mapfile -t rows < <(nmcli -f SSID,SECURITY,SIGNAL,BARS device wifi list | sed '1d')

if [ ${#rows[@]} -eq 0 ]; then
  echo "Keine WLANs gefunden."; exit 1
fi

echo "Verfügbare WLANs:"
i=1
for r in "${rows[@]}"; do
  printf "  %2d) %s\n" "$i" "$r"
  ((i++))
done

read -rp "Nummer wählen: " num
if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt "${#rows[@]}" ]; then
  echo "Ungültige Auswahl."; exit 1
fi

line="${rows[$((num-1))]}"
# SSID robust extrahieren (alles bis vorletzte Spalten SECURITY/SIGNAL/BARS kann Leerzeichen enthalten)
ssid="$(echo "$line" | awk '{for(i=1;i<=NF-3;i++) printf $i (i<NF-3?" ":"");}')"
security="$(echo "$line" | awk '{print $(NF-2)}')"

echo "Ausgewählt: '$ssid' (Sicherheit: $security)"
if [[ "$security" == "--" || "$security" == "NONE" ]]; then
  # Kein sudo nötig - User ist in networkmanager Gruppe
  nmcli device wifi connect "$ssid" && { echo "Verbunden."; exit 0; }
  echo "Verbindung fehlgeschlagen."; exit 1
else
  read -rsp "Passwort: " pw; echo
  # Kein sudo nötig - User ist in networkmanager Gruppe
  nmcli device wifi connect "$ssid" password "$pw" && { echo "Verbunden."; exit 0; }
  echo "Verbindung fehlgeschlagen."; exit 1
fi
