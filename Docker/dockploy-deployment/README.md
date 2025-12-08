# 🚀 Déploiement RadioManager avec Dockploy

[![Dockploy](https://img.shields.io/badge/Dockploy-Modern%20PaaS-blue.svg)](https://dockploy.com)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![SSL](https://img.shields.io/badge/SSL-Auto-green.svg)](https://letsencrypt.org/)

> **Déployez RadioManager et API Audace avec une interface graphique moderne et puissante**

## 📋 Table des matières

- [Qu'est-ce que Dockploy ?](#-quest-ce-que-dockploy-)
- [Pourquoi utiliser Dockploy ?](#-pourquoi-utiliser-dockploy-)
- [Comparaison des solutions](#-comparaison-des-solutions)
- [Prérequis](#-prérequis)
- [Installation de Dockploy](#-installation-de-dockploy)
- [Déploiement RadioManager Frontend](#-déploiement-radiomanager-frontend)
- [Déploiement API Audace Stack](#-déploiement-api-audace-stack)
- [Configuration avancée](#-configuration-avancée)
- [Monitoring et maintenance](#-monitoring-et-maintenance)
- [CI/CD avec Webhooks](#-cicd-avec-webhooks)
- [Dépannage](#-dépannage)
- [Migration depuis installation classique](#-migration-depuis-installation-classique)

## 🎯 Qu'est-ce que Dockploy ?

**Dockploy** est une plateforme open-source d'hébergement et de gestion d'applications Docker. Elle offre une interface web moderne pour déployer, gérer et monitorer vos applications conteneurisées sans avoir à manipuler Docker directement.

### Fonctionnalités principales

- 🖥️ **Interface web intuitive** : Gestion visuelle de tous vos projets
- 🔄 **Déploiement automatique** : Depuis Git (GitHub, GitLab, Bitbucket)
- 🔒 **SSL automatique** : Let's Encrypt intégré avec renouvellement auto
- 📊 **Monitoring intégré** : CPU, RAM, réseau en temps réel
- 📝 **Logs centralisés** : Tous les logs accessibles depuis l'interface
- 🔐 **Gestion des secrets** : Variables d'environnement sécurisées
- 🔄 **Rollback facile** : Retour à une version précédente en un clic
- 🌐 **Multi-domaines** : Gérez plusieurs domaines et sous-domaines
- 🪝 **Webhooks** : Déploiement automatique sur push Git
- 🐳 **Docker Compose** : Support natif des stacks complexes

## 💡 Pourquoi utiliser Dockploy ?

### Avantages par rapport aux autres solutions

#### 1. Par rapport à Docker CLI/Compose

**Docker CLI** :
```bash
# Chaque déploiement nécessite des commandes
docker-compose up -d
docker-compose logs -f
docker-compose restart
# Pas d'interface, tout en ligne de commande
```

**Avec Dockploy** :
- ✅ Tout depuis l'interface web
- ✅ Logs en temps réel dans le navigateur
- ✅ Monitoring graphique intégré
- ✅ Déploiement en un clic

#### 2. Par rapport aux scripts bash

**Scripts personnalisés** :
- ❌ Maintenance du code
- ❌ Gestion manuelle du SSL
- ❌ Pas de monitoring
- ❌ Difficile pour les non-techniciens

**Avec Dockploy** :
- ✅ Pas de maintenance de scripts
- ✅ SSL automatique
- ✅ Monitoring intégré
- ✅ Interface accessible à tous

#### 3. Par rapport à des PaaS payants (Heroku, Railway)

**PaaS payants** :
- ❌ Coûts élevés (>$10-50/mois par app)
- ❌ Dépendance au fournisseur
- ❌ Limitations des ressources

**Avec Dockploy** :
- ✅ Gratuit et open-source
- ✅ Hébergé sur votre serveur
- ✅ Contrôle total des ressources

## 📊 Comparaison des solutions

| Critère | Installation classique | Docker CLI | **Dockploy** | PaaS payant |
|---------|----------------------|------------|--------------|-------------|
| **Facilité déploiement** | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Interface graphique** | ❌ | ❌ | ✅ | ✅ |
| **SSL automatique** | Manuel | Manuel | ✅ Auto | ✅ Auto |
| **Monitoring** | Configuration | Configuration | ✅ Intégré | ✅ Intégré |
| **Logs centralisés** | ❌ | Commandes | ✅ Interface | ✅ Interface |
| **Rollback** | Manuel | Manuel | ✅ 1 clic | ✅ 1 clic |
| **Multi-projets** | Complexe | docker-compose | ✅ Natif | ✅ Natif |
| **Coût** | Gratuit | Gratuit | Gratuit | $$$$ |
| **Contrôle** | ✅ Total | ✅ Total | ✅ Total | ⚠️ Limité |
| **Courbe apprentissage** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ |

### Verdict : Quand utiliser Dockploy ?

**✅ Utilisez Dockploy si** :
- Vous gérez plusieurs applications/projets
- Vous voulez une interface web moderne
- Vous déployez fréquemment depuis Git
- Vous avez une équipe non-technique
- Vous voulez du monitoring sans configuration
- Vous voulez simplifier la gestion SSL

**❌ Préférez Docker CLI si** :
- Vous avez un seul projet simple
- Vous êtes expert Docker et préférez CLI
- Serveur avec ressources très limitées
- Vous voulez le contrôle le plus bas niveau

**❌ Préférez installation classique si** :
- Serveur très ancien ou sans Docker
- Besoins de performances maximales
- Configuration système très spécifique

## 📦 Prérequis

### Système
- **OS** : Ubuntu 20.04+, Debian 11+, ou toute distribution Linux moderne
- **RAM** : Minimum 2GB (recommandé 4GB)
- **CPU** : 2 cores minimum
- **Disque** : 20GB d'espace libre
- **Réseau** : IP publique fixe

### Logiciels
- **Docker** : 20.10+ (installé automatiquement par Dockploy)
- **Ports ouverts** :
  - `80` (HTTP)
  - `443` (HTTPS)
  - `3000` (Interface Dockploy)

### Domaines
- Un ou plusieurs noms de domaine pointant vers votre serveur
- Accès DNS pour configurer les enregistrements A/CNAME

## 🚀 Installation de Dockploy

### Méthode 1 : Installation automatique (Recommandé)

```bash
# Script d'installation officiel
curl -sSL https://dockploy.com/install.sh | sh
```

Ce script va :
1. ✅ Installer Docker et Docker Compose (si absent)
2. ✅ Créer un utilisateur système `dockploy`
3. ✅ Démarrer Dockploy dans un conteneur
4. ✅ Configurer le reverse proxy Traefik
5. ✅ Générer les certificats SSL

**Temps estimé** : 3-5 minutes

### Méthode 2 : Installation manuelle

```bash
# Installer Docker si nécessaire
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Créer le répertoire de données
sudo mkdir -p /var/lib/dockploy

# Lancer Dockploy
docker run -d \
  --name dockploy \
  --restart unless-stopped \
  -p 3000:3000 \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /var/lib/dockploy:/data \
  dockploy/dockploy:latest
```

### Première connexion

1. **Accéder à l'interface** :
   ```
   https://votre-ip:3000
   ```

2. **Créer le compte administrateur** :
   - Email : votre@email.com
   - Mot de passe : (choisir un mot de passe fort)

3. **Configuration initiale** :
   - Définir l'URL de base
   - Configurer les notifications (optionnel)
   - Ajouter vos clés SSH Git (optionnel)

### Sécuriser l'interface

```bash
# Configurer un sous-domaine pour Dockploy
# Exemple : dockploy.votre-domaine.com

# Dans l'interface Dockploy :
# Settings → General → Server URL
# Entrer : https://dockploy.votre-domaine.com

# Le SSL sera automatiquement configuré
```

## 🎨 Déploiement RadioManager Frontend

### Étape 1 : Créer un nouveau projet

1. **Dans l'interface Dockploy**, cliquer sur **"New Project"**
2. **Nom du projet** : `RadioManager Frontend`
3. **Type** : Sélectionner **"Application"**

### Étape 2 : Connecter le repository Git

1. **Source** : Choisir **"Git Repository"**
2. **URL du repository** : 
   ```
   https://github.com/lwilly3/radioManager.git
   ```
3. **Branche** : `main`
4. **Authentification** : 
   - Public : Aucune
   - Privé : Ajouter votre clé SSH ou token

### Étape 3 : Configurer le build

1. **Build Method** : Sélectionner **"Dockerfile"**
2. **Dockerfile path** : Créer un `Dockerfile` dans votre repo :

```dockerfile
# À ajouter dans votre repository Git
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

3. **Port** : `80`

### Étape 4 : Configurer le domaine

1. **Domain** : `app.radioaudace.com`
2. **SSL** : ✅ Activer "Auto SSL (Let's Encrypt)"
3. **Force HTTPS** : ✅ Activer

### Étape 5 : Variables d'environnement

#### Interface Dockploy

Dans l'interface Dockploy, onglet **"Environment Variables"** :

**Comprendre les types de variables dans Dockploy** :

1. **Variables publiques** (🌐) : Visibles dans l'interface et les logs
2. **Variables secrètes** (🔒) : Masquées dans l'interface, chiffrées

#### Configuration recommandée

| Variable | Valeur | Type | Priorité | Description |
|----------|--------|------|----------|-------------|
| `NODE_ENV` | `production` | Public | ⚠️ CRITIQUE | Mode d'exécution de Node.js |
| `VITE_API_URL` | `https://api.radio.audace.ovh` | Public | ⚠️ CRITIQUE | URL de l'API backend |
| `VITE_STREAM_URL` | `https://radio.audace.ovh/stream.mp3` | Public | 🔵 IMPORTANTE | URL du flux audio |
| `VITE_APP_NAME` | `Radio Audace` | Public | 🟢 OPTIONNELLE | Nom de l'application |
| `VITE_APP_TAGLINE` | `La radio qui ose !` | Public | 🟢 OPTIONNELLE | Slogan de l'application |
| `TZ` | `Europe/Paris` | Public | 🟢 OPTIONNELLE | Fuseau horaire |
| `LOG_LEVEL` | `info` | Public | 🟢 OPTIONNELLE | Niveau de logs |

#### Ajouter des variables dans Dockploy

**Méthode 1 : Interface Web (Recommandé)**

```
1. Projet → Settings → Environment Variables
2. Cliquer "Add Variable"
3. Remplir :
   - Name: VITE_API_URL
   - Value: https://api.radio.audace.ovh
   - Type: Public (ou Secret si sensible)
4. Cliquer "Save"
5. Redéployer pour appliquer : "Deploy" → "Restart"
```

**Méthode 2 : Bulk Import (Import en masse)**

```
1. Préparer un fichier .env :

NODE_ENV=production
VITE_API_URL=https://api.radio.audace.ovh
VITE_STREAM_URL=https://radio.audace.ovh/stream.mp3
VITE_APP_NAME=Radio Audace

2. Dans Dockploy :
   Project → Environment → Import from .env file
   
3. Copier-coller le contenu
4. Cliquer "Import"
```

**Méthode 3 : Via API Dockploy (Avancé)**

```bash
# Utiliser l'API Dockploy pour automatiser
curl -X POST https://dockploy.votre-domaine.com/api/projects/PROJECT_ID/env \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "key": "VITE_API_URL",
    "value": "https://api.radio.audace.ovh",
    "isSecret": false
  }'
```

#### Gestion des secrets

**Variables sensibles à marquer comme "Secret"** :

```bash
# Dans Dockploy, cocher "Secret" pour :
API_SECRET_KEY=generez_une_cle_secrete_256bits
DB_PASSWORD=VotreMotDePasseSecurise123!
ICECAST_ADMIN_PASSWORD=AdminPassword123!
SENTRY_DSN=https://xxxxx@sentry.io/xxxxx
STRIPE_SECRET_KEY=sk_live_xxxxxxxxxxxxx
```

**Avantages des secrets dans Dockploy** :
- 🔒 **Chiffrés** dans la base de données
- 🙈 **Masqués** dans l'interface (•••••)
- 📝 **Absents** des logs
- 🚫 **Non exportables** via API sans authentification

**Comment définir un secret** :
```
1. Add Variable
2. Name: DB_PASSWORD
3. Value: VotreMotDePasseSecurise123!
4. ✅ Cocher "Is Secret"
5. Save
```

#### Templates de variables par environnement

##### Développement (local avec Dockploy)

```env
# Variables de développement
NODE_ENV=development
VITE_API_URL=http://localhost:8000
VITE_STREAM_URL=http://localhost:8080/stream.mp3
VITE_ENABLE_ANALYTICS=false
VITE_ENABLE_DEBUG=true
VITE_APP_NAME=RadioManager [DEV]
TZ=Europe/Paris
LOG_LEVEL=debug
```

**Dans Dockploy** :
- Créer un projet "RadioManager Dev"
- Port externe : 3000
- Domaine : dev.app.radioaudace.com

##### Staging (pré-production)

```env
# Variables de staging
NODE_ENV=staging
VITE_API_URL=https://api-staging.radio.audace.ovh
VITE_STREAM_URL=https://stream-staging.radio.audace.ovh/stream.mp3
VITE_ENABLE_ANALYTICS=true
VITE_ANALYTICS_ID=G-STAGING123
VITE_ENABLE_DEBUG=false
VITE_APP_NAME=RadioManager [STAGING]
VITE_ERROR_REPORTING_DSN=https://sentry-staging.io/xxxxx
TZ=Europe/Paris
LOG_LEVEL=info
```

**Dans Dockploy** :
- Créer un projet "RadioManager Staging"
- Port externe : 80
- Domaine : staging.app.radioaudace.com
- Branche Git : develop

##### Production

```env
# Variables de production
NODE_ENV=production
VITE_API_URL=https://api.radio.audace.ovh
VITE_STREAM_URL=https://radio.audace.ovh/stream.mp3
VITE_ENABLE_ANALYTICS=true
VITE_ANALYTICS_ID=G-PROD123456
VITE_ENABLE_DEBUG=false
VITE_APP_NAME=Radio Audace
VITE_ERROR_REPORTING_DSN=https://sentry.io/xxxxx  # Secret
VITE_ENABLE_PWA=true
VITE_ENABLE_OFFLINE_MODE=true
TZ=Europe/Paris
LOG_LEVEL=warning
```

**Dans Dockploy** :
- Créer un projet "RadioManager Production"
- Port externe : 80
- Domaine : app.radioaudace.com
- Branche Git : main
- ✅ Auto-deploy activé

#### Priorité des variables dans Dockploy

Dockploy applique les variables dans cet ordre :

```
1. Variables définies dans Dockploy (Interface)     ← Priorité MAXIMALE
2. Variables dans docker-compose.yml
3. Variables dans Dockerfile (ENV)
4. Valeurs par défaut dans le code
```

**Exemple de priorité** :

```yaml
# docker-compose.yml
environment:
  - VITE_API_URL=https://api-compose.com  # Priorité 2

# Dockploy Interface
VITE_API_URL=https://api-dockploy.com     # Priorité 1 ← GAGNE

# Résultat : Docker utilisera https://api-dockploy.com
```

**💡 Best Practice** : Définissez toutes les variables dans l'interface Dockploy pour une gestion centralisée.

#### Validation automatique dans Dockploy

**Script de health check avec validation des variables** :

```yaml
# Dans docker-compose.yml
services:
  radiomanager:
    # ...existing code...
    healthcheck:
      test: |
        sh -c '
        # Vérifier que les variables critiques sont définies
        if [ -z "$VITE_API_URL" ]; then
          echo "❌ VITE_API_URL non définie";
          exit 1;
        fi;
        
        # Vérifier que l'application répond
        wget --spider -q http://localhost/ || exit 1;
        
        echo "✅ Health check OK";
        '
      interval: 30s
      timeout: 10s
      retries: 3
```

**Notifications Dockploy** :

```
Settings → Notifications → Add Webhook
URL: https://hooks.slack.com/services/YOUR/WEBHOOK
Events:
  ✅ Health check failed
  ✅ Environment variables changed
  ✅ Deployment failed
```

#### Variables spécifiques à Dockploy

**Variables système injectées automatiquement** :

| Variable | Description | Exemple |
|----------|-------------|---------|
| `DOCKPLOY_PROJECT_ID` | ID unique du projet | `proj_abc123xyz` |
| `DOCKPLOY_DEPLOYMENT_ID` | ID du déploiement actuel | `dep_def456uvw` |
| `DOCKPLOY_GIT_COMMIT` | Hash du commit Git | `a1b2c3d4e5f6` |
| `DOCKPLOY_GIT_BRANCH` | Branche Git déployée | `main` |
| `DOCKPLOY_DEPLOYED_AT` | Timestamp du déploiement | `2025-01-15T10:30:00Z` |

**Utilisation dans l'application** :

```javascript
// Afficher la version déployée
console.log(`Version: ${import.meta.env.VITE_APP_VERSION}`);
console.log(`Commit: ${import.meta.env.DOCKPLOY_GIT_COMMIT}`);
console.log(`Branch: ${import.meta.env.DOCKPLOY_GIT_BRANCH}`);
```

#### Export/Import des variables

**Exporter les variables d'un projet** :

```
1. Dockploy → Project → Environment
2. Cliquer "Export"
3. Format : JSON ou .env
4. Télécharger le fichier
```

**Importer dans un autre projet** :

```
1. Nouveau projet → Environment
2. Cliquer "Import"
3. Uploader le fichier .env ou JSON
4. Vérifier et confirmer
```

**⚠️ Attention** : Les secrets ne sont PAS exportés pour des raisons de sécurité. Vous devrez les redéfinir manuellement.

#### Synchronisation multi-environnements

**Stratégie de gestion** :

```bash
# Structure de fichiers locale
.env.dev        # Variables de développement
.env.staging    # Variables de staging
.env.production # Variables de production
.env.example    # Template public (sans secrets)

# Ne jamais commiter .env.* (sauf .env.example)
```

**Workflow recommandé** :

```bash
# 1. Développer localement avec .env.dev
docker-compose --env-file .env.dev up

# 2. Tester en staging
# - Copier .env.staging dans Dockploy (projet staging)
# - Déployer et tester

# 3. Déployer en production
# - Copier .env.production dans Dockploy (projet prod)
# - Vérifier 2 fois les valeurs
# - Déployer
```

#### Dépannage des variables dans Dockploy

##### Variable non visible dans l'application

```bash
# 1. Vérifier dans l'interface Dockploy
Project → Environment → Chercher la variable

# 2. Redémarrer le conteneur
Project → Actions → Restart

# 3. Vérifier dans les logs
Project → Logs → Chercher "VITE_API_URL"

# 4. Inspecter le conteneur
docker exec -it container_name env | grep VITE_API_URL
```

##### Secret ne fonctionne pas

```bash
# Les secrets Dockploy sont pour des variables SYSTÈME
# Pas pour des variables Vite (frontend)

# ❌ NE PAS mettre en secret :
VITE_API_URL (visible côté client de toute façon)

# ✅ Mettre en secret :
DB_PASSWORD
API_SECRET_KEY
ENCRYPTION_KEY
```

##### Variable modifiée mais ancienne valeur utilisée

```bash
# 1. Sauvegarder la variable
# 2. Cliquer "Deploy" → "Rebuild & Restart"
# 3. Attendre la fin du build
# 4. Vérifier les logs de déploiement
```

#### Checklist avant déploiement

**Variables critiques** :
- [ ] `NODE_ENV` défini sur `production`
- [ ] `VITE_API_URL` pointe vers l'API de production
- [ ] `VITE_STREAM_URL` valide et accessible
- [ ] Toutes les URLs utilisent HTTPS

**Secrets** :
- [ ] Aucun secret exposé dans les variables VITE_*
- [ ] Secrets marqués comme "Secret" dans Dockploy
- [ ] Secrets différents entre staging et production
- [ ] Longueur suffisante (min 32 caractères)

**Configuration** :
- [ ] Fuseau horaire correct (`TZ`)
- [ ] Niveau de logs approprié (`LOG_LEVEL`)
- [ ] Analytics activé avec bon ID
- [ ] Health checks configurés

**Tests** :
- [ ] Application démarre correctement
- [ ] Variables accessibles dans l'app
- [ ] Health check réussit
- [ ] Aucune erreur dans les logs

## 💡 Configuration avancée

### Webhooks pour déploiement automatique

1. **Dans Dockploy** :
   - Aller dans Project Settings
   - Copier l'URL du webhook

2. **Dans GitHub** :
   - Settings → Webhooks → Add webhook
   - Payload URL : Coller l'URL de Dockploy
   - Content type : `application/json`
   - Events : `Just the push event`

3. **Résultat** : Chaque `git push` déclenche un déploiement automatique !

### Environnements multiples (Staging/Production)

```yaml
# Créer 2 projets dans Dockploy

# Projet 1 : Staging
- Domain: staging.app.radioaudace.com
- Branch: develop
- Variables: VITE_ENV=staging

# Projet 2 : Production
- Domain: app.radioaudace.com
- Branch: main
- Variables: VITE_ENV=production
```

### Scaling horizontal

```bash
# Dans l'interface Dockploy
# Project → Settings → Scale
# Nombre d'instances : 3

# Dockploy configure automatiquement :
# - Load balancing
# - Health checks
# - Distribution du trafic
```

### Backup automatique

```yaml
# Ajouter un service de backup dans docker-compose.yml
backup:
  image: offen/docker-volume-backup:v2
  environment:
    BACKUP_CRON_EXPRESSION: "0 2 * * *"  # 2h du matin
    BACKUP_RETENTION_DAYS: "7"
  volumes:
    - postgres_data:/backup/postgres_data:ro
    - ./backups:/archive
```

## 📊 Monitoring et maintenance

### Dashboard intégré

Dockploy fournit :
- 📈 **Métriques temps réel** : CPU, RAM, réseau
- 📝 **Logs centralisés** : Tous les containers
- 🔔 **Alertes** : Email/Slack en cas de problème
- 📊 **Historique déploiements** : Avec possibilité de rollback

### Accéder aux métriques

1. **Dashboard principal** : Vue d'ensemble
2. **Cliquer sur un projet** : Métriques détaillées
3. **Onglet "Metrics"** : Graphiques en temps réel

### Consulter les logs

```
Interface Dockploy → Project → Logs
- Filtrer par service
- Recherche en temps réel
- Téléchargement des logs
```

### Rollback en cas de problème

1. **Project → Deployments**
2. **Sélectionner une version précédente**
3. **Cliquer sur "Rollback"**
4. ✅ Application restaurée en 10 secondes !

### Alertes et notifications

```yaml
# Dans Settings → Notifications
# Configurer :
- Email : admin@radioaudace.com
- Slack : webhook-url
- Discord : webhook-url

# Déclencheurs :
- Container stopped
- High CPU usage (>80%)
- High memory usage (>90%)
- Deployment failed
```

## 🔄 CI/CD avec Webhooks

### GitHub Actions + Dockploy

Créer `.github/workflows/deploy.yml` :

```yaml
name: Deploy to Dockploy

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Dockploy Deploy
        run: |
          curl -X POST ${{ secrets.DOCKPLOY_WEBHOOK_URL }}
```

### Déploiement avec tests

```yaml
name: Test and Deploy

on:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Tests
        run: npm test

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Dockploy
        run: |
          curl -X POST ${{ secrets.DOCKPLOY_WEBHOOK_URL }}
```

## 🐛 Dépannage

### Container ne démarre pas

```bash
# Dans l'interface Dockploy
1. Project → Logs
2. Rechercher les erreurs
3. Vérifier les variables d'environnement
4. Tester le build localement :
   docker build -t test .
```

### SSL ne se génère pas

```bash
# Vérifier DNS
nslookup votre-domaine.com

# Dans Dockploy :
# Settings → SSL → Refresh Certificates
```

### Problème de performance

```bash
# Vérifier les ressources
1. Dashboard → Metrics
2. Si CPU/RAM > 80% :
   - Augmenter les limites
   - Ou scaler horizontalement
```

### Port conflit

```bash
# Dans Project Settings
# Changer le port externe :
ports:
  - "8080:80"  # Au lieu de 80:80
```

### Variables d'environnement non prises en compte

```bash
# Redéployer complètement
1. Project → Settings → Environment
2. Modifier les variables
3. Cliquer "Save & Restart"
```

## 🔄 Migration depuis installation classique

### Étape 1 : Préparer les données

```bash
# Exporter la base de données
pg_dump audace_db > audace_backup.sql

# Copier les fichiers de configuration
cp /etc/nginx/sites-available/* ./nginx-backup/
cp /etc/icecast2/icecast.xml ./icecast-backup/
```

### Étape 2 : Créer le projet dans Dockploy

Suivre les étapes de déploiement ci-dessus.

### Étape 3 : Importer les données

```bash
# Depuis l'interface Dockploy
# Project → Database → Import
# Uploader : audace_backup.sql
```

### Étape 4 : Tester et basculer

```bash
# Tester le nouveau déploiement
curl https://api.radio.audace.ovh/health

# Si OK, mettre à jour les DNS
# Pointer vers la nouvelle IP/serveur
```

### Étape 5 : Désinstaller l'ancien

```bash
# Arrêter les services classiques
sudo systemctl stop nginx postgresql icecast2

# Optionnel : Désinstaller
sudo apt remove nginx postgresql icecast2
```

## 📚 Ressources complémentaires

- **Documentation Dockploy** : https://docs.dockploy.com
- **GitHub Dockploy** : https://github.com/dockploy/dockploy
- **Community Discord** : https://discord.gg/dockploy
- **Tutoriels vidéo** : https://youtube.com/dockploy

## 🎯 Cas d'usage réels

### Scénario 1 : Agence avec plusieurs clients

```
Serveur unique avec Dockploy
├── Client 1 : Site vitrine
├── Client 2 : E-commerce
├── Client 3 : API + Frontend
└── Client 4 : Plateforme SaaS

Avantages :
✅ Gestion centralisée
✅ SSL automatique pour tous
✅ Monitoring global
✅ Facturation simplifiée
```

### Scénario 2 : Startup en croissance

```
Phase 1 : MVP
- 1 serveur avec Dockploy
- App frontend + API

Phase 2 : Scale
- Scaler horizontalement (3 instances)
- Ajouter monitoring Grafana

Phase 3 : Production
- Environnements séparés (staging/prod)
- CI/CD avec tests automatiques
```

### Scénario 3 : Développeur freelance

```
Portfolio personnel : portfolio.dev
Projet client 1 : client1.com
Projet client 2 : client2.com
Side project : sideproject.io

✅ Tous sur le même serveur
✅ SSL gratuit pour tous
✅ Déploiement en 2 clics
✅ Coût : ~$10/mois (VPS unique)
```

## 💰 Estimation des coûts

### Solution classique
```
Serveur VPS : $10-20/mois
+ Temps setup : 2-4h par projet
+ Maintenance : 2-3h/mois
= Coût réel : $50-100/mois (temps inclus)
```

### Avec Dockploy
```
Serveur VPS : $10-20/mois
+ Setup initial : 30min
+ Maintenance : 15min/mois
= Coût réel : $15-25/mois (temps inclus)
```

**Économie : 60-75% du temps de gestion !**

## 🎓 Formation et apprentissage

### Niveau débutant (2h)
1. Installer Dockploy
2. Déployer une app simple
3. Configurer un domaine
4. Consulter les logs

### Niveau intermédiaire (4h)
1. Déployer une stack complète
2. Configurer les variables
3. Mettre en place les webhooks
4. Monitoring basique

### Niveau avancé (8h)
1. Multi-environnements
2. Scaling horizontal
3. Backups automatiques
4. Intégration CI/CD complète
5. Monitoring avancé (Grafana)

## ✅ Checklist avant production

- [ ] Dockploy installé et sécurisé
- [ ] Domaines configurés et DNS vérifiés
- [ ] SSL actif pour tous les domaines
- [ ] Variables d'environnement sécurisées (secrets)
- [ ] Backups automatiques configurés
- [ ] Monitoring et alertes actifs
- [ ] Health checks configurés
- [ ] Logs centralisés accessibles
- [ ] Documentation du projet à jour
- [ ] Plan de rollback testé

## 🚀 Prochaines étapes

Après avoir maîtrisé Dockploy :

1. **Ajouter Grafana** pour monitoring avancé
2. **Configurer Prometheus** pour métriques détaillées
3. **Implémenter Redis** pour cache/sessions
4. **Ajouter Elasticsearch** pour recherche logs
5. **Tester Kubernetes** pour orchestration enterprise

---

<div align="center">

**Questions ?** Rejoignez la [communauté Dockploy](https://discord.gg/dockploy)

Made with ❤️ and 🚀

</div>
