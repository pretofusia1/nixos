#!/usr/bin/env bash

# ============================================================
# Claude Launcher - SSH-basiert für Hetzner Server
# ============================================================
# Connectet via WireGuard (10.10.0.3) zum Claude-Container
# und führt Agenten auf dem Server aus

# Server-Konfiguration
SERVER_IP="10.10.0.3"
SSH_PORT="52022"
SSH_USER="claude"
AGENTS_DIR="/workspace/agents"

# Hole Wallpaper-Farben (lokal auf Laptop)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
COLORS_SCRIPT="$SCRIPT_DIR/get-wallpaper-colors.sh"

# Fallback: Suche in mehreren Pfaden
if [ ! -f "$COLORS_SCRIPT" ]; then
    if [ -f "$HOME/get-wallpaper-colors.sh" ]; then
        COLORS_SCRIPT="$HOME/get-wallpaper-colors.sh"
    elif [ -f "$HOME/.local/bin/get-wallpaper-colors.sh" ]; then
        COLORS_SCRIPT="$HOME/.local/bin/get-wallpaper-colors.sh"
    fi
fi

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

# Konvertiere Hex zu ANSI
hex_to_ansi() {
    local hex=$1
    hex=${hex#"#"}
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "\e[38;2;${r};${g};${b}m"
}

# WireGuard-Verbindung prüfen
check_wireguard() {
    if ! ip link show wg0 &> /dev/null; then
        echo ""
        echo "[38;5;196m✗[0m WireGuard nicht verbunden!"
        echo "[38;5;226m→[0m Starte WireGuard..."

        # Versuche WireGuard zu starten (systemd)
        if command -v systemctl &> /dev/null; then
            sudo systemctl start wg-quick@wg0 2>/dev/null
        fi

        sleep 2

        if ! ip link show wg0 &> /dev/null; then
            echo "[38;5;196m✗[0m WireGuard-Start fehlgeschlagen!"
            echo "Bitte manuell starten: sudo systemctl start wg-quick@wg0"
            return 1
        fi
    fi

    # Prüfe ob Server erreichbar ist
    if ! ping -c 1 -W 2 "$SERVER_IP" &> /dev/null; then
        echo "[38;5;196m✗[0m Server $SERVER_IP nicht erreichbar!"
        return 1
    fi

    return 0
}

# SSH-Verbindung zum Server testen
check_ssh() {
    if ! ssh -p "$SSH_PORT" -o ConnectTimeout=5 -o BatchMode=yes "$SSH_USER@$SERVER_IP" "exit" 2>/dev/null; then
        echo ""
        echo "[38;5;196m✗[0m SSH-Verbindung zu $SERVER_IP:$SSH_PORT fehlgeschlagen!"
        echo "[38;5;240mPrüfe:"
        echo "  - WireGuard verbunden? (ip a show wg0)"
        echo "  - SSH-Key hinterlegt? (ssh-copy-id -p $SSH_PORT claude@$SERVER_IP)"
        echo "  - Container läuft? (docker ps auf Server)"
        echo ""
        return 1
    fi
    return 0
}

# Claude Logo ASCII Art
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
    echo -e "${c6}    Server: [1m$SERVER_IP:$SSH_PORT[0m     ${reset}"
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
    echo "  [38;5;82m5)[0m [1mClaude Interactive[0m - Interaktive Session"
    echo ""
    echo "  [38;5;196mq)[0m Beenden"
    echo ""
    echo -n "[38;5;75m➜[0m Auswahl: "
}

# IT-Agent via SSH starten
start_it_agent() {
    clear
    local c3=$(hex_to_ansi "$C3")
    local reset="\e[0m"

    echo -e "${c3}╔════════════════════════════════════════╗${reset}"
    echo -e "${c3}║${reset}         [1mIT-Agent Modus[0m              ${c3}║${reset}"
    echo -e "${c3}╚════════════════════════════════════════╝${reset}"
    echo ""
    echo "[38;5;240mIT-Infrastruktur, NixOS, Proxmox, Docker, WireGuard[0m"
    echo "[38;5;240mTippe 'exit' um zurück zum Hauptmenü zu gelangen[0m"
    echo "[38;5;240mVerbindung zu: $SERVER_IP[0m"
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
        echo "[38;5;240m[SSH → $SERVER_IP] Führe IT-Agent aus...[0m"
        ssh -p "$SSH_PORT" "$SSH_USER@$SERVER_IP" "bash $AGENTS_DIR/IT/it-agent.sh \"$question\""
        echo ""
    done
}

# Basic-Agent via SSH starten
start_basic_agent() {
    clear
    local c3=$(hex_to_ansi "$C3")
    local reset="\e[0m"

    echo -e "${c3}╔════════════════════════════════════════╗${reset}"
    echo -e "${c3}║${reset}        [1mBasic-Agent Modus[0m            ${c3}║${reset}"
    echo -e "${c3}╚════════════════════════════════════════╝${reset}"
    echo ""
    echo "[38;5;240mAllgemeine Fragen, Wissen, Erklärungen[0m"
    echo "[38;5;240mTippe 'exit' um zurück zum Hauptmenü zu gelangen[0m"
    echo "[38;5;240mVerbindung zu: $SERVER_IP[0m"
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
        echo "[38;5;240m[SSH → $SERVER_IP] Führe Basic-Agent aus...[0m"
        ssh -p "$SSH_PORT" "$SSH_USER@$SERVER_IP" "bash $AGENTS_DIR/basic/basic-agent.sh \"$question\""
        echo ""
    done
}

# Report-Agent via SSH starten
start_report_agent() {
    clear
    local c3=$(hex_to_ansi "$C3")
    local reset="\e[0m"

    echo -e "${c3}╔════════════════════════════════════════╗${reset}"
    echo -e "${c3}║${reset}       [1mReport-Agent Modus[0m            ${c3}║${reset}"
    echo -e "${c3}╚════════════════════════════════════════╝${reset}"
    echo ""
    echo "[38;5;240mStrukturierte Reports & Dokumentation[0m"
    echo "[38;5;240mTippe 'exit' um zurück zum Hauptmenü zu gelangen[0m"
    echo "[38;5;240mVerbindung zu: $SERVER_IP[0m"
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
        echo "[38;5;240m[SSH → $SERVER_IP] Führe Report-Agent aus...[0m"
        ssh -p "$SSH_PORT" "$SSH_USER@$SERVER_IP" "bash $AGENTS_DIR/reports/report-agent.sh \"$topic\""
        echo ""
    done
}

# Email-Agent via SSH starten
start_email_agent() {
    clear
    local c3=$(hex_to_ansi "$C3")
    local reset="\e[0m"

    echo -e "${c3}╔════════════════════════════════════════╗${reset}"
    echo -e "${c3}║${reset}       [1mEmail-Agent Modus[0m             ${c3}║${reset}"
    echo -e "${c3}╚════════════════════════════════════════╝${reset}"
    echo ""
    echo "[38;5;240mProfessionelle Emails verfassen[0m"
    echo "[38;5;240mTippe 'exit' um zurück zum Hauptmenü zu gelangen[0m"
    echo "[38;5;240mVerbindung zu: $SERVER_IP[0m"
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
        echo "[38;5;240m[SSH → $SERVER_IP] Führe Email-Agent aus...[0m"
        ssh -p "$SSH_PORT" "$SSH_USER@$SERVER_IP" "bash $AGENTS_DIR/emails/email-agent.sh \"$request\""
        echo ""
    done
}

# Interaktive Claude-Session via SSH
start_interactive_claude() {
    echo ""
    echo "[38;5;82m→[0m Starte interaktive Claude-Session auf Server..."
    echo "[38;5;240mVerbindung zu: $SERVER_IP:$SSH_PORT[0m"
    echo ""

    # Direkte interaktive SSH-Session mit Claude
    ssh -t -p "$SSH_PORT" "$SSH_USER@$SERVER_IP" "cd /workspace && exec bash -l"
}

# Startup-Checks
clear
echo "[38;5;75m╔═══════════════════════════════════════╗[0m"
echo "[38;5;75m║[0m  [1mClaude Launcher - Startup Check[0m    [38;5;75m║[0m"
echo "[38;5;75m╚═══════════════════════════════════════╝[0m"
echo ""
echo "[38;5;240m[1/2] Prüfe WireGuard-Verbindung...[0m"

if ! check_wireguard; then
    echo ""
    echo "[38;5;196m✗[0m Startup fehlgeschlagen. Drücke Enter zum Beenden."
    read
    exit 1
fi

echo "[38;5;82m✓[0m WireGuard verbunden"
echo ""
echo "[38;5;240m[2/2] Prüfe SSH-Verbindung zu Server...[0m"

if ! check_ssh; then
    echo ""
    echo "[38;5;196m✗[0m Startup fehlgeschlagen. Drücke Enter zum Beenden."
    read
    exit 1
fi

echo "[38;5;82m✓[0m SSH-Verbindung OK"
echo ""
echo "[38;5;82m✓[0m Alle Checks erfolgreich!"
sleep 2

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
            start_interactive_claude
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
