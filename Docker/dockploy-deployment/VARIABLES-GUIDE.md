# 📋 Guide Complet des Variables d'Environnement

> **Guide de référence pour la configuration des variables d'environnement dans RadioManager et API Audace**

## 📚 Table des matières

- [Concepts de base](#-concepts-de-base)
- [RadioManager Frontend](#-radiomanager-frontend)
- [API Audace Backend](#-api-audace-backend)
- [Stack complète](#-stack-complète)
- [Priorités et résolution](#-priorités-et-résolution)
- [Sécurité](#-sécurité)
- [Exemples complets](#-exemples-complets)
- [Troubleshooting](#-troubleshooting)

## 🎯 Concepts de base

### Qu'est-ce qu'une variable d'environnement ?

Une variable d'environnement est une valeur dynamique qui peut affecter le comportement d'un programme. Elles permettent de :

1. **Séparer la configuration du code** : Le code reste générique, la config est externe
2. **Adapter l'app aux environnements** : Dev, staging, production avec configs différentes
3. **Sécuriser les secrets** : Clés API, mots de passe ne sont pas dans le code
4. **Faciliter le déploiement** : Changer de config sans modifier le code

### Nomenclature

```bash
# Format standard
NOM_VARIABLE=valeur

# Conventions de nommage
MAJUSCULES_AVEC_UNDERSCORES  # Standard Unix/Linux
PascalCase                   # Moins courant
kebab-case                   # Jamais (invalide)

# Préfixes spéciaux
VITE_*     # Variables exposées au frontend Vite
REACT_APP_* # Variables exposées à React
NEXT_PUBLIC_* # Variables exposées à Next.js
```

### Portée des variables

```
┌─────────────────────────────────────────┐
│         Système d'exploitation          │  ← Variables système (PATH, HOME)
├─────────────────────────────────────────┤
│         Docker Compose / Host           │  ← Variables host (.env, export)
├─────────────────────────────────────────┤
│         Conteneur Docker                │  ← Variables conteneur (docker-compose.yml)
├─────────────────────────────────────────┤
│    Application (Node.js/Python)         │  ← Variables runtime (process.env)
├─────────────────────────────────────────┤
│    Frontend (Vite/React)                │  ← Variables build-time (import.meta.env)
└─────────────────────────────────────────┘
```

## 🎨 RadioManager Frontend

### Variables obligatoires

#### NODE_ENV

```bash
NODE_ENV=production
```

**Description** : Définit l'environnement d'exécution de Node.js

**Valeurs possibles** :
- `development` : Mode développement (debug activé, hot reload)
- `staging` : Pré-production (proche de prod mais avec logs verbeux)
- `production` : Production (optimisé, minifié, logs minimaux)
- `test` : Tests automatisés

**Impact** :
- ✅ Optimisations du build (minification, tree-shaking)
- ✅ Niveau de logs
- ✅ Source maps (activées en dev, désactivées en prod)
- ✅ Mode strict de frameworks

**Priorité** : ⚠️ **CRITIQUE**

**Exemple d'utilisation** :
```javascript
if (import.meta.env.MODE === 'development') {
  console.log('Mode debug activé');
}
```

---

#### VITE_API_URL

```bash
VITE_API_URL=https://api.radio.audace.ovh
```

**Description** : URL complète de l'API backend

**Format attendu** : `https://domaine.com` ou `https://domaine.com/api`

**Impact** :
- ✅ Toutes les requêtes HTTP vers le backend
- ✅ Gestion CORS
- ✅ WebSockets (si applicable)

**Priorité** : ⚠️ **CRITIQUE**

**Validation** :
```javascript
// Vérification automatique au démarrage
const apiUrl = import.meta.env.VITE_API_URL;
if (!apiUrl) {
  throw new Error('VITE_API_URL est obligatoire');
}
if (!apiUrl.startsWith('http')) {
  throw new Error('VITE_API_URL doit commencer par http:// ou https://');
}
```

**Erreurs courantes** :
```bash
# ❌ Mauvais
VITE_API_URL=api.radio.audace.ovh        # Manque http(s)://
VITE_API_URL=https://api.radio.audace.ovh/  # Trailing slash (peut causer des problèmes)

# ✅ Bon
VITE_API_URL=https://api.radio.audace.ovh
```

### Variables optionnelles

#### VITE_STREAM_URL

```bash
VITE_STREAM_URL=https://radio.audace.ovh/stream.mp3
```

**Description** : URL du flux audio en direct

**Défaut** : `null` (fonctionnalité streaming désactivée)

**Formats supportés** :
- `.mp3` : Stream MP3 (recommandé)
- `.ogg` : Stream Ogg Vorbis
- `.aac` : Stream AAC
- `.m3u8` : Stream HLS (iOS/Safari)

**Priorité** : 🔵 **IMPORTANTE**

**Utilisation** :
```javascript
const streamUrl = import.meta.env.VITE_STREAM_URL;
if (streamUrl) {
  audio.src = streamUrl;
  audio.play();
} else {
  console.warn('Streaming désactivé : VITE_STREAM_URL non défini');
}
```

---

#### VITE_APP_NAME

```bash
VITE_APP_NAME=Radio Audace
```

**Description** : Nom de l'application affiché dans l'interface

**Défaut** : `RadioManager`

**Priorité** : 🟢 **OPTIONNELLE**

**Utilisation** :
- `<title>` de la page HTML
- Nom dans la barre de navigation
- Metadata OpenGraph/Twitter

---

#### VITE_APP_TAGLINE

```bash
VITE_APP_TAGLINE=La radio qui ose !
```

**Description** : Slogan ou description courte

**Défaut** : `""` (vide)

**Priorité** : 🟢 **OPTIONNELLE**

---

#### VITE_THEME_PRIMARY_COLOR

```bash
VITE_THEME_PRIMARY_COLOR=#FF6B6B
```

**Description** : Couleur principale du thème

**Format** : Code hexadécimal (`#RRGGBB`)

**Défaut** : `#3B82F6` (bleu)

**Priorité** : 🟢 **OPTIONNELLE**

**Validation** :
```javascript
const color = import.meta.env.VITE_THEME_PRIMARY_COLOR;
if (!/^#[0-9A-Fa-f]{6}$/.test(color)) {
  console.warn('Format de couleur invalide, utilisation du défaut');
}
```

---

#### VITE_ENABLE_ANALYTICS

```bash
VITE_ENABLE_ANALYTICS=true
```

**Description** : Active/désactive Google Analytics ou autre outil de tracking

**Valeurs** : `true` | `false`

**Défaut** : `false`

**Priorité** : 🟢 **OPTIONNELLE**

**Dépendances** : Nécessite `VITE_ANALYTICS_ID` si activé

---

#### VITE_ANALYTICS_ID

```bash
VITE_ANALYTICS_ID=G-XXXXXXXXXX
```

**Description** : ID de mesure Google Analytics 4

**Format** : `G-XXXXXXXXXX` (GA4) ou `UA-XXXXXXXX-X` (Universal Analytics)

**Défaut** : `null`

**Priorité** : 🟢 **OPTIONNELLE**

---

#### VITE_ENABLE_PWA

```bash
VITE_ENABLE_PWA=true
```

**Description** : Active les fonctionnalités Progressive Web App

**Impact** :
- Service Worker pour cache offline
- Installation sur écran d'accueil mobile
- Notifications push (si configurées)

**Valeurs** : `true` | `false`

**Défaut** : `false`

**Priorité** : 🟢 **OPTIONNELLE**

---

#### VITE_ENABLE_DEBUG

```bash
VITE_ENABLE_DEBUG=true
```

**Description** : Active les logs de debug dans la console

**Recommandé** :
- `true` en développement
- `false` en staging/production

**Impact sur performance** : Minimal (mais logs verbeux)

**Priorité** : 🟢 **OPTIONNELLE**

---

### Variables système (Docker)

#### APP_PORT

```bash
APP_PORT=80
```

**Description** : Port d'écoute du serveur Nginx dans le conteneur

**Défaut** : `80`

**Usage** : Rarement modifié (géré par Docker port mapping)

---

#### TZ

```bash
TZ=Europe/Paris
```

**Description** : Fuseau horaire du conteneur

**Défaut** : `UTC`

**Impact** :
- Timestamps dans les logs
- Dates affichées dans l'interface

**Valeurs** : [Liste IANA](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

---

## 🔧 API Audace Backend

### Variables obligatoires

#### DATABASE_URL

```bash
DATABASE_URL=postgresql://user:password@postgres:5432/audace_db
```

**Description** : URL de connexion à PostgreSQL

**Format** : `postgresql://[user]:[password]@[host]:[port]/[database]`

**Priorité** : ⚠️ **CRITIQUE**

**Sécurité** : 🔒 **SECRET** - Ne JAMAIS exposer publiquement

**Validation** :
```python
import re
pattern = r'postgresql://[\w]+:[\w]+@[\w\.]+:\d+/[\w]+'
if not re.match(pattern, os.getenv('DATABASE_URL')):
    raise ValueError('DATABASE_URL invalide')
```

---

#### SECRET_KEY

```bash
SECRET_KEY=VotreCleSecrete256BitsMinimum1234567890ABCDEF
```

**Description** : Clé secrète pour chiffrement JWT, sessions, CSRF

**Exigences** :
- Minimum 32 caractères
- Caractères alphanumériques + symboles
- Unique par environnement

**Priorité** : ⚠️ **CRITIQUE**

**Sécurité** : 🔒 **SECRET**

**Génération sécurisée** :
```bash
# Python
python -c "import secrets; print(secrets.token_urlsafe(32))"

# OpenSSL
openssl rand -base64 32

# Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

---

#### CORS_ORIGINS

```bash
CORS_ORIGINS=https://app.radioaudace.com,https://staging.app.radioaudace.com
```

**Description** : Liste des origines autorisées pour les requêtes CORS

**Format** : URLs séparées par des virgules (sans espaces)

**Priorité** : ⚠️ **CRITIQUE**

**Sécurité** : Ne PAS utiliser `*` en production

**Exemple multi-environnements** :
```bash
# Dev
CORS_ORIGINS=http://localhost:3000,http://localhost:5173

# Staging
CORS_ORIGINS=https://staging.app.radioaudace.com

# Production
CORS_ORIGINS=https://app.radioaudace.com
```

---

### Variables de base de données

#### DB_NAME

```bash
DB_NAME=audace_db
```

**Défaut** : `audace_db`

---

#### DB_USER

```bash
DB_USER=audace_user
```

**Défaut** : `audace_user`

---

#### DB_PASSWORD

```bash
DB_PASSWORD=VotreMotDePasseSecurise123!
```

**Priorité** : ⚠️ **CRITIQUE**

**Sécurité** : 🔒 **SECRET**

**Exigences** :
- Minimum 12 caractères
- Lettres, chiffres, symboles
- Pas de mots du dictionnaire

---

### Variables Icecast

#### ICECAST_ADMIN_PASSWORD

```bash
ICECAST_ADMIN_PASSWORD=AdminPassword123!
```

**Description** : Mot de passe pour l'interface d'administration Icecast

**Priorité** : ⚠️ **CRITIQUE**

**Sécurité** : 🔒 **SECRET**

**Accès** : `https://radio.audace.ovh/admin`

---

#### ICECAST_SOURCE_PASSWORD

```bash
ICECAST_SOURCE_PASSWORD=SourcePassword123!
```

**Description** : Mot de passe pour les sources audio (diffuseurs)

**Priorité** : ⚠️ **CRITIQUE**

**Sécurité** : 🔒 **SECRET**

**Usage** : Configuration dans le logiciel de diffusion (BUTT, Mixxx, etc.)

---

#### ICECAST_MAX_CLIENTS

```bash
ICECAST_MAX_CLIENTS=1000
```

**Description** : Nombre maximum d'auditeurs simultanés

**Défaut** : `100`

**Impact sur ressources** :
```
100 clients = ~2.5 MB/s bande passante (128kbps stream)
1000 clients = ~25 MB/s bande passante
```

---

### Variables optionnelles

#### LOG_LEVEL

```bash
LOG_LEVEL=info
```

**Valeurs** :
- `debug` : Tous les logs (développement)
- `info` : Informations + warnings + erreurs (staging)
- `warning` : Warnings + erreurs (production)
- `error` : Erreurs uniquement (production critique)

**Défaut** : `info`

---

#### API_WORKERS

```bash
API_WORKERS=4
```

**Description** : Nombre de workers Gunicorn/Uvicorn

**Calcul recommandé** : `(2 × CPU_cores) + 1`

**Exemple** :
- 2 CPU cores → 5 workers
- 4 CPU cores → 9 workers

---

## 📦 Stack complète

### Exemple de configuration complète

```env
# ============================================
# RADIOMANAGER + API AUDACE - PRODUCTION
# ============================================

# === FRONTEND (RadioManager) ===
NODE_ENV=production
VITE_API_URL=https://api.radio.audace.ovh
VITE_STREAM_URL=https://radio.audace.ovh/stream.mp3
VITE_APP_NAME=Radio Audace
VITE_APP_TAGLINE=La radio qui ose !
VITE_THEME_PRIMARY_COLOR=#FF6B6B
VITE_ENABLE_ANALYTICS=true
VITE_ANALYTICS_ID=G-PROD123456
VITE_ENABLE_PWA=true

# === BACKEND (API) ===
DATABASE_URL=postgresql://audace_user:SecurePass123!@postgres:5432/audace_db
SECRET_KEY=VotreCleSecrete256BitsMinimum1234567890ABCDEF
CORS_ORIGINS=https://app.radioaudace.com
LOG_LEVEL=warning
API_WORKERS=4

# === DATABASE ===
DB_NAME=audace_db
DB_USER=audace_user
DB_PASSWORD=SecurePass123!

# === ICECAST ===
ICECAST_ADMIN_PASSWORD=AdminSecure123!
ICECAST_SOURCE_PASSWORD=SourceSecure123!
ICECAST_RELAY_PASSWORD=RelaySecure123!
ICECAST_HOSTNAME=radio.audace.ovh
ICECAST_MAX_CLIENTS=1000
ICECAST_MAX_SOURCES=10

# === REDIS (Cache) ===
REDIS_PASSWORD=RedisSecure123!
REDIS_MAX_MEMORY=256mb

# === SYSTÈME ===
TZ=Europe/Paris
```

## 🔐 Priorités et résolution

### Ordre de résolution

```
1. Variables shell (export)                    ← Priorité MAXIMALE
2. Variables Dockploy Interface               ← Recommandé
3. Variables docker-compose.yml (environment:)
4. Variables fichier .env
5. Variables Dockerfile (ENV)
6. Valeurs par défaut dans le code            ← Priorité MINIMALE
```

### Cas pratiques

#### Cas 1 : Surcharge temporaire

```bash
# Tester une nouvelle URL API sans modifier .env
VITE_API_URL=https://api-test.example.com docker-compose up -d
```

#### Cas 2 : Environnements multiples

```bash
# Structure de fichiers
.env.dev         # Variables de développement
.env.staging     # Variables de staging
.env.production  # Variables de production

# Utilisation
docker-compose --env-file .env.production up -d
```

#### Cas 3 : CI/CD

```yaml
# GitHub Actions
- name: Deploy
  env:
    VITE_API_URL: ${{ secrets.API_URL }}
    DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
  run: docker-compose up -d
```

## 🔒 Sécurité

### Variables sensibles (SECRETS)

**🔒 À PROTÉGER ABSOLUMENT** :
```bash
SECRET_KEY               # Chiffrement JWT
DB_PASSWORD              # Base de données
ICECAST_*_PASSWORD       # Streaming
API_SECRET_KEY           # API interne
ENCRYPTION_KEY           # Chiffrement données
AWS_SECRET_ACCESS_KEY    # Cloud
STRIPE_SECRET_KEY        # Paiement
SENTRY_DSN               # Monitoring
```

### Variables publiques (OK pour frontend)

**✅ SAFE pour exposition** :
```bash
VITE_API_URL             # URL publique
VITE_STREAM_URL          # URL publique
VITE_APP_NAME            # Nom public
VITE_ANALYTICS_ID        # ID public
NODE_ENV                 # Environnement
```

### Bonnes pratiques

1. **Ne JAMAIS commiter les secrets dans Git**
   ```bash
   echo ".env" >> .gitignore
   echo ".env.*" >> .gitignore
   echo "!.env.example" >> .gitignore
   ```

2. **Utiliser des secrets différents par environnement**
   ```bash
   # Dev
   SECRET_KEY=dev_key_1234567890

   # Prod
   SECRET_KEY=prod_totally_different_key_9876543210
   ```

3. **Rotation régulière des secrets**
   ```bash
   # Tous les 90 jours
   python -c "import secrets; print(secrets.token_urlsafe(32))"
   ```

4. **Chiffrer les secrets au repos**
   ```bash
   # Utiliser des outils comme :
   # - HashiCorp Vault
   # - AWS Secrets Manager
   # - Azure Key Vault
   # - 1Password CLI
   ```

## 📝 Exemples complets

### Développement local

```env
NODE_ENV=development
VITE_API_URL=http://localhost:8000
VITE_STREAM_URL=http://localhost:8080/stream.mp3
VITE_ENABLE_DEBUG=true
VITE_ENABLE_ANALYTICS=false
DATABASE_URL=postgresql://dev:dev@localhost:5432/dev_db
SECRET_KEY=dev_key_not_secure_1234567890
CORS_ORIGINS=http://localhost:3000,http://localhost:5173
LOG_LEVEL=debug
```

### Staging

```env
NODE_ENV=staging
VITE_API_URL=https://api-staging.radio.audace.ovh
VITE_STREAM_URL=https://stream-staging.radio.audace.ovh/stream.mp3
VITE_ENABLE_DEBUG=false
VITE_ENABLE_ANALYTICS=true
VITE_ANALYTICS_ID=G-STAGING123
DATABASE_URL=postgresql://staging_user:StgPass123!@db-staging:5432/staging_db
SECRET_KEY=staging_secret_key_9876543210ABCDEF
CORS_ORIGINS=https://staging.app.radioaudace.com
LOG_LEVEL=info
```

### Production

```env
NODE_ENV=production
VITE_API_URL=https://api.radio.audace.ovh
VITE_STREAM_URL=https://radio.audace.ovh/stream.mp3
VITE_APP_NAME=Radio Audace
VITE_ENABLE_ANALYTICS=true
VITE_ANALYTICS_ID=G-PROD123456
VITE_ENABLE_PWA=true
VITE_ENABLE_DEBUG=false
DATABASE_URL=postgresql://prod_user:VerySecurePass123!@db-prod:5432/prod_db
SECRET_KEY=production_secret_key_ABCDEF1234567890
CORS_ORIGINS=https://app.radioaudace.com
LOG_LEVEL=warning
ICECAST_ADMIN_PASSWORD=AdminSecurePassword123!
ICECAST_SOURCE_PASSWORD=SourceSecurePassword123!
TZ=Europe/Paris
```

## 🛠️ Troubleshooting

### Variable non prise en compte

**Symptôme** : Variable définie mais application utilise valeur par défaut

**Solutions** :
```bash
# 1. Vérifier le nom (sensible à la casse)
echo $VITE_API_URL  # doit afficher la valeur

# 2. Vérifier le préfixe VITE_ pour frontend
VITE_MY_VAR=value  # ✅ Visible frontend
MY_VAR=value       # ❌ Non visible frontend

# 3. Reconstruire sans cache
docker-compose build --no-cache
docker-compose up -d

# 4. Vérifier dans le conteneur
docker-compose exec radiomanager env | grep VITE
```

### Variable undefined dans le code

**Symptôme** : `import.meta.env.VITE_API_URL is undefined`

**Causes** :
```javascript
// ❌ Variable non préfixée par VITE_
console.log(import.meta.env.API_URL);  // undefined

// ✅ Variable correctement préfixée
console.log(import.meta.env.VITE_API_URL);  // OK
```

### Secret exposé accidentellement

**Symptôme** : Secret visible dans les logs ou le frontend

**Actions** :
```bash
# 1. ROTATION IMMÉDIATE du secret
python -c "import secrets; print(secrets.token_urlsafe(32))"

# 2. Mettre à jour partout
# - Base de données
# - Variables d'environnement
# - Dockploy/Docker Compose

# 3. Redéployer
docker-compose up -d

# 4. Invalider les sessions/tokens existants
# (dépend de votre API)
```

### Priorité incorrecte

**Symptôme** : Variable shell ignorée

**Solution** :
```bash
# Forcer l'utilisation de la variable shell
unset VITE_API_URL  # Supprimer des autres sources
export VITE_API_URL=https://nouvelle-url.com
docker-compose up -d
```

---

<div align="center">

**Questions ?** Consultez la [documentation principale](README.md)

Made with ❤️ for RadioManager

</div>
