# Guide pour les Agents IA - Scripts RadioManager

> **Document de référence pour la génération et la documentation de scripts**  
> Date de création : 8 décembre 2025  
> Mainteneur : lwilly3

## 📋 Vue d'ensemble du projet

Ce repository contient des scripts d'automatisation pour différents projets et situations :
- **API Audace** : Déploiement d'API FastAPI avec streaming Icecast
- **RadioManager** : Frontend Vite avec déploiement automatisé
- **N8N** : Plateforme d'automatisation de workflows
- **VPN WireGuard** : Solutions VPN pour différents contextes (serveur, routeur, clients)

## 🎯 Standards de documentation

### Structure obligatoire pour chaque script

Chaque script **DOIT** avoir un fichier `.md` associé avec la structure suivante :

```markdown
# [nom-du-script] - Documentation

## 📋 Vue d'ensemble
[Description concise en 2-3 phrases]

## 🎯 Objectif
[Liste à puces des objectifs principaux]

## 📦 Prérequis
[Système, accès, réseau, dépendances]

## ⚙️ Variables de configuration
[Tableau ou bloc de code avec toutes les variables]

## 🚀 Installation
[Étapes numérotées claires et détaillées]

## 📝 Processus d'exécution/installation détaillé
[Explication de chaque étape majeure]

## 🔍 Vérification
[Commandes pour vérifier le bon fonctionnement]

## 📂 Structure des fichiers
[Arborescence des fichiers créés/modifiés]

## 🛠️ Maintenance
[Procédures de mise à jour, logs, sauvegardes]

## 🔒 Sécurité
[Bonnes pratiques et recommandations]

## ⚠️ Dépannage
[Problèmes courants et solutions]

## 📚 Ressources
[Liens vers documentation officielle]

## 📞 Support
[Où trouver de l'aide]

## 📜 Notes importantes
[Avertissements et considérations]
```

### Conventions d'écriture

#### Emojis à utiliser
- 📋 Vue d'ensemble
- 🎯 Objectif
- 📦 Prérequis
- ⚙️ Configuration
- 🚀 Installation
- 📝 Processus
- 🔍 Vérification
- 📂 Fichiers
- 🛠️ Maintenance
- 🔒 Sécurité
- ⚠️ Dépannage
- 📚 Ressources
- 📞 Support
- 📜 Notes
- 🔧 Composants
- 🏗️ Architecture
- 🌐 Accès
- 📊 Monitoring
- 🎨 Personnalisation
- 🔗 Intégration
- 📈 Performances
- 🔄 Mise à jour
- 💾 Sauvegarde
- 🎓 Cas d'usage

#### Style de rédaction

1. **Clarté avant tout** : Écrire pour quelqu'un qui découvre le sujet
2. **Exemples concrets** : Toujours inclure des exemples de commandes
3. **Tableaux** : Utiliser pour les listes de paramètres, composants, etc.
4. **Blocs de code** : Spécifier le langage (```bash, ```powershell, etc.)
5. **Sections courtes** : Paragraphes de 3-5 lignes maximum
6. **Français correct** : Orthographe et grammaire soignées

#### Sections obligatoires pour les scripts Shell/Bash

```bash
#!/bin/bash

# Description du script
# Ce script fait X, Y et Z

# Variables de configuration
VARIABLE_NAME="valeur"  # Description

# Fonction de gestion d'erreur
check_error() {
    if [ $? -ne 0 ]; then
        echo "Erreur: $1"
        exit 1
    fi
}

# Vérification des privilèges
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté avec sudo"
   exit 1
fi
```

#### Sections obligatoires pour les scripts PowerShell

```powershell
<#
.SYNOPSIS
    Description courte du script

.DESCRIPTION
    Description détaillée

.PARAMETER ParameterName
    Description du paramètre

.EXAMPLE
    Exemple d'utilisation

.NOTES
    Auteur: [Nom]
    Date: [Date]
#>

# Vérification des privilèges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Ce script doit être exécuté en tant qu'administrateur"
    exit
}
```

## 🔧 Technologies et plateformes du projet

### Systèmes supportés
- **Ubuntu 24.10** : Scripts API et RadioManager
- **Amazon Linux 2/2023** : Scripts N8N sur EC2
- **Windows 10/11** : Scripts VPN PowerShell
- **MikroTik RouterOS 7.x** : Configuration réseau

### Technologies utilisées
- **Backend** : Python (FastAPI), PostgreSQL
- **Frontend** : Vite, Vue.js/React
- **Streaming** : Icecast2
- **Automation** : N8N
- **VPN** : WireGuard, WG-Easy
- **Proxy** : Nginx
- **SSL** : Let's Encrypt (Certbot)
- **Conteneurisation** : Docker
- **Orchestration** : systemd

## 📁 Structure du repository

```
scripts-radioManager/
├── README.md                               # Vue d'ensemble générale
├── AGENT.md                                # Ce fichier (guide pour agents IA)
│
├── API audace/
│   ├── API-setup_server.sh                # Installation API + Icecast
│   ├── API-setup_server.md                # Documentation
│   ├── config-audaceStream-IceCast.xml    # Configuration Icecast
│   └── config-audaceStream-IceCast.md     # Documentation
│
├── N8N/
│   ├── Script_installation_N8N_sur_EC2_AmazonLinux.sh
│   ├── Script_installation_N8N_sur_EC2_AmazonLinux.md
│   ├── Script_MAJ_N8N.sh
│   └── Script_MAJ_N8N.md
│
├── radioManager/
│   ├── acript-autoStart-radioManager.sh
│   ├── acript-autoStart-radioManager.md
│   ├── init-radioManager-frontend-server.sh
│   ├── init-radioManager-frontend-server.md
│   ├── update_frontend.sh
│   └── update_frontend.md
│
└── VPN wireguard/
    ├── serveur VPN/
    │   ├── install-wg-easy-nginx.sh
    │   └── install-wg-easy-nginx.md
    │
    ├── Routeur Mikrotik/
    │   ├── script-wiregard-client-ikrotik
    │   └── script-wireguard-client-mikrotik.md
    │
    └── script utilisateur domaine AD/
        ├── README.md                       # Documentation détaillée existante
        ├── Solution-Service-HTTP.ps1
        └── Solution-Service-HTTP.md
```

## 🎨 Patterns de scripts récurrents

### Pattern 1 : Installation de service avec systemd

```bash
# 1. Installation des dépendances
apt update && apt install -y [packages]

# 2. Création de l'utilisateur système
useradd -r -s /bin/false service_user

# 3. Configuration de l'application
# [Copie des fichiers, configuration]

# 4. Création du service systemd
cat > /etc/systemd/system/service.service <<EOF
[Unit]
Description=Description du service
After=network.target

[Service]
Type=simple
User=service_user
ExecStart=/chemin/vers/executable
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 5. Activation et démarrage
systemctl daemon-reload
systemctl enable service
systemctl start service
```

### Pattern 2 : Configuration Nginx avec SSL

```bash
# 1. Configuration HTTP (temporaire pour Certbot)
cat > /etc/nginx/sites-available/site <<EOF
server {
    listen 80;
    server_name domain.com;
    
    location / {
        proxy_pass http://localhost:PORT;
    }
}
EOF

# 2. Activation
ln -s /etc/nginx/sites-available/site /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# 3. Obtention du certificat SSL
certbot --nginx -d domain.com \
    --email admin@domain.com \
    --agree-tos --redirect --non-interactive

# 4. Configuration finale HTTPS générée automatiquement par Certbot
```

### Pattern 3 : Script avec variables interactives

```bash
# Déclaration des variables
VARIABLE=""

# Demande interactive si non définie
if [ -z "$VARIABLE" ]; then
    read -p "Entrez la valeur (par défaut: default) : " VARIABLE
    [ -z "$VARIABLE" ] && VARIABLE="default"
fi

# Pour les mots de passe
if [ -z "$PASSWORD" ]; then
    read -s -p "Entrez le mot de passe : " PASSWORD
    echo ""
    [ -z "$PASSWORD" ] && { echo "Erreur: Mot de passe requis"; exit 1; }
fi
```

### Pattern 4 : Vérification et gestion d'erreurs

```bash
# Fonction de vérification
check_error() {
    if [ $? -ne 0 ]; then
        echo "Erreur: $1"
        exit 1
    fi
}

# Utilisation
apt update
check_error "Mise à jour des paquets"

# Ou avec set -e pour arrêt automatique
set -e  # Arrêter le script à la première erreur
```

## 🔐 Bonnes pratiques de sécurité

### À TOUJOURS faire
1. ✅ Vérifier les privilèges (root/admin) en début de script
2. ✅ Demander les mots de passe en mode masqué (`read -s`)
3. ✅ Valider les entrées utilisateur
4. ✅ Utiliser des utilisateurs système dédiés (pas root)
5. ✅ Configurer UFW/firewall pour limiter les ports
6. ✅ Forcer HTTPS avec redirection (Certbot)
7. ✅ Documenter les ports ouverts
8. ✅ Créer des sauvegardes avant modifications majeures

### À ÉVITER
1. ❌ Mots de passe en clair dans les scripts
2. ❌ Exécuter des services en tant que root
3. ❌ Désactiver SELinux/AppArmor sans raison
4. ❌ Ouvrir tous les ports du firewall
5. ❌ Ignorer les certificats SSL invalides
6. ❌ Utiliser `chmod 777` sur des fichiers sensibles
7. ❌ Oublier de valider les URLs/domaines fournis

## 🚀 Processus de création d'un nouveau script

### 1. Planification
- [ ] Définir l'objectif précis
- [ ] Lister les prérequis
- [ ] Identifier les technologies nécessaires
- [ ] Prévoir les cas d'erreur

### 2. Développement
- [ ] Créer le fichier script (.sh, .ps1, etc.)
- [ ] Ajouter les commentaires d'en-tête
- [ ] Implémenter les vérifications préalables
- [ ] Ajouter la gestion d'erreurs
- [ ] Tester sur un environnement propre

### 3. Documentation
- [ ] Créer le fichier .md correspondant
- [ ] Suivre la structure standardisée
- [ ] Ajouter des exemples concrets
- [ ] Documenter tous les paramètres
- [ ] Inclure des captures d'écran si pertinent

### 4. Validation
- [ ] Tester le script sur système vierge
- [ ] Vérifier tous les chemins de code (succès/erreur)
- [ ] S'assurer que la documentation est claire
- [ ] Valider les commandes de vérification
- [ ] Tester le processus de dépannage

### 5. Intégration
- [ ] Placer dans le bon dossier du repository
- [ ] Mettre à jour le README.md principal si nécessaire
- [ ] Ajouter au système de versionnement Git
- [ ] Notifier les utilisateurs des nouveaux scripts

## 📊 Métriques de qualité

Un bon script doit avoir :

### Score de documentation (sur 10)
- Vue d'ensemble claire : 1 point
- Prérequis exhaustifs : 1 point
- Instructions d'installation : 2 points
- Exemples de code : 1 point
- Section dépannage : 2 points
- Commandes de vérification : 1 point
- Ressources externes : 1 point
- Mise en forme professionnelle : 1 point

**Score minimal acceptable : 7/10**

### Score de robustesse (sur 10)
- Gestion des erreurs : 2 points
- Vérification des prérequis : 2 points
- Messages d'erreur clairs : 1 point
- Logging approprié : 1 point
- Rollback possible : 2 points
- Tests des dépendances : 1 point
- Validation des entrées : 1 point

**Score minimal acceptable : 7/10**

## 🔄 Workflow Git recommandé

### Pour ajouter un nouveau script

```bash
# 1. Créer une branche
git checkout -b feature/nouveau-script

# 2. Ajouter les fichiers
git add nouveau-script.sh nouveau-script.md

# 3. Commit avec message descriptif
git commit -m "feat: Ajouter script d'installation [technologie]

- Installation automatisée de [composant]
- Configuration [service]
- Documentation complète
- Tests sur Ubuntu 24.10"

# 4. Push et créer une PR
git push origin feature/nouveau-script
```

### Messages de commit recommandés
- `feat:` Nouveau script ou fonctionnalité
- `fix:` Correction de bug
- `docs:` Mise à jour de documentation
- `refactor:` Refactorisation sans changement fonctionnel
- `test:` Ajout de tests
- `chore:` Maintenance (mise à jour dépendances, etc.)

## 🎓 Exemples de référence

### Scripts les plus complets du repository
1. **API-setup_server.sh** : Installation complexe multi-services
2. **install-wg-easy-nginx.sh** : Docker + Nginx + SSL
3. **Solution-Service-HTTP.ps1** : Script Windows avancé

### Documentations les plus détaillées
1. **Solution-Service-HTTP.md** : Documentation technique + pédagogique
2. **install-wg-easy-nginx.md** : Architecture, monitoring, sécurité
3. **API-setup_server.md** : Processus détaillé étape par étape

**Consigne pour les agents : S'inspirer de ces références pour maintenir la cohérence.**

## 📝 Checklist finale avant soumission

Avant d'ajouter un nouveau script au repository, vérifier :

### Script
- [ ] Shebang correct (`#!/bin/bash` ou équivalent)
- [ ] Commentaires d'en-tête présents
- [ ] Variables documentées
- [ ] Gestion d'erreurs implémentée
- [ ] Vérification des privilèges
- [ ] Messages utilisateur clairs
- [ ] Testé sur système propre

### Documentation
- [ ] Fichier .md créé avec le même nom de base
- [ ] Toutes les sections obligatoires présentes
- [ ] Emojis utilisés correctement
- [ ] Exemples de code fonctionnels
- [ ] Tableaux bien formatés
- [ ] Liens externes valides
- [ ] Pas de fautes d'orthographe majeures

### Repository
- [ ] Placé dans le bon dossier
- [ ] Nommage cohérent avec les autres scripts
- [ ] README.md principal mis à jour si pertinent
- [ ] AGENT.md mis à jour si nouveaux patterns

## 🌟 Principes directeurs

### Pour les agents IA générant du code

1. **Cohérence** : Suivre les patterns existants du repository
2. **Clarté** : Code lisible > Code court
3. **Sécurité** : Ne jamais compromettre la sécurité pour la simplicité
4. **Documentation** : Chaque ligne de code complexe doit être commentée
5. **Testabilité** : Fournir des moyens de vérifier le bon fonctionnement
6. **Résilience** : Prévoir et gérer les cas d'erreur
7. **Pédagogie** : La documentation doit enseigner, pas juste lister

### Pour les utilisateurs du repository

Ce repository est conçu pour être utilisé par :
- **DevOps** : Automatisation de déploiements
- **Administrateurs système** : Configuration serveurs
- **Développeurs** : Mise en place d'environnements
- **Utilisateurs avancés** : Solutions personnalisées

Chaque script doit être compréhensible par quelqu'un ayant des connaissances de base en Linux/Windows.

## 📞 Contact et contribution

### Maintainer
- **GitHub** : @lwilly3
- **Repository** : https://github.com/lwilly3/scripts-radioManager

### Contribution
Les contributions sont les bienvenues ! Veuillez :
1. Fork le repository
2. Créer une branche feature
3. Suivre les standards de ce document
4. Soumettre une Pull Request avec description détaillée

---

**Version de ce guide** : 1.0  
**Dernière mise à jour** : 8 décembre 2025  
**Compatibilité** : Tous les scripts du repository scripts-radioManager

> 💡 **Note pour les agents IA** : Ce document est votre référence absolue. En cas de doute, privilégiez toujours la clarté et la sécurité. La cohérence avec les scripts existants est primordiale.
