# Persistance des donnees et restauration de la base de donnees

> Ce guide explique comment les donnees survivent aux deploiements,
> comment les sauvegarder, et comment les restaurer en cas de probleme
> (crash serveur, reinstallation, migration de VPS).
>
> **Public** : debutant a intermediaire. Chaque concept est explique.

---

## Table des matieres

- [1. Comprendre la persistance des donnees](#1-comprendre-la-persistance-des-donnees)
  - [Le probleme : les containers sont ephemeres](#le-probleme--les-containers-sont-ephemeres)
  - [La solution : les volumes Docker](#la-solution--les-volumes-docker)
  - [Schema de l'architecture RadioManager](#schema-de-larchitecture-radiomanager)
  - [Ou sont les donnees physiquement ?](#ou-sont-les-donnees-physiquement-)
  - [Que se passe-t-il a chaque deploiement ?](#que-se-passe-t-il-a-chaque-deploiement-)
  - [Quelles donnees sont persistantes ?](#quelles-donnees-sont-persistantes-)
- [2. Backups automatiques](#2-backups-automatiques)
  - [Ce qui est configure par le script](#ce-qui-est-configure-par-le-script)
  - [Verifier que les backups fonctionnent](#verifier-que-les-backups-fonctionnent)
  - [Lancer un backup manuellement](#lancer-un-backup-manuellement)
  - [Telecharger un backup sur votre Mac](#telecharger-un-backup-sur-votre-mac)
- [3. Restaurer la base de donnees](#3-restaurer-la-base-de-donnees)
  - [Scenario A : Restaurer sur le meme serveur](#scenario-a--restaurer-sur-le-meme-serveur)
  - [Scenario B : Reconstruire un serveur complet depuis zero](#scenario-b--reconstruire-un-serveur-complet-depuis-zero)
  - [Scenario C : Migrer vers un nouveau VPS](#scenario-c--migrer-vers-un-nouveau-vps)
- [4. Procedures detaillees](#4-procedures-detaillees)
  - [Procedure 1 : Backup avant une operation risquee](#procedure-1--backup-avant-une-operation-risquee)
  - [Procedure 2 : Restaurer une table supprimee par erreur](#procedure-2--restaurer-une-table-supprimee-par-erreur)
  - [Procedure 3 : Revenir a l'etat d'hier](#procedure-3--revenir-a-letat-dhier)
  - [Procedure 4 : Reconstruction complete du serveur](#procedure-4--reconstruction-complete-du-serveur)
- [5. Bonnes pratiques](#5-bonnes-pratiques)
- [6. Depannage](#6-depannage)
- [7. Glossaire](#7-glossaire)

---

## 1. Comprendre la persistance des donnees

### Le probleme : les containers sont ephemeres

Docker fait tourner les applications dans des **containers**. Un container,
c'est comme une boite isolee avec l'application et tout ce qu'elle a besoin
pour fonctionner.

**Le probleme** : quand un container est supprime (a chaque re-deploiement,
mise a jour, ou restart), tout ce qui est **a l'interieur** disparait :

```
Deploiement v1                Deploiement v2
┌──────────────────┐          ┌──────────────────┐
│  Container       │ DETRUIT  │  Nouveau         │
│  PostgreSQL v1   │ ──────>  │  Container v2    │
│                  │          │                  │
│  tables ✓        │          │  tables ?        │
│  donnees ✓       │          │  donnees ?       │
│  utilisateurs ✓  │          │  → TOUT PERDU    │
└──────────────────┘          └──────────────────┘
```

Sans volume, chaque deploiement repart avec une base de donnees **vide**.

### La solution : les volumes Docker

Un **volume Docker** est un espace de stockage sur le disque du VPS (le vrai
disque dur physique) qui est **branche** a l'interieur du container.

Quand PostgreSQL ecrit des donnees, elles sont en realite ecrites sur le
disque du VPS, pas a l'interieur du container. Quand le container est detruit
et recree, il se rebranche sur le meme volume → il retrouve toutes les donnees.

```
VPS (disque physique)
┌─────────────────────────────────────────────────┐
│                                                 │
│  /var/lib/docker/volumes/postgres_data/_data/   │  ← VOS DONNEES
│  ├── base/                (les tables)          │     (survivent aux
│  ├── global/              (les roles)           │      deploiements)
│  ├── pg_wal/              (les journaux)        │
│  └── postgresql.conf      (la config)           │
│                                                 │
└──────────────────────┬──────────────────────────┘
                       │
                       │  ← "monte" (branche)
                       │
┌──────────────────────▼──────────────────────────┐
│  Container PostgreSQL                           │
│                                                 │
│  /var/lib/postgresql/data/  ← pointe vers le    │
│                                volume ci-dessus │
│                                                 │
│  PostgreSQL lit et ecrit ici, mais les donnees  │
│  sont en fait sur le disque du VPS.             │
└─────────────────────────────────────────────────┘
```

**Analogie** : c'est comme brancher une cle USB dans un ordinateur.
Vous pouvez jeter l'ordinateur (le container) et brancher la cle USB
(le volume) dans un nouvel ordinateur : les fichiers sont toujours la.

### Schema de l'architecture RadioManager

```
Internet
    │
    ▼
┌──────────┐     ┌─────────────┐     ┌───────────────┐
│ Traefik  │────>│ FastAPI     │────>│ PostgreSQL    │
│ (proxy)  │     │ (backend)   │     │ (base de      │
│ SSL/HTTPS│     │ Python      │     │  donnees)     │
└──────────┘     └─────────────┘     └───────┬───────┘
    │                                        │
    │            ┌─────────────┐             │
    └───────────>│ React       │      ┌──────▼──────┐
                 │ (frontend)  │      │  VOLUME     │
                 │ JavaScript  │      │  postgres_  │
                 └─────────────┘      │  data       │
                                      │             │
    Pas de volume                     │  PERSISTANT │
    (recree a chaque deploy)          └─────────────┘

                                      ┌─────────────┐
                                      │  /backup/   │
                                      │  postgres/  │
                                      │             │
                                      │  Dumps SQL  │
                                      │  quotidiens │
                                      └─────────────┘
```

### Ou sont les donnees physiquement ?

| Donnee | Emplacement sur le VPS | Persiste ? |
|--------|----------------------|------------|
| Tables, lignes, index PostgreSQL | `/var/lib/docker/volumes/postgres_data/_data/` | Oui (volume Docker) |
| Backups PostgreSQL (dumps) | `/backup/postgres/` | Oui (fichiers sur le disque) |
| Code FastAPI | Recree a chaque deploy depuis Git | Non (rebuild) |
| Code React (build) | Recree a chaque deploy depuis Git | Non (rebuild) |
| Variables d'environnement | Stockees dans Dokploy | Oui (config Dokploy) |
| Fichiers uploades | Firebase Storage (service externe) | Oui (cloud Google) |
| Firestore (citations, settings) | Firebase Firestore (service externe) | Oui (cloud Google) |
| Configuration Dokploy | `/var/lib/dokploy/` | Oui (disque VPS) |
| Certificats SSL (Let's Encrypt) | Geres par Traefik/Dokploy | Oui (regeneres auto si perdus) |

### Que se passe-t-il a chaque deploiement ?

Quand vous deployez une nouvelle version via Dokploy (push Git ou deploy manuel) :

```
1. Dokploy detecte le nouveau code
   │
2. Dokploy ARRETE l'ancien container (FastAPI ou React)
   │  → Le volume PostgreSQL reste intact (il n'est PAS dans ce container)
   │  → Le container PostgreSQL continue de tourner
   │
3. Dokploy BUILD le nouveau container (npm build / pip install)
   │
4. Dokploy DEMARRE le nouveau container
   │  → Il se connecte au MEME container PostgreSQL
   │  → Toutes les donnees sont la
   │
5. Traefik detecte le nouveau container et route le trafic vers lui
```

**Point important** : le deploiement du frontend ou du backend ne touche
PAS a PostgreSQL. La base de donnees tourne dans son propre container,
avec son propre volume reliee au volume. Elle n'est pas impactee.

**La seule situation ou PostgreSQL redemarre** :
- Si vous deployez une nouvelle version de PostgreSQL (rare)
- Si vous redemarrez manuellement le container
- Si le serveur reboot

Dans tous ces cas, le volume persiste → les donnees sont intactes.

### Quelles donnees sont persistantes ?

Pour RadioManager, voici la carte complete :

```
DONNEES PERSISTANTES (survivent a tout)
├── PostgreSQL (volume Docker)
│   ├── Utilisateurs et authentification
│   ├── Roles et permissions
│   ├── Emissions
│   ├── Conducteurs (shows)
│   ├── Animateurs (presenters)
│   ├── Invites (guests)
│   ├── Segments
│   ├── Logs d'audit
│   ├── Notifications
│   ├── Tokens revoques
│   ├── Secrets 2FA (chiffres)
│   └── Backup codes (hashes)
│
├── Firebase Firestore (cloud)
│   ├── Citations
│   ├── Workflow de statuts
│   ├── Settings par module
│   └── Inventaire (equipements, mouvements, maintenance)
│
├── Firebase Storage (cloud)
│   └── Fichiers uploades (photos, documents)
│
└── Backups SQL (disque VPS)
    └── /backup/postgres/dump_YYYYMMDD.sql.gz (7 derniers jours)

DONNEES NON PERSISTANTES (recreees a chaque deploy)
├── Code source FastAPI (rebuild depuis Git)
├── Code source React (rebuild depuis Git)
├── Cache npm / pip (dans le container)
└── Fichiers temporaires
```

---

## 2. Backups automatiques

### Ce qui est configure par le script

Le script `quick-prepare-vps.sh` v2.1 a installe un **cron job** qui fait :

| Quand | Quoi | Ou | Retention |
|-------|------|-----|-----------|
| Chaque nuit a 3h00 | Dump de la base audace_db (compresse) | `/backup/postgres/dump_YYYYMMDD.sql.gz` | 7 jours |
| Chaque nuit a 3h30 | Suppression des backups > 7 jours | `/backup/postgres/` | — |

**Comment ca marche** :

```
3h00 — Le cron lance cette commande :
  docker exec postgres → pg_dump --clean --if-exists audace_db → gzip → /backup/postgres/dump_20260313.sql.gz

3h30 — Le cron lance cette commande :
  find /backup/postgres/ -mtime +7 -delete → supprime les fichiers > 7 jours
```

`pg_dump --clean --if-exists` exporte la base `audace_db` avec des instructions
`DROP TABLE IF EXISTS` avant chaque `CREATE TABLE`. Le fichier resultant est
directement compatible avec `psql -d audace_db` pour la restauration.

> **Note** : on utilise `pg_dump` (une seule base) et non `pg_dumpall` (cluster entier).
> `pg_dump` est plus adapte car on ne restaure qu'une seule base, et l'option `--clean`
> garantit que les anciennes tables sont supprimees avant d'etre recreees.

Le fichier gzip resultant fait generalement entre 1-10 MB (selon la taille
de votre base). Sept jours de backups = ~70 MB maximum.

### Verifier que les backups fonctionnent

Connectez-vous a votre VPS et verifiez :

```bash
# Lister les backups existants
ls -lh /backup/postgres/

# Resultat attendu (apres au moins une nuit) :
# -rw-r--r-- 1 root root 2.3M Mar 16 03:00 dump_20260316.sql.gz
# -rw-r--r-- 1 root root 2.3M Mar 15 03:00 dump_20260315.sql.gz
# -rw-r--r-- 1 root root 2.1M Mar 14 03:00 dump_20260314.sql.gz
```

**Si le dossier est vide** (pas de backups) :

```bash
# 1. Verifier que le cron est bien configure
cat /etc/cron.d/backup-postgres

# 2. Verifier que le container PostgreSQL tourne
docker ps | grep postgres

# 3. Tester le backup manuellement (voir section suivante)
```

**Verifier qu'un backup n'est pas corrompu** :

```bash
# Tester l'integrite du fichier gzip
gunzip -t /backup/postgres/dump_20260316.sql.gz
# Si aucune erreur → le fichier est valide

# Afficher les premieres lignes du dump (sans decompresser entierement)
zcat /backup/postgres/dump_20260316.sql.gz | head -30
# Vous devriez voir des commandes SQL (CREATE ROLE, CREATE DATABASE, etc.)
```

### Lancer un backup manuellement

Avant une operation risquee (mise a jour majeure, migration), faites
un backup maintenant plutot que d'attendre 3h du matin :

```bash
# Trouver le nom/ID du container PostgreSQL
docker ps | grep postgres
# Exemple de sortie :
# a1b2c3d4e5f6   postgres:15-alpine   ...   audace_db

# Lancer le dump (remplacez le nom du container si different)
docker exec -t audace_db pg_dump --clean --if-exists -U postgres audace_db | \
  gzip > /backup/postgres/dump_manuel_$(date +%Y%m%d_%H%M%S).sql.gz

# Verifier
ls -lh /backup/postgres/dump_manuel_*
```

> **Explication de la commande** :
> - `docker exec -t audace_db` : execute une commande dans le container PostgreSQL
> - `pg_dump --clean --if-exists -U postgres audace_db` : exporte la base audace_db avec DROP TABLE avant chaque CREATE TABLE
> - `|` (pipe) : envoie la sortie vers la commande suivante
> - `gzip > /backup/postgres/dump_manuel_...` : compresse et enregistre le fichier
> - `$(date +%Y%m%d_%H%M%S)` : ajoute la date et l'heure au nom du fichier

### Telecharger un backup sur votre Mac

Pour plus de securite, gardez une copie des backups sur votre Mac :

```bash
# Depuis votre Mac (pas le VPS)

# Telecharger le dernier backup
scp vps:/backup/postgres/dump_20260316.sql.gz ~/Desktop/

# Ou si vous n'avez pas configure l'alias SSH :
scp dokploy@IP_DU_VPS:/backup/postgres/dump_20260316.sql.gz ~/Desktop/

# Telecharger TOUS les backups
scp vps:/backup/postgres/dump_*.sql.gz ~/Desktop/backups-radiomanager/
```

> **`scp`** (Secure Copy) copie des fichiers entre votre Mac et le serveur
> via SSH. Il utilise la meme cle SSH que votre connexion SSH normale.
>
> **Recommandation** : telecharger un backup sur votre Mac une fois par
> semaine et le stocker dans un endroit sur (disque externe, cloud chiffre).
> Par exemple, si le disque du VPS lache, les backups dessus sont perdus aussi.

---

## 3. Restaurer la base de donnees

### Scenario A : Restaurer sur le meme serveur

**Situation** : vous avez fait une erreur (supprime des donnees, migration
Alembic qui casse la base) et voulez revenir a l'etat d'un backup.

**Prerequis** : le container PostgreSQL tourne toujours.

```bash
# 1. Connectez-vous au VPS
ssh vps

# 2. Listez les backups disponibles
ls -lh /backup/postgres/
# Choisissez le backup a restaurer (celui d'avant le probleme)

# 3. (RECOMMANDE) Faites un backup de l'etat actuel AVANT de restaurer
#    Au cas ou vous changeriez d'avis
docker exec -t audace_db pg_dump --clean --if-exists -U postgres audace_db | \
  gzip > /backup/postgres/dump_avant_restauration_$(date +%Y%m%d_%H%M%S).sql.gz

# 4. Restaurer le backup choisi
#    Cette commande decompresse le dump et l'injecte dans PostgreSQL
gunzip < /backup/postgres/dump_20260315.sql.gz | \
  docker exec -i audace_db psql -U audace_user -d audace_db

# 5. Verifier que les donnees sont la
docker exec -it audace_db psql -U postgres -c "\l"
# Liste les bases de donnees — vous devriez voir votre base (ex: audace_db)

docker exec -it audace_db psql -U postgres -d audace_db -c "\dt"
# Liste les tables — verifiez que toutes vos tables sont presentes

# 6. Redemarrer le backend pour qu'il se reconnecte proprement
docker restart audace_api
```

> **Explication de la commande de restauration** :
> - `gunzip < dump.sql.gz` : decompresse le fichier et envoie le SQL brut
> - `|` (pipe) : envoie le SQL vers la commande suivante
> - `docker exec -i audace_db` : execute dans le container (`-i` = envoie du stdin)
> - `psql -U postgres` : client PostgreSQL, execute les commandes SQL recues
>
> **ATTENTION** : la restauration **ecrase** les donnees existantes.
> Le backend (Alembic) recree automatiquement les tables manquantes au redemarrage.

### Scenario B : Reconstruire un serveur complet depuis zero

**Situation** : votre VPS est mort, vous avez un nouveau VPS vierge,
et vous avez un fichier backup (sur votre Mac ou un stockage externe).

**C'est la procedure la plus complete. Suivez chaque etape dans l'ordre.**

```
SCHEMA DE LA RECONSTRUCTION :

  Votre Mac                    Nouveau VPS vierge
  ┌───────────────┐            ┌───────────────────┐
  │ backup .sql.gz│            │                   │
  │ cle SSH       │ ────────>  │ 1. Script VPS     │
  │ ce guide      │            │ 2. Dokploy        │
  └───────────────┘            │ 3. Backend+DB     │
                               │    (compose)      │
                               │ 4. Restauration   │
                               │ 5. Frontend       │
                               └───────────────────┘
```

#### Etape B.1 — Preparer le nouveau VPS (5 min)

```bash
# Sur le nouveau VPS (connecte en root)
sudo SSH_PUBKEY="votre-cle-publique" bash quick-prepare-vps.sh
```

Suivez le guide [MISE-EN-OEUVRE.md](MISE-EN-OEUVRE.md) pour cette etape.

#### Etape B.2 — Installer Dokploy (5 min)

```bash
# Connecte en tant que dokploy
ssh dokploy@IP_NOUVEAU_VPS

curl -sSL https://dokploy.com/install.sh | sudo sh
```

#### Etape B.3 — Deployer le backend (FastAPI + PostgreSQL) dans Dokploy

Le backend RadioManager utilise un `docker-compose.yml` qui definit **deux services
ensemble** : PostgreSQL (`db`) et FastAPI (`api`). En deployant ce docker-compose
dans Dokploy, les deux services sont crees automatiquement.

> **IMPORTANT** : ne creez PAS PostgreSQL separement comme service "Database"
> dans Dokploy. Il est deja inclus dans le docker-compose du backend.
> Creer un PostgreSQL en plus causerait un conflit (deux bases, deux volumes).

Via l'interface Dokploy (`https://IP:3000`) :

1. Cliquez sur **Create Project** → nommez-le "RadioManager"
2. Dans le projet, cliquez **Create Service** → **Compose**
3. Source : **Git** → votre repo backend FastAPI
4. Dokploy detecte le `docker-compose.yml` qui contient :
   - Service `db` : PostgreSQL 15-alpine (container `audace_db`)
   - Service `api` : FastAPI (container `audace_api`)
   - Volume `postgres_data` : persistance des donnees
5. Configurez les **variables d'environnement** dans Dokploy :
   - `DB_NAME` : `audace_db`
   - `DB_USER` : `audace_user`
   - `DB_PASSWORD` : un mot de passe fort (notez-le !)
   - `SECRET_KEY` : votre cle secrete JWT
   - `TOTP_ENCRYPTION_KEY` : votre cle TOTP (pour le 2FA)
   - (et les autres variables — voir [VARIABLES-GUIDE.md](../VARIABLES-GUIDE.md))
6. Configurez le domaine pour l'API : `api.radio.audace.ovh`
   (via les labels Traefik deja presents dans le docker-compose)
7. Cliquez **Deploy**

Attendez que les deux containers soient "Running" (vert).

**Verifier** :

```bash
# Sur le VPS, verifier que les deux containers tournent
docker ps | grep audace
# Attendu :
# audace_db   postgres:15-alpine   ... Up ...
# audace_api  ...                  ... Up ...
```

> **Comment ca marche** : le docker-compose.yml du backend definit tout :
> - L'image PostgreSQL, le volume, le healthcheck
> - L'API FastAPI avec `depends_on: db` (attend que PostgreSQL soit pret)
> - Les labels Traefik pour le routage HTTPS
> - Le reseau Docker pour la communication entre les services
>
> Dokploy execute simplement `docker compose up -d` avec ce fichier.

#### Etape B.4 — Envoyer le backup vers le nouveau VPS

```bash
# Depuis votre Mac, envoyer le fichier backup vers le nouveau VPS
scp ~/Desktop/dump_20260316.sql.gz dokploy@IP_NOUVEAU_VPS:/tmp/

# Ou avec l'alias SSH si configure :
scp ~/Desktop/dump_20260316.sql.gz vps:/tmp/
```

#### Etape B.5 — Restaurer le backup

```bash
# Sur le nouveau VPS
ssh dokploy@IP_NOUVEAU_VPS

# Verifier que le container PostgreSQL tourne
docker ps | grep audace_db
# Attendu : audace_db   postgres:15-alpine   ... Up ...

# Restaurer le backup (nettoie d'abord les donnees existantes)
docker exec -i audace_db psql -U audace_user -d audace_db \
  -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
gunzip < /tmp/dump_20260316.sql.gz | \
  docker exec -i audace_db psql -U audace_user -d audace_db

# Verifier la restauration
docker exec -it audace_db psql -U audace_user -d audace_db -c "\dt"
# Vous devriez voir les tables (users, emissions, etc.)

docker exec -it audace_db psql -U audace_user -d audace_db -c "SELECT count(*) FROM users;"
# Vous devriez voir le nombre d'utilisateurs (pas 0)
```

> **Note** : le `DROP SCHEMA public CASCADE` supprime toutes les tables avant de restaurer.
> Cela evite les conflits de cles primaires et garantit une restauration propre.
> Alembic remettra a jour le schema automatiquement au redemarrage du backend.

#### Etape B.6 — Redemarrer le backend pour qu'il prenne en compte les donnees

```bash
# Le backend doit se reconnecter a la base restauree
docker restart audace_api

# Verifier que l'API repond
curl -f http://localhost:8000/version/health
# Attendu : un JSON avec status OK
```

#### Etape B.7 — Deployer le frontend (React)

Dans Dokploy :

1. **Create Service** → **Application**
2. Source : **Git** → votre repo RadioManager
3. Variables d'environnement :
   - `VITE_API_URL` : `https://api.radio.audace.ovh`
4. Domaine : `app.radio.audace.ovh`
5. Deploy

#### Etape B.8 — Configurer les DNS

Chez votre registrar, mettez a jour les enregistrements A pour pointer
vers la **nouvelle IP** du VPS :

```
A    api.radio.audace.ovh    → NOUVELLE_IP
A    app.radio.audace.ovh    → NOUVELLE_IP
A    dokploy.audace.ovh      → NOUVELLE_IP
```

#### Etape B.9 — Verifier que tout fonctionne

```bash
# Backend
curl https://api.radio.audace.ovh/health
# Attendu : {"status": "ok"} ou similaire

# Frontend
# Ouvrez https://app.radio.audace.ovh dans votre navigateur
# Connectez-vous avec vos identifiants habituels
```

Si le login fonctionne → la base de donnees a ete restauree correctement,
les utilisateurs, les permissions, les tokens sont tous la.

#### Etape B.10 — Deplacer le backup dans le bon dossier

```bash
# Deplacer le backup depuis /tmp vers le dossier de backups
sudo mv /tmp/dump_20260316.sql.gz /backup/postgres/

# Verifier que le cron de backup quotidien fonctionne
# (attendre le lendemain et verifier)
ls -lh /backup/postgres/
```

### Scenario C : Migrer vers un nouveau VPS

**Situation** : vous changez de VPS (meilleur hebergeur, plus de RAM, etc.)
et voulez deplacer tout RadioManager.

La procedure est identique au Scenario B, mais avec une etape supplementaire
au debut : faire un backup **frais** depuis l'ancien serveur.

```bash
# 1. Sur l'ANCIEN VPS — backup frais
docker exec -t audace_db pg_dump --clean --if-exists -U audace_user audace_db | \
  gzip > /backup/postgres/dump_migration_$(date +%Y%m%d_%H%M%S).sql.gz

# 2. Telecharger sur votre Mac
scp ancien-vps:/backup/postgres/dump_migration_*.sql.gz ~/Desktop/

# 3. Suivre le Scenario B depuis l'etape B.1 avec le nouveau VPS

# 4. Une fois tout valide sur le nouveau VPS :
#    - Mettre a jour les DNS vers la nouvelle IP
#    - Eteindre l'ancien VPS (ne pas le supprimer tout de suite)
#    - Attendre 24-48h (propagation DNS)
#    - Si tout fonctionne → supprimer l'ancien VPS
```

> **PRECAUTION** : ne supprimez pas l'ancien VPS immediatement.
> Gardez-le 48h en backup au cas ou quelque chose ne fonctionnerait pas
> sur le nouveau. L'ancien VPS coute quelques euros de plus pour 2 jours
> — c'est un prix derisoire compare au risque de perte de donnees.

---

## 4. Procedures detaillees

### Procedure 1 : Backup avant une operation risquee

**Quand utiliser** : avant une migration Alembic, une mise a jour majeure
de PostgreSQL, ou toute operation qui modifie la structure de la base.

```bash
# 1. Backup complet
docker exec -t audace_db pg_dump --clean --if-exists -U audace_user audace_db | \
  gzip > /backup/postgres/dump_avant_operation_$(date +%Y%m%d_%H%M%S).sql.gz

# 2. Verifier que le backup est valide
ls -lh /backup/postgres/dump_avant_operation_*
gunzip -t /backup/postgres/dump_avant_operation_*.sql.gz
# Pas d'erreur → le backup est OK

# 3. Faites votre operation risquee
# ...

# 4. Si ca se passe mal → restaurer
docker exec -i audace_db psql -U audace_user -d audace_db \
  -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
gunzip < /backup/postgres/dump_avant_operation_YYYYMMDD_HHMMSS.sql.gz | \
  docker exec -i audace_db psql -U audace_user -d audace_db
docker restart audace_api
```

### Procedure 2 : Restaurer une table supprimee par erreur

**Situation** : vous avez fait un `DELETE FROM users` sans `WHERE` (oups)
ou un `DROP TABLE` par accident.

```bash
# 1. NE TOUCHEZ PLUS A RIEN sur la base
#    Chaque seconde qui passe, de nouvelles donnees arrivent et
#    ecrasent potentiellement les anciennes.

# 2. Arretez le backend pour eviter de nouvelles ecritures
docker stop audace_api

# 3. Choisissez le backup le plus recent
ls -lh /backup/postgres/

# 4. Restaurez
gunzip < /backup/postgres/dump_20260316.sql.gz | \
  docker exec -i audace_db psql -U postgres

# 5. Redemarrez le backend
docker start audace_api

# 6. Verifiez que les donnees sont revenues
docker exec -it audace_db psql -U postgres -d audace_db \
  -c "SELECT count(*) FROM users;"
```

> **Attention** : la restauration remplace TOUTE la base. Les donnees
> ajoutees entre le moment du backup (3h du matin) et le moment de
> l'erreur seront perdues. C'est pourquoi il est preferable de faire
> un backup manuel AVANT une operation risquee.

### Procedure 3 : Revenir a l'etat d'hier

```bash
# 1. Lister les backups
ls -lh /backup/postgres/
# Identifier le dump d'hier (ex: dump_20260315.sql.gz)

# 2. (Optionnel) Sauvegarder l'etat actuel avant de restaurer
docker exec -t audace_db pg_dump --clean --if-exists -U audace_user audace_db | \
  gzip > /backup/postgres/dump_etat_actuel_$(date +%Y%m%d_%H%M%S).sql.gz

# 3. Arreter le backend
docker stop audace_api

# 4. Restaurer le backup d'hier (nettoyer d'abord)
docker exec -i audace_db psql -U audace_user -d audace_db \
  -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
gunzip < /backup/postgres/dump_20260315.sql.gz | \
  docker exec -i audace_db psql -U audace_user -d audace_db

# 5. Redemarrer le backend
docker start audace_api
```

### Procedure 4 : Reconstruction complete du serveur

C'est la procedure la plus longue. A utiliser si le VPS est completement perdu.

**Ce dont vous avez besoin** :

```
SUR VOTRE MAC (ou un stockage externe)
[ ] Un fichier backup PostgreSQL (.sql.gz)
[ ] Votre cle SSH (ou en generer une nouvelle)
[ ] Le mot de passe dokploy (dans votre gestionnaire de mots de passe)
[ ] Les variables d'environnement du backend (dans Dokploy ou notees quelque part)
[ ] L'acces a votre registrar DNS

CHEZ VOTRE HEBERGEUR
[ ] Un nouveau VPS provisionne (Ubuntu 24.04)
[ ] L'IP du nouveau VPS
```

**Procedure** :

```
Temps estime total : 30-45 minutes

 0:00  Provisionner le nouveau VPS chez OVH/Hetzner
 0:05  Lancer quick-prepare-vps.sh (Phase 1-4 du guide MISE-EN-OEUVRE)
 0:10  Installer Dokploy
 0:15  Deployer le backend (Compose = API + PostgreSQL ensemble)
 0:20  Envoyer le backup SQL vers le VPS (scp)
 0:22  Restaurer le backup dans PostgreSQL
 0:25  Deployer le frontend React dans Dokploy
 0:30  Configurer les DNS
 0:35  Tester et valider
 0:40  Termine !
```

Suivez le [**Scenario B**](#scenario-b--reconstruire-un-serveur-complet-depuis-zero)
pour les commandes detaillees de chaque etape.

---

## 5. Bonnes pratiques

### Stockage des backups : la regle du 3-2-1

La regle d'or des backups :

```
3 copies de vos donnees
2 supports differents
1 copie hors site (off-site)
```

Pour RadioManager :

| Copie | Support | Emplacement | Automatique ? |
|-------|---------|-------------|---------------|
| 1. Volume Docker | Disque VPS | `/var/lib/docker/volumes/` | Oui (temps reel) |
| 2. Dump SQL | Disque VPS | `/backup/postgres/` | Oui (cron quotidien) |
| 3. Copie sur Mac | Disque Mac | `~/backups/radiomanager/` | **Non — a faire regulierement** |

La copie 3 est la seule que vous devez faire manuellement.
Programmez-vous un rappel hebdomadaire :

```bash
# Sur votre Mac — a faire une fois par semaine
mkdir -p ~/backups/radiomanager
scp vps:/backup/postgres/dump_$(date +%Y%m%d).sql.gz ~/backups/radiomanager/
```

### Ne jamais faire

| Action | Risque | Alternative |
|--------|--------|------------|
| `docker volume rm postgres_data` | Perte totale des donnees | Ne supprimez JAMAIS un volume sauf si vous etes sur |
| `DROP DATABASE audace_db;` en prod | Perte totale | Faites un backup AVANT toute operation destructrice |
| Stocker le backup uniquement sur le VPS | Si le VPS meurt, le backup meurt aussi | Telechargez regulierement sur votre Mac |
| Supprimer l'ancien VPS avant de valider le nouveau | Pas de retour en arriere | Gardez l'ancien 48h apres migration |
| Restaurer sans backup prealable | Ecrase l'etat actuel irreversiblement | Sauvegardez l'etat actuel avant de restaurer |

### Tester regulierement la restauration

Un backup qui n'a jamais ete teste n'est PAS un backup.
Au moins une fois par trimestre, verifiez :

```bash
# 1. Le backup existe et n'est pas vide
ls -lh /backup/postgres/dump_$(date +%Y%m%d).sql.gz

# 2. Le fichier n'est pas corrompu
gunzip -t /backup/postgres/dump_$(date +%Y%m%d).sql.gz

# 3. Le contenu est du SQL valide
zcat /backup/postgres/dump_$(date +%Y%m%d).sql.gz | head -5
# Attendu : des commandes SQL (pas du binaire ou du vide)
```

---

## 6. Depannage

### Le dossier /backup/postgres/ est vide

```bash
# Verifier que le cron est configure
cat /etc/cron.d/backup-postgres

# Verifier que le container PostgreSQL tourne
docker ps | grep postgres
# Si rien → PostgreSQL ne tourne pas. Verifiez dans Dokploy.

# Tester le backup manuellement
docker exec -t $(docker ps -qf "ancestor=postgres" | head -1) \
  pg_dump --clean --if-exists -U audace_user audace_db | gzip > /backup/postgres/test.sql.gz

# Si erreur "Error: No such container" :
# Le container n'est pas base sur l'image "postgres".
# Listez les containers et trouvez le bon :
docker ps --format "{{.Names}} ({{.Image}})"
# Puis adaptez la commande avec le bon nom de container.
```

### Le backup fait 0 octet

```bash
# Le dump a echoue. Testez manuellement et regardez l'erreur :
docker exec -t audace_db pg_dump --clean --if-exists -U audace_user audace_db 2>&1 | head -20

# Erreur courante : "FATAL: role 'postgres' does not exist"
# → L'utilisateur PostgreSQL s'appelle autrement.
# Verifiez :
docker exec -it audace_db psql -U audace_user -c "\du"
# Utilisez le bon nom d'utilisateur dans la commande de dump.
```

### "ERROR: database already exists" pendant la restauration

Ce message peut apparaitre si vous restaurez un ancien dump `pg_dumpall`.
Avec les nouveaux dumps `pg_dump --clean --if-exists`, ce probleme ne se produit plus.
Si vous le voyez, c'est sans danger — les donnees sont quand meme restaurees.

### "FATAL: Peer authentication failed"

```bash
# Le container utilise l'auth "peer" au lieu de "md5/scram".
# Rien de grave quand on exec dans le container.
# Ajoutez -U avec le bon utilisateur :
docker exec -it audace_db psql -U postgres
# ou
docker exec -it audace_db psql -U audace_user -d audace_db
```

### La restauration prend tres longtemps

Pour une base de quelques Go, la restoration peut prendre 5-15 minutes.
C'est normal. Ne l'interrompez PAS.

Si ca prend plus de 30 minutes :
```bash
# Verifiez que le processus tourne encore
docker exec -it audace_db ps aux | grep psql
# Si psql est actif → tout va bien, patience

# Verifiez l'espace disque (un disque plein peut bloquer)
df -h
```

---

## 7. Glossaire

| Terme | Definition simple |
|-------|------------------|
| **Volume Docker** | Espace de stockage sur le vrai disque, branche dans un container. Les donnees survivent a la destruction du container. |
| **Container** | Boite isolee qui contient une application (PostgreSQL, FastAPI, etc.). Ephemere — peut etre detruit et recree. |
| **pg_dump** | Commande PostgreSQL qui exporte UNE base en commandes SQL. Avec `--clean --if-exists`, le dump inclut les instructions de nettoyage. |
| **pg_dumpall** | Variante qui exporte TOUTES les bases + roles. Moins adapte pour une restauration ciblee (risque de doublons dans `alembic_version`). |
| **psql** | Client en ligne de commande pour PostgreSQL. Permet d'executer des requetes SQL. |
| **gzip / gunzip** | Compression / decompression de fichiers. Reduit la taille du dump de 5-10x. |
| **scp** | Secure Copy — copie de fichiers entre votre Mac et le serveur via SSH. |
| **cron** | Planificateur de taches Linux. Execute des commandes a des heures precises (ex: backup a 3h). |
| **Restauration** | Processus de reinjecter un backup dans la base de donnees. Ecrase les donnees actuelles. |
| **OOM Killer** | Mecanisme Linux qui tue les processus quand la RAM est epuisee. PostgreSQL est souvent la cible. |
| **Dump SQL** | Fichier texte contenant des commandes SQL (CREATE TABLE, INSERT, etc.) qui recreent la base. |
| **Volume mount** | L'action de brancher un volume dans un container, comme brancher une cle USB. |
| **Alembic** | Outil de migration de base de donnees pour SQLAlchemy. Modifie la structure des tables (pas les donnees). |

---

## Resume en une page

```
ARCHITECTURE DES DONNEES RADIOMANAGER
======================================

PostgreSQL (volume Docker) ← DONNEES PRINCIPALS
  Backup automatique : /backup/postgres/dump_YYYYMMDD.sql.gz (7 jours)
  Backup manuel : docker exec -t audace_db pg_dump --clean --if-exists -U audace_user audace_db | gzip > fichier.sql.gz

Firebase (cloud Google) ← DONNEES SECONDAIRES
  Firestore : citations, inventaire, settings
  Storage : fichiers uploades
  Pas de backup necessaire (gere par Google)


RESTAURER SUR LE MEME SERVEUR
==============================
docker exec -i audace_db psql -U audace_user -d audace_db -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
gunzip < /backup/postgres/dump_YYYYMMDD.sql.gz | docker exec -i audace_db psql -U audace_user -d audace_db
docker restart audace_api


RECONSTRUIRE UN SERVEUR DEPUIS ZERO
====================================
1. quick-prepare-vps.sh          ← Securiser le VPS
2. Dokploy                       ← Installer la plateforme
3. Backend (Compose)             ← Deploie API + PostgreSQL ensemble
4. scp backup.sql.gz vers VPS    ← Envoyer le dump
5. gunzip | docker exec psql     ← Restaurer les donnees
6. Frontend React                ← Deployer le frontend
7. DNS                           ← Pointer les domaines


REGLE D'OR
==========
3 copies — 2 supports — 1 hors site
Telecharger un backup sur votre Mac chaque semaine :
  scp vps:/backup/postgres/dump_YYYYMMDD.sql.gz ~/backups/
```

---

*Derniere mise a jour : 2026-03-16 — Script quick-prepare-vps.sh v2.1*
*Projet RadioManager*
