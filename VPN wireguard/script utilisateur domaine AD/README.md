# Solution VPN Toggle - Documentation

## 📋 Vue d'ensemble

Cette solution permet à des utilisateurs **sans droits administrateur** de contrôler l'activation/désactivation d'un adaptateur réseau VPN (WireGuard) sur Windows via des fichiers BAT simples.

## 🎯 Problème résolu

**Problème initial :** Les utilisateurs du domaine Active Directory n'ont pas les droits pour activer/désactiver les adaptateurs réseau, même en utilisant des tâches planifiées.

**Solution :** Un service HTTP local tournant en tant que SYSTEM qui écoute les requêtes HTTP locales des utilisateurs.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Utilisateur (sans droits admin)                            │
│  Double-clic sur Enable-VPN.bat ou Disable-VPN.bat          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Fichier BAT                                                 │
│  → Lance le script PowerShell correspondant                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Script PowerShell (Enable/Disable/Status-VPN.ps1)          │
│  → Envoie requête HTTP à localhost:9876                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Service HTTP Local (WG-Service.ps1)                         │
│  → Tourne en tant que SYSTEM (droits admin)                  │
│  → Exécute Enable-NetAdapter ou Disable-NetAdapter           │
│  → Retourne le résultat                                      │
└─────────────────────────────────────────────────────────────┘
```

## 📦 Fichiers générés

### Emplacement : `C:\VPN Scripts\`

| Fichier | Type | Description | Utilisé par |
|---------|------|-------------|-------------|
| `Enable-VPN.bat` | Batch | Active le VPN | **Utilisateur** |
| `Disable-VPN.bat` | Batch | Désactive le VPN | **Utilisateur** |
| `Status-VPN.bat` | Batch | Vérifie le statut du VPN | **Utilisateur** |
| `Enable-VPN.ps1` | PowerShell | Script d'activation (appelle le service) | Fichier BAT |
| `Disable-VPN.ps1` | PowerShell | Script de désactivation (appelle le service) | Fichier BAT |
| `Status-VPN.ps1` | PowerShell | Script de statut (appelle le service) | Fichier BAT |
| `WG-Service.ps1` | PowerShell | Service HTTP local | Tâche planifiée |

## 🚀 Installation

### Prérequis

- Windows avec PowerShell 5.1+
- Droits **Administrateur** pour l'installation uniquement
- Interface réseau WireGuard installée et détectable

### Étapes d'installation

1. **Ouvrir PowerShell en tant qu'Administrateur**

2. **Exécuter le script d'installation :**
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File "Solution-Service-HTTP.ps1"
   ```

3. **Vérification :**
   - Le script détecte automatiquement l'interface VPN
   - Crée les fichiers dans `C:\VPN Scripts\`
   - Démarre le service automatiquement
   - Configure une tâche planifiée pour le démarrage au boot

### Ce que fait le script d'installation

1. ✅ Détecte l'interface réseau WireGuard
2. ✅ Crée le dossier `C:\VPN Scripts\`
3. ✅ Génère le service HTTP `WG-Service.ps1`
4. ✅ Crée une tâche planifiée "WG-Service" (SYSTEM, démarrage auto)
5. ✅ Génère les fichiers BAT pour les utilisateurs
6. ✅ Génère les scripts PowerShell appelants
7. ✅ Démarre le service immédiatement

## 👥 Utilisation (Utilisateur final)

### Pour activer le VPN

1. Double-cliquer sur **`Enable-VPN.bat`**
2. Le VPN s'active automatiquement
3. Un message détaillé explique :
   - Le rôle du VPN (accès aux ressources internes hors des locaux)
   - La navigation Internet reste directe
   - Recommandation : désactiver si dans les locaux de l'entreprise

### Pour désactiver le VPN

1. Double-cliquer sur **`Disable-VPN.bat`**
2. Le VPN se désactive automatiquement
3. Un message détaillé explique :
   - Connexion Internet locale directe
   - Meilleure vitesse dans les locaux
   - Comment réactiver si nécessaire

### Pour vérifier le statut

1. Double-cliquer sur **`Status-VPN.bat`**
2. Affiche l'état actuel : **VPN ACTIF** ou **VPN DESACTIVE**
3. Rappel des bonnes pratiques d'utilisation

## 🔧 Fonctionnement technique

### Service HTTP Local

- **Port :** `9876` (localhost uniquement)
- **Endpoints :**
  - `http://localhost:9876/enable` → Active le VPN
  - `http://localhost:9876/disable` → Désactive le VPN
  - `http://localhost:9876/status` → Vérifie le statut

### Tâche planifiée

- **Nom :** `WG-Service`
- **Utilisateur :** SYSTEM
- **Déclencheur :** Au démarrage du système
- **Action :** Exécute `WG-Service.ps1` en arrière-plan

### Commandes PowerShell utilisées

```powershell
# Activation
Enable-NetAdapter -Name "NomInterface" -Confirm:$false

# Désactivation
Disable-NetAdapter -Name "NomInterface" -Confirm:$false

# Vérification du statut
Get-NetAdapter -Name "NomInterface"
```

## 📊 Messages utilisateur

### Structure des messages

Tous les messages incluent :
- ✅ **Salutation personnalisée** avec `$env:USERNAME`
- ✅ **Titre de l'action** (activation/désactivation)
- ✅ **État résultant** du VPN
- ✅ **Explications pédagogiques** :
  - Rôle du VPN (accès distant aux ressources internes)
  - Navigation Internet directe (split-tunnel)
  - Recommandations selon la localisation
- ✅ **Instructions** pour l'action inverse

### Exemple de message (Enable-VPN)

```
===========================================
         ACTIVATION DU VPN
===========================================

VPN ACTIVE

===========================================
  INFORMATIONS IMPORTANTES
===========================================

Bonjour USERNAME,

Le VPN est maintenant ACTIVE.

-------------------------------------------
 A QUOI SERT LE VPN ?
-------------------------------------------

Lorsque vous etes EN DEHORS des locaux de
l'entreprise (teletravail, deplacement...),
le VPN vous permet d'acceder aux ressources
internes du reseau de l'entreprise.

-------------------------------------------
 NAVIGATION INTERNET
-------------------------------------------

Votre navigation sur Internet (sites web
publics, YouTube, etc.) reste DIRECTE
et ne passe PAS par le VPN.

Seuls les acces aux ressources INTERNES
de l'entreprise passent par le VPN.

-------------------------------------------
 IMPORTANT
-------------------------------------------

Si vous etes DANS LES LOCAUX de l'entreprise,
il est preferable de DESACTIVER le VPN pour
une meilleure vitesse de connexion.

Pour desactiver : Double-cliquez sur Disable-VPN.bat
```

## 🔐 Sécurité

### Points de sécurité

✅ **Service local uniquement** : Écoute sur `localhost` (pas d'accès réseau)  
✅ **Pas de ports externes** : Aucun risque d'accès distant  
✅ **Exécution SYSTEM** : Droits minimaux nécessaires pour gérer les adaptateurs  
✅ **Pas d'authentification nécessaire** : Sécurisé par localhost  
✅ **Pas de données sensibles** : Pas de mots de passe ou clés  

### Limites de sécurité

⚠️ **N'importe quel processus local** peut envoyer des requêtes au service  
⚠️ **Pas de logging des actions** : Considérer l'ajout de logs si nécessaire  

## 🛠️ Maintenance

### Vérifier si le service est actif

```powershell
Get-ScheduledTask -TaskName "WG-Service"
```

### Redémarrer le service

```powershell
Restart-ScheduledTask -TaskName "WG-Service"
```

### Arrêter le service

```powershell
Stop-ScheduledTask -TaskName "WG-Service"
```

### Supprimer complètement la solution

```powershell
# Arrêter et supprimer la tâche
Unregister-ScheduledTask -TaskName "WG-Service" -Confirm:$false

# Supprimer les fichiers
Remove-Item -Path "C:\VPN Scripts" -Recurse -Force
```

### Logs et diagnostics

Le service affiche des logs dans la console PowerShell :
- `[SERVICE] Demarrage du service VPN Toggle...`
- `[REQUEST] enable/disable/status`
- `[OK] VPN active/desactive`
- `[ERREUR] Message d'erreur`

Pour voir les logs en temps réel :
```powershell
# Démarrer le service manuellement en mode visible
& "C:\VPN Scripts\WG-Service.ps1"
```

## 🐛 Dépannage

### Le service ne démarre pas

**Vérifier la tâche planifiée :**
```powershell
Get-ScheduledTask -TaskName "WG-Service" | Get-ScheduledTaskInfo
```

**Démarrer manuellement :**
```powershell
Start-ScheduledTask -TaskName "WG-Service"
```

### Erreur "Service non disponible"

**Causes possibles :**
1. Le service n'est pas démarré
2. Le port 9876 est utilisé par une autre application
3. Pare-feu bloque localhost (rare)

**Solution :**
```powershell
# Vérifier si le port est en écoute
netstat -an | findstr "9876"

# Redémarrer le service
Restart-ScheduledTask -TaskName "WG-Service"
```

### L'interface VPN n'est pas détectée

**Vérifier les adaptateurs :**
```powershell
Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*WireGuard*" }
```

**Si aucun résultat :**
- Vérifier que WireGuard est installé
- Vérifier que l'interface est créée
- Modifier le script pour chercher un autre pattern

### Messages en codes ASCII

**Problème résolu dans la version actuelle**, mais si le problème persiste :
- Vérifier l'encodage UTF-8 des fichiers PS1
- Vérifier que `chcp 65001` est dans les fichiers BAT

## 📝 Personnalisation

### Changer le port du service

Éditer `WG-Service.ps1` :
```powershell
$Port = 9876  # Changer ici
```

Puis mettre à jour les scripts `Enable-VPN.ps1`, `Disable-VPN.ps1`, `Status-VPN.ps1` :
```powershell
"http://localhost:9876/enable"  # Changer le port ici
```

### Changer le dossier d'installation

Éditer `Solution-Service-HTTP.ps1` :
```powershell
$ServiceFolder = "C:\VPN Scripts"  # Changer ici
```

### Personnaliser les messages

Éditer les sections dans `Solution-Service-HTTP.ps1` :
- `$EnablePS` : Messages d'activation
- `$DisablePS` : Messages de désactivation
- `$StatusPS` : Messages de statut

## 📚 Références

### Commandes PowerShell utilisées

- `Get-NetAdapter` : Liste les adaptateurs réseau
- `Enable-NetAdapter` : Active un adaptateur
- `Disable-NetAdapter` : Désactive un adaptateur
- `New-ScheduledTask*` : Crée des tâches planifiées
- `Invoke-WebRequest` : Envoie des requêtes HTTP
- `System.Net.HttpListener` : Serveur HTTP léger

### Documentation Microsoft

- [Get-NetAdapter](https://docs.microsoft.com/en-us/powershell/module/netadapter/get-netadapter)
- [Enable-NetAdapter](https://docs.microsoft.com/en-us/powershell/module/netadapter/enable-netadapter)
- [Scheduled Tasks](https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/)

## ✅ Avantages de cette solution

| Avantage | Description |
|----------|-------------|
| 🔓 **Pas de droits admin requis** | L'utilisateur peut l'utiliser sans élévation |
| 🚀 **Démarrage automatique** | Le service démarre avec Windows |
| 💻 **Interface simple** | Double-clic sur fichier BAT |
| 📖 **Messages pédagogiques** | L'utilisateur comprend ce qu'il fait |
| 🔐 **Sécurisé** | Communication localhost uniquement |
| 🎯 **Fiable** | Service SYSTEM avec droits appropriés |
| 🛠️ **Maintenable** | Scripts lisibles et modifiables |
| 📊 **Split-tunnel expliqué** | Utilisateur comprend la navigation directe |

## 📞 Support

### Questions fréquentes

**Q : Les utilisateurs doivent-ils être dans un groupe spécifique ?**  
R : Non, n'importe quel utilisateur du domaine peut utiliser les fichiers BAT.

**Q : Le service redémarre-t-il après un reboot ?**  
R : Oui, automatiquement via la tâche planifiée.

**Q : Peut-on utiliser cette solution pour d'autres adaptateurs ?**  
R : Oui, modifier le filtre dans `Get-NetAdapter` pour détecter l'adaptateur souhaité.

**Q : Y a-t-il un délai entre l'action et le résultat ?**  
R : Non, l'activation/désactivation est quasi instantanée (< 2 secondes).

**Q : Peut-on déployer via GPO ?**  
R : Oui, exécuter `Solution-Service-HTTP.ps1` via GPO Startup Script (ordinateur).

---

**Version :** 1.0  
**Date :** 5 décembre 2025  
**Auteur :** Script d'automatisation VPN Toggle  
**License :** Usage interne entreprise
