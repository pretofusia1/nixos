#!/usr/bin/env bash
mkdir -p ~/Pictures/Screenshots
grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%F_%T).png && notify-send "Screenshot gespeichert"
