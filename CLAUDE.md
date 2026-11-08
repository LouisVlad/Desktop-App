# CLAUDE.md

Dépôt de dépannage de Claude Desktop sous Windows pour Louis (Piava). Pas de code applicatif.

## Déclencheur

Louis signale que Claude Desktop ne se lance plus, ou affiche « Ce fichier est utilisé par une autre application » / « Another program is currently using this file » / erreur `0x80070020`, par exemple après une mise à jour.

## Procédure à suivre

Suivre `docs/runbook-cowork-0x80070020.md`, sans improviser d'autre manipulation.

1. **Vérifier l'environnement.** Le script ne s'exécute que sur le PC Windows de Louis (Claude Code en local, PowerShell).
   - Session cloud ou Linux : ne pas exécuter. Donner à Louis les commandes à copier dans **Terminal (administrateur)**.
   - Session locale Windows sans droits administrateur : demander à Louis d'ouvrir **Terminal (administrateur)** et d'y lancer les commandes.
2. **Diagnostic (lecture seule, sans confirmation)** :
   `powershell -ExecutionPolicy Bypass -File .\scripts\claude-cowork.ps1 -Action Status`
3. **Désactiver Cowork** :
   `powershell -ExecutionPolicy Bypass -File .\scripts\claude-cowork.ps1 -Action Disable`
   Louis a autorisé cette étape à l'avance. Elle est réversible.
4. **Redémarrage** : demander confirmation à Louis avant `Restart-Computer`, pour qu'il puisse sauvegarder son travail.
5. Après le redémarrage, faire lancer Claude à Louis et confirmer le résultat.
6. **Consigner l'incident** dans la section 7 du runbook : date, version (`Get-AppxPackage *Claude*`), observations, résolution. Commit et push.

## Réactivation de Cowork

Seulement à la demande de Louis. Vérifier d'abord les prérequis (section 5 du runbook), puis lancer `-Action Enable`. Prévenir Louis que l'erreur peut revenir, et que `-Action Disable` la corrige.

## Règles

- Ne jamais modifier, renommer ni supprimer de fichiers dans `C:\Program Files\WindowsApps\`.
- Ne pas utiliser les méthodes listées comme inefficaces dans la section 3 du runbook.
- Si la procédure échoue, ne pas inventer de solution : se reporter à la section 6 du runbook.
- Réponses en français, sans émojis ni tirets quadratins, avec sources.
