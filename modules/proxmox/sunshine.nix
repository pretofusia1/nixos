{ config, pkgs, ... }:
{
  # Sunshine - Game/Desktop Streaming Server
  # Ermöglicht Remote-Zugriff auf Desktop via Moonlight-Client
  # Ähnlich wie Parsec/Steam Remote Play

  services.sunshine = {
    enable = true;
    autoStart = true;

    # capSysAdmin = true erlaubt Sunshine Screenshots/Screencasts zu erstellen
    # Notwendig für Desktop-Streaming
    capSysAdmin = true;

    # Öffnet Standard-Ports in Firewall (47984-47990 TCP/UDP)
    # 47984: HTTPS Web UI
    # 47989: HTTP Web UI
    # 47998-47999: Video/Audio Streaming
    openFirewall = true;
  };

  # Intel GPU VAAPI Support für Hardware-Encoding
  # Wichtig für performantes Streaming auf Virtual Display
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver  # iHD Driver für Intel GPU (TigerLake)
      vaapiIntel          # Legacy VA-API
      libvdpau-va-gl      # VDPAU Support
    ];
  };

  # Environment Variables für Sunshine mit Virtual Display
  environment.sessionVariables = {
    # Intel GPU VAAPI Driver
    LIBVA_DRIVER_NAME = "iHD";

    # Wayland Display für Sunshine
    # (wird automatisch von Hyprland gesetzt, hier als Fallback)
    # WAYLAND_DISPLAY = "wayland-1";
  };

  # Debugging-Tools für VA-API und GPU-Encoding
  environment.systemPackages = with pkgs; [
    libva-utils        # vainfo - prüft VA-API Support
    intel-gpu-tools    # intel_gpu_top - GPU-Monitoring
  ];
}
