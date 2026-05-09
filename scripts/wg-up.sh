#!/usr/bin/env bash
# wg-up: WireGuard wg0 manuell starten
# Key wird zur Laufzeit aus KeePassXC via YubiKey geholt.
# Phase 1: Mechanik aufbauen - Key bleibt gleich (kein neues Keypair!)
#
# Strategie: Interface manuell aufbauen (kein wg-quick, damit kein PrivateKey in /etc/wireguard/wg0.conf nötig)
#   1. Key aus KeePassXC lesen
#   2. Key in /dev/shm (RAM-FS) ablegen
#   3. ip link add wg0 type wireguard
#   4. wg set wg0 private-key ... + peer-Konfiguration
#   5. ip address add / ip link set up / ip route add
#   6. Key-Datei sofort löschen
#
# HINWEIS: pkgs.writeShellApplication fügt 'set -euo pipefail' und Shebang automatisch hinzu.
set -euo pipefail

# === ANPASSEN: Pfad zur KeePassXC-Datenbank ===
KDBX="$HOME/Documents/keepass/homelab.kdbx"  # ANPASSEN!

# KeePassXC-Eintrag-Name
ENTRY="WireGuard wg0 Hetzner"

# WireGuard-Parameter (müssen mit /etc/wireguard/wg0.conf übereinstimmen)
WG_ADDR="10.10.0.10/32"
WG_PEER_PUBKEY="U8NbnEX4uY5oG5ar7qKEqzdQv1O/Ib56D6M5+DVoY30="
WG_ENDPOINT="168.119.159.48:51820"
WG_ALLOWED_IPS="10.10.0.0/24"
WG_KEEPALIVE=25

# === Vorprüfungen ===

if [[ ! -f "$KDBX" ]]; then
  echo "FEHLER: KeePassXC-Datenbank nicht gefunden: $KDBX" >&2
  echo "Bitte KDBX-Pfad in scripts/wg-up.sh im NixOS-Repo anpassen und nixos-rebuild switch ausführen." >&2
  exit 1
fi

if ip link show wg0 &>/dev/null 2>&1; then
  echo "wg0 läuft bereits. Zuerst 'wg-down' ausführen." >&2
  exit 1
fi

if ! YK_SERIAL=$(ykman list --serials 2>/dev/null | head -1) || [[ -z "$YK_SERIAL" ]]; then
  echo "FEHLER: Kein YubiKey gefunden. YubiKey einstecken und erneut versuchen." >&2
  exit 1
fi

echo "YubiKey gefunden: $YK_SERIAL"
echo "KeePassXC-Passphrase eingeben (danach YubiKey antippen wenn er blinkt)..."

# === Key aus KeePassXC holen ===
WG_KEY=$(keepassxc-cli show \
  --yubikey "2:${YK_SERIAL}" \
  --attributes Password \
  --show-protected \
  "$KDBX" \
  "$ENTRY")

if [[ -z "$WG_KEY" ]]; then
  echo "FEHLER: Kein Key aus KeePassXC gelesen." >&2
  echo "Prüfen: Existiert Entry '$ENTRY' in der Datenbank? Ist das Password-Feld befüllt?" >&2
  exit 1
fi

# === Key sicher in RAM-FS ablegen ===
# /dev/shm liegt im RAM - wird nie auf Disk geschrieben
KEY_FILE=$(mktemp /dev/shm/wg-XXXXXX)
chmod 0600 "$KEY_FILE"
printf '%s\n' "$WG_KEY" > "$KEY_FILE"

# Key-Variable sofort löschen (liegt jetzt nur noch in KEY_FILE)
WG_KEY=""
unset WG_KEY

# Cleanup-Trap: Key-Datei wird in jedem Fall gelöscht
cleanup() {
  rm -f "$KEY_FILE"
}
trap cleanup EXIT INT TERM

# === WireGuard Interface aufbauen ===
# Wir nutzen direkt ip + wg statt wg-quick, damit kein PrivateKey in /etc nötig ist.

echo "Erstelle wg0 Interface..."
sudo ip link add wg0 type wireguard

# Key injizieren (sudo liest Datei direkt, kein Argument-Leak)
sudo wg set wg0 \
  private-key "$KEY_FILE" \
  peer "$WG_PEER_PUBKEY" \
    endpoint "$WG_ENDPOINT" \
    allowed-ips "$WG_ALLOWED_IPS" \
    persistent-keepalive "$WG_KEEPALIVE"

# Key-Datei explizit löschen (trap würde es auch tun, aber früher ist besser)
rm -f "$KEY_FILE"

# Interface konfigurieren und hochfahren
sudo ip address add "$WG_ADDR" dev wg0
sudo ip link set wg0 up

# Route für VPN-Subnetz setzen
# (Split-Tunnel: nur VPN-Netz wird durch wg0 geroutet)
sudo ip route add "$WG_ALLOWED_IPS" dev wg0 2>/dev/null || true

echo ""
echo "wg0 gestartet. Status:"
sudo wg show wg0
