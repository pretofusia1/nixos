#!/usr/bin/env bash
# wg-down: WireGuard wg0 sauber beenden
# Spiegelbild zu wg-up: Interface manuell abbauen (kein wg-quick)
#
# HINWEIS: pkgs.writeShellApplication fügt 'set -euo pipefail' und Shebang automatisch hinzu.
set -euo pipefail

WG_ALLOWED_IPS="10.10.0.0/24"
WG_ADDR="10.10.0.10/32"

if ! ip link show wg0 &>/dev/null 2>&1; then
  echo "wg0 ist nicht aktiv."
  exit 0
fi

echo "Stoppe wg0..."

# Route entfernen
sudo ip route del "$WG_ALLOWED_IPS" dev wg0 2>/dev/null || true

# Interface runterfahren und löschen
sudo ip link set wg0 down
sudo ip link del wg0

echo "wg0 gestoppt."
