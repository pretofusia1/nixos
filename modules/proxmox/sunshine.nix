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

  # Optional: Zusätzliche Pakete für bessere Streaming-Qualität
  # environment.systemPackages = with pkgs; [
  #   libva-utils  # VA-API Debugging (vainfo)
  # ];
}
