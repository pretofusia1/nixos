{ config, pkgs, lib, ... }:

{
  # ============================================
  # USB-Automount mit udisks2 + udiskie
  # ============================================
  # Erstellt: 2026-02-08
  # Zweck: Automatisches Mounten von USB-Sticks
  # ============================================
  #
  # Funktionsweise:
  # - udisks2: D-Bus-Dienst fuer Laufwerksverwaltung (System-Level)
  # - udiskie: Userspace-Daemon der USB-Geraete automatisch mounted
  # - Benachrichtigung via dunst bei Mount/Unmount
  # - Thunar oeffnet automatisch den gemounteten USB-Stick
  #
  # Mount-Pfad: /run/media/<username>/<label>
  #
  # Alternativen:
  # - Vollautomatisch: udiskie laeuft als Daemon (Standard)
  # - Manuell: ~/bin/usb-mount.sh fuer interaktives Mounten
  # ============================================

  # --- udisks2: System-Dienst fuer Laufwerksverwaltung ---
  services.udisks2.enable = true;

  # --- Polkit: Erlaubt Usern in "storage" Gruppe das Mounten ohne sudo ---
  security.polkit.enable = true;

  # --- Benoetigte Pakete ---
  environment.systemPackages = with pkgs; [
    udiskie          # Automount-Daemon (userspace)
    ntfs3g           # NTFS-Support (Windows USB-Sticks)
    exfatprogs       # exFAT userspace-Tools (nativer Kernel-Treiber seit 5.8)
  ];

  # --- User "preto" zur storage-Gruppe hinzufuegen ---
  # Ermoeglicht Mounten ohne Root-Rechte
  users.users.preto.extraGroups = [ "storage" ];
}
