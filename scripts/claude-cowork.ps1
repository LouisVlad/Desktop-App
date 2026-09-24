<#
.SYNOPSIS
    Diagnostic et contournement du blocage de Claude Desktop sous Windows
    ("Ce fichier est utilise par une autre application", erreur 0x80070020)
    cause par le service CoworkVMService (cowork-svc.exe).

.DESCRIPTION
    Procedure detaillee et sources : docs/runbook-cowork-0x80070020.md
    Source principale : https://github.com/anthropics/claude-code/issues/91736

    Actions :
      Status   Lecture seule. Etat du service, du paquet Claude et des prerequis Cowork.
      Disable  Desactive CoworkVMService (Start = 4). Sauvegarde la valeur d'origine.
      Enable   Reactive CoworkVMService avec la valeur sauvegardee (ou -Value).

    Disable et Enable exigent une console PowerShell en administrateur
    et prennent effet apres un redemarrage de Windows.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\claude-cowork.ps1 -Action Status
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\claude-cowork.ps1 -Action Disable
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\claude-cowork.ps1 -Action Enable
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\claude-cowork.ps1 -Action Enable -Value 2
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Status', 'Disable', 'Enable')]
    [string]$Action,

    [ValidateRange(0, 4)]
    [int]$Value
)

$ServiceKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\CoworkVMService'
$BackupDir  = Join-Path $env:LOCALAPPDATA 'ClaudeCoworkFix'
$BackupFile = Join-Path $BackupDir 'start-value-origine.txt'

function Test-Admin {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Admin {
    if (-not (Test-Admin)) {
        Write-Error "Console non administrateur. Ouvrir 'Terminal (administrateur)' puis relancer."
        exit 1
    }
}

function Get-StartValue {
    if (-not (Test-Path $ServiceKey)) { return $null }
    return (Get-ItemProperty -Path $ServiceKey -Name Start).Start
}

function Show-Section([string]$Title) {
    Write-Host ''
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

switch ($Action) {

    'Status' {
        Show-Section 'Console'
        Write-Host ("Administrateur : {0}" -f (Test-Admin))

        Show-Section 'Service CoworkVMService (Start : 2 = auto, 3 = manuel, 4 = desactive)'
        $start = Get-StartValue
        if ($null -eq $start) {
            Write-Host 'Cle de registre absente : service non installe.'
        } else {
            Write-Host "Start = $start"
        }
        if (Test-Path $BackupFile) {
            Write-Host ("Valeur d'origine sauvegardee : {0}" -f (Get-Content $BackupFile))
        } else {
            Write-Host "Aucune valeur d'origine sauvegardee."
        }

        Show-Section 'Processus cowork-svc'
        $procs = Get-CimInstance Win32_Process | Where-Object { $_.Name -like 'cowork*' }
        if ($procs) {
            $procs | Select-Object ProcessId, ParentProcessId, CreationDate | Format-Table -AutoSize
        } else {
            Write-Host 'Aucun processus cowork en cours.'
        }

        Show-Section 'Paquet Claude installe'
        Get-AppxPackage *Claude* | Select-Object Name, Version, Architecture, Status | Format-Table -AutoSize

        Show-Section 'Erreurs 0x80070020 (journal AppModel-Runtime, 200 derniers evenements)'
        $events = Get-WinEvent -LogName 'Microsoft-Windows-AppModel-Runtime/Admin' -MaxEvents 200 -ErrorAction SilentlyContinue |
            Where-Object { $_.Message -like '*80070020*' } |
            Select-Object -First 5 TimeCreated, Id, Message
        if ($events) { $events | Format-List } else { Write-Host 'Aucune erreur 0x80070020 trouvee.' }

        Show-Section 'Prerequis Cowork (support.claude.com)'
        if (Test-Admin) {
            Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform |
                Select-Object FeatureName, State | Format-Table -AutoSize
            bcdedit | Select-String 'hypervisorlaunchtype'
        } else {
            Write-Host 'Verification ignoree : necessite une console administrateur.'
        }
    }

    'Disable' {
        Assert-Admin
        $start = Get-StartValue
        if ($null -eq $start) {
            Write-Error 'Cle CoworkVMService absente : rien a desactiver, Cowork ne peut pas etre en cause.'
            exit 1
        }
        if ($start -ne 4 -and -not (Test-Path $BackupFile)) {
            New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
            Set-Content -Path $BackupFile -Value $start
            Write-Host "Valeur d'origine ($start) sauvegardee dans $BackupFile"
        }
        # Commande issue de https://github.com/anthropics/claude-code/issues/91736
        Set-ItemProperty -Path $ServiceKey -Name Start -Value 4
        Write-Host ("Start = {0}. Redemarrer Windows, puis lancer Claude." -f (Get-StartValue)) -ForegroundColor Green
    }

    'Enable' {
        Assert-Admin
        if ($PSBoundParameters.ContainsKey('Value')) {
            $target = $Value
        } elseif (Test-Path $BackupFile) {
            $target = [int](Get-Content $BackupFile)
        } else {
            Write-Error "Aucune valeur d'origine sauvegardee. Relancer avec -Value <chiffre note avant la desactivation>."
            exit 1
        }
        if ($target -eq 4) {
            Write-Error 'La valeur 4 desactive le service. Utiliser Disable ou une autre valeur.'
            exit 1
        }
        Set-ItemProperty -Path $ServiceKey -Name Start -Value $target
        Write-Host ("Start = {0}. Redemarrer Windows, puis lancer Claude. En cas d'erreur, relancer -Action Disable." -f (Get-StartValue)) -ForegroundColor Green
    }
}
