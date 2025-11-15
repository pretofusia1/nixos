#!/usr/bin/env bash

# Pywal-Farben laden (falls vorhanden)
if [ -f "$HOME/.cache/wal/sequences" ]; then
    cat "$HOME/.cache/wal/sequences"
fi

# Fastfetch mit Pywal-Farben starten
fastfetch
