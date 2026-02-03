#!/usr/bin/env bash
mkdir -p ~/Pictures/Screenshots
grim ~/Pictures/Screenshots/$(date +%F_%T).png && notify-send "Screenshot gespeichert"
