# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Dépôt de dépannage de Claude Desktop sous Windows pour Louis (Piava). Pas de code applicatif : un runbook, un script PowerShell et un README.

## Déclencheur

Louis signale que Claude Desktop ne se lance plus, ou affiche « Ce fichier est utilisé par une autre application » / « Another program is currently using this file » / erreur `0x80070020`, par exemple après une mise à jour.

## Procédure à suivre

Suivre `docs/runbook-cowork-0x80070020.md`, sans improviser d'autre manipulation.

1. **Vérifier l'environnement.** Le script ne s'exécute que sur le PC Windows de Louis (Claude Code en local, PowerShell).
   - Session cloud ou Linux : ne pas exécuter (`pwsh` n'y est pas installé). Donner à Louis les commandes à copier dans **Terminal (administrateur)**.
   - Session locale Windows sans droits administrateur : demander à Louis d'ouvrir **Terminal (administrateur)** et d'y lancer les commandes.
2. **Diagnostic (lecture seule, sans confirmation)** :
   `powershell -ExecutionPolicy Bypass -File .\scripts\claude-cowork.ps1 -Action Status`
3. **Désactiver Cowork** :
   `powershell -ExecutionPolicy Bypass -File .\scripts\claude-cowork.ps1 -Action Disable`
   Louis a autorisé cette étape à l'avance. Elle est réversible.
4. **Redémarrage** : demander confirmation à Louis avant `Restart-Computer`, pour qu'il puisse sauvegarder son travail.
5. Après le redémarrage, faire lancer Claude à Louis et confirmer le résultat.
6. **Consigner l'incident** dans la section 7 du runbook (une ligne de tableau) : date, version (`Get-AppxPackage *Claude*`), observations, résolution. Commit et push.

## Réactivation de Cowork

Seulement à la demande de Louis. Vérifier d'abord les prérequis (section 5 du runbook), puis lancer `-Action Enable`. Prévenir Louis que l'erreur peut revenir, et que `-Action Disable` la corrige.

## Fonctionnement du script `scripts/claude-cowork.ps1`

- Il agit sur une seule valeur de registre : `Start` de `HKLM:\SYSTEM\CurrentControlSet\Services\CoworkVMService` (2 auto, 3 manuel, 4 désactivé). Rien d'autre n'est modifié.
- `Disable` sauvegarde la valeur d'origine dans `%LOCALAPPDATA%\ClaudeCoworkFix\start-value-origine.txt`, une seule fois : une sauvegarde existante n'est jamais écrasée. `Enable` relit ce fichier, ou prend `-Value`, et refuse la valeur 4.
- `Disable` et `Enable` exigent une console administrateur. `Status` fonctionne sans, mais saute alors la vérification des prérequis Cowork.
- Le fichier est en ASCII pur, commentaires et messages compris (pas d'accents). Le garder ainsi : Windows PowerShell 5.1 lit un fichier sans BOM en ANSI et afficherait mal les caractères accentués.

## Modifier le dépôt

- Pas de build, de lint ni de tests. Aucun moyen d'exécuter le script hors du PC Windows de Louis : toute modification se vérifie par relecture, puis par `-Action Status` sur sa machine.
- Les commandes du script figurent à trois endroits : `README.md` (réparation rapide), le runbook (section 4) et ce fichier. Les mettre à jour ensemble.
- Ce fichier renvoie aux sections 3, 5, 6 et 7 du runbook par leur numéro : ne pas renuméroter le runbook sans corriger ces renvois.
- Chaque affirmation du runbook cite sa source (tickets GitHub, support.claude.com, Microsoft Learn). Conserver cette règle pour tout ajout.

## Règles

- Ne jamais modifier, renommer ni supprimer de fichiers dans `C:\Program Files\WindowsApps\`.
- Ne pas utiliser les méthodes listées comme inefficaces dans la section 3 du runbook.
- Si la procédure échoue, ne pas inventer de solution : se reporter à la section 6 du runbook.
- Réponses en français, sans émojis ni tirets quadratins, avec sources.
