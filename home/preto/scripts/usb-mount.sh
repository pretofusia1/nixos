#!/usr/bin/env bash
# ============================================
# USB-Mount Script - Manuelles Mounten/Unmounten
# ============================================
# Verwendet udisksctl (kein sudo noetig!)
#
# Nutzung:
#   usb-mount.sh          -> Interaktives Menue
#   usb-mount.sh mount    -> Alle nicht-gemounteten USB-Geraete mounten
#   usb-mount.sh unmount  -> Gemountetes USB-Geraet auswaehlen und unmounten
#   usb-mount.sh status   -> Status aller USB-Geraete anzeigen
#   usb-mount.sh eject    -> USB-Geraet sicher auswerfen (unmount + poweroff)
# ============================================

set -euo pipefail

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Benachrichtigung senden (falls notify-send verfuegbar)
notify() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    if command -v notify-send &>/dev/null; then
        notify-send -u "$urgency" -i "drive-removable-media" "$title" "$message"
    fi
    echo -e "${GREEN}$title${NC}: $message"
}

# Alle USB-Block-Geraete finden
get_usb_devices() {
    lsblk -nrpo NAME,TYPE,MOUNTPOINT,SIZE,LABEL,TRAN | grep -E "usb" | grep -E "part|disk" || true
}

# Nur nicht-gemountete USB-Partitionen
get_unmounted_usb() {
    lsblk -nrpo NAME,TYPE,MOUNTPOINT,SIZE,LABEL,TRAN | grep -E "usb" | grep "part" | awk '$3==""' || true
}

# Nur gemountete USB-Partitionen
get_mounted_usb() {
    lsblk -nrpo NAME,TYPE,MOUNTPOINT,SIZE,LABEL,TRAN | grep -E "usb" | grep "part" | awk '$3!=""' || true
}

# Status aller USB-Geraete anzeigen
cmd_status() {
    echo -e "${BLUE}=== USB-Geraete Status ===${NC}"
    echo ""

    local devices
    devices=$(get_usb_devices)

    if [ -z "$devices" ]; then
        echo -e "${YELLOW}Keine USB-Speichergeraete gefunden.${NC}"
        return
    fi

    echo -e "${BLUE}Geraet          Typ   Groesse  Label           Mountpoint${NC}"
    echo "----------------------------------------------------------------------"

    while IFS=' ' read -r name type mountpoint size label tran; do
        label="${label:-(kein Label)}"
        if [ -z "$mountpoint" ]; then
            echo -e "${YELLOW}$name  $type  $size  $label  (nicht gemountet)${NC}"
        else
            echo -e "${GREEN}$name  $type  $size  $label  $mountpoint${NC}"
        fi
    done <<< "$devices"
    echo ""
}

# Alle nicht-gemounteten USB-Geraete mounten
cmd_mount() {
    local unmounted
    unmounted=$(get_unmounted_usb)

    if [ -z "$unmounted" ]; then
        echo -e "${YELLOW}Keine nicht-gemounteten USB-Geraete gefunden.${NC}"
        return
    fi

    while IFS=' ' read -r name type mountpoint size label tran; do
        label="${label:-(kein Label)}"
        echo -e "${BLUE}Mounte $name ($label, $size)...${NC}"

        if udisksctl mount -b "$name" 2>/dev/null; then
            local new_mount
            new_mount=$(lsblk -nrpo MOUNTPOINT "$name" | head -1)
            notify "USB gemountet" "$label ($size) -> $new_mount"

            # Thunar oeffnen, falls im Hyprland
            if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v thunar &>/dev/null; then
                thunar "$new_mount" &
            fi
        else
            echo -e "${RED}Fehler beim Mounten von $name${NC}"
        fi
    done <<< "$unmounted"
}

# Interaktives Unmounten
cmd_unmount() {
    local mounted
    mounted=$(get_mounted_usb)

    if [ -z "$mounted" ]; then
        echo -e "${YELLOW}Keine gemounteten USB-Geraete gefunden.${NC}"
        return
    fi

    echo -e "${BLUE}Gemountete USB-Geraete:${NC}"
    echo ""

    local -a devices=()
    local i=1

    while IFS=' ' read -r name type mountpoint size label tran; do
        label="${label:-(kein Label)}"
        echo -e "  ${GREEN}$i)${NC} $name - $label ($size) -> $mountpoint"
        devices+=("$name")
        ((i++))
    done <<< "$mounted"

    echo ""
    read -rp "Nummer zum Unmounten (oder 'a' fuer alle, 'q' zum Abbrechen): " choice

    if [ "$choice" = "q" ]; then
        return
    fi

    if [ "$choice" = "a" ]; then
        for dev in "${devices[@]}"; do
            local label
            label=$(lsblk -nrpo LABEL "$dev" | head -1)
            label="${label:-(kein Label)}"
            echo -e "${BLUE}Unmounte $dev...${NC}"
            if udisksctl unmount -b "$dev" 2>/dev/null; then
                notify "USB ausgehaengt" "$label ($dev)"
            else
                echo -e "${RED}Fehler beim Unmounten von $dev${NC}"
            fi
        done
        return
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#devices[@]}" ]; then
        local dev="${devices[$((choice-1))]}"
        local label
        label=$(lsblk -nrpo LABEL "$dev" | head -1)
        label="${label:-(kein Label)}"
        echo -e "${BLUE}Unmounte $dev...${NC}"
        if udisksctl unmount -b "$dev" 2>/dev/null; then
            notify "USB ausgehaengt" "$label ($dev)"
        else
            echo -e "${RED}Fehler beim Unmounten von $dev${NC}"
        fi
    else
        echo -e "${RED}Ungueltige Auswahl.${NC}"
    fi
}

# Sicher auswerfen (unmount + power-off)
cmd_eject() {
    local all_usb
    all_usb=$(lsblk -nrpo NAME,TYPE,MOUNTPOINT,SIZE,LABEL,TRAN | grep -E "usb" | grep "disk" || true)

    if [ -z "$all_usb" ]; then
        echo -e "${YELLOW}Keine USB-Geraete gefunden.${NC}"
        return
    fi

    echo -e "${BLUE}USB-Laufwerke:${NC}"
    echo ""

    local -a devices=()
    local i=1

    while IFS=' ' read -r name type mountpoint size label tran; do
        label="${label:-(kein Label)}"
        echo -e "  ${GREEN}$i)${NC} $name - $label ($size)"
        devices+=("$name")
        ((i++))
    done <<< "$all_usb"

    echo ""
    read -rp "Nummer zum sicheren Auswerfen (oder 'q' zum Abbrechen): " choice

    if [ "$choice" = "q" ]; then
        return
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#devices[@]}" ]; then
        local dev="${devices[$((choice-1))]}"
        local label
        label=$(lsblk -nrpo LABEL "$dev" | head -1)
        label="${label:-(kein Label)}"

        # Erst alle Partitionen unmounten
        local parts
        parts=$(lsblk -nrpo NAME "$dev" | tail -n +2)
        for part in $parts; do
            if findmnt "$part" &>/dev/null; then
                echo -e "${BLUE}Unmounte $part...${NC}"
                udisksctl unmount -b "$part" 2>/dev/null || true
            fi
        done

        # Dann Laufwerk auswerfen
        echo -e "${BLUE}Werfe $dev aus...${NC}"
        if udisksctl power-off -b "$dev" 2>/dev/null; then
            notify "USB sicher entfernt" "$label ($dev) kann jetzt abgezogen werden"
        else
            echo -e "${YELLOW}Power-Off nicht moeglich, aber Geraet ist sicher ausgehaengt.${NC}"
            notify "USB ausgehaengt" "$label ($dev) - Partitionen sicher ausgehaengt"
        fi
    else
        echo -e "${RED}Ungueltige Auswahl.${NC}"
    fi
}

# Interaktives Menue
cmd_menu() {
    echo -e "${BLUE}=== USB-Mount Manager ===${NC}"
    echo ""
    echo "  1) Status    - Alle USB-Geraete anzeigen"
    echo "  2) Mount     - USB-Geraete mounten"
    echo "  3) Unmount   - USB-Geraete aushaengen"
    echo "  4) Eject     - USB-Geraet sicher auswerfen"
    echo "  q) Beenden"
    echo ""
    read -rp "Auswahl: " choice

    case "$choice" in
        1) cmd_status ;;
        2) cmd_mount ;;
        3) cmd_unmount ;;
        4) cmd_eject ;;
        q|Q) exit 0 ;;
        *) echo -e "${RED}Ungueltige Auswahl.${NC}" ;;
    esac
}

# Hauptprogramm
case "${1:-}" in
    mount)   cmd_mount ;;
    unmount) cmd_unmount ;;
    status)  cmd_status ;;
    eject)   cmd_eject ;;
    help|--help|-h)
        echo "Nutzung: $(basename "$0") [mount|unmount|status|eject|help]"
        echo ""
        echo "Ohne Argument: Interaktives Menue"
        ;;
    *)       cmd_menu ;;
esac
