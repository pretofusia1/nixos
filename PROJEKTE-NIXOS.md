# NixOS Projekte

**Erstellt:** 2026-01-30
**Status:** In Planung

---

## Projekt 1: Laptop2 eigene WireGuard-Config

### Problem
Aktuell nutzt `preto-laptop2` das gleiche WireGuard-Modul wie `preto-laptop` mit **derselben IP-Adresse** (10.10.0.10). Das führt zu Konflikten wenn beide gleichzeitig verbunden sind.

### Lösung
Eigenes WireGuard-Modul für Laptop2 mit separater IP.

### Geplante IP-Zuweisung
| Gerät | VPN IP |
|-------|--------|
| preto-laptop | 10.10.0.10 |
| preto-laptop2 | 10.10.0.11 |
| (NixOS VM) | 10.10.0.12 |

### Implementierung

**Schritt 1:** Neues Modul erstellen: `modules/network/wireguard-laptop2.nix`

```nix
{ config, lib, pkgs, ... }:

let
  endpointHost = "168.119.159.48";
  endpointPort = 51820;
  serverPubKey = "pzo6fnTRP/r+Lac8wvpwIsV+QVDmfie0Gbg26LPrglo=";

  privKeyFile = if config.sops.secrets ? "wireguard/laptop2_private"
                then config.sops.secrets."wireguard/laptop2_private".path
                else "/etc/secret/wireguard/laptop2_private.key";
in
{
  networking.wg-quick.interfaces = {
    wg0 = {
      autostart = false;
      address = [ "10.10.0.11/32" ];  # EIGENE IP!
      privateKeyFile = privKeyFile;
      peers = [{
        publicKey = serverPubKey;
        endpoint  = "${endpointHost}:${toString endpointPort}";
        persistentKeepalive = 25;
        allowedIPs = [ "10.10.0.0/24" ];
      }];
    };

    wg0full = {
      autostart = false;
      address = [ "10.10.0.11/32" ];  # EIGENE IP!
      privateKeyFile = privKeyFile;
      peers = [{
        publicKey = serverPubKey;
        endpoint  = "${endpointHost}:${toString endpointPort}";
        persistentKeepalive = 25;
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
      }];
    };
  };

  environment.shellAliases = {
    wg-up      = "sudo systemctl start wg-quick-wg0";
    wg-down    = "sudo systemctl stop wg-quick-wg0";
    wg-full    = "sudo systemctl start wg-quick-wg0full";
    wg-fulloff = "sudo systemctl stop  wg-quick-wg0full";
    wg-stat    = "sudo wg show";
  };

  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ ];
    allowedTCPPorts = [ ];
  };

  systemd.tmpfiles.rules = [
    "d /etc/secret/wireguard 0700 root root -"
  ];
}
```

**Schritt 2:** `hosts/preto-laptop2/default.nix` anpassen:
```nix
imports = [
  # ...
  ../../modules/network/wireguard-laptop2.nix  # STATT wireguard.nix
  # ...
];

# SOPS Secret für Laptop2:
sops.secrets."wireguard/laptop2_private" = {
  mode = "0400";
  owner = "root";
  group = "root";
};
```

**Schritt 3:** Server-Konfiguration (Hetzner)
```bash
# Neuen Peer hinzufügen in /etc/wireguard/wg0.conf:
[Peer]
# preto-laptop2
PublicKey = <LAPTOP2_PUBLIC_KEY>
AllowedIPs = 10.10.0.11/32
```

**Schritt 4:** Keys generieren
```bash
# Auf Laptop2:
wg genkey | tee laptop2_private.key | wg pubkey > laptop2_public.key

# Private Key in sops-secrets verschlüsseln:
sops secrets/secrets.yaml
# Hinzufügen: wireguard/laptop2_private: <KEY>
```

### Status
- [ ] Modul `wireguard-laptop2.nix` erstellen
- [ ] Keys für Laptop2 generieren
- [ ] SOPS Secret hinzufügen
- [ ] Server-Config updaten
- [ ] Laptop2 Config anpassen
- [ ] Testen

---

## Projekt 2: GIMP mit Photoshop-Look

### Ziel
GIMP so konfigurieren, dass es wie Photoshop aussieht und sich bedient.

### Komponenten
1. **PhotoGIMP** - Komplettes Photoshop-Theme + Shortcuts
2. **GIMP Plugins** - Wichtige Zusatz-Features
3. **Tastatur-Shortcuts** - Photoshop-kompatibel

### Implementierung

**In `modules/common.nix` oder eigenes Modul `modules/graphics/gimp-photoshop.nix`:**

```nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # GIMP mit Plugins
    gimp-with-plugins

    # Oder manuell mit spezifischen Plugins:
    (gimp.override {
      withPlugins = true;
      plugins = with gimpPlugins; [
        gmic          # G'MIC - Bildverarbeitung
        resynthesizer # Content-Aware Fill (wie PS)
        # bimp        # Batch Image Manipulation
      ];
    })
  ];
}
```

**PhotoGIMP Theme installieren (Home-Manager):**

In `home/preto/home.nix`:

```nix
{ pkgs, ... }:

let
  # PhotoGIMP von GitHub holen
  photogimp = pkgs.fetchFromGitHub {
    owner = "Diolinux";
    repo = "PhotoGIMP";
    rev = "master";
    sha256 = ""; # Wird beim ersten Build ermittelt
  };
in
{
  # PhotoGIMP Konfiguration kopieren
  home.file.".config/GIMP/2.10" = {
    source = "${photogimp}/.var/app/org.gimp.GIMP/config/GIMP/2.10";
    recursive = true;
  };

  # Oder manuell:
  xdg.configFile."GIMP/2.10/menurc".source = ./gimp/menurc;
  xdg.configFile."GIMP/2.10/toolrc".source = ./gimp/toolrc;
}
```

### PhotoGIMP Features
- Photoshop-ähnliches Layout (Werkzeuge links, Ebenen rechts)
- Photoshop-Shortcuts (Ctrl+D = Deselect, etc.)
- Dunkles Theme
- Splash Screen

### Manuelle Installation (Alternative)
```bash
# PhotoGIMP herunterladen
git clone https://github.com/Diolinux/PhotoGIMP.git
cd PhotoGIMP

# Für GIMP 2.10:
cp -r .var/app/org.gimp.GIMP/config/GIMP/2.10/* ~/.config/GIMP/2.10/
```

### Status
- [x] GIMP mit Plugins in common.nix hinzufügen ✅ (30.01.2026)
- [x] PhotoGIMP Theme integrieren ✅ (30.01.2026)
- [x] Shortcuts konfigurieren (via PhotoGIMP) ✅ (30.01.2026)
- [ ] Auf allen 3 NixOS testen

---

## Projekt 3: LibreOffice mit Word-Look

### Ziel
LibreOffice Writer so konfigurieren, dass es wie Microsoft Word aussieht.

### Komponenten
1. **Ribbon-UI** - Tabbed Toolbar (wie Office 2007+)
2. **MS-kompatible Schriften** - Calibri, Arial, Times New Roman
3. **Standard-Format** - .docx als Default

### Implementierung

**In `modules/common.nix` oder `modules/office/libreoffice-word.nix`:**

```nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # LibreOffice mit allen Komponenten
    libreoffice-fresh  # Oder libreoffice-still für stabile Version

    # Microsoft-kompatible Schriften
    corefonts          # Arial, Times New Roman, etc.
    vistafonts         # Calibri, Cambria, etc.
  ];

  # Alternativ: Nur spezifische Fonts
  fonts.packages = with pkgs; [
    corefonts
    vistafonts
    liberation_ttf     # Metrisch kompatibel mit MS Fonts
  ];
}
```

**LibreOffice Konfiguration (Home-Manager):**

In `home/preto/home.nix`:

```nix
{ pkgs, ... }:

{
  # LibreOffice User-Config
  xdg.configFile."libreoffice/4/user/registrymodifications.xcu".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <oor:items xmlns:oor="http://openoffice.org/2001/registry"
               xmlns:xs="http://www.w3.org/2001/XMLSchema"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

      <!-- Tabbed/Ribbon UI aktivieren -->
      <item oor:path="/org.openoffice.Office.UI.ToolbarMode/Applications/Writer">
        <prop oor:name="Active" oor:op="fuse">
          <value>Tabbed</value>
        </prop>
      </item>

      <!-- Standard-Dateiformat auf DOCX -->
      <item oor:path="/org.openoffice.Setup/Office/Factories/com.sun.star.text.TextDocument">
        <prop oor:name="ooSetupFactoryDefaultFilter" oor:op="fuse">
          <value>MS Word 2007 XML</value>
        </prop>
      </item>

      <!-- Standard-Schrift auf Calibri -->
      <item oor:path="/org.openoffice.Office.Writer/DefaultFont">
        <prop oor:name="Standard" oor:op="fuse">
          <value>Calibri</value>
        </prop>
      </item>

    </oor:items>
  '';
}
```

### Manuelle Konfiguration (Alternative)

1. **Ribbon-UI aktivieren:**
   - Menü → Ansicht → Benutzeroberfläche
   - "Tabbed" oder "Tabbed Compact" wählen

2. **Standard-Format auf DOCX:**
   - Extras → Optionen → Laden/Speichern → Allgemein
   - "Immer speichern als:" → "Microsoft Word 2007-365 (.docx)"

3. **Standard-Schrift ändern:**
   - Extras → Optionen → LibreOffice Writer → Grundschriften (westlich)
   - Standard: Calibri, Größe: 11

### Icon-Theme (Optional)
```nix
# Für moderneres Aussehen:
environment.systemPackages = with pkgs; [
  libreoffice-fresh
  papirus-icon-theme  # Wird von LO erkannt
];
```

### Status
- [x] LibreOffice in common.nix hinzufügen ✅ (30.01.2026)
- [x] MS-Fonts installieren (corefonts, vistafonts, liberation_ttf) ✅ (30.01.2026)
- [ ] Ribbon-UI konfigurieren (manuell beim ersten Start)
- [ ] DOCX als Standard setzen (manuell beim ersten Start)
- [ ] Calibri als Standard-Schrift (manuell beim ersten Start)
- [ ] Auf allen 3 NixOS testen

---

## Zusammenfassung

| Projekt | Priorität | Aufwand | Status |
|---------|-----------|---------|--------|
| Laptop2 WireGuard | Hoch | Mittel | 📋 Geplant |
| GIMP Photoshop-Style | Mittel | Gering | ✅ Implementiert |
| LibreOffice Word-Style | Mittel | Gering | ✅ Implementiert (Fonts + Paket) |

### Nächste Schritte

1. **WireGuard Laptop2:**
   - Keys generieren
   - Modul erstellen
   - Server updaten

2. **GIMP + LibreOffice:**
   - Module erstellen
   - In common.nix für alle 3 Systeme einbinden
   - Testen

### Betroffene Hosts
- `preto-laptop` (Haupt-Laptop)
- `preto-laptop2` (Zweiter Laptop)
- NixOS VM (falls vorhanden)

---

**Letzte Aktualisierung:** 2026-01-30
