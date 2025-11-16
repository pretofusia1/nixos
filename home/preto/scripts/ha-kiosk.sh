#!/usr/bin/env bash
#
# Home Assistant Kiosk Mode Script
# Startet Browser im echten Kiosk-Mode für HA Dashboard
# ohne Menüs, Tabs, Addressbar etc.
#

HA_URL="https://ha.fruehlingszimmer.de"

# OPTION 1: Chromium App-Mode (Beste Kiosk-Experience)
# Falls chromium installiert ist, verwende es - sonst Firefox
if command -v chromium &> /dev/null; then
    chromium \
        --app="$HA_URL" \
        --class=scratchpad-ha \
        --window-size=1920,1080 \
        --window-position=0,0 \
        --disable-infobars \
        --disable-features=TranslateUI \
        --no-first-run \
        --no-default-browser-check \
        2>/dev/null &
elif command -v google-chrome &> /dev/null; then
    google-chrome \
        --app="$HA_URL" \
        --class=scratchpad-ha \
        --window-size=1920,1080 \
        --window-position=0,0 \
        --disable-infobars \
        --disable-features=TranslateUI \
        --no-first-run \
        --no-default-browser-check \
        2>/dev/null &
else
    # OPTION 2: Firefox Kiosk-Mode (Fallback)
    firefox \
        --class scratchpad-ha \
        --kiosk "$HA_URL" \
        --new-instance \
        2>/dev/null &
fi

exit 0
