# Runbook : Claude Desktop ne se lance plus (« Ce fichier est utilisé par une autre application »)

## 1. Symptôme

Au lancement de Claude Desktop sous Windows, une fenêtre d'erreur s'affiche et l'application ne démarre pas :

- titre de la fenêtre : `C:\Program Files\WindowsApps\Claude_<version>_...`
- message : « Ce fichier est utilisé par une autre application. » (en anglais : « Another program is currently using this file »)

Code d'erreur Windows associé : `0x80070020` (ERROR_SHARING_VIOLATION).

## 2. Cause documentée

Source : [anthropics/claude-code#91736](https://github.com/anthropics/claude-code/issues/91736)

- Le message est trompeur : aucun fichier n'est réellement verrouillé. La panne vient de la création du conteneur Windows (AppX) de l'application.
- Le service `CoworkVMService` (processus `cowork-svc.exe`), qui fait tourner Cowork, est en cause.
- Le problème revient environ à chaque mise à jour de Claude Desktop.

## 3. Ce qui ne fonctionne pas (d'après le ticket #91736)

- Paramètres > Applications > Claude > Réparer ou Réinitialiser
- `Add-AppxPackage -Register`
- `net stop CoworkVMService`
- `taskkill /F /IM Claude.exe` ou `taskkill /F /IM cowork-svc.exe` (le service est relancé immédiatement)
- `Set-Service` ou `sc.exe config` (« Accès refusé »)

Constaté le 2026-09-24 sur le PC de Louis : redémarrage de Windows et réinstallation de l'application sans effet.

## 4. Solution qui a fonctionné (2026-09-24)

Désactiver le service par le registre (commande du ticket #91736), puis redémarrer Windows :

```powershell
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\CoworkVMService" -Name Start -Value 4
```

Conséquence : Claude Desktop se lance, mais Cowork est indisponible tant que le service reste désactivé.

### Procédure avec le script du dépôt

Dans **Terminal (administrateur)**, depuis la racine du dépôt :

| Étape | Commande | Effet |
|---|---|---|
| 1. Diagnostic | `powershell -ExecutionPolicy Bypass -File .\scripts\claude-cowork.ps1 -Action Status` | Lecture seule |
| 2. Désactiver Cowork | `powershell -ExecutionPolicy Bypass -File .\scripts\claude-cowork.ps1 -Action Disable` | Sauvegarde la valeur d'origine puis passe `Start` à 4 |
| 3. Redémarrer Windows | `Restart-Computer` | Applique le changement |
| 4. Lancer Claude | Menu Démarrer | L'application doit s'ouvrir |

La valeur d'origine est sauvegardée dans `%LOCALAPPDATA%\ClaudeCoworkFix\start-value-origine.txt`.

### Procédure manuelle (sans le script)

1. Relever la valeur actuelle et la noter :
   ```powershell
   Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\CoworkVMService" -Name Start
   ```
2. Désactiver : commande de la section 4.
3. Redémarrer Windows, lancer Claude.

## 5. Réactiver Cowork

Prérequis Cowork, d'après la [documentation officielle de déploiement Windows](https://support.claude.com/en/articles/12622703-deploy-claude-desktop-for-windows) :

- fonctionnalité Windows « Plateforme de machine virtuelle » (`VirtualMachinePlatform`) activée ;
- `bcdedit` affiche `hypervisorlaunchtype` à `Auto` ;
- pas de machine virtuelle sans virtualisation imbriquée.

Le script `-Action Status` vérifie les deux premiers points.

Réactivation :

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\claude-cowork.ps1 -Action Enable
```

Puis redémarrer Windows. Si l'erreur revient, relancer `-Action Disable` et redémarrer.

Signification des valeurs `Start` : 2 = automatique, 3 = manuel, 4 = désactivé. Source : [Microsoft Learn, INF AddService Directive](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-addservice-directive).

## 6. Si la solution ne suffit plus

- Signaler le cas en commentaire du ticket [#91736](https://github.com/anthropics/claude-code/issues/91736), avec la sortie de `-Action Status`.
- Autres tickets sur le même bug : [#53247](https://github.com/anthropics/claude-code/issues/53247), [#92202](https://github.com/anthropics/claude-code/issues/92202), [#95266](https://github.com/anthropics/claude-code/issues/95266).
- Support Anthropic : [support.claude.com](https://support.claude.com).

## 7. Journal des incidents

| Date | Version Claude | Observations | Résolution |
|---|---|---|---|
| 2026-09-24 | 2.7032.0.0 (architecture à confirmer, suffixe `_ar...` : arm64 possible) | Aucune erreur 0x80070020 dans le journal AppModel-Runtime. `cowork-svc` lancé par `services`, PID stable. Redémarrage et réinstallation sans effet. | `Start = 4` + redémarrage : Claude se lance. Cowork désactivé. |
