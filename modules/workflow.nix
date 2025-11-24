{ config, lib, pkgs, ... }:

{
  # ============================================
  # Workflow-Optimierungen für NixOS
  # ============================================
  # Erstellt: 2025-01-24
  # Zweck: Besserer Development- & Daily-Workflow
  # ============================================

  # -------------------------------------------
  # 1. Nix-Index - Command-not-found
  # -------------------------------------------
  # "Befehl nicht gefunden? → nix-shell -p <pkg>"
  programs.command-not-found.enable = false;  # Deaktiviere alte Implementation
  programs.nix-index = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # -------------------------------------------
  # 2. Cachix - Binary Caches
  # -------------------------------------------
  # Spare Build-Zeit durch vorgefertigte Binaries
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

    # Fallback zu Build wenn Binary-Cache fehlschlägt
    fallback = true;

    # Mehr parallele Downloads
    http-connections = 128;
  };

  # -------------------------------------------
  # 3. Auto-Garbage-Collection
  # -------------------------------------------
  # Automatische Aufräumung alter Generationen
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";  # Behalte letzte 2 Wochen
  };

  # Begrenze Boot-Einträge (verhindert /boot-Volllauf)
  # HINWEIS: Bereits in performance.nix, aber hier nochmal zur Sicherheit
  # boot.loader.systemd-boot.configurationLimit = 10;

  # -------------------------------------------
  # 4. Nix-Einstellungen für besseren Workflow
  # -------------------------------------------
  nix.settings = {
    # Experimentelle Features
    experimental-features = [ "nix-command" "flakes" ];

    # Vertraue User für nix-Befehle
    trusted-users = [ "root" "preto" ];

    # Warn bei Dirty-Tree
    warn-dirty = false;

    # Mehr Build-Details
    show-trace = true;
    keep-going = true;        # Baue weiter bei Fehlern in Unterpaketen

    # Nix-Daemon-Optimierungen
    connect-timeout = 5;
  };

  # -------------------------------------------
  # 5. Development-Tools
  # -------------------------------------------
  environment.systemPackages = with pkgs; [
    # Nix-Tools
    nix-tree              # Visualisiere Nix-Store-Abhängigkeiten
    nix-diff              # Zeige Unterschiede zwischen Derivations
    nix-du                # Analysiere Store-Größen
    nix-index             # Package-Index für command-not-found

    # Nix-Development
    nil                   # Nix LSP Server (für VS Code/Neovim)
    nixfmt-classic        # Nix-Code-Formatter

    # Git-Tools (ergänzend)
    git-crypt             # Git-Repository-Verschlüsselung
    gh                    # GitHub CLI
  ];

  # -------------------------------------------
  # 6. Bash/Zsh-Completion
  # -------------------------------------------
  # Bessere Shell-Experience
  programs.bash.completion.enable = true;  # FIX: Umbenannt von enableCompletion
  programs.zsh.enableCompletion = true;

  # -------------------------------------------
  # 7. Documentation
  # -------------------------------------------
  # Lokale Nix-Dokumentation
  documentation = {
    enable = true;
    man.enable = true;
    dev.enable = true;      # Development-Docs
    nixos.enable = true;    # NixOS-Manual
  };

  # -------------------------------------------
  # 8. System-Upgrade-Hinweise
  # -------------------------------------------
  # Zeige Hinweise nach Upgrades
  system.activationScripts.diff = ''
    if [[ -e /run/current-system ]]; then
      echo "=== Systemänderungen ==="
      ${pkgs.nix}/bin/nix store diff-closures /run/current-system "$systemConfig" || true
      echo "========================"
    fi
  '';

  # -------------------------------------------
  # 9. Rebuild-Aliases (werden in home.nix gesetzt)
  # -------------------------------------------
  # Siehe home/preto/home.nix für Shell-Aliases
}
