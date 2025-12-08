# scripts-radioManager

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/lwilly3/scripts-radioManager/graphs/commit-activity)

> **Collection de scripts d'automatisation pour déploiement et gestion d'infrastructures**

Bienvenue dans le dépôt **scripts-radioManager** ! Ce repository contient une collection de scripts d'automatisation pour différents projets : déploiement d'API, streaming audio, automatisation de workflows, et solutions VPN. Chaque script est accompagné d'une documentation complète pour faciliter la prise en main.

## 📋 Table des matières

- [Vue d'ensemble](#-vue-densemble)
- [Structure du repository](#-structure-du-repository)
- [Projets disponibles](#-projets-disponibles)
  - [API Audace](#1-api-audace---streaming--api)
  - [RadioManager Frontend](#2-radiomanager---frontend-vite)
  - [N8N Automation](#3-n8n---automatisation-de-workflows)
  - [Solutions Docker](#4-solutions-docker-)
  - [VPN WireGuard](#5-vpn-wireguard)
- [Documentation](#-documentation)
- [Prérequis généraux](#-prérequis-généraux)
- [Guide de contribution](#-guide-de-contribution)
- [Dépannage](#-dépannage-général)
- [Support](#-support)

## 🎯 Vue d'ensemble

Ce repository regroupe des scripts pour :
- **Déploiement d'API** : FastAPI + PostgreSQL + Icecast
- **Frontend moderne** : Vite + Node.js + Nginx
- **Automatisation** : N8N sur EC2 Amazon Linux
- **Solutions Docker** : Conteneurs pour RadioManager et API Audace
- **Solutions VPN** : WireGuard pour serveur, routeur MikroTik et clients Windows

**Systèmes supportés** : Ubuntu 24.10, Amazon Linux 2/2023, Windows 10/11, MikroTik RouterOS 7.x

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
│   └── api-audace-docker/
│       ├── README.md
│       ├── docker-compose.yml
│       └── nginx/
│           └── nginx.conf
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

**Documentation** : [`Docker/dockploy-deployment/README.md`](Docker/dockploy-deployment/README.md)

**Quick Start - Installation Dockploy** :
```bash
# Installer Dockploy sur votre serveur
curl -sSL https://dockploy.com/install.sh | sh

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

## 🎓 Guide de contribution

### Pour les contributeurs

Avant de contribuer, consultez le fichier **[AGENT.md](AGENT.md)** qui contient :
- 📐 Standards de documentation obligatoires
- 🎨 Templates de code (Bash, PowerShell)
- 🔒 Bonnes pratiques de sécurité
- 📊 Métriques de qualité (score minimal : 7/10)
- ✅ Checklist de validation complète

### Processus de contribution

1. **Fork** le repository
2. Créez une branche : `git checkout -b feature/nouveau-script`
3. Suivez les standards définis dans [AGENT.md](AGENT.md)
4. Documentez complètement votre script (fichier `.md` obligatoire)
5. Testez sur un système propre
6. Soumettez une Pull Request avec description détaillée

### Standards de commit

```bash
feat: Ajouter script d'installation [technologie]
fix: Corriger erreur dans [script]
docs: Mettre à jour documentation [script]
refactor: Améliorer [script] sans changement fonctionnel
```

## 🛠️ Dépannage général

### Logs à consulter

```bash
# Nginx
sudo tail -f /var/log/nginx/error.log

# Services systemd
sudo journalctl -u [nom-service] -f

# Scripts personnalisés
cat /var/log/[nom-script].log
```

### Problèmes courants

#### Certificat SSL échoue
```bash
# Vérifier DNS
nslookup votre-domaine.com

# Re-tenter Certbot
sudo certbot --nginx -d votre-domaine.com --force-renewal
```

#### Service ne démarre pas
```bash
# Vérifier le statut
sudo systemctl status [service]

# Voir les erreurs détaillées
sudo journalctl -u [service] -n 50 --no-pager
```

#### Port déjà utilisé
```bash
# Identifier le processus
sudo netstat -tlnp | grep :[port]

# Ou avec ss (plus moderne)
sudo ss -tlnp | grep :[port]
```

#### Erreur de permissions
```bash
# Vérifier les permissions
ls -la /chemin/vers/fichier

# Corriger si nécessaire
sudo chown -R utilisateur:groupe /chemin/vers/dossier
sudo chmod 755 /chemin/vers/script.sh
```

## 📞 Support

### Ressources
- **Issues GitHub** : [github.com/lwilly3/scripts-radioManager/issues](https://github.com/lwilly3/scripts-radioManager/issues)
- **Documentation** : Fichiers `.md` dans chaque dossier
- **Guide de contribution** : [`AGENT.md`](AGENT.md)
- **Forum communautaire** : [forum.radioaudace.com](https://forum.radioaudace.com)

### Contact
Pour toute question ou problème non résolu, ouvrez une issue sur GitHub ou contactez-nous via le forum communautaire. Nous nous efforçons de répondre dans les plus brefs délais.

---

Merci d'utiliser **scripts-radioManager** ! Nous espérons que ces outils faciliteront la gestion et le déploiement de vos infrastructures. N'hésitez pas à contribuer et à faire grandir cette communauté !
