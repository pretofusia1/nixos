{ config, pkgs, ... }:
{
  # Intel GPU Passthrough für Proxmox VMs
  # Aktiviert Hardware-Beschleunigung für Remote-Desktop (Sunshine)

  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver    # iHD VA-API Driver (TigerLake+)
    libva                 # VA-API Runtime
    mesa                  # OpenGL/Vulkan
    vulkan-loader         # Vulkan ICD Loader
    vpl-gpu-rt            # Intel oneVPL GPU Runtime (QSV fuer Sunshine encoder)
  ];

  # GPU-Tools in den PATH (vainfo etc. sind in sunshine.nix)

  # i915 früh laden für GPU-Zugriff in der VM
  # WICHTIG: Muss vor DRM EDID-Firmware geladen werden!
  boot.initrd.kernelModules = [ "i915" ];

  # DRM EDID Firmware-Loading erlauben (fuer headless EDID-Trick)
  # CONFIG_DRM_LOAD_EDID_FIRMWARE ist in NixOS standardmaessig aktiv,
  # aber sicherheitshalber stellen wir sicher dass es verfuegbar ist.
  # Die tatsaechlichen Kernel-Parameter stehen in hosts/proxmox-vm/default.nix

  # User-Gruppen für GPU-Zugriff
  # video = VA-API, render = Vulkan/DRM
  users.users.preto.extraGroups = [ "video" "render" ];
}
