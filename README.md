# scripts-radioManager

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/lwilly3/scripts-radioManager/graphs/commit-activity)

> **Collection de scripts d'automatisation pour déploiement et gestion d'infrastructures**

Bienvenue dans le dépôt **scripts-radioManager** ! Ce repository contient une collection de scripts d'automatisation pour différents projets : déploiement d'API, streaming audio, automatisation de workflows, et solutions VPN. Chaque script est accompagné d'une documentation complète pour faciliter la prise en main.

## 📋 Table des matières

- [Vue d'ensemble](#-vue-densemble)
- [🚀 Quick Start (Installation rapide)](#-quick-start-installation-rapide)
- [Structure du repository](#-structure-du-repository)
- [Projets disponibles](#-projets-disponibles)
  - [API Audace](#1-api-audace---streaming--api)
  - [RadioManager Frontend](#2-radiomanager---frontend-vite)
  - [N8N Automation](#3-n8n---automatisation-de-workflows)
  - [Solutions Docker](#4-solutions-docker-)
  - [VPN WireGuard](#5-vpn-wireguard)
- [📊 Tableau comparatif des solutions](#-tableau-comparatif-des-solutions)
- [🎯 Cas d'usage et recommandations](#-cas-dusage-et-recommandations)
- [Documentation](#-documentation)
- [Prérequis généraux](#-prérequis-généraux)
- [🔄 Mises à jour et maintenance](#-mises-à-jour-et-maintenance)
- [🔒 Sécurité et bonnes pratiques](#-sécurité-et-bonnes-pratiques)
- [Guide de contribution](#-guide-de-contribution)
- [Dépannage](#-dépannage-général)
- [📈 Roadmap](#-roadmap)
- [Support](#-support)

## 🎯 Vue d'ensemble

Ce repository regroupe des scripts pour :
- **Déploiement d'API** : FastAPI + PostgreSQL + Icecast
- **Frontend moderne** : Vite + Node.js + Nginx
- **Automatisation** : N8N sur EC2 Amazon Linux
- **Solutions Docker** : Conteneurs pour RadioManager et API Audace
- **Solutions VPN** : WireGuard pour serveur, routeur MikroTik et clients Windows

**Systèmes supportés** : Ubuntu 24.10, Amazon Linux 2/2023, Windows 10/11, MikroTik RouterOS 7.x

**Fuseau horaire par défaut** : Africa/Douala (UTC+1, Cameroun)

## 📁 Structure du repository

```
scripts-radioManager/
├── README.md                        # Ce fichier
├── AGENT.md                         # Guide pour agents IA et contributeurs
│
├── API audace/                      # 🎵 Streaming audio + API
│   ├── API-setup_server.sh
│   ├── API-setup_server.md
│   ├── config-audaceStream-IceCast.xml
│   └── config-audaceStream-IceCast.md
│
├── radioManager/                    # 🌐 Frontend Vite
│   ├── init-radioManager-frontend-server.sh
│   ├── init-radioManager-frontend-server.md
│   ├── acript-autoStart-radioManager.sh
│   ├── acript-autoStart-radioManager.md
│   ├── update_frontend.sh
│   └── update_frontend.md
│
├── N8N/                            # 🔄 Automatisation workflows
│   ├── Script_installation_N8N_sur_EC2_AmazonLinux.sh
│   ├── Script_installation_N8N_sur_EC2_AmazonLinux.md
│   ├── Script_MAJ_N8N.sh
│   └── Script_MAJ_N8N.md
│
├── Docker/                         # 🐳 Solutions Docker
│   ├── radioManager-docker/
│   │   ├── README.md
│   │   ├── Dockerfile
│   │   ├── docker-compose.yml
│   │   └── nginx.conf
│   ├── api-audace-docker/
│   │   ├── README.md
│   │   ├── docker-compose.yml
│   │   └── nginx/
│   │       └── nginx.conf
│   └── quick-prepare-vps-for-dockploy/    # ⭐ RÉORGANISÉ
│       ├── README.md                       # Guide principal
│       ├── quick-prepare-vps.sh            # Script de préparation
│       ├── docs/
│       │   ├── USAGE.md                    # Guide d'utilisation détaillé
│       │   ├── PREPARATION.md              # Guide préparation complète
│       │   ├── POST-INSTALL.md             # État post-installation
│       │   ├── FAIL2BAN-EMAIL.md           # Configuration Fail2ban
│       │   ├── VARIABLES.md                # Guide variables d'env
│       │   └── MIGRATION.md                # Guide de migration
│       └── examples/
│           └── .env.example                # Template configuration
│
└── VPN wireguard/                  # 🔒 Solutions VPN
    ├── serveur VPN/
    │   ├── install-wg-easy-nginx.sh
    │   └── install-wg-easy-nginx.md
    ├── Routeur Mikrotik/
    │   ├── script-wiregard-client-ikrotik
    │   └── script-wireguard-client-mikrotik.md
    └── script utilisateur domaine AD/
        ├── README.md
        ├── Solution-Service-HTTP.ps1
        └── Solution-Service-HTTP.md
```

## 🚀 Projets disponibles

### 1. API Audace - Streaming + API

**Description** : Déploiement complet d'une infrastructure backend avec API FastAPI, streaming Icecast et base PostgreSQL.

**Composants** :
- FastAPI (API REST)
- PostgreSQL (base de données)
- Icecast2 (streaming audio)
- Nginx (reverse proxy)
- SSL Let's Encrypt

**Documentation** : [`API audace/API-setup_server.md`](API%20audace/API-setup_server.md)

**Quick Start** :
```bash
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/API%20audace/API-setup_server.sh
chmod +x API-setup_server.sh
sudo bash API-setup_server.sh
```

**Résultat** :
- Icecast : `https://radio.audace.ovh/stream.mp3`
- API : `https://api.radio.audace.ovh`

---

### 2. RadioManager - Frontend Vite

**Description** : Configuration de serveurs pour héberger des applications frontend modernes basées sur Vite.

**Scripts disponibles** :
- **Installation initiale** : Configure Nginx, Node.js, SSL
- **Démarrage automatique** : Service systemd pour haute disponibilité
- **Mise à jour** : Déploiement depuis Git avec compilation

**Documentation** :
- Installation : [`radioManager/init-radioManager-frontend-server.md`](radioManager/init-radioManager-frontend-server.md)
- Auto-start : [`radioManager/acript-autoStart-radioManager.md`](radioManager/acript-autoStart-radioManager.md)
- Mise à jour : [`radioManager/update_frontend.md`](radioManager/update_frontend.md)

**Quick Start** :
```bash
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/radioManager/init-radioManager-frontend-server.sh
chmod +x init-radioManager-frontend-server.sh
sudo bash init-radioManager-frontend-server.sh
```

**Résultat** : Site accessible sur `https://app.radioaudace.com`

---

### 3. N8N - Automatisation de workflows

**Description** : Installation et maintenance de N8N (alternative open-source à Zapier) sur instances EC2 Amazon Linux.

**Fonctionnalités** :
- Installation complète avec Docker ou npm
- Configuration Nginx + SSL
- Script de mise à jour avec sauvegarde
- Intégration avec plus de 400 services

**Documentation** :
- Installation : [`N8N/Script_installation_N8N_sur_EC2_AmazonLinux.md`](N8N/Script_installation_N8N_sur_EC2_AmazonLinux.md)
- Mise à jour : [`N8N/Script_MAJ_N8N.md`](N8N/Script_MAJ_N8N.md)

**Quick Start** :
```bash
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/N8N/Script_installation_N8N_sur_EC2_AmazonLinux.sh
chmod +x Script_installation_N8N_sur_EC2_AmazonLinux.sh
sudo bash Script_installation_N8N_sur_EC2_AmazonLinux.sh
```

**Résultat** : Interface N8N accessible sur `https://n8n.votre-domaine.com`

---

### 4. Solutions Docker 🐳

**Description** : Déploiement des applications RadioManager et API Audace dans des conteneurs Docker pour une meilleure portabilité et isolation.

#### 4.1 RadioManager Frontend (Docker)

Déploiement du frontend Vite dans un conteneur avec Nginx.

**Avantages** :
- ✅ Déploiement reproductible
- ✅ Isolation complète de l'environnement
- ✅ Facilité de mise à jour et rollback
- ✅ Scalabilité horizontale simple
- ✅ Idéal pour développement et production

**Documentation** : [`Docker/radioManager-docker/README.md`](Docker/radioManager-docker/README.md)

**Quick Start** :
```bash
cd Docker/radioManager-docker
docker-compose up -d
```

#### 4.2 API Audace Stack (Docker)

Stack complète avec FastAPI, PostgreSQL, Icecast et Nginx dans des conteneurs orchestrés.

**Documentation** : [`Docker/api-audace-docker/README.md`](Docker/api-audace-docker/README.md)

**Quick Start** :
```bash
cd Docker/api-audace-docker
docker-compose up -d
```

**Résultat** : Tous les services accessibles via Nginx comme reverse proxy.

#### 4.3 Déploiement avec Dockploy 🚀

Dockploy est une plateforme d'hébergement moderne qui simplifie le déploiement d'applications Docker avec interface web intuitive.

**Avantages de Dockploy** :
- ✅ Interface web élégante et moderne
- ✅ Déploiement en un clic depuis Git
- ✅ SSL automatique avec Let's Encrypt
- ✅ Monitoring intégré (CPU, RAM, réseau)
- ✅ Gestion multi-projets et multi-domaines
- ✅ Logs en temps réel
- ✅ Rollback instantané
- ✅ Variables d'environnement sécurisées
- ✅ Support Docker Compose natif
- ✅ Webhooks pour CI/CD automatique

**Cas d'usage recommandés** :
- 🎯 Équipes qui veulent une interface graphique
- 🎯 Projets multiples sur un même serveur
- 🎯 Besoin de monitoring intégré
- 🎯 Déploiements fréquents depuis Git
- 🎯 Gestion simplifiée des certificats SSL

**Documentation** : [`Docker/quick-prepare-vps-for-dockploy/README.md`](Docker/quick-prepare-vps-for-dockploy/README.md)

**Quick Start - Installation Dockploy** :
```bash
# Installer Dockploy sur votre serveur
curl -sSL https://dokploy.com/install.sh | sh

# Accéder à l'interface : https://votre-ip:3000
```

**Quick Start - Déployer RadioManager** :
1. Créer un nouveau projet dans Dockploy
2. Connecter votre repository Git
3. Configurer le domaine et les variables
4. Déployer en un clic !

**Résultat** : Application déployée avec monitoring, logs et SSL automatique.

---

### 5. VPN WireGuard

**Description** : Solutions VPN WireGuard pour différents cas d'usage.

#### 5.1 Serveur VPN (WG-Easy)

Installation d'un serveur VPN avec interface web de gestion.

**Documentation** : [`VPN wireguard/serveur VPN/install-wg-easy-nginx.md`](VPN%20wireguard/serveur%20VPN/install-wg-easy-nginx.md)

```bash
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/VPN%20wireguard/serveur%20VPN/install-wg-easy-nginx.sh
chmod +x install-wg-easy-nginx.sh
sudo bash install-wg-easy-nginx.sh
```

**Résultat** : Interface WG-Easy sur `https://vps.monassurance.net`

#### 5.2 Client MikroTik

Configuration d'un routeur MikroTik en client VPN WireGuard.

**Documentation** : [`VPN wireguard/Routeur Mikrotik/script-wireguard-client-mikrotik.md`](VPN%20wireguard/Routeur%20Mikrotik/script-wireguard-client-mikrotik.md)

**Utilisation** : Copier-coller les commandes dans le terminal RouterOS via Winbox ou SSH.

#### 5.3 Client Windows (sans droits admin)

Solution pour utilisateurs de domaine Active Directory sans privilèges administrateur.

**Documentation** : 
- [`VPN wireguard/script utilisateur domaine AD/README.md`](VPN%20wireguard/script%20utilisateur%20domaine%20AD/README.md)
- [`VPN wireguard/script utilisateur domaine AD/Solution-Service-HTTP.md`](VPN%20wireguard/script%20utilisateur%20domaine%20AD/Solution-Service-HTTP.md)

```powershell
# Exécuter en tant qu'Administrateur (une seule fois)
powershell.exe -ExecutionPolicy Bypass -File "Solution-Service-HTTP.ps1"
```

**Résultat** : Fichiers BAT permettant aux utilisateurs d'activer/désactiver le VPN sans droits admin.

---

## 📖 Documentation

Chaque script dispose d'une documentation complète au format Markdown (`.md`) détaillant :
- 📋 Vue d'ensemble et objectifs
- 📦 Prérequis système
- ⚙️ Variables de configuration
- 🚀 Instructions d'installation pas à pas
- 🔍 Vérifications post-installation
- 🛠️ Maintenance et mises à jour
- ⚠️ Dépannage complet
- 📚 Ressources et liens utiles

**⚠️ Consultez toujours le fichier `.md` associé à chaque script avant utilisation.**

## 🔧 Prérequis généraux

### Pour les scripts Ubuntu/Debian
- ✅ Serveur Ubuntu 24.10 (ou Debian récent)
- ✅ Accès root ou privilèges sudo
- ✅ Connexion Internet stable
- ✅ Nom(s) de domaine pointant vers l'IP du serveur (pour SSL)

### Pour les scripts Amazon Linux
- ✅ Instance EC2 avec Amazon Linux 2 ou 2023
- ✅ Security Groups configurés (ports 22, 80, 443)
- ✅ Accès SSH avec clé

### Pour les scripts Windows
- ✅ Windows 10/11 ou Windows Server
- ✅ PowerShell 5.1+
- ✅ Droits administrateur (installation uniquement)

### Pour la configuration MikroTik
- ✅ Routeur avec RouterOS 7.x ou supérieur
- ✅ Accès Winbox, WebFig ou SSH
- ✅ Clés WireGuard générées depuis le serveur

## 🚀 Quick Start (Installation rapide)

### Déploiement complet en 10 minutes

Vous voulez tester rapidement ? Voici la méthode la plus rapide pour avoir une stack complète fonctionnelle :

#### Option 1 : Docker Compose (Recommandé pour débuter)

```bash
# 1. Cloner le repository
git clone https://github.com/lwilly3/scripts-radioManager.git
cd scripts-radioManager/Docker

# 2. Choisir votre stack
cd api-audace-docker  # Pour API + Database + Icecast
# OU
cd radioManager-docker  # Pour Frontend uniquement

# 3. Configurer les variables
cp .env.example .env
nano .env  # Remplir les variables obligatoires

# 4. Lancer la stack
docker-compose up -d

# 5. Vérifier que tout fonctionne
docker-compose ps
docker-compose logs -f
```

**Temps estimé** : ⏱️ 5-10 minutes  
**Compétences requises** : Docker de base  
**Résultat** : Stack complète opérationnelle avec SSL auto

---

#### Option 2 : Dockploy (Interface graphique)

```bash
# 1. Préparer le serveur (sécurité + optimisations)
# Timezone par défaut : Africa/Douala (Cameroun, UTC+1)
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/Docker/quick-prepare-vps-for-dockploy/quick-prepare-vps.sh
sudo bash quick-prepare-vps.sh

# 2. Installer Dokploy
curl -sSL https://dokploy.com/install.sh | sh

# 3. Accéder à l'interface web
https://votre-ip:3000

# 4. Créer un nouveau projet
- Cliquer "New Project"
- Connecter votre repository Git
- Configurer les variables d'environnement
- Déployer en un clic !
```

**Temps estimé** : ⏱️ 10 minutes  
**Compétences requises** : Aucune (interface graphique)  
**Résultat** : Monitoring, logs, SSL automatique

**📋 Documentation détaillée** :
- [Guide Quick Prepare VPS](Docker/quick-prepare-vps-for-dockploy/README.md) 📚 **Principal**
- [Guide d'utilisation](Docker/quick-prepare-vps-for-dockploy/docs/USAGE.md) ⭐ **Recommandé**
- [Préparation VPS complète](Docker/quick-prepare-vps-for-dockploy/docs/PREPARATION.md)
- [État post-installation](Docker/quick-prepare-vps-for-dockploy/docs/POST-INSTALL.md)
- [Configuration Fail2ban](Docker/quick-prepare-vps-for-dockploy/docs/FAIL2BAN-EMAIL.md)
- [Variables d'environnement](Docker/quick-prepare-vps-for-dockploy/docs/VARIABLES.md)

---

#### Option 3 : Scripts Bash (Installation classique)

```bash
# API Backend complet
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/API%20audace/API-setup_server.sh
chmod +x API-setup_server.sh
sudo bash API-setup_server.sh

# Frontend Vue.js
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/radioManager/init-radioManager-frontend-server.sh
chmod +x init-radioManager-frontend-server.sh
sudo bash init-radioManager-frontend-server.sh
```

**Temps estimé** : ⏱️ 15-20 minutes  
**Compétences requises** : Linux de base  
**Résultat** : Installation directe sur le serveur (sans Docker)

---

### Première connexion

Après déploiement, accédez aux interfaces :

- **Frontend** : https://app.radioaudace.com
- **API Docs** : https://api.radio.audace.ovh/docs
- **Stream Audio** : https://radio.audace.ovh/stream.mp3
- **Icecast Admin** : https://radio.audace.ovh/admin

**Identifiants par défaut** (à changer immédiatement) :
- Voir la documentation spécifique de chaque projet

---

## 📊 Tableau comparatif des solutions

| Critère | Scripts Bash | Docker Compose | **Dockploy** | Installation manuelle |
|---------|--------------|----------------|--------------|----------------------|
| **Facilité d'installation** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **Temps d'installation** | 15-20 min | 5-10 min | **5 min** | 30-60 min |
| **Compétences requises** | Linux basique | Docker basique | **Aucune** | Linux avancé |
| **Interface graphique** | ❌ | ❌ | ✅ | ❌ |
| **Monitoring intégré** | ❌ | Logs uniquement | ✅ | À configurer |
| **SSL automatique** | ✅ Certbot | À configurer | ✅ | À configurer |
| **Mise à jour** | Script | Rebuild image | **1 clic** | Manuel |
| **Rollback** | Manuel | Tag image | **1 clic** | Backup/restore |
| **Multi-environnements** | Scripts séparés | docker-compose séparés | ✅ Natif | Configuration manuelle |
| **Isolation** | ❌ | ✅ | ✅ | ❌ |
| **Scalabilité** | Difficile | Moyenne | ✅ Facile | Difficile |
| **Backup** | À configurer | Volumes Docker | À configurer | À configurer |
| **Ressources (RAM)** | 1-2 GB | 2-4 GB | 2-4 GB | 1-2 GB |
| **Portabilité** | ❌ | ✅ | ✅ | ❌ |
| **Courbe d'apprentissage** | ⭐⭐⭐ | ⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐⭐ |
| **Coût (infrastructure)** | VPS $10/mois | VPS $15/mois | VPS $15/mois | VPS $10/mois |
| **Support communautaire** | ✅ | ✅ | ✅ | ❌ |

### 🏆 Nos recommandations

| Profil | Solution recommandée | Pourquoi ? |
|--------|---------------------|------------|
| **Débutant** | Dockploy | Interface graphique, pas de ligne de commande |
| **DevOps junior** | Docker Compose | Bon équilibre simplicité/contrôle |
| **Sysadmin expérimenté** | Scripts Bash | Contrôle total, personnalisation maximale |
| **Équipe de dev** | Dockploy | Collaboration facile, monitoring intégré |
| **Agence web** | Dockploy | Multi-clients, scaling facile |
| **Serveur limité (<2GB RAM)** | Scripts Bash | Moins de overhead Docker |
| **Production critique** | Docker Compose | Isolation, rollback, haute disponibilité |
| **POC/Test rapide** | Dockploy | Installation en 5 min |

---

## 🎯 Cas d'usage et recommandations

### Cas 1 : Radio locale communautaire

**Besoin** : Diffuser un stream audio avec une interface web simple

**Solution recommandée** :
```bash
# Installation scripts bash
API Audace (Icecast + API) + RadioManager Frontend
Temps : 30 min
Coût : VPS $10/mois
```

**Architecture** :
```
VPS Ubuntu 24.10
├── Icecast (streaming)
├── API FastAPI (gestion contenu)
├── Frontend Vue.js (interface utilisateurs)
└── PostgreSQL (base de données)
```

**Utilisateurs simultanés supportés** : 100-500

---

### Cas 2 : Plateforme SaaS multi-radios

**Besoin** : Héberger plusieurs radios avec isolation et scaling

**Solution recommandée** :
```bash
# Dockploy avec multi-projets
Chaque radio = 1 projet Dockploy
Temps : 10 min par radio
Coût : VPS $30-50/mois
```

**Architecture** :
```
Serveur avec Dockploy
├── Radio 1 (containers isolés)
├── Radio 2 (containers isolés)
├── Radio 3 (containers isolés)
└── Base PostgreSQL partagée (optionnel)
```

**Radios supportées** : 5-10 par serveur

---

### Cas 3 : Environnements Dev/Staging/Prod

**Besoin** : Développement en équipe avec CI/CD

**Solution recommandée** :
```bash
# Docker Compose + GitHub Actions
3 serveurs séparés ou 1 serveur avec 3 stacks
Temps : 1h de setup initial
Coût : VPS $20-30/mois
```

**Workflow** :
```
Dev (localhost) → Push Git → GitHub Actions
                              ↓
                         Staging (tests auto)
                              ↓
                    Production (après validation)
```

---

### Cas 4 : Agence avec plusieurs clients

**Besoin** : Gérer 10+ sites clients sur un serveur

**Solution recommandée** :
```bash
# Dockploy Interface
1 serveur avec Dockploy
Chaque client = 1 projet
Temps : 5 min par client
Coût : VPS $40-60/mois
```

**Avantages** :
- ✅ Interface centralisée
- ✅ SSL automatique pour tous
- ✅ Monitoring global
- ✅ Facturation simplifiée

---

## 🔄 Mises à jour et maintenance

### Stratégie de mise à jour

#### Pour les scripts Bash

```bash
# 1. Vérifier la version actuelle
systemctl status api
journalctl -u api -n 20

# 2. Télécharger la nouvelle version du script
cd /opt/scripts-radioManager
git pull origin main

# 3. Exécuter le script de mise à jour
sudo bash radioManager/update_frontend.sh

# 4. Vérifier après mise à jour
systemctl status radiomanager-frontend
curl -I https://app.radioaudace.com
```

**Fréquence recommandée** : Mensuelle ou à chaque nouvelle release

---

#### Pour Docker Compose

```bash
# 1. Sauvegarder les données
docker-compose exec postgres pg_dump -U audace_user audace_db > backup.sql

# 2. Mettre à jour les images
docker-compose pull

# 3. Reconstruire et redémarrer
docker-compose up -d --build

# 4. Vérifier les logs
docker-compose logs -f --tail=50
```

**Fréquence recommandée** : Bimensuelle ou à chaque security patch

---

#### Pour Dockploy

```bash
# Via l'interface web
Project → Deployments → Latest → Deploy

# Ou via webhook automatique (recommandé)
GitHub → Settings → Webhooks → Ajouter webhook Dockploy
```

**Fréquence** : Automatique à chaque `git push` (CI/CD)

---

### Calendrier de maintenance recommandé

| Tâche | Fréquence | Temps estimé |
|-------|-----------|--------------|
| **Mise à jour système** (apt update) | Hebdomadaire | 5 min |
| **Mise à jour applications** | Mensuelle | 15-30 min |
| **Backup base de données** | Quotidienne (automatisée) | 0 min |
| **Vérification logs** | Hebdomadaire | 10 min |
| **Test de restauration** | Trimestrielle | 30 min |
| **Rotation secrets** (JWT, passwords) | Annuelle | 1h |
| **Audit de sécurité** | Semestrielle | 2-3h |
| **Renouvellement SSL** | Automatique | 0 min |

---

### Scripts de maintenance automatique

Créez un cron job pour automatiser certaines tâches :

```bash
# Éditer le crontab
sudo crontab -e

# Ajouter ces lignes

# Backup quotidien à 2h du matin
0 2 * * * docker-compose exec postgres pg_dump -U audace_user audace_db > /backup/db_$(date +\%Y\%m\%d).sql

# Nettoyage des vieux backups (>30 jours)
0 3 * * * find /backup -name "db_*.sql" -mtime +30 -delete

# Mise à jour système hebdomadaire (dimanche 3h)
0 3 * * 0 apt update && apt upgrade -y && apt autoremove -y

# Redémarrage mensuel (1er du mois à 4h)
0 4 1 * * /sbin/reboot
```

---

## 🔒 Sécurité et bonnes pratiques

### Checklist de sécurité avant production

#### Niveau 1 : Essentiel (Obligatoire)

- [ ] **Mots de passe forts** (min 16 caractères, lettres+chiffres+symboles)
- [ ] **SSL activé** sur tous les domaines (HTTPS uniquement)
- [ ] **Pare-feu configuré** (UFW ou iptables)
- [ ] **Ports non nécessaires fermés** (ne laisser que 22, 80, 443)
- [ ] **SSH sécurisé** (désactiver root login, clés SSH uniquement)
- [ ] **Variables d'environnement** (.env dans .gitignore)
- [ ] **CORS configuré** (pas de wildcard `*` en production)
- [ ] **JWT secrets rotatés** (différents dev/prod)
- [ ] **Base de données** (utilisateur non-root, permissions limitées)
- [ ] **Backups quotidiens** automatisés et testés

#### Niveau 2 : Recommandé

- [ ] **Fail2ban installé** (protection brute force SSH)
- [ ] **Monitoring actif** (Prometheus, Grafana, ou Dockploy)
- [ ] **Logs centralisés** (rotation, rétention limitée)
- [ ] **Rate limiting API** (limiter requêtes par IP)
- [ ] **Health checks** configurés pour tous les services
- [ ] **Alertes email/Slack** en cas de downtime
- [ ] **Certificats SSL** avec renouvellement auto vérifié
- [ ] **Utilisateurs système** dédiés (pas de root)
- [ ] **Docker secrets** (pour variables sensibles)
- [ ] **WAF** (Web Application Firewall) si exposé publiquement

#### Niveau 3 : Avancé (Production critique)

- [ ] **Audit de sécurité** régulier (Lynis, OpenVAS)
- [ ] **Intrusion detection** (AIDE, OSSEC)
- [ ] **2FA activé** sur tous les comptes admin
- [ ] **VPN** pour accès admin (pas de SSH public)
- [ ] **Segmentation réseau** (VLAN, Docker networks)
- [ ] **DDoS protection** (Cloudflare, AWS Shield)
- [ ] **Chiffrement at-rest** (disques chiffrés)
- [ ] **Conformité RGPD** (si données européennes)
- [ ] **Pen testing** annuel
- [ ] **Plan de reprise d'activité** (DRP) documenté et testé

---

### Commandes de sécurité utiles

```bash
# Audit rapide avec Lynis
sudo apt install lynis
sudo lynis audit system

# Vérifier les ports ouverts
sudo ss -tlnp

# Tester la configuration SSL
curl -I https://api.radio.audace.ovh
sslscan api.radio.audace.ovh

# Vérifier les certificats
sudo certbot certificates

# Logs de tentatives SSH échouées
sudo grep "Failed password" /var/log/auth.log | tail -20

# Scanner les vulnérabilités (mise à jour système)
sudo apt update
apt list --upgradable

# Configurer les notifications email Fail2ban (recommandé)
# Voir : Docker/quick-prepare-vps-for-dockploy/docs/FAIL2BAN-EMAIL.md
```

---

### Durcissement SSH (Hardening)

```bash
# Éditer la config SSH
sudo nano /etc/ssh/sshd_config

# Recommandations :
PermitRootLogin no                    # Désactiver login root
PasswordAuthentication no             # Uniquement clés SSH
PubkeyAuthentication yes              # Activer clés publiques
Port 2222                             # Changer le port (optionnel)
MaxAuthTries 3                        # Limiter tentatives
ClientAliveInterval 300               # Timeout inactivité
ClientAliveCountMax 2
AllowUsers votre_utilisateur          # Whitelist utilisateurs

# Redémarrer SSH
sudo systemctl restart sshd
```

---

## 📈 Roadmap

### Version actuelle : 2.0 (Décembre 2024)

✅ Scripts bash pour Ubuntu 24.10  
✅ Solutions Docker (Compose + Dockploy)  
✅ Documentation complète  
✅ Support RadioManager-SaaS + API Audace  
✅ VPN WireGuard (serveur + clients)  
✅ N8N Automation

### Version 2.1 (Q1 2025) - Planifiée

🔄 **En cours** :
- [ ] Support Kubernetes (Helm charts)
- [ ] Scripts pour Amazon Linux 2023
- [ ] Monitoring avec Prometheus + Grafana
- [ ] Solution de backup S3 automatique
- [ ] Scripts Terraform pour infra as code

📝 **Documentation** :
- [ ] Vidéos tutorielles YouTube
- [ ] Guide migration vers Docker
- [ ] Exemples de CI/CD complets

### Version 2.2 (Q2 2025) - Envisagée
- [ ] Support multi-cloud (AWS, Azure, GCP)
- [ ] High Availability (HA) avec load balancing
- [ ] Intégration Vault (secrets management)
- [ ] Auto-scaling basé sur métriques
- [ ] CDN integration (Cloudflare, Fastly)
- [ ] Support ARM64 (Raspberry Pi, Apple Silicon)

### Version 3.0 (Q4 2025) - Vision
- [ ] Interface web d'administration complète
- [ ] Marketplace de plugins
- [ ] Support multi-langues (EN, ES, DE)
- [ ] Dashboard unifié multi-projets
- [ ] API REST pour gestion programmatique

---

## Contribution

Vous avez une idée ? Participez !

1. **Consulter les issues** : [github.com/lwilly3/scripts-radioManager/issues](https://github.com/lwilly3/scripts-radioManager/issues)
2. **Proposer une feature** : Créer une issue avec le label `enhancement`
3. **Voter pour une feature** : 👍 sur l'issue correspondante
4. **Contribuer au code** : Pull request avec tests et documentation

**Guide de contribution** : [`AGENT.md`](AGENT.md)

---

## 📞 Support

### Ressources
- **Issues GitHub** : [github.com/lwilly3/scripts-radioManager/issues](https://github.com/lwilly3/scripts-radioManager/issues)
- **Documentation** : Fichiers `.md` dans chaque dossier
- **Discussions** : [github.com/lwilly3/scripts-radioManager/discussions](https://github.com/lwilly3/scripts-radioManager/discussions)
- **Guide de contribution** : [`AGENT.md`](AGENT.md)
- **Changelog** : [CHANGELOG.md](CHANGELOG.md)
- **Forum communautaire** : [forum.radioaudace.com](https://forum.radioaudace.com)

### Ressources complémentaires

- **Wiki** : [github.com/lwilly3/scripts-radioManager/wiki](https://github.com/lwilly3/scripts-radioManager/wiki)

**Q: Quelle solution choisir entre Docker et scripts bash ?**  
R: Docker pour isolation et portabilité, scripts bash pour performances et simplicité sur serveur dédié.

**Q: Combien d'auditeurs simultanés peut supporter un VPS à $10/mois ?**  
R: Environ 100-200 auditeurs avec un stream 128kbps (≈2.5 MB/s).

**Q: Le projet est-il maintenu activement ?**  
R: Oui ! Vérifiez l'activité sur [GitHub Activity](https://github.com/lwilly3/scripts-radioManager/graphs/commit-activity)

---

<div align="center">**Version** : 2.0  
**Dernière mise à jour** : Décembre 2024  </div>
