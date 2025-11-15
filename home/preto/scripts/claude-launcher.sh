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
    local max_wait=10  # Max 5 Sekunden warten

    # Warte auf Pywal-Farben (falls gerade beim Boot)
    local elapsed=0
    while [ ! -f "$colors_sh" ] && [ $elapsed -lt $max_wait ]; do
        sleep 0.5
        elapsed=$((elapsed + 1))
    done

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

# ANSI-Codes für Logo
c1=$(hex_to_ansi "$C1")
c2=$(hex_to_ansi "$C2")
c3=$(hex_to_ansi "$C3")
c4=$(hex_to_ansi "$C4")
c5=$(hex_to_ansi "$C5")
c6=$(hex_to_ansi "$C6")

# Farben für Menü (aus Pywal)
menu_border=$(hex_to_ansi "$C2")      # Rahmen/Borders
menu_text=$(hex_to_ansi "$C6")        # Text
menu_number=$(hex_to_ansi "$C4")      # Nummern (1-5)
menu_title=$(hex_to_ansi "$C5")       # Titel (bold)
menu_status_ok=$(hex_to_ansi "$C3")   # WireGuard OK
menu_status_err=$(hex_to_ansi "$C1")  # Fehler
menu_quit=$(hex_to_ansi "$C1")        # Quit-Option
menu_prompt=$(hex_to_ansi "$C3")      # Eingabe-Prompt
reset="\e[0m"
bold="\e[1m"

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
        echo -e "${menu_status_err}✗${reset} WireGuard Interface '$WG_INTERFACE' nicht gefunden!"
        echo -e "${menu_text}  Bitte WireGuard starten: sudo wg-quick up $WG_INTERFACE${reset}"
        return 1
    fi

    if ! ip addr show "$WG_INTERFACE" | grep -q "inet "; then
        echo -e "${menu_status_err}✗${reset} WireGuard Interface '$WG_INTERFACE' hat keine IP!"
        return 1
    fi

    # Prüfe ob Remote-Host erreichbar ist
    if ! ping -c 1 -W 2 "$REMOTE_HOST" &>/dev/null; then
        echo -e "${menu_status_err}✗${reset} Cloud-Server '$REMOTE_HOST' nicht erreichbar!"
        echo -e "${menu_text}  Prüfe WireGuard-Konfiguration${reset}"
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
        echo -e "${menu_status_ok}●${reset} WireGuard aktiv - Server erreichbar"
    else
        echo ""
        read -p "Drücke Enter zum Beenden..."
        exit 1
    fi

    echo ""
    echo -e "${menu_border}╔═══════════════════════════════════════════╗${reset}"
    echo -e "${menu_border}║${reset}  ${bold}${menu_title}Claude Launcher - Agent wählen${reset}         ${menu_border}║${reset}"
    echo -e "${menu_border}╚═══════════════════════════════════════════╝${reset}"
    echo ""
    echo -e "  ${menu_number}1)${reset} ${bold}IT-Agent${reset}         ${menu_text}- IT-Infrastruktur & Server${reset}"
    echo -e "  ${menu_number}2)${reset} ${bold}Basic-Agent${reset}      ${menu_text}- Allgemeine Fragen & Wissen${reset}"
    echo -e "  ${menu_number}3)${reset} ${bold}Report-Agent${reset}     ${menu_text}- Strukturierte Reports${reset}"
    echo -e "  ${menu_number}4)${reset} ${bold}Email-Agent${reset}      ${menu_text}- Professionelle Emails${reset}"
    echo -e "  ${menu_number}5)${reset} ${bold}Claude Normal${reset}    ${menu_text}- Ohne speziellen Agenten${reset}"
    echo ""
    echo -e "  ${menu_quit}q)${reset} Beenden"
    echo ""
    echo -ne "${menu_prompt}➜${reset} Auswahl: "
}

# SSH zu Agent verbinden
connect_to_agent() {
    local agent_type=$1
    local ssh_host="claude-${agent_type}"

    echo ""
    echo -e "${menu_status_ok}→${reset} Verbinde zu ${agent_type}-Agent..."
    echo -e "${menu_text}  (Tippe 'exit' um zurückzukehren)${reset}"
    echo ""
    sleep 1

    # Verbinde via SSH mit spezifischem Host aus ~/.ssh/config
    ssh "$ssh_host"

    echo ""
    echo -e "${menu_prompt}←${reset} Verbindung beendet"
    sleep 1
}

# Claude Normal (ohne Agent) starten
start_normal_claude() {
    echo ""
    echo -e "${menu_status_ok}→${reset} Verbinde zu Claude Server..."
    echo -e "${menu_text}  (Normaler Claude-Modus ohne Agent)${reset}"
    echo ""
    sleep 1

    # Normale SSH-Verbindung mit interaktiver Shell
    ssh claude

    echo ""
    echo -e "${menu_prompt}←${reset} Verbindung beendet"
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
            echo -e "${menu_quit}✗${reset} Claude Launcher beendet."
            echo ""
            exit 0
            ;;
        *)
            echo ""
            echo -e "${menu_status_err}✗${reset} Ungültige Auswahl. Bitte erneut versuchen."
            sleep 2
            ;;
    esac
done
