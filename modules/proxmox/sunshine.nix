{ config, pkgs, ... }:
{
  # Sunshine - Game/Desktop Streaming Server
  # Ermöglicht Remote-Zugriff auf Desktop via Moonlight-Client
  # Ähnlich wie Parsec/Steam Remote Play
  #
  # ============================================
  # WICHTIG: Sunshine Version & Headless Support
  # ============================================
  # NixOS 24.11 liefert Sunshine ~0.23.x (KEIN headless wlr-screencopy!)
  # Fuer HEADLESS-* Outputs braucht man >= v2025.628.4510 (PR #3783)
  # Mit dem EDID-Trick (DP-1 als "connected" DRM Output) funktioniert
  # aber auch die aeltere Version, da Sunshine dann KMS capture nutzt.
  #
  # Falls Headless-Output benoetigt wird: Sunshine aus nixpkgs-unstable
  # oder als Overlay/Override einbinden.

  services.sunshine = {
    enable = true;
    autoStart = true;

    # capSysAdmin = true erlaubt KMS capture (DRM framebuffer direkt lesen)
    # KRITISCH fuer Wayland - ohne cap_sys_admin kein Screen-Capture!
    capSysAdmin = true;

    # Öffnet Standard-Ports in Firewall (47984-47990 TCP/UDP)
    # 47984: HTTPS Web UI
    # 47989: HTTP Web UI
    # 47998-47999: Video/Audio Streaming
    openFirewall = true;

    # Sunshine Settings (sunshine.conf)
    # Verfuegbar nach erstem Start via Web-UI https://<IP>:47990
    # Oder direkt in ~/.config/sunshine/sunshine.conf
    #
    # WICHTIGE SETTINGS fuer Headless VM:
    # adapter_name = /dev/dri/renderD128
    # capture = kms           (fuer EDID-Trick / DRM Output)
    # output_name = 0         (erster erkannter Monitor)
    # encoder = quicksync     (Intel QSV via VA-API)
    #
    # Falls HEADLESS-Output statt DRM:
    # capture = wlr           (braucht Sunshine >= v2025.628.4510!)
  };

  # Intel GPU VAAPI Support wird in gpu.nix konfiguriert!
  # hardware.graphics.enable + extraPackages sind dort definiert.
  # Hier NICHT duplizieren - gpu.nix hat die vollständige GPU-Config
  # (intel-media-driver, libva, mesa, vulkan-loader).

  # Environment Variables für Sunshine mit Virtual Display
  environment.sessionVariables = {
    # Intel GPU VAAPI Driver
    LIBVA_DRIVER_NAME = "iHD";
  };

  # Debugging-Tools für VA-API und GPU-Encoding
  environment.systemPackages = with pkgs; [
    libva-utils        # vainfo - prüft VA-API Support
    intel-gpu-tools    # intel_gpu_top - GPU-Monitoring
  ];
}
