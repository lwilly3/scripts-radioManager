# API-setup_server.sh - Documentation

## 📋 Vue d'ensemble

Ce script automatise la configuration complète d'un serveur Ubuntu 24.10 pour héberger une **API FastAPI** avec base de données PostgreSQL et un **serveur de streaming audio Icecast**.

## 🎯 Objectif

Déployer une infrastructure complète comprenant :
- Serveur API REST avec FastAPI
- Base de données PostgreSQL
- Serveur de streaming Icecast
- Reverse proxy Nginx avec SSL (Let's Encrypt)
- Configuration du pare-feu
- Service systemd pour l'API

## 🔧 Composants installés

| Composant | Version | Rôle |
|-----------|---------|------|
| **PostgreSQL** | Dernière | Base de données de l'API |
| **Python 3** | 3.x | Environnement pour FastAPI |
| **FastAPI** | Dernière | Framework API REST |
| **Icecast2** | 2.x | Serveur de streaming audio |
| **Nginx** | Dernière | Reverse proxy et serveur web |
| **Certbot** | Dernière | Certificats SSL Let's Encrypt |
| **UFW** | Dernière | Pare-feu système |

## 📦 Prérequis

- **Système d'exploitation** : Ubuntu 24.10 fraîchement installé
- **Accès** : Privilèges root ou sudo
- **Réseau** : Connexion Internet stable
- **DNS** : Domaines configurés pointant vers l'IP du serveur :
  - `radio.audace.ovh` (pour Icecast)
  - `api.radio.audace.ovh` (pour l'API)

## ⚙️ Variables de configuration

### Variables principales à modifier

```bash
# Utilisateur système
AUDACE_PASSWORD=""                    # Mot de passe pour l'utilisateur 'audace'

# Base de données PostgreSQL
DB_USER=""                            # Nom d'utilisateur PostgreSQL
DB_PASSWORD=""                        # Mot de passe PostgreSQL
DB_NAME=""                            # Nom de la base de données
DB_HOSTNAME="localhost"               # Hôte PostgreSQL
DB_PORT="5432"                        # Port PostgreSQL

# Sécurité JWT
SECRET_KEY=""                         # Clé secrète pour JWT
ALGORITHM="HS256"                     # Algorithme de signature JWT
ACCESS_TOKEN_EXPIRATION_MINUTE="30"  # Durée de vie des tokens (minutes)

# SSL
ADMIN_EMAIL="admin@example.com"       # Email pour Certbot
```

### Variables avancées

```bash
# Configuration Icecast
ICE_CAST_CONFIG_URL="https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/config-audaceStream-IceCast.xml"

# Répertoires
APP_DIR="/home/audace/app"
VENV_DIR="/home/audace/app/venv"

# Dépôt Git de l'API
API_REPO="https://github.com/lwilly3/api.audace.git"
```

## 🚀 Installation

### Étape 1 : Téléchargement du script

```bash
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/API-setup_server.sh -O setup_server.sh
```

### Étape 2 : Rendre le script exécutable

```bash
chmod +x setup_server.sh
```

### Étape 3 : Éditer les variables (optionnel)

Vous pouvez soit :
- Éditer les variables directement dans le script
- Laisser le script vous les demander de manière interactive

```bash
nano setup_server.sh
```

### Étape 4 : Exécution du script

```bash
sudo bash setup_server.sh
```

Le script vous demandera de manière interactive toutes les informations nécessaires si elles n'ont pas été pré-définies.

## 📝 Processus d'installation détaillé

### 1. Mise à jour du système
- Mise à jour des paquets système
- Mise à niveau de la distribution
- Nettoyage des paquets obsolètes

### 2. Installation d'Icecast2
- Installation du serveur Icecast
- Téléchargement de la configuration personnalisée depuis GitHub
- Configuration du point de montage `/stream.mp3`
- Démarrage et activation au boot

### 3. Installation de Nginx et Certbot
- Installation du serveur web Nginx
- Installation de Certbot pour SSL
- Configuration de deux domaines :
  - `radio.audace.ovh` → Proxy vers Icecast (port 8000)
  - `api.radio.audace.ovh` → Proxy vers l'API (port 8001)

### 4. Installation de PostgreSQL
- Installation du serveur de base de données
- Création de l'utilisateur PostgreSQL
- Création de la base de données
- Configuration de l'authentification

### 5. Configuration de l'environnement Python
- Installation de Python 3 et pip
- Création d'un environnement virtuel
- Clonage du dépôt Git de l'API
- Installation des dépendances Python (`requirements.txt`)

### 6. Configuration de l'API
- Création du fichier `.env` avec les variables d'environnement
- Configuration de la connexion PostgreSQL
- Configuration JWT
- Configuration des paramètres de l'API

### 7. Service systemd pour l'API
- Création d'un service systemd
- Configuration du démarrage automatique
- Démarrage du service API

### 8. Configuration SSL
- Obtention des certificats Let's Encrypt
- Configuration de la redirection HTTPS
- Renouvellement automatique des certificats

### 9. Configuration du pare-feu
- Installation et activation de UFW
- Ouverture des ports nécessaires :
  - 22/tcp (SSH)
  - 80/tcp (HTTP)
  - 443/tcp (HTTPS)
  - 8000/tcp (Icecast)

## 🔍 Vérification de l'installation

### Vérifier les services

```bash
# Vérifier Icecast
systemctl status icecast2

# Vérifier l'API
systemctl status api

# Vérifier Nginx
systemctl status nginx

# Vérifier PostgreSQL
systemctl status postgresql
```

### Tester les endpoints

```bash
# Tester le flux Icecast
curl https://radio.audace.ovh/stream.mp3

# Tester l'API
curl https://api.radio.audace.ovh/docs
```

## 📂 Structure des fichiers

```
/home/audace/app/
├── venv/                          # Environnement virtuel Python
├── src/                           # Code source de l'API (cloné depuis Git)
│   ├── main.py
│   ├── requirements.txt
│   └── .env                       # Variables d'environnement
└── logs/                          # Logs de l'application (si configurés)

/etc/nginx/sites-available/
├── radio.audace.ovh               # Configuration Nginx pour Icecast
└── api.radio.audace.ovh           # Configuration Nginx pour l'API

/etc/systemd/system/
└── api.service                    # Service systemd pour l'API

/etc/icecast2/
└── icecast.xml                    # Configuration Icecast
```

## 🛠️ Maintenance

### Mettre à jour l'API

```bash
cd /home/audace/app/src
git pull origin main
source ../venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart api
```

### Consulter les logs

```bash
# Logs API
sudo journalctl -u api -f

# Logs Nginx
sudo tail -f /var/log/nginx/error.log

# Logs Icecast
sudo tail -f /var/log/icecast2/error.log
```

### Renouveler les certificats SSL

Les certificats se renouvellent automatiquement, mais vous pouvez le faire manuellement :

```bash
sudo certbot renew
sudo systemctl reload nginx
```

## 🔒 Sécurité

- Les mots de passe sont demandés de manière sécurisée (pas d'affichage)
- JWT pour l'authentification API
- SSL/TLS obligatoire (redirection HTTPS)
- Pare-feu configuré (UFW)
- Utilisateur système dédié sans privilèges root

## ⚠️ Dépannage

### Problème : L'API ne démarre pas

```bash
# Vérifier les logs
sudo journalctl -u api -n 50

# Vérifier l'environnement virtuel
source /home/audace/app/venv/bin/activate
python /home/audace/app/src/main.py
```

### Problème : Icecast ne diffuse pas

```bash
# Vérifier le statut
systemctl status icecast2

# Vérifier la configuration
cat /etc/icecast2/icecast.xml

# Tester la connexion
telnet localhost 8000
```

### Problème : Erreur SSL

```bash
# Vérifier que le domaine pointe vers le serveur
nslookup radio.audace.ovh
nslookup api.radio.audace.ovh

# Re-tenter l'obtention du certificat
sudo certbot --nginx -d radio.audace.ovh
sudo certbot --nginx -d api.radio.audace.ovh
```

## 🔗 Liens utiles

- [Documentation FastAPI](https://fastapi.tiangolo.com/)
- [Documentation Icecast](https://icecast.org/docs/)
- [Documentation Nginx](https://nginx.org/en/docs/)
- [Dépôt GitHub de l'API](https://github.com/lwilly3/api.audace)

## 📞 Support

Pour toute question ou problème, consultez :
- Les logs système : `journalctl -xe`
- Les logs Nginx : `/var/log/nginx/error.log`
- Les logs de l'API : `journalctl -u api`

## 📜 Licence

Ce script est fourni "tel quel" sans garantie. Utilisez-le à vos propres risques.
