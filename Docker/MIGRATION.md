# 🔄 Guide de Migration vers Docker

> **Guide complet pour migrer une installation classique vers Docker**

## 📋 Table des matières

- [Pourquoi migrer ?](#-pourquoi-migrer-)
- [Avant de commencer](#-avant-de-commencer)
- [Migration RadioManager Frontend](#-migration-radiomanager-frontend)
- [Migration API Audace](#-migration-api-audace)
- [Migration complète (Full Stack)](#-migration-complète-full-stack)
- [Vérifications post-migration](#-vérifications-post-migration)
- [Rollback en cas de problème](#-rollback-en-cas-de-problème)
- [FAQ Migration](#-faq-migration)

## 🎯 Pourquoi migrer ?

### Avantages de Docker

| Avant (Installation classique) | Après (Docker) |
|-------------------------------|----------------|
| Configuration dépendante du serveur | Configuration portable |
| Mise à jour risquée | Rollback en 10 secondes |
| Conflits de dépendances possibles | Isolation complète |
| Scaling complexe | Scaling avec `docker-compose scale` |
| Backup compliqué | Volumes Docker facilement sauvegardés |
| Reproduction difficile | `docker-compose.yml` reproductible |

### Inconvénients à considérer

- ⚠️ Overhead mémoire (200-300 MB par service)
- ⚠️ Courbe d'apprentissage Docker nécessaire
- ⚠️ Debugging légèrement plus complexe

## ✅ Avant de commencer

### Prérequis

```bash
# Vérifier l'espace disque disponible (min 10GB recommandé)
df -h /

# Installer Docker et Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Vérifier les versions
docker --version
docker-compose --version
```

### Checklist pré-migration

- [ ] **Backup complet** de la base de données
- [ ] **Backup des fichiers** de configuration
- [ ] **Noter les variables** d'environnement actuelles
- [ ] **Temps de downtime** planifié (15-30 min)
- [ ] **Test sur environnement** de staging (recommandé)
- [ ] **Communication** aux utilisateurs
- [ ] **Plan de rollback** documenté

### Estimer le downtime

| Type de migration | Downtime estimé | Peut être réduit à |
|-------------------|-----------------|---------------------|
| Frontend seul | 5-10 min | 2 min (avec préparation) |
| API seule | 10-15 min | 5 min (avec volumes prêts) |
| Stack complète | 20-30 min | 10 min (migration progressive) |

## 🌐 Migration RadioManager Frontend

### Étape 1 : Sauvegarde de l'existant

```bash
# Créer un dossier de backup
sudo mkdir -p /backup/radiomanager-$(date +%Y%m%d)

# Sauvegarder la configuration Nginx
sudo cp -r /etc/nginx/sites-available /backup/radiomanager-$(date +%Y%m%d)/

# Sauvegarder le code source
sudo tar -czf /backup/radiomanager-$(date +%Y%m%d)/app.tar.gz /home/radiomanager/app

# Sauvegarder les certificats SSL
sudo cp -r /etc/letsencrypt /backup/radiomanager-$(date +%Y%m%d)/
```

### Étape 2 : Noter les variables actuelles

```bash
# Extraire les variables du service systemd
sudo cat /etc/systemd/system/radiomanager-frontend.service

# Ou du fichier .env
cat /home/radiomanager/app/.env
```

Créer un fichier de mapping :
```bash
# variables-mapping.txt
INSTALLATION_CLASSIQUE → DOCKER
API_URL → VITE_API_BASE_URL
STREAM_URL → VITE_STREAM_URL
```

### Étape 3 : Arrêter les services existants

```bash
# Arrêter le service systemd
sudo systemctl stop radiomanager-frontend

# Désactiver le démarrage automatique (garde le service pour rollback)
sudo systemctl disable radiomanager-frontend

# Arrêter Nginx temporairement
sudo systemctl stop nginx
```

### Étape 4 : Préparer Docker

```bash
# Cloner le repository
cd /opt
git clone https://github.com/lwilly3/scripts-radioManager.git
cd scripts-radioManager/Docker/radioManager-docker

# Créer le fichier .env
cp .env.example .env
nano .env
```

Remplir avec les valeurs de l'ancienne installation :
```bash
VITE_API_BASE_URL=https://api.radio.audace.ovh
VITE_STREAM_URL=https://radio.audace.ovh/stream.mp3
VITE_APP_TITLE=Radio Audace
# ... autres variables
```

### Étape 5 : Lancer Docker

```bash
# Construire et démarrer
docker-compose up -d --build

# Vérifier les logs
docker-compose logs -f
```

### Étape 6 : Migrer la configuration Nginx

```bash
# Backup de la config Docker par défaut
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

# Adapter votre ancienne config pour pointer vers Docker
sudo nano /etc/nginx/sites-available/app.radioaudace.com
```

Modifier le `proxy_pass` :
```nginx
location / {
    proxy_pass http://localhost:80;  # Port Docker
    # ...reste de la config identique
}
```

```bash
# Tester et recharger Nginx
sudo nginx -t
sudo systemctl start nginx
sudo systemctl reload nginx
```

### Étape 7 : Tests

```bash
# Test local
curl -I http://localhost:80

# Test depuis l'extérieur
curl -I https://app.radioaudace.com

# Vérifier les logs Docker
docker-compose logs radiomanager | grep error
```

---

## 🔧 Migration API Audace

### Étape 1 : Backup de la base de données

```bash
# Créer un backup PostgreSQL complet
sudo -u postgres pg_dump audace_db > /backup/audace_db_$(date +%Y%m%d).sql

# Vérifier le backup
ls -lh /backup/audace_db_*.sql
```

### Étape 2 : Exporter les variables d'environnement

```bash
# Depuis le fichier .env de l'API
cat /home/audace/app/.env > /backup/env_backup.txt

# Extraire les secrets importants
grep "SECRET_KEY\|DB_PASSWORD\|ICECAST" /home/audace/app/.env
```

### Étape 3 : Arrêter les services

```bash
# API
sudo systemctl stop api

# PostgreSQL (attention : fera planter d'autres services si partagé)
sudo systemctl stop postgresql

# Icecast
sudo systemctl stop icecast2
```

### Étape 4 : Préparer Docker Compose

```bash
cd /opt/scripts-radioManager/Docker/api-audace-docker

# Créer le .env avec les vraies valeurs
cp .env.example .env
nano .env
```

Remplir les secrets depuis `/backup/env_backup.txt`.

### Étape 5 : Importer la base de données

```bash
# Démarrer uniquement PostgreSQL
docker-compose up -d postgres

# Attendre que PostgreSQL soit prêt (30 secondes)
sleep 30

# Importer le backup
cat /backup/audace_db_20241215.sql | docker-compose exec -T postgres psql -U audace_user audace_db

# Vérifier
docker-compose exec postgres psql -U audace_user -d audace_db -c "SELECT COUNT(*) FROM users;"
```

### Étape 6 : Démarrer toute la stack

```bash
# Lancer API + Icecast
docker-compose up -d

# Vérifier les logs
docker-compose logs -f api
docker-compose logs -f icecast
```

### Étape 7 : Tests

```bash
# Health check API
curl https://api.radio.audace.ovh/health

# Test authentification
curl -X POST https://api.radio.audace.ovh/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"test"}'

# Test stream Icecast
curl -I https://radio.audace.ovh/stream.mp3
```

---

## 🚀 Migration complète (Full Stack)

### Stratégie : Migration progressive (Downtime minimal)

```
Étape 1 : Migrer Icecast (service indépendant) → 5 min downtime
   ↓
Étape 2 : Migrer PostgreSQL (avec réplication) → 0 min downtime
   ↓
Étape 3 : Migrer API (basculement Blue/Green) → 2 min downtime
   ↓
Étape 4 : Migrer Frontend (avec cache CDN) → 0 min downtime
```

### Script de migration automatique

```bash
#!/bin/bash
# migrate-to-docker.sh

set -e

echo "🔄 Migration vers Docker démarrée..."

# 1. Backups
echo "📦 Backups en cours..."
sudo -u postgres pg_dump audace_db > /backup/audace_db_$(date +%Y%m%d).sql
tar -czf /backup/app_$(date +%Y%m%d).tar.gz /home/audace/app /home/radiomanager/app

# 2. Arrêter les services
echo "⏸️  Arrêt des services..."
sudo systemctl stop api radiomanager-frontend icecast2

# 3. Démarrer Docker
echo "🐳 Démarrage Docker..."
cd /opt/scripts-radioManager/Docker/api-audace-docker
docker-compose up -d postgres
sleep 30

# 4. Importer la base
echo "📊 Import base de données..."
cat /backup/audace_db_$(date +%Y%m%d).sql | docker-compose exec -T postgres psql -U audace_user audace_db

# 5. Démarrer tout
echo "🚀 Démarrage de tous les services..."
docker-compose up -d

# 6. Tests
echo "✅ Tests..."
sleep 10
curl -f http://localhost:8002/health || { echo "❌ API KO"; exit 1; }
curl -f http://localhost:80/ || { echo "❌ Frontend KO"; exit 1; }

echo "✅ Migration réussie !"
echo "🔍 Vérifiez les logs : docker-compose logs -f"
```

---

## 🔍 Vérifications post-migration

### Checklist de validation

```bash
# 1. Tous les conteneurs actifs
docker-compose ps
# Attendu : tous "Up"

# 2. Health checks OK
docker-compose ps | grep healthy

# 3. Logs sans erreurs
docker-compose logs --tail=50 | grep -i error

# 4. Base de données accessible
docker-compose exec postgres psql -U audace_user -d audace_db -c "SELECT 1;"

# 5. API répond
curl -I https://api.radio.audace.ovh/docs

# 6. Frontend accessible
curl -I https://app.radioaudace.com

# 7. Stream fonctionne
curl -I https://radio.audace.ovh/stream.mp3

# 8. SSL valide
curl -vI https://api.radio.audace.ovh 2>&1 | grep "SSL certificate verify ok"

# 9. Authentification fonctionne
# Tester le login sur l'interface web

# 10. Logs persistants
ls -la docker-volumes/logs
```

### Performance : Avant/Après

```bash
# Mesurer le temps de réponse API
time curl https://api.radio.audace.ovh/health

# Avant : ~50-100ms
# Après Docker : ~60-120ms (acceptable)
```

---

## ↩️ Rollback en cas de problème

### Si migration échouée < 1h

```bash
# 1. Arrêter Docker
docker-compose down

# 2. Restaurer les services classiques
sudo systemctl start postgresql
sudo systemctl start api
sudo systemctl start radiomanager-frontend
sudo systemctl start icecast2
sudo systemctl start nginx

# 3. Vérifier
systemctl status api radiomanager-frontend
```

### Si besoin de restaurer la base

```bash
# 1. Arrêter PostgreSQL
sudo systemctl stop postgresql

# 2. Restaurer le backup
sudo -u postgres psql audace_db < /backup/audace_db_20241215.sql

# 3. Redémarrer
sudo systemctl start postgresql
```

---

## ❓ FAQ Migration

**Q: Puis-je garder l'installation classique en parallèle ?**  
R: Oui ! Changez les ports Docker (8080:80, 8003:8002) pour éviter les conflits.

**Q: Combien de temps prend la migration complète ?**  
R: 20-30 minutes en moyenne, 10 minutes si bien préparée.

**Q: Puis-je migrer progressivement (service par service) ?**  
R: Oui, c'est même recommandé pour minimiser le downtime.

**Q: Les performances sont-elles impactées ?**  
R: Overhead de 5-10% en latence, mais scalabilité bien meilleure.

**Q: Comment revenir en arrière si problème ?**  
R: Arrêter Docker, redémarrer les services systemd classiques (voir section Rollback).

---

<div align="center">

**Besoin d'aide ?** Ouvrez une [issue sur GitHub](https://github.com/lwilly3/scripts-radioManager/issues)

</div>
