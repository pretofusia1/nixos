{ pkgs, lib, config, ... }:
let
  # Wrapper-Script für Hyprland in der headless VM
  # Startet Hyprland, wartet bis IPC ready, erstellt headless Fallback-Monitor
  hyprland-headless-wrapper = pkgs.writeShellScript "hyprland-headless-wrapper" ''
    # Hyprland im Hintergrund starten
    Hyprland &
    HYPR_PID=$!

    # Warten bis Hyprland-Socket existiert (max 30 Sekunden)
    TIMEOUT=30
    ELAPSED=0
    while ! ls "$XDG_RUNTIME_DIR"/hypr/*/.socket.sock >/dev/null 2>&1; do
      sleep 1
      ELAPSED=$((ELAPSED + 1))
      if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "WARNUNG: Hyprland-Socket nach ''${TIMEOUT}s nicht gefunden"
        break
      fi
    done

    # Kurz warten damit IPC vollstaendig bereit ist
    sleep 2

    # Pruefen ob ein Monitor existiert (durch EDID-Trick sollte DP-1 da sein)
    MONITORS=$(hyprctl monitors 2>/dev/null | grep -c "Monitor" || echo "0")
    if [ "$MONITORS" -eq "0" ]; then
      echo "Kein DRM-Monitor gefunden - erstelle headless Fallback..."
      hyprctl output create headless
      sleep 1
      # Monitor konfigurieren
      hyprctl keyword monitor "HEADLESS-1,1920x1080@60,0x0,1"
    else
      echo "DRM-Monitor gefunden ($MONITORS Monitore aktiv)"
    fi

    # Environment an systemd propagieren (wichtig fuer Sunshine)
    systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY
    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY

    # Auf Hyprland warten
    wait $HYPR_PID
  '';
in
{
  services.greetd = {
    enable = true;
    settings.default_session =
      # Auto-Login für VM (proxmox-vm), manueller Login für andere Hosts
      if config.networking.hostName == "proxmox-vm" then {
        # Wrapper-Script statt direktem Hyprland-Start
        # Erstellt headless Monitor falls EDID-Trick nicht greift
        command = "${hyprland-headless-wrapper}";
        user = "preto";
      } else {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
  };
}
