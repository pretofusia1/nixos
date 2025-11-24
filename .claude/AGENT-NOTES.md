# Notizen für Claude Agent

## Git-Konfiguration

**KRITISCH:** Das Git-Remote für dieses Repo ist **IMMER SSH**, niemals HTTPS!

```bash
# Korrekt:
origin  git@github.com:pretofusia1/nixos.git

# FALSCH (niemals verwenden):
origin  https://github.com/pretofusia1/nixos.git
```

**Wenn Remote falsch ist, korrigieren mit:**
```bash
git remote set-url origin git@github.com:pretofusia1/nixos.git
```

**Grund:** Der User hat SSH-Keys konfiguriert, HTTPS funktioniert nicht.

## Container Push-Workflow

Wenn ich im Container Änderungen committe:
1. Ich kann NICHT selbst pushen (keine SSH-Keys im Container)
2. User muss selbst `git push` ausführen
3. Dann auf Laptop: `cd /etc/nixos && git pull`
