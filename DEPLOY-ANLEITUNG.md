# 🚀 NixOS Deployment Anleitung

## ✅ Änderungen vorgenommen in `/home/claude/nixos-deploy/`

### 1. `home/preto/hypr/hyprland.conf`
**GEÄNDERT:**
- ❌ **ENTFERNT**: Claude-Launcher exec-once (Zeile 21)
- ✅ **HINZUGEFÜGT**: Claude-Launcher Keybinding `SUPER + C` (Zeile 236)

**Ergebnis:**
- Waybar startet **automatisch** beim Boot ✅
- Claude-Launcher startet **manuell** mit `SUPER + C` ✅

---

### 2. `home/preto/waybar/config.jsonc` & `style.css`
**KOMPLETT ÜBERARBEITET - LibrePhoenix Style! 🎨**

**config.jsonc Änderungen:**
- ✅ **Layout**: Workspaces zentriert, Clock ganz rechts
- ✅ **Module rechts**: Network (WLAN), Volume, CPU, RAM, Battery, Tray, Clock
- ✅ **Margins**: Platz an Seiten (12px left/right, 8px top)
- ✅ **Symbole**: Alle Icons vorhanden ( CPU,  RAM,  Volume, 󰤨 WLAN, 󰥔 Clock)

**style.css Änderungen:**
- ✅ **Runde Ecken**: border-radius 16px oben & unten
- ✅ **Transparenz**: alpha(@background, 0.85) - 85% Deckkraft
- ✅ **Platz an Seiten**: margin-left/right 12px
- ✅ **Hover-Effekte**: Module heben sich beim Hover
- ✅ **Pywal-Integration**: Farben bleiben dynamisch

**Ergebnis:**
- 🎨 LibrePhoenix-Style mit runden Ecken & Transparenz
- 📊 Workspaces zentriert, Infos rechts
- 🕐 Uhr & Datum ganz rechts
- 📶 WLAN-Signalstärke angezeigt
- 🔊 Volume, 💻 CPU, 🧠 RAM mit Symbolen

---

### 3. `home/preto/home.nix`
**KEINE ÄNDERUNG NÖTIG!**

Die home.nix deployed bereits **ALLE** Skripte aus `./scripts/` rekursiv:
```nix
xdg.configFile."hypr/scripts" = {
  source = ./scripts;   # enthält screenshot-*.sh, wallpaper-wal.sh, waybar-launcher.sh etc.
  recursive = true;
  force = true;
};
```

---

## 📋 Deployment Workflow (vom Container aus)

### SCHRITT 1: Push vom Container zu GitHub
```bash
# Im Container (wo du gerade bist):
cd /home/claude/nixos-deploy
git status
git add home/preto/hypr/hyprland.conf
git add home/preto/waybar/config.jsonc
git add home/preto/waybar/style.css
git commit -m "Waybar LibrePhoenix Style + Claude-Launcher manual (SUPER+C)"
git push
```

### SCHRITT 2: Pull auf dem Laptop
```bash
# Auf preto-laptop:
cd /etc/nixos
git pull
```

### SCHRITT 3: NixOS Rebuild
```bash
# Auf preto-laptop:
sudo nixos-rebuild switch --flake .#preto-laptop
```

### SCHRITT 4: Reboot
```bash
reboot
```

---

## ✅ Nach dem Reboot

**Erwartetes Verhalten:**
- ✅ **Waybar**: Startet automatisch
- ✅ **archterm**: Startet automatisch mit Fastfetch
- ✅ **Claude-Launcher**: Startet NICHT automatisch
- ✅ **Claude-Launcher manuell**: `SUPER + C` drücken

---

## 🔍 Troubleshooting

### Waybar startet immer noch nicht?
```bash
# Prüfe ob Skripte deployed wurden:
ls -la ~/.config/hypr/scripts/

# Sollte enthalten:
# - waybar-launcher.sh
# - wallpaper-wal.sh
# - fastfetch-colored.sh
# - screenshot-area.sh
# - screenshot-full.sh
# - etc.

# Manuell testen:
~/.config/hypr/scripts/waybar-launcher.sh

# Logs checken:
journalctl --user -u hyprland -f
```

### Skripte fehlen nach nixos-rebuild?
```bash
# Prüfe ob das scripts-Verzeichnis im Repo vollständig ist:
ls -la /etc/nixos/home/preto/scripts/

# Falls waybar-launcher.sh fehlt, pull nochmal:
cd /etc/nixos
git pull
sudo nixos-rebuild switch --flake .#preto-laptop
```

---

## 📝 Zusammenfassung

**Geänderte Datei:**
- `home/preto/hypr/hyprland.conf` → Claude-Launcher exec-once entfernt, bind SUPER+C hinzugefügt

**Keine Änderung:**
- `home/preto/home.nix` → Bereits korrekt konfiguriert

**Deployment:**
1. Container: `git push`
2. Laptop: `git pull`
3. Laptop: `sudo nixos-rebuild switch --flake .#preto-laptop`
4. Laptop: `reboot`

---

Erstellt: 2025-01-15
System: IT-Agent Container (Hetzner) → GitHub → preto-laptop (NixOS)
