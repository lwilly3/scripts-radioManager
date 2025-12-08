# Solution-Service-HTTP.ps1 - Documentation

## 📋 Vue d'ensemble

Ce script PowerShell crée une **solution complète** permettant aux utilisateurs d'un **domaine Active Directory sans droits administrateur** de contrôler l'activation/désactivation d'un adaptateur réseau VPN (WireGuard) sur Windows via de simples fichiers BAT.

**Note** : Un README.md détaillé existe déjà dans le dossier. Cette documentation complémente celui-ci avec des informations techniques supplémentaires.

## 🎯 Objectif

Résoudre le problème suivant :
- **Problème** : Les utilisateurs du domaine AD n'ont pas les droits pour activer/désactiver les adaptateurs réseau
- **Solution** : Un service HTTP local tournant en tant que SYSTEM qui écoute les requêtes HTTP des utilisateurs

## 🏗️ Architecture de la solution

```
┌─────────────────────────────────────────────┐
│  Utilisateur (sans droits admin)            │
│  Double-clic sur Enable-VPN.bat             │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  Script PowerShell (Enable-VPN.ps1)         │
│  Envoie requête HTTP à localhost:9876       │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  Service HTTP Local (WG-Service.ps1)        │
│  Tourne en tant que SYSTEM                  │
│  Exécute Enable/Disable-NetAdapter          │
└─────────────────────────────────────────────┘
```

## 📦 Prérequis

- **Système** : Windows 10/11 ou Windows Server
- **PowerShell** : Version 5.1 ou supérieure
- **WireGuard** : Installé et interface détectable
- **Privilèges** : Administrateur pour l'installation **UNIQUEMENT**
- **Réseau** : Port 9876 disponible localement

## 🔧 Composants générés

Le script crée automatiquement ces fichiers dans `C:\VPN Scripts\` :

| Fichier | Type | Utilisateur | Description |
|---------|------|-------------|-------------|
| `Enable-VPN.bat` | Batch | ✅ Utilisateur | Active le VPN |
| `Disable-VPN.bat` | Batch | ✅ Utilisateur | Désactive le VPN |
| `Status-VPN.bat` | Batch | ✅ Utilisateur | Vérifie le statut |
| `Enable-VPN.ps1` | PowerShell | ⚙️ Automatique | Script d'activation |
| `Disable-VPN.ps1` | PowerShell | ⚙️ Automatique | Script de désactivation |
| `Status-VPN.ps1` | PowerShell | ⚙️ Automatique | Script de vérification |
| `WG-Service.ps1` | PowerShell | 🔒 Système | Service HTTP |

## 🚀 Installation

### Étape 1 : Téléchargement du script

```powershell
# Télécharger depuis GitHub
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/VPN%20wireguard/script%20utilisateur%20domaine%20AD/Solution-Service-HTTP.ps1" -OutFile "Solution-Service-HTTP.ps1"
```

### Étape 2 : Exécution du script d'installation

**Ouvrir PowerShell en tant qu'Administrateur** :

```powershell
powershell.exe -ExecutionPolicy Bypass -File "Solution-Service-HTTP.ps1"
```

### Étape 3 : Vérification

Le script effectue automatiquement :
1. ✅ Détection de l'interface WireGuard
2. ✅ Création du dossier `C:\VPN Scripts\`
3. ✅ Génération du service HTTP
4. ✅ Création de la tâche planifiée
5. ✅ Génération des fichiers BAT et PS1
6. ✅ Démarrage du service

## 📝 Fonctionnement détaillé

### 1. Détection de l'interface VPN

```powershell
$WGInterface = Get-NetAdapter | Where-Object { 
    $_.InterfaceDescription -like "*WireGuard*" 
}
```

Recherche automatiquement l'adaptateur WireGuard installé.

### 2. Création du service HTTP (WG-Service.ps1)

```powershell
$ServiceScript = @"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:9876/")
$listener.Start()

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $action = $context.Request.Url.LocalPath.TrimStart('/')
    
    switch ($action) {
        "enable"  { Enable-NetAdapter -Name $InterfaceName }
        "disable" { Disable-NetAdapter -Name $InterfaceName }
        "status"  { Get-NetAdapter -Name $InterfaceName }
    }
}
"@
```

**Endpoints disponibles** :
- `http://localhost:9876/enable` : Active le VPN
- `http://localhost:9876/disable` : Désactive le VPN
- `http://localhost:9876/status` : Vérifie le statut

### 3. Création de la tâche planifiée

```powershell
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File 'C:\VPN Scripts\WG-Service.ps1'"

$Trigger = New-ScheduledTaskTrigger -AtStartup

$Principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

Register-ScheduledTask -TaskName "WG-Service" `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal
```

**Caractéristiques** :
- Exécution en tant que **SYSTEM** (droits administrateur)
- Démarrage **automatique au boot**
- Fenêtre **masquée**

### 4. Génération des fichiers utilisateur

#### Enable-VPN.bat

```batch
@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Enable-VPN.ps1"
pause
```

#### Enable-VPN.ps1

```powershell
$response = Invoke-WebRequest -Uri "http://localhost:9876/enable" -UseBasicParsing
$bytes = $response.RawContentStream.ToArray()
$text = [System.Text.Encoding]::UTF8.GetString($bytes)
Write-Host $text -ForegroundColor Green
```

## 👥 Utilisation (Utilisateur final)

### Activer le VPN

1. Double-cliquer sur **`Enable-VPN.bat`**
2. Le VPN s'active en 2-3 secondes
3. Message de confirmation affiché
4. Informations pédagogiques :
   - Rôle du VPN (accès ressources internes hors locaux)
   - Navigation Internet reste directe
   - Recommandation de désactiver dans les locaux

### Désactiver le VPN

1. Double-cliquer sur **`Disable-VPN.bat`**
2. Le VPN se désactive instantanément
3. Message explicatif :
   - Connexion locale directe
   - Meilleure vitesse dans les locaux
   - Comment réactiver si nécessaire

### Vérifier le statut

1. Double-cliquer sur **`Status-VPN.bat`**
2. Affiche l'état actuel (Actif/Désactivé)
3. Rappel des bonnes pratiques

## 🔍 Vérification de l'installation

### Vérifier la tâche planifiée

```powershell
Get-ScheduledTask -TaskName "WG-Service"
```

Doit afficher :
- **État** : Ready
- **Triggers** : At startup
- **Actions** : Start a program

### Vérifier le service

```powershell
# Tester l'endpoint status
Invoke-WebRequest -Uri "http://localhost:9876/status" -UseBasicParsing
```

### Vérifier les fichiers

```powershell
Get-ChildItem "C:\VPN Scripts\"
```

Doit lister 7 fichiers (3 BAT + 3 PS1 + 1 service).

## 🛠️ Administration

### Démarrer le service manuellement

```powershell
Start-ScheduledTask -TaskName "WG-Service"
```

### Arrêter le service

```powershell
Stop-ScheduledTask -TaskName "WG-Service"
```

### Redémarrer le service

```powershell
Stop-ScheduledTask -TaskName "WG-Service"
Start-Sleep -Seconds 2
Start-ScheduledTask -TaskName "WG-Service"
```

### Voir les logs

```powershell
# Logs de la tâche planifiée
Get-WinEvent -LogName "Microsoft-Windows-TaskScheduler/Operational" | 
    Where-Object { $_.Message -like "*WG-Service*" } | 
    Select-Object -First 10
```

### Désinstaller

```powershell
# Arrêter et supprimer la tâche
Unregister-ScheduledTask -TaskName "WG-Service" -Confirm:$false

# Supprimer les fichiers
Remove-Item "C:\VPN Scripts\" -Recurse -Force
```

## 🔒 Sécurité

### Pourquoi localhost uniquement ?

Le service écoute **UNIQUEMENT sur localhost** (127.0.0.1) :
- ❌ Aucun accès possible depuis le réseau
- ✅ Seuls les utilisateurs locaux peuvent y accéder
- ✅ Pas de risque d'attaque externe

### Permissions du service

- **Utilisateur** : SYSTEM (droits administrateur)
- **Exécution** : Niveau le plus élevé
- **Accès** : Uniquement via localhost

### Protection des fichiers

```powershell
# Restreindre l'accès au service
$acl = Get-Acl "C:\VPN Scripts\WG-Service.ps1"
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "SYSTEM", "FullControl", "Allow"
)
$acl.AddAccessRule($rule)
Set-Acl "C:\VPN Scripts\WG-Service.ps1" $acl
```

## ⚠️ Dépannage

### Problème : Service ne démarre pas

```powershell
# Vérifier les erreurs
Get-ScheduledTaskInfo -TaskName "WG-Service"

# Tester le script manuellement (en admin)
PowerShell -ExecutionPolicy Bypass -File "C:\VPN Scripts\WG-Service.ps1"
```

### Problème : Interface VPN introuvable

```powershell
# Lister toutes les interfaces
Get-NetAdapter | Format-Table Name, InterfaceDescription, Status

# Vérifier WireGuard
Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*WireGuard*" }
```

### Problème : Erreur "Service non disponible"

```powershell
# Vérifier que le service écoute
Test-NetConnection -ComputerName localhost -Port 9876

# Redémarrer la tâche
Stop-ScheduledTask -TaskName "WG-Service"
Start-ScheduledTask -TaskName "WG-Service"
```

### Problème : Permissions insuffisantes

Le script d'installation doit être exécuté **en tant qu'Administrateur**. Sinon :
- Clic droit sur PowerShell → "Exécuter en tant qu'administrateur"
- Ou via `runas /user:Administrator powershell`

## 📊 Monitoring

### Statistiques d'utilisation

Ajoutez du logging dans le service :

```powershell
# Dans WG-Service.ps1, ajouter :
$logFile = "C:\VPN Scripts\usage.log"
Add-Content -Path $logFile -Value "$(Get-Date) - $action - $env:USERNAME"
```

### Alertes administrateur

Créez un script de surveillance :

```powershell
# check-vpn-service.ps1
$task = Get-ScheduledTask -TaskName "WG-Service"
if ($task.State -ne "Running") {
    Send-MailMessage -To "admin@example.com" `
        -Subject "VPN Service Down" `
        -Body "Le service VPN n'est pas actif" `
        -SmtpServer "smtp.example.com"
}
```

## 🎓 Cas d'usage

### Scénario 1 : Télétravail

Employé à domicile :
1. Active le VPN avec `Enable-VPN.bat`
2. Accède aux serveurs internes
3. Désactive le VPN en fin de journée

### Scénario 2 : Déplacement professionnel

Employé en hôtel :
1. Active le VPN
2. Travaille normalement
3. Navigation web reste rapide (split-tunneling)

### Scénario 3 : Dans les locaux

Employé au bureau :
1. Désactive le VPN
2. Accès direct au réseau local (plus rapide)
3. Pas de latence supplémentaire

## 📚 Personnalisation

### Changer le port du service

Dans le script d'installation, modifiez :

```powershell
$Port = 9876  # Changer pour 8080 par exemple
```

### Ajouter des fonctionnalités

Ajoutez des endpoints dans `WG-Service.ps1` :

```powershell
"restart" {
    Disable-NetAdapter -Name $InterfaceName -Confirm:$false
    Start-Sleep -Seconds 2
    Enable-NetAdapter -Name $InterfaceName -Confirm:$false
    $result = "VPN REDÉMARRE"
}
```

### Changer l'interface réseau cible

Modifiez la détection :

```powershell
# Pour une interface Ethernet spécifique
$Interface = Get-NetAdapter -Name "Ethernet 2"

# Pour tout type d'interface VPN
$Interface = Get-NetAdapter | Where-Object { $_.InterfaceType -eq 53 }
```

## 🔗 Intégration

### Déploiement via GPO

1. Copiez le script dans un partage réseau
2. Créez une GPO de démarrage :
   ```
   Computer Configuration → Policies → Windows Settings → Scripts → Startup
   ```
3. Ajoutez le script PowerShell

### Déploiement via SCCM/Intune

Créez un package d'application avec :
- Script d'installation
- Méthode de détection : Présence de `C:\VPN Scripts\WG-Service.ps1`

## 📞 Support

### Logs à consulter

```powershell
# Logs tâches planifiées
Get-WinEvent -LogName "Microsoft-Windows-TaskScheduler/Operational" | 
    Select-Object -First 20

# Logs PowerShell
Get-WinEvent -LogName "Windows PowerShell" | 
    Select-Object -First 20
```

### Commandes de diagnostic

```powershell
# Vérifier le service
Get-ScheduledTask -TaskName "WG-Service" | Get-ScheduledTaskInfo

# Tester la connexion au service
Test-NetConnection -ComputerName localhost -Port 9876

# Vérifier l'interface VPN
Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*WireGuard*" }
```

## 📜 Notes importantes

- ⚠️ **Installation requiert des droits admin** une seule fois
- ✅ **Utilisateurs n'ont besoin d'aucun droit** pour utiliser
- 🔒 **Service tourne en tant que SYSTEM** pour les permissions
- 🌐 **Localhost uniquement** pour la sécurité
- 🔄 **Démarrage automatique** au boot
- 📝 **Messages pédagogiques** pour guider les utilisateurs
- 🎯 **Split-tunneling** : Navigation Internet reste directe

## 🎉 Avantages de cette solution

1. **Simplicité** : Double-clic suffit
2. **Sécurité** : Pas de droits admin donnés aux utilisateurs
3. **Autonomie** : Les utilisateurs gèrent eux-mêmes le VPN
4. **Pédagogique** : Messages explicatifs détaillés
5. **Fiable** : Service système robuste
6. **Maintenance** : Aucune intervention requise
7. **Performance** : Exécution instantanée

## 📖 Documentation existante

Un **README.md très détaillé** (397 lignes) existe déjà dans le dossier avec :
- Architecture complète
- Tableaux des fichiers
- Instructions d'installation
- Guide utilisateur avec captures
- Dépannage avancé
- Exemples de code

Cette documentation .md complète le README existant avec des aspects techniques supplémentaires.
