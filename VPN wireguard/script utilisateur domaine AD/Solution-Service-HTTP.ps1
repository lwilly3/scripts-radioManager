#
# SOLUTION ULTIME - Service HTTP local pour controler le VPN
# Sans taches planifiees, sans permissions complexes
# A executer UNE FOIS en tant qu'ADMINISTRATEUR
#

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " SERVICE VPN TOGGLE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Detecter l'interface
$WGInterface = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*WireGuard*" }
if (-not $WGInterface) {
    Write-Host "[ERREUR] Interface VPN introuvable !" -ForegroundColor Red
    exit
}

$InterfaceName = $WGInterface.Name
Write-Host "[OK] Interface : $InterfaceName" -ForegroundColor Green
Write-Host ""

# ===========================================
# 1. Creer un service PowerShell qui ecoute
# ===========================================
Write-Host "[1] Creation du service d'ecoute..." -ForegroundColor Yellow

$ServiceFolder = "C:\VPN Scripts"
if (-not (Test-Path $ServiceFolder)) {
    New-Item -Path $ServiceFolder -ItemType Directory -Force | Out-Null
}

# Script du service (ecoute sur port local)
$ServiceScript = @"
# Service VPN Toggle - Ecoute sur HTTP local
`$InterfaceName = "$InterfaceName"
`$Port = 9876

Write-Host "[SERVICE] Demarrage du service VPN Toggle..." -ForegroundColor Green
Write-Host "[SERVICE] Interface : `$InterfaceName" -ForegroundColor Cyan
Write-Host "[SERVICE] Port : `$Port" -ForegroundColor Cyan

`$listener = New-Object System.Net.HttpListener
`$listener.Prefixes.Add("http://localhost:`$Port/")

try {
    `$listener.Start()
    Write-Host "[SERVICE] En ecoute..." -ForegroundColor Green
    
    while (`$listener.IsListening) {
        `$context = `$listener.GetContext()
        `$request = `$context.Request
        `$response = `$context.Response
        
        `$action = `$request.Url.LocalPath.TrimStart('/')
        `$result = ""
        
        Write-Host "[REQUEST] `$action" -ForegroundColor Yellow
        
        switch (`$action) {
            "disable" {
                try {
                    Disable-NetAdapter -Name `$InterfaceName -Confirm:`$false
                    `$result = "VPN DESACTIVE"
                    Write-Host "[OK] VPN desactive" -ForegroundColor Green
                } catch {
                    `$result = "ERREUR: Impossible de desactiver le VPN"
                    Write-Host "[ERREUR] `$(`$_.Exception.Message)" -ForegroundColor Red
                }
            }
            "enable" {
                try {
                    Enable-NetAdapter -Name `$InterfaceName -Confirm:`$false
                    `$result = "VPN ACTIVE"
                    Write-Host "[OK] VPN active" -ForegroundColor Green
                } catch {
                    `$result = "ERREUR: Impossible d'activer le VPN"
                    Write-Host "[ERREUR] `$(`$_.Exception.Message)" -ForegroundColor Red
                }
            }
            "status" {
                try {
                    `$adapter = Get-NetAdapter -Name `$InterfaceName
                    if (`$adapter.Status -eq "Up") {
                        `$result = "VPN ACTIF"
                    } else {
                        `$result = "VPN DESACTIVE"
                    }
                } catch {
                    `$result = "ERREUR: Interface introuvable"
                }
            }
            default {
                `$result = "Commande invalide"
            }
        }
        
        # Envoyer la reponse
        `$buffer = [System.Text.Encoding]::UTF8.GetBytes(`$result)
        `$response.ContentLength64 = `$buffer.Length
        `$response.OutputStream.Write(`$buffer, 0, `$buffer.Length)
        `$response.OutputStream.Close()
    }
} catch {
    Write-Host "[ERREUR] `$(`$_.Exception.Message)" -ForegroundColor Red
} finally {
    if (`$listener.IsListening) {
        `$listener.Stop()
    }
}
"@

$ServiceScript | Out-File -FilePath "$ServiceFolder\WG-Service.ps1" -Encoding UTF8 -Force
Write-Host "[OK] Service cree : $ServiceFolder\WG-Service.ps1" -ForegroundColor Green
Write-Host ""

# ===========================================
# 2. Creer une tache planifiee pour le service
# ===========================================
Write-Host "[2] Creation de la tache planifiee..." -ForegroundColor Yellow

$TaskName = "WG-Service"
$TaskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($TaskExists) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "[OK] Ancienne tache supprimee" -ForegroundColor Yellow
}

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ServiceFolder\WG-Service.ps1`""
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings | Out-Null
Write-Host "[OK] Tache '$TaskName' creee (demarre au boot)" -ForegroundColor Green
Write-Host ""

# ===========================================
# 3. Creer les fichiers BAT pour utilisateurs
# ===========================================
Write-Host "[3] Creation des fichiers utilisateurs..." -ForegroundColor Yellow

# Enable-VPN.bat
$EnableBat = @"
@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Enable-VPN.ps1"
pause
"@
$EnableBat | Out-File -FilePath "$ServiceFolder\Enable-VPN.bat" -Encoding ASCII -Force

# Disable-VPN.bat
$DisableBat = @"
@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Disable-VPN.ps1"
pause
"@
$DisableBat | Out-File -FilePath "$ServiceFolder\Disable-VPN.bat" -Encoding ASCII -Force

# Status-VPN.bat
$StatusBat = @"
@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Status-VPN.ps1"
pause
"@
$StatusBat | Out-File -FilePath "$ServiceFolder\Status-VPN.bat" -Encoding ASCII -Force

Write-Host "[OK] Fichiers BAT crees" -ForegroundColor Green
Write-Host ""

# ===========================================
# 4. Creer les scripts PowerShell appelants
# ===========================================
Write-Host "[4] Creation des scripts PowerShell..." -ForegroundColor Yellow

# Enable-VPN.ps1
$EnablePS = @'
Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "         ACTIVATION DU VPN" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9876/enable" -UseBasicParsing
    $bytes = $response.RawContentStream.ToArray()
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    Write-Host $text -ForegroundColor Green
} catch {
    Write-Host "ERREUR: Service non disponible" -ForegroundColor Red
}
Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  INFORMATIONS IMPORTANTES" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Bonjour $env:USERNAME," -ForegroundColor White
Write-Host ""
Write-Host "Le VPN est maintenant ACTIVE." -ForegroundColor Green
Write-Host ""
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host " A QUOI SERT LE VPN ?" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "Lorsque vous etes EN DEHORS des locaux de" -ForegroundColor White
Write-Host "l'entreprise (teletravail, deplacement...)," -ForegroundColor White
Write-Host "le VPN vous permet d'acceder aux ressources" -ForegroundColor White
Write-Host "internes du reseau de l'entreprise." -ForegroundColor White
Write-Host ""
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host " NAVIGATION INTERNET" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "Votre navigation sur Internet (sites web" -ForegroundColor White
Write-Host "publics, YouTube, etc.) reste DIRECTE" -ForegroundColor White
Write-Host "et ne passe PAS par le VPN." -ForegroundColor White
Write-Host ""
Write-Host "Seuls les acces aux ressources INTERNES" -ForegroundColor White
Write-Host "de l'entreprise passent par le VPN." -ForegroundColor White
Write-Host ""
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host " IMPORTANT" -ForegroundColor Red
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "Si vous etes DANS LES LOCAUX de l'entreprise," -ForegroundColor Yellow
Write-Host "il est preferable de DESACTIVER le VPN pour" -ForegroundColor Yellow
Write-Host "une meilleure vitesse de connexion." -ForegroundColor Yellow
Write-Host ""
Write-Host "Pour desactiver : Double-cliquez sur Disable-VPN.bat" -ForegroundColor Cyan
Write-Host ""
'@
$EnablePS | Out-File -FilePath "$ServiceFolder\Enable-VPN.ps1" -Encoding UTF8 -Force

# Disable-VPN.ps1
$DisablePS = @'
Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "        DESACTIVATION DU VPN" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9876/disable" -UseBasicParsing
    $bytes = $response.RawContentStream.ToArray()
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    Write-Host $text -ForegroundColor Yellow
} catch {
    Write-Host "ERREUR: Service non disponible" -ForegroundColor Red
}
Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  INFORMATIONS IMPORTANTES" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Bonjour $env:USERNAME," -ForegroundColor White
Write-Host ""
Write-Host "Le VPN est maintenant DESACTIVE." -ForegroundColor Yellow
Write-Host ""
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host " CONSEQUENCE" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "Vous utilisez maintenant votre connexion" -ForegroundColor White
Write-Host "Internet locale directe." -ForegroundColor White
Write-Host ""
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host " QUAND DESACTIVER LE VPN ?" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "Vous devriez desactiver le VPN lorsque vous" -ForegroundColor White
Write-Host "etes DANS LES LOCAUX de l'entreprise." -ForegroundColor White
Write-Host ""
Write-Host "Cela vous permettra de profiter d'une" -ForegroundColor Green
Write-Host "connexion plus RAPIDE et d'une meilleure" -ForegroundColor Green
Write-Host "experience de navigation." -ForegroundColor Green
Write-Host ""
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host " ACCES AUX RESSOURCES" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "Dans les locaux : Acces direct aux ressources" -ForegroundColor White
Write-Host "internes (serveurs, dossiers partages...)." -ForegroundColor White
Write-Host ""
Write-Host "Hors des locaux : Vous devrez REACTIVER" -ForegroundColor Yellow
Write-Host "le VPN pour acceder aux ressources internes." -ForegroundColor Yellow
Write-Host ""
Write-Host "Pour reactiver : Double-cliquez sur Enable-VPN.bat" -ForegroundColor Cyan
Write-Host ""
'@
$DisablePS | Out-File -FilePath "$ServiceFolder\Disable-VPN.ps1" -Encoding UTF8 -Force

# Status-VPN.ps1
$StatusPS = @'
Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "          STATUT DU VPN" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9876/status" -UseBasicParsing
    $bytes = $response.RawContentStream.ToArray()
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    Write-Host $text -ForegroundColor White
} catch {
    Write-Host "ERREUR: Service non disponible" -ForegroundColor Red
}
Write-Host ""
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host "Fichiers disponibles :" -ForegroundColor White
Write-Host "  - Enable-VPN.bat  : Activer le VPN" -ForegroundColor White
Write-Host "  - Disable-VPN.bat : Desactiver le VPN" -ForegroundColor White
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  INFORMATIONS IMPORTANTES" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Bonjour $env:USERNAME," -ForegroundColor White
Write-Host ""
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host " RAPPEL : UTILISATION DU VPN" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "DANS les locaux de l'entreprise :" -ForegroundColor White
Write-Host "  -> DESACTIVEZ le VPN pour une connexion" -ForegroundColor Green
Write-Host "     plus rapide et une meilleure experience" -ForegroundColor Green
Write-Host ""
Write-Host "HORS des locaux de l'entreprise :" -ForegroundColor White
Write-Host "  -> ACTIVEZ le VPN pour acceder aux" -ForegroundColor Yellow
Write-Host "     ressources internes du reseau" -ForegroundColor Yellow
Write-Host ""
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host " NAVIGATION INTERNET" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "Meme avec le VPN active, votre navigation" -ForegroundColor White
Write-Host "Internet (sites web publics) reste DIRECTE" -ForegroundColor White
Write-Host "et ne passe PAS par le VPN." -ForegroundColor White
Write-Host ""
Write-Host "Seuls les acces aux ressources INTERNES" -ForegroundColor White
Write-Host "de l'entreprise utilisent le VPN." -ForegroundColor White
Write-Host ""
'@
$StatusPS | Out-File -FilePath "$ServiceFolder\Status-VPN.ps1" -Encoding UTF8 -Force

Write-Host "[OK] Scripts PowerShell crees" -ForegroundColor Green
Write-Host ""

# ===========================================
# 5. Demarrer le service
# ===========================================
Write-Host "[5] Demarrage du service..." -ForegroundColor Yellow
Start-ScheduledTask -TaskName $TaskName
Start-Sleep -Seconds 3
Write-Host "[OK] Service demarre !" -ForegroundColor Green
Write-Host ""

# ===========================================
# TERMINE !
# ===========================================
Write-Host "========================================" -ForegroundColor Green
Write-Host "   INSTALLATION TERMINEE !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Fichiers disponibles dans : $ServiceFolder" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pour l'utilisateur :" -ForegroundColor Yellow
Write-Host "  - Enable-VPN.bat  : Activer le VPN" -ForegroundColor White
Write-Host "  - Disable-VPN.bat : Desactiver le VPN" -ForegroundColor White
Write-Host "  - Status-VPN.bat  : Verifier le statut" -ForegroundColor White
Write-Host ""
Write-Host "Le service demarre automatiquement au demarrage de l'ordinateur." -ForegroundColor Cyan
Write-Host ""
