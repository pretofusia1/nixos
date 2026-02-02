{ config, lib, pkgs, ... }:

let
  # === VPN-Parameter für Proxmox VM ===
  endpointHost = "168.119.159.48";
  endpointPort = 51820;
  serverPubKey = "pzo6fnTRP/r+Lac8wvpwIsV+QVDmfie0Gbg26LPrglo=";

  # SOPS-nix Secret für VM
  privKeyFile = if config.sops.secrets ? "wireguard/proxmox-vm_private"
                then config.sops.secrets."wireguard/proxmox-vm_private".path
                else "/etc/secret/wireguard/proxmox-vm_private.key";
in
{
  imports = [ ];

  # WireGuard (wg-quick) aktivieren
  networking.wg-quick.interfaces = {
    # --- Split-Tunnel: nur internes VPN-Netz ---
    wg0 = {
      autostart = false;
      address = [ "10.10.0.12/32" ];  # VM-spezifische IP!
      privateKeyFile = privKeyFile;
      peers = [{
        publicKey = serverPubKey;
        endpoint  = "${endpointHost}:${toString endpointPort}";
        persistentKeepalive = 25;
        allowedIPs = [ "10.10.0.0/24" ];
      }];
    };

    # --- Full-Tunnel: gesamter Traffic über Gateway ---
    wg0full = {
      autostart = false;
      address = [ "10.10.0.12/32" ];  # VM-spezifische IP!
      privateKeyFile = privKeyFile;
      peers = [{
        publicKey = serverPubKey;
        endpoint  = "${endpointHost}:${toString endpointPort}";
        persistentKeepalive = 25;
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
      }];
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
  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ ];
    allowedTCPPorts = [ ];
  };

  # Stelle sicher, dass das Secret-Verzeichnis existiert
  systemd.tmpfiles.rules = [
    "d /etc/secret/wireguard 0700 root root -"
  ];
}
