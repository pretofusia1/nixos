#!/usr/bin/env bash
# ===================================
# Firefox Window Handler
# ===================================
# Überwacht neue Firefox-Fenster und setzt ab dem 2. Fenster:
# - float (schwebend)
# - stayfocused (im Vordergrund)
# - zentriert & auf angemessene Größe gesetzt

# Zähle aktuelle Firefox-Fenster
get_firefox_count() {
    hyprctl clients -j | jq '[.[] | select(.class == "firefox")] | length'
}

# Event-Handler
handle_event() {
    case "$1" in
        openwindow*)
            # Format: openwindow>>ADDRESS,CLASS,TITLE
            local event="$1"
            local address=$(echo "$event" | cut -d'>' -f3 | cut -d',' -f1)
            local class=$(echo "$event" | cut -d',' -f2)

            # Nur Firefox-Fenster verarbeiten
            if [[ "$class" != "firefox" ]]; then
                return
            fi

            # Warte kurz, damit Hyprland das Fenster registriert
            sleep 0.1

            # Zähle Firefox-Fenster
            local count=$(get_firefox_count)

            # Ab dem 2. Fenster: float + stayfocused + zentriert
            if (( count >= 2 )); then
                echo "[$(date '+%H:%M:%S')] Firefox-Fenster #$count erkannt → setze float + stayfocused"
                hyprctl dispatch togglefloating "address:0x$address"
                hyprctl dispatch centerwindow "address:0x$address"
                hyprctl dispatch resizewindowpixel "exact 75% 80%,address:0x$address"
                # Pin-Funktion für always-on-top
                hyprctl dispatch pin "address:0x$address"
            else
                echo "[$(date '+%H:%M:%S')] Erstes Firefox-Fenster → bleibt gekachelt"
            fi
            ;;
    esac
}

# Event-Loop
echo "[$(date '+%H:%M:%S')] Firefox Window Handler gestartet"
socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    handle_event "$line"
done
