{ config, lib, pkgs, ... }:

{
  # ============================================
  # Performance-Optimierungen für NixOS
  # ============================================
  # Erstellt: 2025-01-24
  # Zweck: Maximale Performance für Desktop-Nutzung
  # ============================================

  # -------------------------------------------
  # 1. ZRAM - Komprimierter RAM-Swap
  # -------------------------------------------
  # Effekt: 30-50% mehr nutzbarer RAM, deutlich schneller als Disk-Swap
  zramSwap = {
    enable = true;
    algorithm = "zstd";      # Schnelle Kompression
    memoryPercent = 50;      # 50% des RAMs für Zram nutzen
  };

  # -------------------------------------------
  # 2. SSD-Optimierungen
  # -------------------------------------------
  # TRIM: Erhält SSD-Performance & Lebensdauer
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # -------------------------------------------
  # 3. tmpfs für /tmp (RAM statt Disk)
  # -------------------------------------------
  # Effekt: Sehr schnelle temporäre Dateien
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "50%";       # Max. 50% des RAMs
  };

  # -------------------------------------------
  # 4. Kernel-Tuning für Desktop
  # -------------------------------------------
  boot.kernel.sysctl = {
    # Memory Management
    "vm.swappiness" = 10;              # Weniger Swap-Nutzung (Standard: 60)
    "vm.vfs_cache_pressure" = 50;      # Mehr Caching (Standard: 100)
    "vm.dirty_ratio" = 10;             # Besseres I/O (Standard: 20)
    "vm.dirty_background_ratio" = 5;   # Früher schreiben (Standard: 10)

    # CPU
    "kernel.nmi_watchdog" = 0;         # Spart CPU-Zyklen

    # Networking (Performance)
    "net.core.netdev_max_backlog" = 16384;
    "net.core.somaxconn" = 8192;
    "net.core.rmem_default" = 1048576;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_default" = 1048576;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_mtu_probing" = 1;
  };

  # -------------------------------------------
  # 5. Boot-Optimierung
  # -------------------------------------------
  boot = {
    loader = {
      timeout = 1;                     # Schnellerer Boot (1 Sekunde Timeout)
      systemd-boot.configurationLimit = 10;  # Max. 10 Boot-Einträge
    };

    # Kernel-Parameter für schnelleren Boot
    kernelParams = [
      "quiet"                          # Weniger Boot-Messages
      "splash"                         # Plymouth-Splash (falls aktiviert)
      # WARNUNG: Nur aktivieren wenn du keine VMs/Container betreibst!
      # "mitigations=off"              # +10% Performance, aber Sicherheitsrisiko
    ];

    initrd.verbose = false;            # Kein initrd-Spam beim Boot
  };

  # -------------------------------------------
  # 6. I/O-Scheduler (für SSDs)
  # -------------------------------------------
  # none/noop für NVMe, mq-deadline für SATA-SSD
  services.udev.extraRules = ''
    # NVMe SSDs: none scheduler (optimal für NVMe)
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"

    # SATA SSDs: mq-deadline
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"

    # HDDs: bfq (falls du eine HDD hast)
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
  '';

  # -------------------------------------------
  # 7. Journald-Optimierung
  # -------------------------------------------
  # Begrenze Log-Größe (du hattest schon 500M, hier etwas erweitert)
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    SystemKeepFree=2G
    MaxRetentionSec=2week
    MaxFileSec=1day
  '';

  # -------------------------------------------
  # 8. Nix Store Optimierung
  # -------------------------------------------
  nix.settings = {
    # Auto-Optimise nach jedem Build (spart Speicher durch Hardlinks)
    auto-optimise-store = true;

    # Mehr parallele Builds (anpassen je nach CPU-Kernen)
    max-jobs = "auto";              # Automatisch basierend auf CPU-Kernen
    cores = 0;                      # 0 = alle verfügbaren Kerne nutzen
  };
}
