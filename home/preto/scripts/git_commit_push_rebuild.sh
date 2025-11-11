#!/usr/bin/env bash
set -euo pipefail

# Commit + Push + NixOS-Rebuild (Flake unterstützt)
# Usage: git_commit_push_rebuild.sh [repo_dir] [flake_target] ["Commit msg..."]

REPO_DIR="${1:-.}"
FLAKE_TARGET="${2:-.}"        # z.B. .#preto-laptop
shift 2 || true
COMMIT_MSG="${*:-Auto update $(date +'%F %T')}"

cd "$REPO_DIR"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Kein Git-Repo."; exit 1
fi

echo "Repository: $(pwd)"
read -rp "git add/commit/push + rebuild ausführen? (j/N) " ok
[[ "$ok" =~ ^[JjYy]$ ]] || { echo "Abbruch."; exit 1; }

git add -A
if git diff --staged --quiet; then
  echo "Keine Änderungen zum Commit."
else
  git commit -m "$COMMIT_MSG"

  # Push mit Error Handling
  if ! git push; then
    echo "FEHLER: git push fehlgeschlagen!"
    echo "Mögliche Ursachen:"
    echo "  - Keine Internet-Verbindung"
    echo "  - SSH Key nicht korrekt"
    echo "  - Branch existiert remote nicht"
    read -rp "Trotzdem mit Rebuild fortfahren? (j/N) " cont
    [[ "$cont" =~ ^[JjYy]$ ]] || exit 1
  fi
fi

if [ -f flake.nix ]; then
  sudo nixos-rebuild switch --flake "$FLAKE_TARGET"
else
  sudo nixos-rebuild switch
fi
echo "Fertig."
