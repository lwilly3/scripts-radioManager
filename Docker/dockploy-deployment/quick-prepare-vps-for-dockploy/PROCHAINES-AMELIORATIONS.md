# Prochaines ameliorations — v2.1

> **Prerequis** : le serveur est prepare (script v2.0), Dokploy installe,
> les services (backend + frontend + PostgreSQL) deployes et fonctionnels.
>
> Ces ameliorations s'ajoutent **apres validation** que tout tourne correctement.

---

## Checklist de validation avant de continuer

Avant d'implementer les ameliorations ci-dessous, verifier que :

```bash
# 1. Les services tournent
docker ps                                  # audace_api + audace_db visibles et "Up"

# 2. L'API repond
curl -s https://api.radio.audace.ovh/health   # doit retourner 200

# 3. Le frontend est accessible
curl -s -o /dev/null -w "%{http_code}" https://app.radioaudace.com   # 200

# 4. Les backups locaux fonctionnent (verifier le lendemain du deploiement)
ls -lh /backup/postgres/                   # au moins un fichier dump_YYYYMMDD.sql.gz

# 5. Le pare-feu est actif
sudo ufw status                            # Status: active
```

Si tout est OK, passer aux ameliorations.

---

## Amelioration 1 — Backup off-site (priorite haute)

### Pourquoi

Les backups PostgreSQL actuels sont stockes sur le meme VPS que la base de donnees.
Si le disque dur du VPS meurt, **les donnees ET les backups sont perdus en meme temps**.

```
SITUATION ACTUELLE (risquee)              SITUATION CIBLE (sure)

VPS OVH                                   VPS OVH
├── PostgreSQL (donnees)                  ├── PostgreSQL (donnees)
└── /backup/postgres/ (copies)            └── /backup/postgres/ (copies)
                                               │
    Si le disque meurt :                       └── copie quotidienne
    tout est perdu                                  │
                                                    ▼
                                              Google Drive
                                              └── RadioManager-Backups/
                                                  ├── dump_20260314.sql.gz
                                                  ├── dump_20260315.sql.gz
                                                  └── dump_20260316.sql.gz

                                              Si le VPS meurt :
                                              les donnees sont en securite
```

### Choix technique : Google Drive + rclone

| Critere | Choix |
|---------|-------|
| Stockage cloud | **Google Drive** (15 GB gratuits avec un compte Google) |
| Outil de sync | **rclone** (open-source, comme un `cp` vers le cloud) |
| Frequence | Quotidienne, 30 min apres le backup local (3h30) |
| Retention | 7 jours (comme les backups locaux) |

### Procedure d'installation

#### Etape 1 — Preparer l'authentification Google Drive

> **Probleme** : le VPS n'a pas de navigateur web, mais rclone a besoin d'une
> autorisation OAuth Google (connexion via navigateur). On va donc generer
> le token d'autorisation **depuis ton Mac**, puis le copier sur le VPS.

**Sur ton Mac** (pas le VPS) :

```bash
# Installer rclone sur ton Mac (si pas deja fait)
brew install rclone

# Lancer la configuration
rclone config
```

Repondre aux questions :

```
n) New remote        ← taper "n" puis Entree
name>                ← taper "offsite" puis Entree
Storage>             ← taper "drive" puis Entree
client_id>           ← Entree (laisser vide = utiliser le client rclone par defaut)
client_secret>       ← Entree (laisser vide)
scope>               ← taper "1" puis Entree (Full access)
service_account_file>← Entree (laisser vide)
Edit advanced config>← taper "n" puis Entree
Use auto config>     ← taper "y" puis Entree
```

Un navigateur s'ouvre → se connecter avec ton compte Google → autoriser rclone.

```
Configure this as a Shared Drive?  ← taper "n" puis Entree
y) Yes this is OK                  ← taper "y" puis Entree
q) Quit config                     ← taper "q" puis Entree
```

**Recuperer le token** :

```bash
# Afficher la configuration generee (contient le token)
cat ~/.config/rclone/rclone.conf
```

Tu verras quelque chose comme :

```ini
[offsite]
type = drive
scope = drive
token = {"access_token":"ya29.xxx...","token_type":"Bearer","refresh_token":"1//0xxx...","expiry":"2026-03-16T..."}
```

**Copier tout le bloc** `[offsite]` (les 4 lignes).

#### Etape 2 — Installer rclone sur le VPS

```bash
# Se connecter au VPS
ssh dokploy@IP_DU_VPS

# Installer rclone
sudo apt update && sudo apt install -y rclone

# Creer le dossier de config rclone pour root (le cron tourne en root)
sudo mkdir -p /root/.config/rclone
```

#### Etape 3 — Coller la configuration sur le VPS

```bash
# Creer/editer le fichier de config rclone
sudo nano /root/.config/rclone/rclone.conf
```

**Coller le bloc copie depuis ton Mac** :

```ini
[offsite]
type = drive
scope = drive
token = {"access_token":"ya29.xxx...","token_type":"Bearer","refresh_token":"1//0xxx...","expiry":"2026-03-16T..."}
```

Sauvegarder : `Ctrl+O` → `Entree` → `Ctrl+X`

> **Pourquoi cette methode ?** Le VPS n'a pas de navigateur. Le token OAuth
> permet a rclone de se connecter a ton Google Drive sans navigateur.
> Le `refresh_token` se renouvelle automatiquement — pas besoin de refaire
> cette manipulation.

#### Etape 4 — Creer le dossier de destination sur Google Drive

```bash
# Creer le dossier RadioManager-Backups sur Google Drive
sudo rclone mkdir offsite:RadioManager-Backups/postgres
```

> Ce dossier apparaitra dans ton Google Drive comme un dossier normal.
> Tu peux le voir depuis drive.google.com.

#### Etape 5 — Tester que ca marche

```bash
# Envoyer un fichier test
echo "test backup offsite" > /tmp/test-offsite.txt
sudo rclone copy /tmp/test-offsite.txt offsite:RadioManager-Backups/test/

# Verifier qu'il est arrive
sudo rclone ls offsite:RadioManager-Backups/test/
# Doit afficher : 21 test-offsite.txt

# Nettoyer le test
sudo rclone delete offsite:RadioManager-Backups/test/
rm /tmp/test-offsite.txt
```

Si `rclone ls` affiche le fichier, la configuration est correcte.
Tu peux aussi verifier dans Google Drive (drive.google.com) que le dossier `RadioManager-Backups` existe.

#### Etape 6 — Ajouter le cron de sync

```bash
# Editer le cron
sudo crontab -e
```

Ajouter cette ligne **apres** le cron de backup PostgreSQL existant :

```cron
# Backup off-site — copie les dumps vers Google Drive (30 min apres le backup local)
30 3 * * * root rclone sync /backup/postgres/ offsite:RadioManager-Backups/postgres/ --max-age 8d --log-file /var/log/rclone-backup.log --log-level INFO 2>/dev/null
```

**Explication de chaque partie :**

| Partie | Signification |
|--------|---------------|
| `30 3 * * *` | S'execute a 3h30 chaque jour |
| `root` | Execute en tant que root (acces aux fichiers de backup) |
| `rclone sync` | Synchronise : envoie les nouveaux fichiers, supprime les anciens |
| `/backup/postgres/` | Dossier source (backups locaux) |
| `offsite:RadioManager-Backups/postgres/` | Destination (dossier Google Drive) |
| `--max-age 8d` | N'envoie que les fichiers de moins de 8 jours |
| `--log-file ...` | Ecrit un log pour pouvoir verifier que ca marche |

#### Etape 7 — Verifier le lendemain

```bash
# Verifier le log rclone
cat /var/log/rclone-backup.log

# Verifier les fichiers sur Google Drive (depuis le VPS)
sudo rclone ls offsite:RadioManager-Backups/postgres/

# Ou simplement ouvrir Google Drive dans ton navigateur :
# → drive.google.com → RadioManager-Backups → postgres
```

### En cas de desastre — restaurer depuis Google Drive

```bash
# Sur le nouveau VPS (apres reinstallation)
sudo apt install -y rclone
sudo mkdir -p /root/.config/rclone

# Option A : recopier le rclone.conf depuis ton Mac (si tu l'as encore)
# Option B : refaire la config OAuth depuis ton Mac (etapes 1 et 3)

# Telecharger le dernier backup
sudo rclone copy offsite:RadioManager-Backups/postgres/ /backup/postgres/

# Lister les backups disponibles
ls -lh /backup/postgres/

# Restaurer le plus recent
gunzip -c /backup/postgres/dump_YYYYMMDD.sql.gz | docker exec -i audace_db psql -U postgres
```

---

## Amelioration 2 — Monitoring avec Uptime Kuma (priorite haute)

### Pourquoi

Actuellement, si un service tombe (API, frontend, base de donnees), **personne n'est alerte**.
On ne le decouvre que quand un utilisateur se plaint.

```
SANS MONITORING                           AVEC MONITORING

3h00  API crash                           3h00  API crash
...silence...                             3h01  Uptime Kuma detecte
9h00  Un animateur: "Ca marche pas !"     3h01  Notification Telegram
9h30  Tu recois le message                3h10  Tu corriges le probleme
10h00 Tu corriges                         3h20  Tout remarche

= 7h de downtime                          = 20 min de downtime
```

### Choix technique : Uptime Kuma

| Critere | Detail |
|---------|--------|
| Outil | **Uptime Kuma** (open-source, gratuit) |
| Installation | Conteneur Docker via Dokploy |
| Ressources | ~60 MB RAM, ~0.1% CPU (negligeable) |
| Alertes | **Telegram** (gratuit, instantane) |
| Interface | Dashboard web avec historique d'uptime |

### Procedure d'installation

#### Etape 1 — Creer un bot Telegram (pour les alertes)

1. Ouvrir **Telegram** sur ton telephone
2. Chercher `@BotFather` (le bot officiel de Telegram pour creer des bots)
3. Envoyer `/newbot`
4. Choisir un nom : `RadioManager Alerts`
5. Choisir un username : `radiomanager_alerts_bot` (doit finir par `_bot`)
6. **BotFather te repond avec un token** — le noter ! Exemple :
   ```
   7123456789:AAHxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
7. Creer un **groupe Telegram** (ex: "RadioManager Monitoring")
8. Ajouter ton bot au groupe
9. Recuperer le **chat ID** du groupe :
   ```
   # Envoyer un message dans le groupe, puis :
   # Ouvrir cette URL dans un navigateur (remplacer TOKEN) :
   https://api.telegram.org/bot<TOKEN>/getUpdates

   # Chercher "chat":{"id": -XXXXXXXXX  ← c'est le chat ID (nombre negatif)
   ```

**Garder de cote :**
- Token du bot : `7123456789:AAHxxxx...`
- Chat ID du groupe : `-XXXXXXXXX`

#### Etape 2 — Deployer Uptime Kuma dans Dokploy

1. Se connecter a Dokploy : `https://IP_DU_VPS:3000`
2. Aller dans ton projet RadioManager
3. **"Create Service"** → **Docker**
4. Remplir :
   - Nom : `uptime-kuma`
   - Image : `louislam/uptime-kuma:1`
   - Port expose : `3001`
5. **Volumes** → ajouter :
   ```
   uptime-kuma-data → /app/data
   ```
   (ce volume garde la configuration meme si le conteneur redemarre)
6. **Domaine** (optionnel mais recommande) :
   - Ajouter : `status.radio.audace.ovh` (ou un sous-domaine de ton choix)
   - Port : `3001`
   - SSL : activer (Let's Encrypt)
7. **Deployer**

> **Note DNS** : si tu ajoutes un domaine, il faut creer un enregistrement DNS
> `status.radio.audace.ovh → IP_DU_VPS` chez ton registraire de domaine.

#### Etape 3 — Configurer Uptime Kuma

1. Acceder a l'interface :
   - Avec domaine : `https://status.radio.audace.ovh`
   - Sans domaine : `http://IP_DU_VPS:3001`
2. **Premiere connexion** : creer un compte admin (nom + mot de passe)
3. Ce compte est local a Uptime Kuma (pas lie a Dokploy)

#### Etape 4 — Configurer les alertes Telegram

1. Aller dans **Settings** (icone engrenage) → **Notifications**
2. Cliquer **"Setup Notification"**
3. Remplir :
   ```
   Type           : Telegram
   Friendly Name  : RadioManager Telegram
   Bot Token      : 7123456789:AAHxxxx...  (token du BotFather)
   Chat ID        : -XXXXXXXXX  (ID du groupe)
   ```
4. Cliquer **"Test"** → un message doit apparaitre dans le groupe Telegram
5. **Sauvegarder**

#### Etape 5 — Ajouter les monitors

**Monitor 1 — API Backend :**

1. Cliquer **"Add New Monitor"**
2. Remplir :
   ```
   Monitor Type   : HTTP(s)
   Friendly Name  : API Backend
   URL            : https://api.radio.audace.ovh/health
   Heartbeat Interval : 60  (verifie toutes les 60 secondes)
   Retries        : 3  (attend 3 echecs avant d'alerter)
   ```
3. Dans **Notifications** → cocher "RadioManager Telegram"
4. Sauvegarder

**Monitor 2 — Frontend :**

1. **"Add New Monitor"**
2. Remplir :
   ```
   Monitor Type   : HTTP(s)
   Friendly Name  : Frontend RadioManager
   URL            : https://app.radioaudace.com
   Heartbeat Interval : 60
   Retries        : 3
   ```
3. Notifications → cocher "RadioManager Telegram"
4. Sauvegarder

**Monitor 3 — Dokploy (optionnel) :**

1. **"Add New Monitor"**
2. Remplir :
   ```
   Monitor Type   : HTTP(s)
   Friendly Name  : Dokploy Dashboard
   URL            : https://IP_DU_VPS:3000
   Heartbeat Interval : 120  (toutes les 2 min, moins critique)
   Retries        : 3
   ```
3. Notifications → cocher "RadioManager Telegram"
4. Sauvegarder

#### Etape 6 — Activer la page de statut publique (optionnel)

Uptime Kuma peut generer une page publique qui montre l'etat de tes services :

1. Aller dans **"Status Pages"** → **"New Status Page"**
2. Nom : `RadioManager`
3. Slug : `radiomanager`
4. Ajouter les monitors (API + Frontend)
5. La page est accessible a : `https://status.radio.audace.ovh/status/radiomanager`

```
┌──────────────────────────────────────┐
│  RadioManager — Etat des services    │
│                                      │
│  ✅ API Backend        99.95%        │
│  ✅ Frontend           99.99%        │
│                                      │
│  Derniers 30 jours : █████████████   │
└──────────────────────────────────────┘
```

Utile pour montrer aux utilisateurs que le service fonctionne (ou pour communiquer pendant une panne).

---

## Resume

| Amelioration | Priorite | Temps | Cout | Etat |
|-------------|----------|-------|------|------|
| Backup off-site (Google Drive + rclone) | Haute | ~30 min | Gratuit (15 GB inclus) | A faire |
| Monitoring (Uptime Kuma + Telegram) | Haute | ~30 min | Gratuit | A faire |

### Ordre recommande

```
1. Verifier que les services tournent (checklist ci-dessus)
2. Installer Uptime Kuma (amelioration 2)
   → Permet de detecter immediatement si quelque chose casse pendant la suite
3. Configurer le backup off-site (amelioration 1)
   → Les donnees sont maintenant protegees meme en cas de perte totale du VPS
```

### Apres les deux ameliorations

L'infrastructure sera complete :

```
VPS OVH
├── Securite           ✅ UFW + Fail2ban + SSH hardened (script v2.0)
├── Services           ✅ API + Frontend + PostgreSQL (Dokploy)
├── Backup local       ✅ pg_dumpall quotidien, retention 7 jours
├── Backup off-site    ✅ rclone → Google Drive (amelioration 1)
├── Monitoring         ✅ Uptime Kuma + alertes Telegram (amelioration 2)
└── SSL/TLS            ✅ Let's Encrypt via Traefik
```

---

## Commandes utiles apres installation

```bash
# Verifier le backup off-site
sudo rclone ls offsite:RadioManager-Backups/postgres/    # fichiers sur Google Drive
cat /var/log/rclone-backup.log                            # log du dernier sync

# Tester manuellement le sync
sudo rclone sync /backup/postgres/ offsite:RadioManager-Backups/postgres/ --dry-run
# (--dry-run = simule sans rien envoyer, pour verifier)

# Uptime Kuma
docker logs uptime-kuma                               # logs du conteneur
```

---

<div align="center">

**[README](README.md)** | **[Mise en oeuvre](MISE-EN-OEUVRE.md)** | **[Persistance & Restauration](PERSISTANCE-ET-RESTAURATION.md)** | **[Guide complet](GUIDE-COMPLET-VPS.md)**

</div>
