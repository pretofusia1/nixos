{ config, lib, pkgs, ... }:

let
  # === VPN-Parameter ===
  # Müssen mit den Werten in scripts/wg-up.sh und scripts/wg-down.sh übereinstimmen!
  endpointHost = "168.119.159.48";
  endpointPort = 51820;
  serverPubKey = "U8NbnEX4uY5oG5ar7qKEqzdQv1O/Ib56D6M5+DVoY30=";
  clientAddress = "10.10.0.10/32";
  vpnSubnet    = "10.10.0.0/24";
in
{
  # === Pakete: WireGuard-Tools, KeePassXC-CLI, YubiKey-Manager ===
  environment.systemPackages = with pkgs; [
    wireguard-tools   # wg, wg-quick (wg-quick nicht genutzt, wg direkt)
    keepassxc         # keepassxc-cli
    yubikey-manager   # ykman

    # wg-up: Tunnel manuell starten, Key kommt aus KeePassXC via YubiKey
    # Das Skript baut das Interface direkt via ip + wg auf (kein wg-quick)
    (pkgs.writeShellApplication {
      name = "wg-up";
      runtimeInputs = [ pkgs.wireguard-tools pkgs.keepassxc pkgs.yubikey-manager pkgs.iproute2 ];
      text = builtins.readFile ../../scripts/wg-up.sh;
    })

    # wg-down: Tunnel sauber beenden
    (pkgs.writeShellApplication {
      name = "wg-down";
      runtimeInputs = [ pkgs.iproute2 ];
      text = builtins.readFile ../../scripts/wg-down.sh;
    })
  ];

  # === Shell-Alias für Status-Abfrage ===
  environment.shellAliases = {
    wg-stat = "sudo wg show";
  };

  # === Firewall ===
  # Als Client keine eingehenden Ports nötig.
  # Ausgehende UDP-Verbindungen werden von der stateful firewall erlaubt.
  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ ];
    allowedTCPPorts = [ ];
    # Optional: SSH nur über WireGuard erlauben:
    # interfaces.wg0.allowedTCPPorts = [ 22 ];
  };

  # === Hinweise ===
  # - Kein autoStart, kein wg-quick systemd-Service
  # - Interface wird via 'wg-up' manuell gestartet
  # - PrivateKey wird NICHT in /etc gespeichert - er kommt aus KeePassXC
  # - SOPS-Secret 'wireguard/laptop_private' ist in hosts/preto-laptop/default.nix noch definiert
  #   → wird von diesem Modul NICHT mehr genutzt → in Phase 2 entfernen
}
