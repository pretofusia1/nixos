#!/usr/bin/env bash
set -euo pipefail

# Pull + (flake update) + commit/push + rebuild + optional GC
# Usage: update_system.sh [repo_dir] [flake_target]

REPO_DIR="${1:-.}"
FLAKE_TARGET="${2:-.}"

cd "$REPO_DIR"

# Git Pull mit Error Handling
echo "Pulling latest changes from remote..."
if ! git pull --rebase; then
  echo "FEHLER: git pull fehlgeschlagen!"
  echo "Mögliche Ursachen:"
  echo "  - Merge-Konflikt (löse mit: git rebase --abort)"
  echo "  - Keine Internet-Verbindung"
  echo "  - Branch wurde umbenannt"
  read -rp "Trotzdem fortfahren? (j/N) " cont
  [[ "$cont" =~ ^[JjYy]$ ]] || exit 1
fi

if [ -f flake.nix ] && command -v nix >/dev/null 2>&1; then
  echo "flake.nix gefunden -> nix flake update ..."
  if ! nix flake update; then
    echo "WARNUNG: flake update fehlgeschlagen"
    read -rp "Trotzdem mit Rebuild fortfahren? (j/N) " cont
    [[ "$cont" =~ ^[JjYy]$ ]] || exit 1
  fi
fi

git add -A
if git diff --staged --quiet; then
  echo "Keine Änderungen zum Commit."
else
  read -rp "Commit-Nachricht (leer = Auto): " msg
  msg="${msg:-Automatisches Update $(date +'%F %T')}"
  git commit -m "$msg"
  git push
fi

if [ -f flake.nix ]; then
  sudo nixos-rebuild switch --flake "$FLAKE_TARGET"
else
  sudo nixos-rebuild switch
fi

read -rp "GC ausführen (nix-collect-garbage -d)? (j/N) " gcok
if [[ "$gcok" =~ ^[JjYy]$ ]]; then
  sudo nix-collect-garbage -d
fi

echo "Update beendet."
