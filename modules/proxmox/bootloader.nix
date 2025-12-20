{ config, pkgs, ... }:
{
  # GRUB Bootloader für Proxmox VMs
  # Proxmox VMs benötigen GRUB statt systemd-boot
  # Grund: EFI-Variablen können in VMs nicht verändert werden

  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";  # EFI-Installation ohne Device-Binding
  };
}
