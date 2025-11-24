{ config, lib, pkgs, ... }:

{
  # ============================================
  # Erweiterte Security-Maßnahmen für NixOS
  # ============================================
  # Erstellt: 2025-01-24
  # Zweck: Defense-in-Depth Security
  # ============================================

  # -------------------------------------------
  # 1. AppArmor - Kernel-Level MAC
  # -------------------------------------------
  # Mandatory Access Control für Programme
  security.apparmor = {
    enable = true;
    packages = [ pkgs.apparmor-profiles ];  # Vordefinierte Profile
    killUnconfinedConfinables = true;      # Erzwinge Profile wo möglich
  };

  # -------------------------------------------
  # 2. Firejail - Application Sandboxing
  # -------------------------------------------
  # Isoliert Programme in Container
  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      # Firefox mit Sandbox
      firefox = {
        executable = "${lib.getBin pkgs.firefox}/bin/firefox";
        profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
        extraArgs = [
          # Zusätzliche Härtung (optional, auskommentieren wenn Probleme):
          # "--disable-mnt"      # Kein mount
          # "--disable-u2f"      # Kein U2F (YubiKey etc.)
        ];
      };

      # Chromium mit Sandbox
      chromium = {
        executable = "${lib.getBin pkgs.chromium}/bin/chromium";
        profile = "${pkgs.firejail}/etc/firejail/chromium.profile";
      };

      # Weitere sandboxed Apps (optional):
      # thunderbird = {
      #   executable = "${lib.getBin pkgs.thunderbird}/bin/thunderbird";
      #   profile = "${pkgs.firejail}/etc/firejail/thunderbird.profile";
      # };
    };
  };

  # -------------------------------------------
  # 3. USBGuard - USB-Angriffsprävention
  # -------------------------------------------
  # Schützt vor BadUSB und unautorisierten USB-Geräten
  services.usbguard = {
    enable = true;
    dbus.enable = true;
    IPCAllowedUsers = [ "preto" ];
    IPCAllowedGroups = [ "wheel" ];

    # Policy: Erlaube alle bereits verbundenen Geräte beim Boot
    rules = ''
      # Erlaube alle Geräte die beim Boot verbunden sind
      allow with-interface equals { 03:00:01 03:01:01 03:01:02 }  # Keyboards/Mice
      allow with-interface equals { 08:*:* }                       # Mass Storage
      allow with-interface equals { 0e:*:* }                       # Video (Webcam)

      # Blockiere alles andere standardmäßig (wird via GUI genehmigt)
      # reject
    '';
  };

  # -------------------------------------------
  # 4. MAC-Adress-Randomisierung
  # -------------------------------------------
  # Verhindert WiFi/Ethernet-Tracking
#  networking.networkmanager = {
#    wifi.macAddress = "random";
#    ethernet.macAddress = "random";
    # Randomisiere bei jedem Connect (nicht nur Boot)
#    wifi.scanRandMacAddress = true;
#  };

  # -------------------------------------------
  # 5. Erweiterte Netzwerk-Härtung
  # -------------------------------------------
  # Zusätzlich zu den bestehenden Security-Einstellungen
  boot.kernel.sysctl = {
    # IPv4 Security
    "net.ipv4.tcp_syncookies" = 1;              # SYN-Flood-Schutz
    "net.ipv4.conf.all.rp_filter" = 1;          # IP-Spoofing-Schutz
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1; # Kein Ping-Broadcast
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.all.log_martians" = 1;       # Logge verdächtige Pakete

    # IPv6 Security
    "net.ipv6.conf.all.accept_ra" = 0;          # Keine Router-Advertisements
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;

    # Kernel-Pointer-Schutz (verhindert Kernel-Memory-Leaks)
    "kernel.kptr_restrict" = 2;

    # Core-Dumps einschränken
    "kernel.core_uses_pid" = 1;
    "fs.suid_dumpable" = 0;
  };

  # -------------------------------------------
  # 6. Bluetooth-Härtung
  # -------------------------------------------
  # Falls Bluetooth aktiviert ist (siehe hosts/preto-laptop/default.nix)
  hardware.bluetooth = {
    powerOnBoot = false;              # Nur bei Bedarf (spart Akku + Security)
    settings = {
      General = {
        Experimental = true;          # Bessere Codec-Unterstützung
        ControllerMode = "dual";      # Dual-Mode für BLE
        JustWorksRepairing = "never"; # Verhindere automatisches Pairing
        Privacy = "device";           # Privacy-Mode
      };
    };
  };

  # -------------------------------------------
  # 7. Sandboxing für Systemd-Services
  # -------------------------------------------
  # Härte systemd-Services (Beispiel für NetworkManager)
  systemd.services.NetworkManager.serviceConfig = {
    PrivateTmp = true;
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = true;
  };

  # -------------------------------------------
  # 8. Audit-System erweitern
  # -------------------------------------------
  # Du hast bereits auditd aktiviert, hier zusätzliche Regeln
  security.audit.rules = [
    # Überwache Passwort-Dateien
    "-w /etc/passwd -p wa -k passwd_changes"
    "-w /etc/shadow -p wa -k shadow_changes"
    "-w /etc/group -p wa -k group_changes"

    # Überwache Sudo-Nutzung
    "-w /usr/bin/sudo -p x -k sudo_usage"

    # Überwache SSH
    "-w /etc/ssh/sshd_config -p wa -k sshd_config"

    # Überwache Kernel-Module
    "-w /sbin/insmod -p x -k modules"
    "-w /sbin/rmmod -p x -k modules"
    "-w /sbin/modprobe -p x -k modules"

    # Überwache Firewall-Änderungen
    "-w /usr/bin/ufw -p x -k firewall_changes"
  ];

  # -------------------------------------------
  # 9. Zusätzliche Security-Pakete
  # -------------------------------------------
  environment.systemPackages = with pkgs; [
    # AppArmor-Utils für Profil-Management
    apparmor-utils

    # Firejail-Tools
    firejail

    # USBGuard-Tools (optional)
    # usbguard-notifier  # Benachrichtigungen bei neuen USB-Geräten
    # usbguard-qt        # GUI für USBGuard

    # Security-Audit-Tools
    lynis          # Security-Audit
    chkrootkit     # Rootkit-Detection
  ];

  # -------------------------------------------
  # 10. Erweiterte Firewall-Regeln
  # -------------------------------------------
  # Zusätzlich zu deiner bestehenden Firewall
  networking.firewall = {
    # Erlaube Ping (ICMP), aber rate-limited
    allowPing = true;
    pingLimit = "--limit 1/minute --limit-burst 5";

    # Extra Firewall-Befehle (iptables)
    extraCommands = ''
      # Blockiere alle NULL-Pakete
      iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

      # Blockiere SYN-Flood
      iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP

      # Blockiere XMAS-Pakete
      iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

      # Rate-Limit SSH (falls du SSH aktivierst)
      # iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
      # iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
    '';
  };
}
