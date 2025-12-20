{ config, pkgs, ... }:
{
  # Intel GPU Passthrough für Proxmox VMs
  # Aktiviert Hardware-Beschleunigung für Remote-Desktop (Sunshine)

  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    libva
    libva-utils
    mesa
    vulkan-loader
  ];

  # Headless/Framebuffer-Fix für Proxmox VMs
  # Verhindert Konflikte mit EFI-Framebuffer
  boot.kernelParams = [ "video=efifb:off" ];

  # User-Gruppen für GPU-Zugriff
  # video = VA-API, render = Vulkan/DRM
  users.users.preto.extraGroups = [ "video" "render" ];
}
