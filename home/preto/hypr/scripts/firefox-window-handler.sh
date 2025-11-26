#!/usr/bin/env bash
# Firefox Window Handler - Float second and subsequent windows
# Überwacht neue Firefox-Fenster und floatet sie automatisch wenn bereits eins existiert

handle() {
  case $1 in
    openwindow*)
      # Extract window address and class
      window_addr="${1#*>>}"
      window_addr="${window_addr%%,*}"
      window_class="${1##*,}"

      # Prüfe ob es ein Firefox-Fenster ist
      if [[ "$window_class" == "firefox" ]]; then
        # Zähle Firefox-Fenster (ohne das gerade geöffnete)
        firefox_count=$(hyprctl clients -j | jq '[.[] | select(.class=="firefox")] | length')

        # Wenn mehr als 1 Firefox-Fenster existiert, floate das neue
        if [ "$firefox_count" -gt 1 ]; then
          hyprctl dispatch togglefloating "address:0x$window_addr"
          hyprctl dispatch centerwindow "address:0x$window_addr"
          hyprctl dispatch resizewindowpixel "exact 80% 85%,address:0x$window_addr"
        fi
      fi
      ;;
  esac
}

# Lese Hyprland Events
socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
  handle "$line"
done
