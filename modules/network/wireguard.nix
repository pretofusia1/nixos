{ config, lib, pkgs, ... }:

let
  # === deine VPN-Parameter hier anpassen ===
  endpointHost = "168.119.159.48"; # z.B. 49.13.x.x
  endpointPort = 51820;
  serverPubKey = "pzo6fnTRP/r+Lac8wvpwIsV+QVDmfie0Gbg26LPrglo=";    # aus /etc/wireguard/server_public.key

  # SICHERHEIT: Private Key über sops-nix (verschlüsselt)
  # Falls sops-nix nicht eingerichtet ist, nutze Fallback auf unverschlüsselten Pfad
  # TODO: Migriere zu sops-nix! Siehe: https://github.com/Mic92/sops-nix
  privKeyFile = if config.sops.secrets ? "wireguard/laptop_private"
                then config.sops.secrets."wireguard/laptop_private".path
                else "/etc/secret/wireguard/laptop_private.key";
in
{
  imports = [ ];

  # WireGuard (wg-quick) aktivieren
  networking.wg-quick.interfaces = {
    # --- Split-Tunnel: nur internes VPN-Netz ---
    wg0 = {
      autostart = false;
      address = [ "10.10.0.10/32" ];
      privateKeyFile = privKeyFile;
      peers = [{
        publicKey = serverPubKey;
        endpoint  = "${endpointHost}:${toString endpointPort}";
        persistentKeepalive = 25;
        allowedIPs = [ "10.10.0.0/24" ];
      }];
      # Optional: MTU setzen, falls nötig
      # mtu = 1420;
    };

    # --- Full-Tunnel: gesamter Traffic über Gateway ---
    wg0full = {
      autostart = false;
      address = [ "10.10.0.10/32" ];
      privateKeyFile = privKeyFile;
      peers = [{
        publicKey = serverPubKey;
        endpoint  = "${endpointHost}:${toString endpointPort}";
        persistentKeepalive = 25;
        allowedIPs = [ "0.0.0.0/0" "::/0" ];  # IPv6 CIDR korrigiert
      }];
      # mtu = 1420;
    };
  };

  # bequeme Aliases zum Umschalten
  environment.shellAliases = {
    wg-up      = "sudo systemctl start wg-quick-wg0";
    wg-down    = "sudo systemctl stop wg-quick-wg0";
    wg-full    = "sudo systemctl start wg-quick-wg0full";
    wg-fulloff = "sudo systemctl stop  wg-quick-wg0full";
    wg-stat    = "sudo wg show";
  };

  # Firewall-Regeln für WireGuard Client
  # WICHTIG: Als Client brauchen wir KEINE offenen Ports!
  # WireGuard baut ausgehende Verbindungen auf (stateful firewall erlaubt Antworten)
  networking.firewall = {
    enable = true;
    # KEINE offenen Ports - Laptop ist Client, nicht Server!
    allowedUDPPorts = [ ];
    allowedTCPPorts = [ ];

    # SICHERHEIT: NICHT blind vertrauen! Nur spezifische Ports über WireGuard erlauben
    # Falls du SSH über WireGuard nutzen möchtest, entkommentiere:
    # interfaces.wg0.allowedTCPPorts = [ 22 ];
    # interfaces.wg0full.allowedTCPPorts = [ 22 ];

    # VERALTET (zu permissiv): trustedInterfaces = [ "wg0" "wg0full" ];
    # Begründung: Falls VPN-Server kompromittiert wird, hätte ein Angreifer
    # vollen Zugriff auf deinen Laptop. Besser: Explicit Deny by Default!
  };

  # Stelle sicher, dass das Secret existiert / korrekte Rechte hat
  systemd.tmpfiles.rules = [
    "d /etc/secret/wireguard 0700 root root -"
  ];

  # === SOPS-NIX SETUP (Optional, aber empfohlen!) ===
  # Aktiviere dies, um WireGuard-Keys verschlüsselt zu speichern:
  #
  # 1. Erstelle secrets.yaml mit sops:
  #    $ sops secrets/secrets.yaml
  #    wireguard:
  #      laptop_private: |
  #        <dein-private-key-hier>
  #
  # 2. Aktiviere in hosts/preto-laptop/default.nix:
  #    imports = [ inputs.sops-nix.nixosModules.sops ];
  #    sops.defaultSopsFile = ../../secrets/secrets.yaml;
  #    sops.age.keyFile = "/home/preto/.config/sops/age/keys.txt";
  #
  # 3. Entkommentiere hier:
  # sops.secrets."wireguard/laptop_private" = {
  #   mode = "0400";
  #   owner = "root";
  #   group = "root";
  # };
}
