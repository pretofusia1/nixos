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
  ];

  # GPU-Tools in den PATH (vainfo etc. sind in sunshine.nix)

  # i915 früh laden für GPU-Zugriff in der VM
  boot.initrd.kernelModules = [ "i915" ];

  # User-Gruppen für GPU-Zugriff
  # video = VA-API, render = Vulkan/DRM
  users.users.preto.extraGroups = [ "video" "render" ];
}
