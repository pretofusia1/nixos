# NixOS System-Optimierungen

**Datum:** 2025-01-24
**System:** preto-laptop (NixOS 24.11)
**Zweck:** Performance, Security & Workflow-Verbesserungen

---

## 📋 Übersicht der Änderungen

Dieses Update fügt **21 Optimierungen** in 3 neuen Modulen hinzu:

1. **`modules/performance.nix`** - Performance-Tuning
2. **`modules/security-advanced.nix`** - Erweiterte Sicherheit
3. **`modules/workflow.nix`** - Workflow-Verbesserungen

Plus Anpassungen in:
- `hosts/preto-laptop/default.nix` (Import der Module)
- `home/preto/home.nix` (User-Einstellungen)

---

## 🚀 Performance-Optimierungen

### 1. **Zram** - Komprimierter RAM-Swap
**Was:** Komprimiert inaktive RAM-Seiten statt auf Disk zu swappen
**Effekt:** 30-50% mehr nutzbarer RAM, 10x schneller als Disk-Swap
**Konfiguration:**
```nix
zramSwap = {
  enable = true;
  algorithm = "zstd";
  memoryPercent = 50;
};
```

### 2. **SSD-Optimierungen**
**Was:** Wöchentliches TRIM für SSD-Lebensdauer
**Effekt:** Erhält SSD-Performance langfristig
**Konfiguration:**
```nix
services.fstrim = {
  enable = true;
  interval = "weekly";
};
```

**Zusätzlich:** I/O-Scheduler automatisch angepasst:
- NVMe: `none` (optimal für moderne SSDs)
- SATA-SSD: `mq-deadline`
- HDD: `bfq` (falls vorhanden)

### 3. **tmpfs für /tmp**
**Was:** Temporäre Dateien im RAM statt auf Disk
**Effekt:** Extrem schnelle temporäre Operationen
**Konfiguration:**
```nix
boot.tmp = {
  useTmpfs = true;
  tmpfsSize = "50%";
};
```

### 4. **Kernel-Tuning**
**Was:** Sysctl-Parameter für Desktop-Nutzung optimiert
**Effekt:** Weniger Swap, besseres Caching, optimiertes I/O

**Wichtigste Parameter:**
- `vm.swappiness = 10` (weniger Swap-Nutzung)
- `vm.vfs_cache_pressure = 50` (mehr Caching)
- `vm.dirty_ratio = 10` (besseres I/O-Verhalten)
- `net.ipv4.tcp_fastopen = 3` (schnellere TCP-Verbindungen)

### 5. **Boot-Optimierung**
**Was:** Schnellerer Boot, weniger Bootloader-Timeout
**Effekt:** ~2-3 Sekunden schnellerer Boot
**Konfiguration:**
- Boot-Timeout: 1 Sekunde (statt 5)
- Kernel-Parameter: `quiet splash`
- Max. 10 Boot-Einträge (spart /boot-Speicher)

### 6. **Nix Store Auto-Optimierung**
**Was:** Automatische Deduplikation via Hardlinks
**Effekt:** Spart 10-30% Speicher im Nix Store
**Konfiguration:**
```nix
nix.settings.auto-optimise-store = true;
```

---

## 🔒 Security-Verbesserungen

### 7. **AppArmor** - Mandatory Access Control
**Was:** Kernel-Level-Schutz für Programme
**Effekt:** Begrenzt Schaden bei Exploits (z.B. Firefox-Hack kann nicht auf SSH-Keys zugreifen)
**Konfiguration:**
```nix
security.apparmor = {
  enable = true;
  packages = [ pkgs.apparmor-profiles ];
  killUnconfinedConfinables = true;
};
```

**Nutzen:** Siehe separate Erklärung oben (AppArmor-Kapitel)

### 8. **Firejail** - Application Sandboxing
**Was:** Isoliert Programme in Container
**Effekt:** Firefox/Chromium können nur auf erlaubte Ordner zugreifen
**Konfiguration:**
```nix
programs.firejail = {
  enable = true;
  wrappedBinaries = {
    firefox = { ... };
    chromium = { ... };
  };
};
```

**Nutzen:** Siehe separate Erklärung oben (Firejail-Kapitel)

### 9. **USBGuard** - USB-Angriffsprävention
**Was:** Blockiert unbekannte USB-Geräte
**Effekt:** Schutz vor BadUSB-Attacks
**Konfiguration:**
```nix
services.usbguard = {
  enable = true;
  dbus.enable = true;
  IPCAllowedUsers = [ "preto" ];
};
```

**Beim ersten Start:** Alle aktuellen USB-Geräte werden genehmigt. Neue Geräte erfordern Genehmigung.

### 10. **MAC-Adress-Randomisierung**
**Was:** Ändert WiFi/Ethernet MAC-Adresse bei jedem Connect
**Effekt:** Verhindert Tracking über WiFi
**Konfiguration:**
```nix
networking.networkmanager = {
  wifi.macAddress = "random";
  ethernet.macAddress = "random";
  wifi.scanRandMacAddress = true;
};
```

### 11. **Erweiterte Netzwerk-Härtung**
**Was:** Zusätzliche Kernel-Sysctl-Parameter für Netzwerk-Security
**Effekt:** Schutz vor IP-Spoofing, SYN-Floods, etc.

**Wichtigste Parameter:**
- `net.ipv4.tcp_syncookies = 1` (SYN-Flood-Schutz)
- `net.ipv4.conf.all.rp_filter = 1` (IP-Spoofing-Schutz)
- `net.ipv6.conf.all.accept_ra = 0` (keine Router-Advertisements)
- `kernel.kptr_restrict = 2` (Kernel-Pointer-Schutz)

### 12. **Bluetooth-Härtung**
**Was:** Bluetooth standardmäßig aus, Privacy-Mode
**Effekt:** Spart Akku, verhindert Bluetooth-Tracking
**Konfiguration:**
```nix
hardware.bluetooth = {
  powerOnBoot = false;
  settings.General.Privacy = "device";
};
```

### 13. **Erweiterte Firewall-Regeln**
**Was:** Blockiert NULL-Pakete, XMAS-Scans, SYN-Floods
**Effekt:** Schutz vor Port-Scanning und Netzwerk-Angriffen

### 14. **Audit-Erweiterungen**
**Was:** Überwacht Zugriffe auf kritische Dateien
**Effekt:** Benachrichtigung bei Änderungen an Passwörtern, SSH-Configs, etc.

**Überwachte Dateien:**
- `/etc/passwd`, `/etc/shadow`
- `/etc/ssh/sshd_config`
- Sudo-Nutzung
- Kernel-Module laden/entladen

---

## ⚡ Workflow-Verbesserungen

### 15. **Nix-Direnv** - Auto-Dev-Environments
**Was:** Lädt Entwicklungsumgebungen automatisch beim `cd` in Projektordner
**Effekt:** `shell.nix` wird automatisch geladen, keine manuellen `nix-shell`-Befehle
**Konfiguration:**
```nix
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
};
```

**Nutzung:**
```bash
cd ~/projekt
# .envrc wird automatisch geladen
# nix-shell Umgebung aktiv!
```

### 16. **Nix-Index** - Command-not-found
**Was:** Zeigt Paket-Name für unbekannte Befehle
**Effekt:** "Befehl nicht gefunden? → nix-shell -p <paket>"
**Konfiguration:**
```nix
programs.nix-index.enable = true;
```

**Beispiel:**
```bash
$ htop
Command 'htop' not found, but can be installed with:
  nix-shell -p htop
```

### 17. **Cachix** - Binary Caches
**Was:** Vorgefertigte Binaries statt selbst kompilieren
**Effekt:** 90% schnellere Builds für Hyprland, etc.
**Konfiguration:**
```nix
nix.settings.substituters = [
  "https://cache.nixos.org"
  "https://hyprland.cachix.org"
  "https://nix-community.cachix.org"
];
```

### 18. **Auto-Garbage-Collection**
**Was:** Wöchentliche automatische Aufräumung alter Generationen
**Effekt:** Spart ~5-10 GB Speicher pro Woche
**Konfiguration:**
```nix
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 14d";
};
```

### 19. **Shell-Aliases**
**Was:** Shortcuts für häufige Befehle
**Effekt:** Schnellerer Workflow

**Neue Aliases:**
```bash
rebuild        # sudo nixos-rebuild switch --flake .#preto-laptop
rebuild-boot   # Boot ohne sofortigen Switch
rebuild-test   # Teste Config ohne zu aktivieren

nix-clean      # Garbage-Collection + Store-Optimierung
nix-update     # Flake-Inputs updaten
nix-search     # Pakete suchen

nix-gen        # Liste Generationen
nix-size       # Zeige System-Größe

gs/ga/gc/gp/gl # Git-Shortcuts
wg-check       # WireGuard-Status
```

### 20. **Development-Tools**
**Was:** Zusätzliche Nix-Entwicklungs-Tools
**Pakete:**
- `nix-tree` - Visualisiere Abhängigkeiten
- `nix-diff` - Vergleiche Derivations
- `nix-du` - Analysiere Store-Größen
- `nil` - Nix LSP Server (für VS Code/Neovim)
- `nixfmt-classic` - Code-Formatter
- `gh` - GitHub CLI

### 21. **System-Diff bei Rebuild**
**Was:** Zeigt Änderungen nach `nixos-rebuild`
**Effekt:** Siehst du genau, was sich geändert hat

**Beispiel-Output:**
```
=== Systemänderungen ===
firefox: 122.0 → 123.0
linux-kernel: 6.6.10 → 6.6.11
+10 neue Pakete, -3 entfernte
========================
```

---

## 🖥️ Desktop/UX-Verbesserungen

### **Firefox Hardware-Acceleration**
**Was:** Nutzt GPU für Video-Dekodierung
**Effekt:** Weniger CPU-Last bei YouTube, etc.
**Konfiguration:**
```nix
programs.firefox.profiles.default.settings = {
  "media.ffmpeg.vaapi.enabled" = true;
  "media.hardware-video-decoding.enabled" = true;
  "gfx.webrender.all" = true;
};
```

### **Chromium Wayland-Native**
**Was:** Chromium nutzt Wayland statt XWayland
**Effekt:** Bessere Performance, native Gestures
**Konfiguration:**
```nix
programs.chromium.commandLineArgs = [
  "--enable-features=UseOzonePlatform"
  "--ozone-platform=wayland"
  "--enable-features=VaapiVideoDecoder"
];
```

---

## 📊 Erwartete Verbesserungen

| Bereich | Verbesserung |
|---------|--------------|
| **Boot-Zeit** | -2 bis -3 Sekunden |
| **RAM-Nutzung** | +30-50% effektiv nutzbarer RAM |
| **Build-Geschwindigkeit** | -90% Zeit für Hyprland/große Pakete |
| **SSD-Lebensdauer** | +20% durch TRIM |
| **Security-Score** | Lynis-Score +15-20 Punkte |
| **Disk-Speicher** | -5-10 GB durch Auto-GC |

---

## 🛠️ Installation & Aktivierung

### **1. Änderungen auf GitHub pushen (vom Container):**
```bash
cd /home/claude/nixos-deploy
git add .
git commit -m "Add performance, security & workflow optimizations"
git push
```

### **2. Auf dem Laptop pullen & rebuilden:**
```bash
cd /etc/nixos
git pull
sudo nixos-rebuild switch --flake .#preto-laptop
```

### **3. Nach dem Rebuild:**

**USBGuard initialisieren:**
```bash
# Aktuell verbundene USB-Geräte genehmigen
sudo usbguard generate-policy > /tmp/rules.conf
sudo mv /tmp/rules.conf /var/lib/usbguard/rules.conf
sudo systemctl restart usbguard
```

**AppArmor-Status prüfen:**
```bash
sudo aa-status
```

**Neue Aliases testen:**
```bash
# Shell neu laden
source ~/.bashrc

# Aliases testen
nix-gen     # Zeigt Generationen
wg-check    # Zeigt WireGuard-Status
rebuild     # Shortcut für rebuild
```

---

## ⚠️ Wichtige Hinweise

### **USBGuard:**
- Beim ersten Einstecken eines neuen USB-Geräts: Popup erscheint
- Genehmigung nötig (einmalig pro Gerät)
- Falls Probleme: `sudo usbguard list-devices`

### **Firejail:**
- Firefox/Chromium starten automatisch in Sandbox
- Falls Programme nicht funktionieren: Prüfe `/etc/firejail/<programm>.profile`
- Debugging: `firejail --debug firefox`

### **AppArmor:**
- Logs: `sudo journalctl -xe | grep apparmor`
- Falls Blockierung: `sudo aa-complain <programm>` (Complain-Mode statt Enforce)

### **Zram:**
- Nutzt max. 50% des RAMs für komprimierten Swap
- Bei Problemen: `zramctl` zeigt Status

### **Performance-Kernel-Parameter:**
- `mitigations=off` ist AUSKOMMENTIERT (Sicherheit > Performance)
- Nur aktivieren wenn du keine VMs/Container nutzt

---

## 🔧 Optional: Weitere Optimierungen

### **Wenn du VMs/Container NICHT nutzt:**
In `modules/performance.nix`, Zeile 66 entkommentieren:
```nix
"mitigations=off"  # +10% Performance, aber Sicherheitsrisiko
```

### **Monitoring installieren (optional):**
```bash
# In hosts/preto-laptop/default.nix:
services.netdata.enable = true;

# Zugriff: http://localhost:19999
```

### **Secure Boot (optional):**
Siehe NixOS Wiki: https://nixos.wiki/wiki/Secure_Boot

---

## 📚 Weiterführende Dokumentation

- **AppArmor:** https://wiki.archlinux.org/title/AppArmor
- **Firejail:** https://firejail.wordpress.com/
- **Nix-Direnv:** https://github.com/nix-community/nix-direnv
- **Lynis Security-Audit:** `sudo lynis audit system`

---

## 🎯 Prioritäten-Zusammenfassung

**Sofort aktiv (hohe Priorität):**
✅ Zram
✅ SSD-Optimierungen
✅ Nix-Direnv
✅ Nix-Index
✅ Cachix
✅ Shell-Aliases

**Aktiv (mittlere Priorität):**
✅ AppArmor
✅ Kernel-Tuning
✅ Auto-Garbage-Collection
✅ tmpfs für /tmp

**Optional (bei Bedarf aktivieren):**
⚙️ USBGuard (nach Initialisierung)
⚙️ Firejail (automatisch aktiv für Firefox/Chromium)
⚙️ Bluetooth-Härtung (falls Bluetooth genutzt)

---

**Fragen oder Probleme?** → IT-Agent fragen! 😊
