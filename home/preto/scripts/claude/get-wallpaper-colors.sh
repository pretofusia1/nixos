#!/usr/bin/env bash

# Script zum Holen der Wallpaper-Farben
# Angepasst an deine wallpaper-wal.sh Config mit pywal

# Funktion: Hole Farben von pywal (wie in deiner Config)
get_pywal_colors() {
    local colors_sh="$HOME/.cache/wal/colors.sh"

    # Prüfe ob pywal-Cache existiert
    if [ -f "$colors_sh" ]; then
        # Source die Farben
        source "$colors_sh"

        # Gebe die ersten 6 Farben zurück (color1-color6)
        echo "$color1:$color2:$color3:$color4:$color5:$color6"
        return 0
    fi
    return 1
}

# Funktion: Fallback - nutze letzte bekannte Wallpaper-Farben
get_fallback_from_wal_cache() {
    local wal_file="$HOME/.cache/wal/wal"

    # Wenn wal-Cache existiert aber colors.sh nicht, regeneriere
    if [ -f "$wal_file" ] && command -v wal &>/dev/null; then
        local img=$(cat "$wal_file")
        if [ -f "$img" ]; then
            # Regeneriere Farben mit gleichen Parametern wie wallpaper-wal.sh
            wal -n -i "$img" --saturate 0.7 >/dev/null 2>&1
            get_pywal_colors
            return $?
        fi
    fi
    return 1
}

# Funktion: Absolute Fallback (Claude-Standard-Farben)
get_fallback_colors() {
    # Orange-Gelb Gradient (Claude-Branding)
    echo "#FF8C00:#FFA500:#FFB700:#FFC700:#FFD700:#FFE700"
}

# Hauptlogik (Priorität: pywal > regenerate > fallback)
if ! get_pywal_colors; then
    if ! get_fallback_from_wal_cache; then
        get_fallback_colors
    fi
fi
