# 🎵 API Audace - Déploiement Docker

[![FastAPI](https://img.shields.io/badge/FastAPI-0.109-009688.svg)](https://fastapi.tiangolo.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791.svg)](https://www.postgresql.org/)
[![Icecast](https://img.shields.io/badge/Icecast-2.4-CC0000.svg)](https://icecast.org/)

> **Stack complète API + Base de données + Streaming audio dans Docker**

## 📋 Table des matières

- [Vue d'ensemble](#-vue-densemble)
- [Architecture](#-architecture)
- [Prérequis du repository](#-prérequis-du-repository)
- [Variables d'environnement](#-variables-denvironnement)
- [Installation](#-installation)
- [Configuration avancée](#-configuration-avancée)
- [Monitoring](#-monitoring)
- [Dépannage](#-dépannage)

## 🎯 Vue d'ensemble

**Repository** : https://github.com/lwilly3/api.audace.git

Cette stack Docker complète déploie :
- **API FastAPI** : Backend REST avec authentification JWT
- **PostgreSQL** : Base de données relationnelle
- **Icecast** : Serveur de streaming audio
- **Nginx** : Reverse proxy avec SSL

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│          Internet / Clients              │
└──────────────────┬──────────────────────┘
                   │
                   │ HTTPS (443)
                   ▼
┌─────────────────────────────────────────┐
│         Nginx Reverse Proxy              │
│    ├── api.radio.audace.ovh:443         │
│    └── radio.audace.ovh:443             │
└──────────┬──────────────┬───────────────┘
           │              │
           │              │
  ┌────────▼─────────┐   │
  │   FastAPI (8002) │   │
  │   - JWT Auth     │   │
  │   - REST API     │   │
  │   - Swagger Docs │   │
  └────────┬─────────┘   │
           │              │
    ┌──────▼──────┐      │
    │ PostgreSQL  │      │
    │   (5432)    │      │
    │ - Alembic   │      │
    │ - Migrations│      │
    └─────────────┘      │
                         │
                  ┌──────▼──────┐
                  │   Icecast    │
                  │   (8000)     │
                  │ - /stream.mp3│
                  └──────────────┘
```

## 📦 Prérequis du repository

### Technologies API Audace

**Repository** : https://github.com/lwilly3/api.audace.git

#### Stack technique
- **Framework** : FastAPI 0.109+
- **Python** : 3.11+
- **ORM** : SQLAlchemy 2.0+
- **Migrations** : Alembic
- **Authentification** : JWT (python-jose)
- **Validation** : Pydantic v2
- **ASGI Server** : Uvicorn + Gunicorn

#### Structure attendue
```
api.audace/
├── app/
│   ├── main.py              # Point d'entrée FastAPI
│   ├── models/              # Modèles SQLAlchemy
│   ├── schemas/             # Schémas Pydantic
│   ├── routers/             # Endpoints API
│   ├── core/
│   │   ├── config.py        # Configuration
│   │   ├── security.py      # JWT & Auth
│   │   └── database.py      # Connexion DB
│   └── dependencies.py      # Dépendances FastAPI
├── alembic/                 # Migrations DB
│   ├── versions/
│   └── env.py
├── requirements.txt         # Dépendances Python
├── alembic.ini             # Config Alembic
└── .env.example            # Template variables
```

#### Dépendances critiques

**API Core** :
```txt
fastapi==0.109.0
uvicorn[standard]==0.27.0
gunicorn==21.2.0
pydantic==2.5.0
pydantic-settings==2.1.0
```

**Base de données** :
```txt
sqlalchemy==2.0.25
alembic==1.13.1
psycopg2-binary==2.9.9
asyncpg==0.29.0
```

**Authentification** :
```txt
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
```

**Utilitaires** :
```txt
python-dotenv==1.0.0
email-validator==2.1.0
```

### Configuration FastAPI

Le fichier `app/core/config.py` doit exposer ces settings :

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str
    
    # JWT
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRATION_MINUTE: int = 30
    
    # CORS
    CORS_ORIGINS: list[str] = ["*"]
    
    # App
    PROJECT_NAME: str = "API Audace"
    VERSION: str = "1.0.0"
    
    class Config:
        env_file = ".env"
```

## 🔐 Variables d'environnement

### Variables API (Critiques)

#### DATABASE_URL
```bash
DATABASE_URL=postgresql://audace_user:SecurePass123!@postgres:5432/audace_db
```
**Description** : URL de connexion PostgreSQL  
**Format** : `postgresql://[user]:[password]@[host]:[port]/[database]`  
**Priorité** : ⚠️ **CRITIQUE**  
**Sécurité** : 🔒 **SECRET**

#### SECRET_KEY
```bash
SECRET_KEY=VotreCleSecrete256BitsMinimum1234567890ABCDEF
```
**Description** : Clé secrète pour signer les JWT  
**Exigences** : Minimum 32 caractères alphanumériques  
**Priorité** : ⚠️ **CRITIQUE**  
**Sécurité** : 🔒 **SECRET**

**Générer une clé sécurisée** :
```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

#### ALGORITHM
```bash
ALGORITHM=HS256
```
**Description** : Algorithme de signature JWT  
**Valeurs** : `HS256` (recommandé) | `HS384` | `HS512`  
**Priorité** : ⚠️ **CRITIQUE**

#### ACCESS_TOKEN_EXPIRATION_MINUTE
```bash
ACCESS_TOKEN_EXPIRATION_MINUTE=30
```
**Description** : Durée de validité des tokens JWT (en minutes)  
**Recommandé** : 30-60 minutes pour la sécurité  
**Priorité** : 🔵 **IMPORTANTE**

#### CORS_ORIGINS
```bash
CORS_ORIGINS=https://app.radioaudace.com,https://staging.app.radioaudace.com
```
**Description** : Origines autorisées pour CORS (séparées par des virgules)  
**Priorité** : ⚠️ **CRITIQUE**  
**Sécurité** : ⚠️ Ne JAMAIS utiliser `*` en production

### Variables PostgreSQL

#### POSTGRES_USER
```bash
POSTGRES_USER=audace_user
```
**Description** : Nom d'utilisateur PostgreSQL  
**Priorité** : ⚠️ **CRITIQUE**

#### POSTGRES_PASSWORD
```bash
POSTGRES_PASSWORD=SecurePass123!
```
**Description** : Mot de passe PostgreSQL  
**Exigences** : Minimum 12 caractères, lettres + chiffres + symboles  
**Priorité** : ⚠️ **CRITIQUE**  
**Sécurité** : 🔒 **SECRET**

#### POSTGRES_DB
```bash
POSTGRES_DB=audace_db
```
**Description** : Nom de la base de données  
**Priorité** : ⚠️ **CRITIQUE**

### Variables Icecast

#### ICECAST_ADMIN_PASSWORD
```bash
ICECAST_ADMIN_PASSWORD=AdminSecure123!
```
**Description** : Mot de passe admin Icecast (interface /admin)  
**Priorité** : ⚠️ **CRITIQUE**  
**Sécurité** : 🔒 **SECRET**

#### ICECAST_SOURCE_PASSWORD
```bash
ICECAST_SOURCE_PASSWORD=SourceSecure123!
```
**Description** : Mot de passe pour les sources audio (diffuseurs)  
**Priorité** : ⚠️ **CRITIQUE**  
**Sécurité** : 🔒 **SECRET**

#### ICECAST_RELAY_PASSWORD
```bash
ICECAST_RELAY_PASSWORD=RelaySecure123!
```
**Description** : Mot de passe pour les relais Icecast  
**Priorité** : 🟢 **OPTIONNELLE**  
**Sécurité** : 🔒 **SECRET**

#### ICECAST_HOSTNAME
```bash
ICECAST_HOSTNAME=radio.audace.ovh
```
**Description** : Nom de domaine du serveur Icecast  
**Priorité** : 🔵 **IMPORTANTE**

#### ICECAST_MAX_CLIENTS
```bash
ICECAST_MAX_CLIENTS=1000
```
**Description** : Nombre maximum d'auditeurs simultanés  
**Impact ressources** :
- 100 clients ≈ 2.5 MB/s (stream 128kbps)
- 1000 clients ≈ 25 MB/s
**Priorité** : 🟢 **OPTIONNELLE**

### Variables optionnelles

#### LOG_LEVEL
```bash
LOG_LEVEL=info
```
**Valeurs** : `debug` | `info` | `warning` | `error`  
**Recommandé** :
- Dev : `debug`
- Staging : `info`
- Production : `warning`

#### API_WORKERS
```bash
API_WORKERS=4
```
**Description** : Nombre de workers Gunicorn  
**Calcul** : `(2 × CPU_cores) + 1`  
**Exemple** : 2 cores → 5 workers

#### TZ
```bash
TZ=Europe/Paris
```
**Description** : Fuseau horaire des conteneurs  
**Impact** : Timestamps dans logs et base de données

## 🚀 Installation

### Étape 1 : Cloner le repository

```bash
git clone https://github.com/lwilly3/scripts-radioManager.git
cd scripts-radioManager/Docker/api-audace-docker
```

### Étape 2 : Créer le fichier .env

```bash
cp .env.example .env
nano .env
```

Remplissez toutes les variables marquées comme **CRITIQUE**.

### Étape 3 : Générer les secrets

```bash
# SECRET_KEY
python3 -c "import secrets; print(f'SECRET_KEY={secrets.token_urlsafe(32)}')" >> .env

# Mots de passe PostgreSQL et Icecast
# Utilisez un gestionnaire de mots de passe ou openssl
openssl rand -base64 32
```

### Étape 4 : Valider la configuration

```bash
# Vérifier que les variables critiques sont définies
./validate-env.sh
```

### Étape 5 : Lancer la stack

```bash
# Construction et démarrage
docker-compose up -d

# Suivre les logs
docker-compose logs -f
```

### Étape 6 : Vérifier les services

```bash
# Statut des conteneurs
docker-compose ps

# Santé de l'API
curl https://api.radio.audace.ovh/health

# Santé d'Icecast
curl https://radio.audace.ovh/status.xsl

# Documentation Swagger
# Ouvrir https://api.radio.audace.ovh/docs
```

## ⚙️ Configuration avancée

### Migrations Alembic

```bash
# Entrer dans le conteneur API
docker-compose exec api bash

# Créer une nouvelle migration
alembic revision --autogenerate -m "Description"

# Appliquer les migrations
alembic upgrade head

# Rollback d'une migration
alembic downgrade -1
```

### Backup de la base de données

```bash
# Backup manuel
docker-compose exec postgres pg_dump -U audace_user audace_db > backup.sql

# Restauration
cat backup.sql | docker-compose exec -T postgres psql -U audace_user audace_db
```

### Scaling de l'API

```bash
# Lancer 3 instances de l'API
docker-compose up -d --scale api=3

# Nginx load balancer automatiquement
```

## 📊 Monitoring

### Endpoints de santé

```bash
# API Health Check
GET https://api.radio.audace.ovh/health
# Réponse: {"status": "healthy", "database": "connected"}

# Icecast Stats
GET https://radio.audace.ovh/status-json.xsl
# Réponse: JSON avec nombre d'auditeurs, sources, etc.
```

### Logs centralisés

```bash
# Tous les services
docker-compose logs -f

# API uniquement
docker-compose logs -f api

# PostgreSQL
docker-compose logs -f postgres

# Icecast
docker-compose logs -f icecast
```

### Métriques Docker

```bash
# Utilisation ressources en temps réel
docker stats

# Inspection d'un conteneur
docker inspect api-audace-api
```

## 🐛 Dépannage

### API ne démarre pas

```bash
# Vérifier les logs
docker-compose logs api

# Erreurs courantes :
# 1. DATABASE_URL invalide
#    → Vérifier .env et que PostgreSQL est démarré

# 2. SECRET_KEY manquant
#    → Définir dans .env

# 3. Port 8002 déjà utilisé
#    → Changer APP_PORT dans docker-compose.yml
```

### Erreur de connexion à la base de données

```bash
# Vérifier que PostgreSQL est actif
docker-compose ps postgres

# Tester la connexion manuellement
docker-compose exec postgres psql -U audace_user -d audace_db -c "SELECT 1;"

# Recréer la base si nécessaire
docker-compose down -v
docker-compose up -d
```

### Icecast ne diffuse pas

```bash
# Vérifier les logs Icecast
docker-compose logs icecast

# Tester l'accès au stream
curl -I https://radio.audace.ovh/stream.mp3

# Vérifier les mots de passe sources
# Dans votre logiciel de diffusion (BUTT, Mixxx) :
# - Host: radio.audace.ovh
# - Port: 443 (HTTPS) ou 8000 (HTTP direct)
# - Password: ICECAST_SOURCE_PASSWORD
```

### Certificats SSL expirés

```bash
# Sur l'hôte (pas dans Docker)
sudo certbot renew --force-renewal

# Recharger Nginx
docker-compose restart nginx
```

## 📚 Ressources

- **API Audace Repository** : https://github.com/lwilly3/api.audace.git
- **FastAPI Docs** : https://fastapi.tiangolo.com/
- **SQLAlchemy** : https://docs.sqlalchemy.org/
- **Alembic** : https://alembic.sqlalchemy.org/
- **Icecast** : https://icecast.org/docs/

---

<div align="center">

**Questions ?** Ouvrez une [issue sur GitHub](https://github.com/lwilly3/scripts-radioManager/issues)

Made with ❤️ for Radio Audace

</div>
