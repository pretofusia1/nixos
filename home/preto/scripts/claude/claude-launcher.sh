#!/usr/bin/env bash

# Pfade zu den Agenten
AGENTS_DIR="/workspace/agents"
IT_AGENT="$AGENTS_DIR/IT/it-agent.sh"
BASIC_AGENT="$AGENTS_DIR/basic/basic-agent.sh"
REPORT_AGENT="$AGENTS_DIR/reports/report-agent.sh"
EMAIL_AGENT="$AGENTS_DIR/emails/email-agent.sh"

# Hole Wallpaper-Farben
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
COLORS_SCRIPT="$SCRIPT_DIR/get-wallpaper-colors.sh"

# Farben initialisieren
if [ -f "$COLORS_SCRIPT" ]; then
    COLORS=$(bash "$COLORS_SCRIPT")
    IFS=':' read -ra COLOR_ARRAY <<< "$COLORS"
    C1="${COLOR_ARRAY[0]:-#FF8C00}"
    C2="${COLOR_ARRAY[1]:-#FFA500}"
    C3="${COLOR_ARRAY[2]:-#FFB700}"
    C4="${COLOR_ARRAY[3]:-#FFC700}"
    C5="${COLOR_ARRAY[4]:-#FFD700}"
    C6="${COLOR_ARRAY[5]:-#FFE700}"
else
    # Fallback: Standard Claude-Farben
    C1="#FF8C00"
    C2="#FFA500"
    C3="#FFB700"
    C4="#FFC700"
    C5="#FFD700"
    C6="#FFE700"
fi

# Konvertiere Hex zu ANSI (vereinfacht: nutze 256-color codes)
# Für echte Hex-Farben im Terminal: \e[38;2;R;G;Bm
hex_to_ansi() {
    local hex=$1
    hex=${hex#"#"}
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "\e[38;2;${r};${g};${b}m"
}

# Claude Logo ASCII Art (mit Wallpaper-Farben)
print_claude_logo() {
    local c1=$(hex_to_ansi "$C1")
    local c2=$(hex_to_ansi "$C2")
    local c3=$(hex_to_ansi "$C3")
    local c4=$(hex_to_ansi "$C4")
    local c5=$(hex_to_ansi "$C5")
    local c6=$(hex_to_ansi "$C6")
    local reset="\e[0m"

    echo -e "${c1}    _____ _                 _      ${reset}"
    echo -e "${c2}   / ____| |               | |     ${reset}"
    echo -e "${c3}  | |    | | __ _ _   _  __| | ___ ${reset}"
    echo -e "${c4}  | |    | |/ _\` | | | |/ _\` |/ _ \\${reset}"
    echo -e "${c5}  | |____| | (_| | |_| | (_| |  __/${reset}"
    echo -e "${c6}   \_____|_|\__,_|\__,_|\__,_|\___|${reset}"
    echo -e "${c6}                                    ${reset}"
    echo -e "${c6}         AI Assistant Ready         ${reset}"
}

# Hauptmenü
show_menu() {
    clear
    print_claude_logo
    echo ""
    echo "[38;5;75m╔═══════════════════════════════════════════╗[0m"
    echo "[38;5;75m║[0m  [1mClaude Launcher - Agent wählen[0m         [38;5;75m║[0m"
    echo "[38;5;75m╚═══════════════════════════════════════════╝[0m"
    echo ""
    echo "  [38;5;82m1)[0m [1mIT-Agent[0m         - IT-Infrastruktur & Server"
    echo "  [38;5;82m2)[0m [1mBasic-Agent[0m      - Allgemeine Fragen & Wissen"
    echo "  [38;5;82m3)[0m [1mReport-Agent[0m     - Strukturierte Reports"
    echo "  [38;5;82m4)[0m [1mEmail-Agent[0m      - Professionelle Emails"
    echo "  [38;5;82m5)[0m [1mClaude Normal[0m    - Ohne speziellen Agenten"
    echo ""
    echo "  [38;5;196mq)[0m Beenden"
    echo ""
    echo -n "[38;5;75m➜[0m Auswahl: "
}

# IT-Agent starten (läuft bis "exit")
start_it_agent() {
    clear
    echo -e "${c3}╔════════════════════════════════════════╗${reset}"
    echo -e "${c3}║${reset}         [1mIT-Agent Modus[0m              ${c3}║${reset}"
    echo -e "${c3}╚════════════════════════════════════════╝${reset}"
    echo ""
    echo "[38;5;240mIT-Infrastruktur, NixOS, Proxmox, Docker, WireGuard[0m"
    echo "[38;5;240mTippe 'exit' um zurück zum Hauptmenü zu gelangen[0m"
    echo ""

    while true; do
        echo -n "[38;5;82m➜[0m "
        read -r question

        if [ "$question" = "exit" ] || [ "$question" = "quit" ] || [ "$question" = "q" ]; then
            echo "[38;5;226m←[0m Zurück zum Hauptmenü..."
            sleep 1
            break
        fi

        if [ -z "$question" ]; then
            continue
        fi

        echo ""
        bash "$IT_AGENT" "$question"
        echo ""
    done
}

# Basic-Agent starten (läuft bis "exit")
start_basic_agent() {
    clear
    echo -e "${c3}╔════════════════════════════════════════╗${reset}"
    echo -e "${c3}║${reset}        [1mBasic-Agent Modus[0m            ${c3}║${reset}"
    echo -e "${c3}╚════════════════════════════════════════╝${reset}"
    echo ""
    echo "[38;5;240mAllgemeine Fragen, Wissen, Erklärungen[0m"
    echo "[38;5;240mTippe 'exit' um zurück zum Hauptmenü zu gelangen[0m"
    echo ""

    while true; do
        echo -n "[38;5;82m➜[0m "
        read -r question

        if [ "$question" = "exit" ] || [ "$question" = "quit" ] || [ "$question" = "q" ]; then
            echo "[38;5;226m←[0m Zurück zum Hauptmenü..."
            sleep 1
            break
        fi

        if [ -z "$question" ]; then
            continue
        fi

        echo ""
        bash "$BASIC_AGENT" "$question"
        echo ""
    done
}

# Report-Agent starten (läuft bis "exit")
start_report_agent() {
    clear
    echo -e "${c3}╔════════════════════════════════════════╗${reset}"
    echo -e "${c3}║${reset}       [1mReport-Agent Modus[0m            ${c3}║${reset}"
    echo -e "${c3}╚════════════════════════════════════════╝${reset}"
    echo ""
    echo "[38;5;240mStrukturierte Reports & Dokumentation[0m"
    echo "[38;5;240mTippe 'exit' um zurück zum Hauptmenü zu gelangen[0m"
    echo ""

    while true; do
        echo -n "[38;5;82m➜[0m "
        read -r topic

        if [ "$topic" = "exit" ] || [ "$topic" = "quit" ] || [ "$topic" = "q" ]; then
            echo "[38;5;226m←[0m Zurück zum Hauptmenü..."
            sleep 1
            break
        fi

        if [ -z "$topic" ]; then
            continue
        fi

        echo ""
        bash "$REPORT_AGENT" "$topic"
        echo ""
    done
}

# Email-Agent starten (läuft bis "exit")
start_email_agent() {
    clear
    echo -e "${c3}╔════════════════════════════════════════╗${reset}"
    echo -e "${c3}║${reset}       [1mEmail-Agent Modus[0m             ${c3}║${reset}"
    echo -e "${c3}╚════════════════════════════════════════╝${reset}"
    echo ""
    echo "[38;5;240mProfessionelle Emails verfassen[0m"
    echo "[38;5;240mTippe 'exit' um zurück zum Hauptmenü zu gelangen[0m"
    echo ""

    while true; do
        echo -n "[38;5;82m➜[0m "
        read -r request

        if [ "$request" = "exit" ] || [ "$request" = "quit" ] || [ "$request" = "q" ]; then
            echo "[38;5;226m←[0m Zurück zum Hauptmenü..."
            sleep 1
            break
        fi

        if [ -z "$request" ]; then
            continue
        fi

        echo ""
        bash "$EMAIL_AGENT" "$request"
        echo ""
    done
}

# Lokaler Claude Start (ohne Agent)
start_local_claude() {
    echo ""
    echo "[38;5;82m→[0m Starte lokalen Claude (ohne Agenten)..."
    echo ""
    ~/.npm-global/bin/claude
}

# Variablen für Farben (global verfügbar machen)
c3=$(hex_to_ansi "$C3")
reset="\e[0m"

# Hauptschleife
while true; do
    show_menu
    read -r choice

    case $choice in
        1)
            start_it_agent
            ;;
        2)
            start_basic_agent
            ;;
        3)
            start_report_agent
            ;;
        4)
            start_email_agent
            ;;
        5)
            start_local_claude
            break
            ;;
        q|Q)
            clear
            echo ""
            echo "[38;5;196m✗[0m Claude Launcher beendet."
            echo ""
            exit 0
            ;;
        *)
            echo ""
            echo "[38;5;196m✗[0m Ungültige Auswahl. Bitte erneut versuchen."
            sleep 2
            ;;
    esac
done
