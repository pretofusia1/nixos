#!/usr/bin/env bash
set -euo pipefail

# Commit + Push + Rebuild + Garbage-Collect
# Usage: git_commit_push_rebuild_gc.sh [repo_dir] [flake_target]

REPO_DIR="${1:-.}"
FLAKE_TARGET="${2:-.}"

cd "$REPO_DIR"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Kein Git-Repo."; exit 1
fi

read -rp "Commit/Push/Rebuild + GC ausführen? (j/N) " ok
[[ "$ok" =~ ^[JjYy]$ ]] || { echo "Abbruch."; exit 1; }

git add -A
if git diff --staged --quiet; then
  echo "Keine Änderungen zum Commit."
else
  read -rp "Commit-Nachricht: " msg
  msg="${msg:-Update $(date +'%F %T')}"
  git commit -m "$msg"
  git push
fi

if [ -f flake.nix ]; then
  sudo nixos-rebuild switch --flake "$FLAKE_TARGET"
else
  sudo nixos-rebuild switch
fi

read -rp "Alle alten Generationen löschen (nix-collect-garbage -d)? (j/N) " gcok
if [[ "$gcok" =~ ^[JjYy]$ ]]; then
  sudo nix-collect-garbage -d
fi
echo "Fertig."
