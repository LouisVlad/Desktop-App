# Desktop-App

Dépannage de Claude Desktop sous Windows.

| Fichier | Contenu |
|---|---|
| [docs/runbook-cowork-0x80070020.md](docs/runbook-cowork-0x80070020.md) | Procédure quand Claude Desktop ne se lance plus (« Ce fichier est utilisé par une autre application ») |
| [scripts/claude-cowork.ps1](scripts/claude-cowork.ps1) | Script PowerShell : diagnostic, désactivation et réactivation du service Cowork |
| [CLAUDE.md](CLAUDE.md) | Instructions pour Claude Code |

## Réparation rapide

Dans **Terminal (administrateur)**, depuis ce dossier :

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\claude-cowork.ps1 -Action Disable
Restart-Computer
```
