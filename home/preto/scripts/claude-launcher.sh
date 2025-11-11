#!/usr/bin/env bash

# ==========================================
# Claude Launcher - Remote Edition
# Verbindet zu Cloud-Server via SSH
# ==========================================

# Konfiguration
WG_INTERFACE="wg0"
REMOTE_HOST="10.10.0.3"
SSH_USER="claude"
SSH_KEY="$HOME/.ssh/id_ed25519"

# Hole Wallpaper-Farben (wie in Workspace 1 Terminal)
get_pywal_colors() {
    local colors_sh="$HOME/.cache/wal/colors.sh"

    if [ -f "$colors_sh" ]; then
        source "$colors_sh"
        echo "$color1:$color2:$color3:$color4:$color5:$color6"
        return 0
    fi

    # Fallback: Standard Claude-Farben
    echo "#FF8C00:#FFA500:#FFB700:#FFC700:#FFD700:#FFE700"
}

# Konvertiere Hex zu ANSI RGB
hex_to_ansi() {
    local hex=$1
    hex=${hex#"#"}
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "\e[38;2;${r};${g};${b}m"
}

# Farben initialisieren
COLORS=$(get_pywal_colors)
IFS=':' read -ra COLOR_ARRAY <<< "$COLORS"
C1="${COLOR_ARRAY[0]}"
C2="${COLOR_ARRAY[1]}"
C3="${COLOR_ARRAY[2]}"
C4="${COLOR_ARRAY[3]}"
C5="${COLOR_ARRAY[4]}"
C6="${COLOR_ARRAY[5]}"

c1=$(hex_to_ansi "$C1")
c2=$(hex_to_ansi "$C2")
c3=$(hex_to_ansi "$C3")
c4=$(hex_to_ansi "$C4")
c5=$(hex_to_ansi "$C5")
c6=$(hex_to_ansi "$C6")
reset="\e[0m"

# Claude Logo ASCII Art (mit Wallpaper-Farben)
print_claude_logo() {
    echo -e "${c1}    _____ _                 _      ${reset}"
    echo -e "${c2}   / ____| |               | |     ${reset}"
    echo -e "${c3}  | |    | | __ _ _   _  __| | ___ ${reset}"
    echo -e "${c4}  | |    | |/ _\` | | | |/ _\` |/ _ \\${reset}"
    echo -e "${c5}  | |____| | (_| | |_| | (_| |  __/${reset}"
    echo -e "${c6}   \_____|_|\__,_|\__,_|\__,_|\___|${reset}"
    echo -e "${c6}                                    ${reset}"
    echo -e "${c6}         AI Assistant Ready         ${reset}"
}

# Prüfe WireGuard-Verbindung
check_wireguard() {
    if ! ip link show "$WG_INTERFACE" &>/dev/null; then
        echo -e "\e[38;5;196m✗\e[0m WireGuard Interface '$WG_INTERFACE' nicht gefunden!"
        echo -e "\e[38;5;240m  Bitte WireGuard starten: sudo wg-quick up $WG_INTERFACE\e[0m"
        return 1
    fi

    if ! ip addr show "$WG_INTERFACE" | grep -q "inet "; then
        echo -e "\e[38;5;196m✗\e[0m WireGuard Interface '$WG_INTERFACE' hat keine IP!"
        return 1
    fi

    # Prüfe ob Remote-Host erreichbar ist
    if ! ping -c 1 -W 2 "$REMOTE_HOST" &>/dev/null; then
        echo -e "\e[38;5;196m✗\e[0m Cloud-Server '$REMOTE_HOST' nicht erreichbar!"
        echo -e "\e[38;5;240m  Prüfe WireGuard-Konfiguration\e[0m"
        return 1
    fi

    return 0
}

# Hauptmenü anzeigen
show_menu() {
    clear
    print_claude_logo
    echo ""

    # WireGuard Status
    if check_wireguard; then
        echo -e "\e[38;5;82m●\e[0m WireGuard aktiv - Server erreichbar"
    else
        echo ""
        read -p "Drücke Enter zum Beenden..."
        exit 1
    fi

    echo ""
    echo -e "\e[38;5;75m╔═══════════════════════════════════════════╗\e[0m"
    echo -e "\e[38;5;75m║\e[0m  \e[1mClaude Launcher - Agent wählen\e[0m         \e[38;5;75m║\e[0m"
    echo -e "\e[38;5;75m╚═══════════════════════════════════════════╝\e[0m"
    echo ""
    echo -e "  \e[38;5;82m1)\e[0m \e[1mIT-Agent\e[0m         - IT-Infrastruktur & Server"
    echo -e "  \e[38;5;82m2)\e[0m \e[1mBasic-Agent\e[0m      - Allgemeine Fragen & Wissen"
    echo -e "  \e[38;5;82m3)\e[0m \e[1mReport-Agent\e[0m     - Strukturierte Reports"
    echo -e "  \e[38;5;82m4)\e[0m \e[1mEmail-Agent\e[0m      - Professionelle Emails"
    echo -e "  \e[38;5;82m5)\e[0m \e[1mClaude Normal\e[0m    - Ohne speziellen Agenten"
    echo ""
    echo -e "  \e[38;5;196mq)\e[0m Beenden"
    echo ""
    echo -ne "\e[38;5;75m➜\e[0m Auswahl: "
}

# SSH zu Agent verbinden
connect_to_agent() {
    local agent_type=$1
    local ssh_host="claude-${agent_type}"

    echo ""
    echo -e "\e[38;5;82m→\e[0m Verbinde zu ${agent_type}-Agent..."
    echo -e "\e[38;5;240m  (Tippe 'exit' um zurückzukehren)\e[0m"
    echo ""
    sleep 1

    # Verbinde via SSH mit spezifischem Host aus ~/.ssh/config
    ssh "$ssh_host"

    echo ""
    echo -e "\e[38;5;226m←\e[0m Verbindung beendet"
    sleep 1
}

# Claude Normal (ohne Agent) starten
start_normal_claude() {
    echo ""
    echo -e "\e[38;5;82m→\e[0m Verbinde zu Claude Server..."
    echo -e "\e[38;5;240m  (Normaler Claude-Modus ohne Agent)\e[0m"
    echo ""
    sleep 1

    # Normale SSH-Verbindung mit interaktiver Shell
    ssh -t "${SSH_USER}@${REMOTE_HOST}" "cd /workspace && exec bash -l"

    echo ""
    echo -e "\e[38;5;226m←\e[0m Verbindung beendet"
    sleep 1
}

# Hauptschleife
while true; do
    show_menu
    read -r choice

    case $choice in
        1)
            connect_to_agent "it"
            ;;
        2)
            connect_to_agent "basic"
            ;;
        3)
            connect_to_agent "report"
            ;;
        4)
            connect_to_agent "email"
            ;;
        5)
            start_normal_claude
            ;;
        q|Q)
            clear
            echo ""
            echo -e "\e[38;5;196m✗\e[0m Claude Launcher beendet."
            echo ""
            exit 0
            ;;
        *)
            echo ""
            echo -e "\e[38;5;196m✗\e[0m Ungültige Auswahl. Bitte erneut versuchen."
            sleep 2
            ;;
    esac
done
