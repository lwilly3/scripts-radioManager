# 🐳 RadioManager Frontend - Déploiement Docker

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=flat&logo=nginx&logoColor=white)](https://nginx.org/)
[![Vite](https://img.shields.io/badge/vite-%23646CFF.svg?style=flat&logo=vite&logoColor=white)](https://vitejs.dev/)

> **Déploiement conteneurisé de l'application RadioManager Frontend avec Docker**

## 📋 Table des matières

- [Vue d'ensemble](#-vue-densemble)
- [Avantages de Docker](#-avantages-de-docker)
- [Prérequis](#-prérequis)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Utilisation](#-utilisation)
- [Maintenance](#-maintenance)
- [Dépannage](#-dépannage)
- [Comparaison avec installation classique](#-comparaison-avec-installation-classique)

## 🎯 Vue d'ensemble

Cette solution permet de déployer l'application RadioManager Frontend dans un environnement Docker complètement isolé et reproductible. L'application Vite est compilée puis servie par Nginx dans un conteneur léger.

**Ce que vous obtenez** :
- ✅ Application prête en **5 minutes**
- ✅ Environnement **isolé et sécurisé**
- ✅ **Facilité de mise à jour** (un seul commande)
- ✅ **Rollback instantané** en cas de problème
- ✅ **Scalabilité** simple (plusieurs instances)
- ✅ **Portabilité** totale (dev → staging → prod)

## 🚀 Avantages de Docker

### Par rapport à l'installation classique

| Critère | Installation classique | Docker |
|---------|----------------------|--------|
| **Temps d'installation** | 15-20 min | 5 min |
| **Isolation** | Partage les ressources système | Isolé complètement |
| **Portabilité** | Dépend de l'OS | Identique partout |
| **Mises à jour** | Risque de casser l'environnement | Rollback facile |
| **Scalabilité** | Duplication manuelle | Orchestration simple |
| **Développement** | Différent de prod | Identique à prod |

### Cas d'usage recommandés

**Utilisez Docker si** :
- ✅ Vous avez plusieurs environnements (dev, staging, prod)
- ✅ Vous voulez une isolation totale
- ✅ Vous prévoyez de scaler l'application
- ✅ Vous voulez simplifier les déploiements
- ✅ Votre équipe utilise déjà Docker

**Utilisez l'installation classique si** :
- ❌ Serveur avec ressources limitées (< 2GB RAM)
- ❌ Vous ne connaissez pas Docker
- ❌ Déploiement unique et simple
- ❌ Besoins de performances maximales

## 📦 Prérequis

### Système
- **OS** : Ubuntu 20.04+, Debian 11+, CentOS 8+, ou tout système supportant Docker
- **RAM** : Minimum 2GB (recommandé 4GB)
- **Disque** : 10GB d'espace libre
- **Réseau** : Connexion Internet pour télécharger les images

### Logiciels
- Docker 20.10+
- Docker Compose 2.0+
- Git (pour cloner le repository)

### Domaine et DNS
- Nom de domaine configuré pointant vers l'IP du serveur
- Ports 80 et 443 ouverts dans le firewall

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│          Internet / Utilisateurs         │
└──────────────────┬──────────────────────┘
                   │
                   │ HTTPS (443)
                   ▼
┌─────────────────────────────────────────┐
│         Nginx Reverse Proxy              │
│        (Let's Encrypt SSL)               │
└──────────────────┬──────────────────────┘
                   │
                   │ HTTP (80)
                   ▼
┌─────────────────────────────────────────┐
│      Docker Container: RadioManager      │
│  ┌─────────────────────────────────┐   │
│  │   Nginx Web Server              │   │
│  │   ├── Static Files (dist/)      │   │
│  │   ├── Vite Build Output         │   │
│  │   └── Single Page App Routing   │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### Flux de construction

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Source Code │────▶│  npm build  │────▶│   Docker    │
│  (Vue/Vite) │     │   (dist/)   │     │    Image    │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │  Container  │
                                        │   Running   │
                                        └─────────────┘
```

## 🛠️ Installation

### Étape 1 : Installer Docker et Docker Compose

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker

# Installer Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Vérifier
docker --version
docker-compose --version
```

### Étape 2 : Cloner le repository

```bash
cd /opt
git clone https://github.com/lwilly3/scripts-radioManager.git
cd scripts-radioManager/Docker/radioManager-docker
```

### Étape 3 : Configurer les variables

Éditez le fichier `docker-compose.yml` :

```bash
nano docker-compose.yml
```

Modifiez ces variables :
- `APP_URL` : Votre domaine (ex: app.radioaudace.com)
- `GIT_REPO` : URL de votre repo Git

### Étape 4 : Lancer l'application

```bash
# Construire et démarrer
docker-compose up -d

# Voir les logs
docker-compose logs -f
```

### Étape 5 : Configurer SSL avec Certbot

```bash
# Installer Certbot (sur l'hôte, pas dans le conteneur)
sudo apt install certbot python3-certbot-nginx -y

# Obtenir le certificat
sudo certbot --nginx -d app.radioaudace.com

# Vérifier le renouvellement automatique
sudo certbot renew --dry-run
```

## ⚙️ Configuration

### Structure des fichiers

```
radioManager-docker/
├── Dockerfile              # Construction de l'image
├── docker-compose.yml      # Orchestration
├── nginx.conf              # Configuration Nginx
├── .dockerignore           # Fichiers à ignorer
└── README.md               # Ce fichier
```

### Variables d'environnement

#### Vue d'ensemble

Les variables d'environnement permettent de configurer l'application sans modifier le code. Elles sont essentielles pour :
- 🔒 Séparer la configuration sensible du code
- 🌍 Adapter l'application aux différents environnements (dev/staging/prod)
- 🔄 Faciliter les déploiements et les mises à jour

#### Ordre de priorité

Docker Compose résout les variables dans cet ordre (du plus prioritaire au moins prioritaire) :

```
1. Variables dans le shell actuel
2. Variables dans docker-compose.yml (section environment:)
3. Variables dans le fichier .env
4. Variables définies avec ENV dans le Dockerfile
5. Valeurs par défaut dans le code de l'application
```

**Exemple** :
```bash
# Si VITE_API_URL est défini à 3 endroits :
export VITE_API_URL="https://api-shell.com"           # Priorité 1
# docker-compose.yml → VITE_API_URL: https://api-compose.com  # Priorité 2
# .env → VITE_API_URL=https://api-env.com            # Priorité 3

# Résultat : Docker utilisera "https://api-shell.com"
```

#### Variables obligatoires

Ces variables **DOIVENT** être définies avant le déploiement :

| Variable | Description | Exemple | Sécurité |
|----------|-------------|---------|----------|
| `NODE_ENV` | Environnement d'exécution | `production` | Public |
| `VITE_API_URL` | URL de l'API backend | `https://api.radio.audace.ovh` | Public |

**⚠️ Sans ces variables, l'application ne fonctionnera pas correctement.**

#### Variables optionnelles

Ces variables ont des valeurs par défaut mais peuvent être personnalisées :

| Variable | Description | Défaut | Exemple |
|----------|-------------|--------|---------|
| `VITE_STREAM_URL` | URL du stream audio | `null` | `https://radio.audace.ovh/stream.mp3` |
| `VITE_APP_NAME` | Nom de l'application | `RadioManager` | `Ma Radio` |
| `VITE_APP_VERSION` | Version de l'application | Auto depuis package.json | `2.1.0` |
| `VITE_ENABLE_ANALYTICS` | Activer les analytics | `false` | `true` |
| `APP_PORT` | Port interne du conteneur | `80` | `8080` |
| `TZ` | Fuseau horaire | `UTC` | `Europe/Paris` |

#### Variables de build

Ces variables sont utilisées pendant la construction de l'image Docker :

| Variable | Description | Défaut | Usage |
|----------|-------------|--------|-------|
| `GIT_REPO` | Repository Git à cloner | Requis | Build |
| `GIT_BRANCH` | Branche à déployer | `main` | Build |
| `NODE_VERSION` | Version de Node.js | `20` | Build |

#### Comment définir les variables

##### Méthode 1 : Fichier .env (Recommandé)

Créez un fichier `.env` à la racine du projet :

```bash
# Créer le fichier .env
cat > .env << 'EOF'
# ============================================
# CONFIGURATION RADIOMANAGER - PRODUCTION
# ============================================

# === OBLIGATOIRES ===
NODE_ENV=production
VITE_API_URL=https://api.radio.audace.ovh

# === URLS ET DOMAINES ===
VITE_STREAM_URL=https://radio.audace.ovh/stream.mp3
VITE_APP_URL=https://app.radioaudace.com

# === PERSONNALISATION ===
VITE_APP_NAME=Radio Audace
VITE_APP_TAGLINE=La radio qui ose !
VITE_THEME_PRIMARY_COLOR=#FF6B6B
VITE_THEME_SECONDARY_COLOR=#4ECDC4

# === FONCTIONNALITÉS ===
VITE_ENABLE_ANALYTICS=true
VITE_ANALYTICS_ID=G-XXXXXXXXXX
VITE_ENABLE_PWA=true
VITE_ENABLE_OFFLINE_MODE=false

# === SYSTÈME ===
APP_PORT=80
TZ=Europe/Paris
LOG_LEVEL=info

# === BUILD (si reconstruction nécessaire) ===
GIT_REPO=https://github.com/lwilly3/radioManager.git
GIT_BRANCH=main
NODE_VERSION=20
EOF
```

**Avantages** :
- ✅ Facile à éditer
- ✅ Ignoré par Git (`.gitignore`)
- ✅ Une seule source de vérité
- ✅ Pas besoin de modifier `docker-compose.yml`

**Utilisation** :
```bash
# Docker Compose charge automatiquement le fichier .env
docker-compose up -d
```

##### Méthode 2 : Dans docker-compose.yml

Modifier directement `docker-compose.yml` :

```yaml
services:
  radiomanager:
    # ...existing code...
    environment:
      # Variables obligatoires
      - NODE_ENV=production
      - VITE_API_URL=https://api.radio.audace.ovh
      
      # Variables optionnelles
      - VITE_STREAM_URL=https://radio.audace.ovh/stream.mp3
      - VITE_APP_NAME=Radio Audace
      - TZ=Europe/Paris
```

**Avantages** :
- ✅ Configuration visible dans le fichier
- ✅ Pas de fichier supplémentaire

**Inconvénients** :
- ❌ Risque de commit de secrets dans Git
- ❌ Moins flexible pour plusieurs environnements

##### Méthode 3 : Variables shell (Temporaire)

Pour tester rapidement sans créer de fichier :

```bash
# Définir les variables dans le shell
export NODE_ENV=production
export VITE_API_URL=https://api.radio.audace.ovh
export VITE_STREAM_URL=https://radio.audace.ovh/stream.mp3

# Lancer avec les variables du shell
docker-compose up -d

# Les variables sont perdues après fermeture du terminal
```

**Avantages** :
- ✅ Rapide pour les tests
- ✅ Aucun fichier créé

**Inconvénients** :
- ❌ Non persistant
- ❌ Doit être redéfini à chaque session

##### Méthode 4 : Fichier .env personnalisé

Pour gérer plusieurs environnements :

```bash
# Créer des fichiers séparés
.env.dev
.env.staging
.env.production

# Utiliser un fichier spécifique
docker-compose --env-file .env.production up -d
```

**Structure recommandée** :
```bash
# .env.dev
NODE_ENV=development
VITE_API_URL=http://localhost:8000
VITE_ENABLE_ANALYTICS=false
LOG_LEVEL=debug

# .env.staging
NODE_ENV=staging
VITE_API_URL=https://api-staging.radio.audace.ovh
VITE_ENABLE_ANALYTICS=true
LOG_LEVEL=info

# .env.production
NODE_ENV=production
VITE_API_URL=https://api.radio.audace.ovh
VITE_ENABLE_ANALYTICS=true
LOG_LEVEL=warning
```

#### Validation des variables

##### Script de validation automatique

Créez `validate-env.sh` :

```bash
#!/bin/bash
# filepath: validate-env.sh
# Script de validation des variables d'environnement

set -e

echo "🔍 Validation des variables d'environnement..."

# Charger les variables depuis .env
if [ -f .env ]; then
    source .env
else
    echo "❌ Fichier .env introuvable"
    exit 1
fi

# Fonction de validation
validate_var() {
    local var_name=$1
    local var_value=${!var_name}
    local is_required=$2
    
    if [ -z "$var_value" ]; then
        if [ "$is_required" = "true" ]; then
            echo "❌ Variable obligatoire manquante: $var_name"
            return 1
        else
            echo "⚠️  Variable optionnelle non définie: $var_name"
            return 0
        fi
    else
        echo "✅ $var_name = $var_value"
        return 0
    fi
}

# Variables obligatoires
ERRORS=0
validate_var "NODE_ENV" true || ((ERRORS++))
validate_var "VITE_API_URL" true || ((ERRORS++))

# Variables optionnelles
validate_var "VITE_STREAM_URL" false
validate_var "VITE_APP_NAME" false
validate_var "APP_PORT" false

# Validation des URLs
if [[ -n "$VITE_API_URL" ]] && [[ ! "$VITE_API_URL" =~ ^https?:// ]]; then
    echo "❌ VITE_API_URL doit commencer par http:// ou https://"
    ((ERRORS++))
fi

# Résultat
echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ Toutes les variables sont valides"
    exit 0
else
    echo "❌ $ERRORS erreur(s) détectée(s)"
    exit 1
fi
```

**Utilisation** :
```bash
chmod +x validate-env.sh
./validate-env.sh
```

##### Validation dans docker-compose.yml

Ajoutez un service de validation :

```yaml
services:
  validator:
    image: alpine:latest
    command: sh -c '
      echo "Validation des variables...";
      test -n "$NODE_ENV" || { echo "NODE_ENV manquant"; exit 1; };
      test -n "$VITE_API_URL" || { echo "VITE_API_URL manquant"; exit 1; };
      echo "✅ Variables valides";
      '
    environment:
      - NODE_ENV=${NODE_ENV}
      - VITE_API_URL=${VITE_API_URL}
```

#### Sécurité des variables

##### Variables sensibles

**❌ NE JAMAIS exposer dans le frontend** :
- Clés API secrètes
- Tokens d'authentification backend
- Mots de passe de base de données
- Clés de chiffrement

**✅ Variables sûres pour le frontend** :
- URLs publiques (API, stream)
- IDs de services tiers publics (Google Analytics)
- Configuration UI (couleurs, noms)
- Flags de fonctionnalités

##### Protection du fichier .env

```bash
# Ajouter .env au .gitignore
echo ".env" >> .gitignore
echo ".env.*" >> .gitignore
echo "!.env.example" >> .gitignore

# Créer un template .env.example
cat > .env.example << 'EOF'
# Configuration RadioManager
# Copiez ce fichier en .env et remplissez les valeurs

NODE_ENV=production
VITE_API_URL=https://votre-api.com
VITE_STREAM_URL=https://votre-stream.com/stream.mp3
VITE_APP_NAME=Votre Radio
EOF

# Permissions restrictives
chmod 600 .env
```

##### Chiffrement des secrets (Avancé)

Pour les environnements de production :

```bash
# Utiliser Docker Secrets (Docker Swarm)
docker secret create api_key api_key.txt

# Ou utiliser des outils de gestion de secrets
# - HashiCorp Vault
# - AWS Secrets Manager
# - Azure Key Vault
```

#### Variables par environnement

##### Développement

```bash
# .env.dev
NODE_ENV=development
VITE_API_URL=http://localhost:8000
VITE_STREAM_URL=http://localhost:8080/stream.mp3
VITE_ENABLE_ANALYTICS=false
VITE_ENABLE_DEBUG=true
LOG_LEVEL=debug
APP_PORT=3000
```

**Caractéristiques** :
- 🔧 Mode debug activé
- 📝 Logs verbeux
- 🚫 Pas d'analytics
- 🌐 URLs locales

##### Staging (Pré-production)

```bash
# .env.staging
NODE_ENV=staging
VITE_API_URL=https://api-staging.radio.audace.ovh
VITE_STREAM_URL=https://stream-staging.radio.audace.ovh/stream.mp3
VITE_ENABLE_ANALYTICS=true
VITE_ANALYTICS_ID=G-STAGING123
VITE_ENABLE_DEBUG=false
LOG_LEVEL=info
APP_PORT=80
```

**Caractéristiques** :
- ✅ Identique à la production
- 📊 Analytics de test
- 🔍 Logs moyens
- 🌐 URLs de staging

##### Production

```bash
# .env.production
NODE_ENV=production
VITE_API_URL=https://api.radio.audace.ovh
VITE_STREAM_URL=https://radio.audace.ovh/stream.mp3
VITE_ENABLE_ANALYTICS=true
VITE_ANALYTICS_ID=G-PROD123456
VITE_ENABLE_DEBUG=false
VITE_ENABLE_ERROR_REPORTING=true
VITE_ERROR_REPORTING_DSN=https://sentry.io/xxxxx
LOG_LEVEL=warning
APP_PORT=80
```

**Caractéristiques** :
- 🚀 Optimisé pour la performance
- 📊 Analytics production
- ⚠️ Logs minimaux (warnings/errors)
- 🐛 Reporting d'erreurs activé

#### Checklist de configuration

Avant de déployer, vérifiez :

- [ ] **Fichier .env créé et configuré**
- [ ] **Variables obligatoires définies** (NODE_ENV, VITE_API_URL)
- [ ] **URLs correctes** (avec https:// en production)
- [ ] **Pas de secrets exposés** dans le code frontend
- [ ] **.env ajouté au .gitignore**
- [ ] **Permissions du fichier .env** restrictives (600)
- [ ] **Validation des variables** réussie
- [ ] **Test de l'application** avec les nouvelles variables

#### Dépannage des variables

##### Variable non prise en compte

```bash
# 1. Vérifier que le fichier .env existe
ls -la .env

# 2. Afficher les variables dans le conteneur
docker-compose exec radiomanager env | grep VITE

# 3. Reconstruire sans cache
docker-compose build --no-cache
docker-compose up -d

# 4. Vérifier les logs de build
docker-compose logs radiomanager
```

##### Variable undefined dans l'application

```javascript
// Dans le code Vite, les variables DOIVENT commencer par VITE_
console.log(import.meta.env.VITE_API_URL);  // ✅ Fonctionne
console.log(import.meta.env.API_URL);       // ❌ undefined

// Variables disponibles uniquement côté serveur
console.log(process.env.NODE_ENV);          // ❌ undefined (frontend)
```

##### Valeur incorrecte utilisée

```bash
# Vérifier l'ordre de priorité
# 1. Variables shell
printenv | grep VITE_API_URL

# 2. docker-compose.yml
cat docker-compose.yml | grep VITE_API_URL

# 3. Fichier .env
cat .env | grep VITE_API_URL

# Forcer l'utilisation du .env uniquement
unset VITE_API_URL  # Supprimer la variable shell
docker-compose up -d
```

##### Documentation des variables personnalisées

Si vous ajoutez de nouvelles variables, documentez-les :

```bash
# Dans votre README.md ou VARIABLES.md

## Variables personnalisées

### VITE_CUSTOM_FEATURE
- **Description** : Active la fonctionnalité XYZ
- **Type** : boolean
- **Défaut** : false
- **Exemple** : `VITE_CUSTOM_FEATURE=true`
- **Environnements** : dev, staging, production

### VITE_MAX_UPLOAD_SIZE
- **Description** : Taille maximale des fichiers uploadés (en Mo)
- **Type** : number
- **Défaut** : 10
- **Exemple** : `VITE_MAX_UPLOAD_SIZE=50`
- **Environnements** : production uniquement
```

## 🎮 Utilisation

### Commandes de base

```bash
# Démarrer
docker-compose up -d

# Arrêter
docker-compose down

# Redémarrer
docker-compose restart

# Voir les logs
docker-compose logs -f

# Voir le statut
docker-compose ps
```

### Mise à jour de l'application

```bash
# Récupérer les nouvelles sources
git pull

# Reconstruire et redémarrer
docker-compose up -d --build

# Ou avec cache nettoyé
docker-compose build --no-cache
docker-compose up -d
```

### Accéder au conteneur

```bash
# Ouvrir un shell dans le conteneur
docker-compose exec radiomanager sh

# Vérifier les fichiers servis
docker-compose exec radiomanager ls -la /usr/share/nginx/html
```

## 🔧 Maintenance

### Sauvegarde

```bash
# Sauvegarder l'image
docker save radiomanager-frontend:latest | gzip > radiomanager-backup.tar.gz

# Restaurer
docker load < radiomanager-backup.tar.gz
```

### Nettoyage

```bash
# Nettoyer les images non utilisées
docker image prune -a

# Nettoyer tout le système Docker
docker system prune -a --volumes
```

### Surveillance

```bash
# Utilisation des ressources
docker stats

# Logs en temps réel
docker-compose logs -f --tail=100

# Inspecter le conteneur
docker inspect radiomanager-frontend
```

### Mise à jour de Docker

```bash
# Mettre à jour Docker
sudo apt update && sudo apt upgrade docker-ce docker-ce-cli containerd.io

# Vérifier la version
docker --version
```

## 🐛 Dépannage

### Le conteneur ne démarre pas

```bash
# Vérifier les logs d'erreur
docker-compose logs radiomanager

# Vérifier la configuration
docker-compose config

# Reconstruire complètement
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Erreur de build npm

```bash
# Nettoyer le cache npm dans le Dockerfile
# Ajouter avant npm install :
RUN npm cache clean --force

# Reconstruire
docker-compose build --no-cache
```

### Port déjà utilisé

```bash
# Identifier le processus
sudo netstat -tlnp | grep :80

# Ou changer le port dans docker-compose.yml
ports:
  - "8080:80"  # Utiliser le port 8080 à la place
```

### Problème de permissions

```bash
# Vérifier les permissions sur l'hôte
ls -la /opt/scripts-radioManager/Docker/radioManager-docker

# Corriger si nécessaire
sudo chown -R $USER:$USER /opt/scripts-radioManager
```

### Le site ne se charge pas

```bash
# Vérifier que le conteneur tourne
docker-compose ps

# Vérifier les logs Nginx
docker-compose logs radiomanager | grep error

# Tester l'accès direct au conteneur
curl -I http://localhost:80

# Vérifier la configuration Nginx
docker-compose exec radiomanager nginx -t
```

### SSL ne fonctionne pas

```bash
# Vérifier le certificat
sudo certbot certificates

# Renouveler manuellement
sudo certbot renew --force-renewal

# Vérifier la configuration Nginx sur l'hôte
sudo nginx -t
sudo systemctl reload nginx
```

## 📊 Comparaison avec installation classique

### Scénario 1 : Première installation

**Installation classique** :
```bash
# Temps : ~20 minutes
sudo bash init-radioManager-frontend-server.sh
# Potentiel conflits avec d'autres services
# Configuration manuelle de Node.js, npm, Nginx
```

**Docker** :
```bash
# Temps : ~5 minutes
docker-compose up -d
# Aucun conflit, isolation totale
# Tout est pré-configuré dans l'image
```

### Scénario 2 : Mise à jour

**Installation classique** :
```bash
sudo bash update_frontend.sh
# Risque de casser l'environnement Node.js
# Nécessite de tester les dépendances
```

**Docker** :
```bash
docker-compose up -d --build
# Rollback facile : docker-compose down && docker-compose up -d
# Environnement propre à chaque build
```

### Scénario 3 : Scaling

**Installation classique** :
```bash
# Dupliquer manuellement sur plusieurs serveurs
# Installer et configurer chaque serveur
# Configurer load balancer séparément
```

**Docker** :
```bash
docker-compose up -d --scale radiomanager=3
# Ou utiliser Docker Swarm / Kubernetes
```

## 📚 Ressources

- **Docker Docs** : https://docs.docker.com/
- **Docker Compose** : https://docs.docker.com/compose/
- **Nginx Docker** : https://hub.docker.com/_/nginx
- **Vite Docs** : https://vitejs.dev/guide/
- **Repository** : https://github.com/lwilly3/scripts-radioManager

## 🎯 Prochaines étapes

Après ce déploiement Docker, vous pouvez :

1. **Ajouter un monitoring** : Prometheus + Grafana
2. **Orchestration avancée** : Kubernetes ou Docker Swarm
3. **CI/CD** : GitHub Actions pour déploiement automatique
4. **Backup automatisé** : Scripts de sauvegarde régulière
5. **Multi-environnement** : Dev, staging, prod avec docker-compose

## 📜 Licence

Ce projet est sous licence libre. Voir le fichier LICENSE à la racine du repository.

---

**Questions ?** Ouvrez une issue sur [GitHub](https://github.com/lwilly3/scripts-radioManager/issues)

---

<div align="center">

Made with ❤️ and 🐳

</div>

