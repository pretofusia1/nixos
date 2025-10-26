{ config, lib, pkgs, ... }:

let
  # === deine VPN-Parameter hier anpassen ===
  endpointHost = "168.119.159.48"; # z.B. 49.13.x.x
  endpointPort = 51820;
  serverPubKey = "zo6fnTRP/r+Lac8wvpwIsV+QVDmfie0Gbg26LPrglo=";    # aus /etc/wireguard/server_public.key
  # Pfad zur privaten Laptop-Keydatei (nicht ins Repo legen!)
  privKeyFile  = "/etc/secret/wireguard/laptop_private.key";
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
        allowedIPs = [ "0.0.0.0/0" "::-0/0" ];
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

  # Firewall-Regeln (falls NixOS-Firewall genutzt wird)
  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ endpointPort ];
  };

  # Stelle sicher, dass das Secret existiert / korrekte Rechte hat
  systemd.tmpfiles.rules = [
    "d /etc/secret/wireguard 0700 root root -"
  ];
}
