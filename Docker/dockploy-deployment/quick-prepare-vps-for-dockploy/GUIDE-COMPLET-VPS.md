# Guide complet — Preparation, securisation et maintenance du VPS

> Ce guide accompagne le script `quick-prepare-vps.sh` v2.0.
> Il explique chaque concept, chaque etape, et couvre les situations
> de recovery (perte de Mac, perte d'acces, etc.).

---

## Table des matieres

- [1. Concepts de base](#1-concepts-de-base)
  - [Qu'est-ce qu'un VPS ?](#quest-ce-quun-vps-)
  - [Qu'est-ce que SSH ?](#quest-ce-que-ssh-)
  - [Qu'est-ce qu'une cle SSH ?](#quest-ce-quune-cle-ssh-)
  - [Qu'est-ce qu'un pare-feu ?](#quest-ce-quun-pare-feu-)
  - [Qu'est-ce que Docker ?](#quest-ce-que-docker-)
  - [Qu'est-ce que Dokploy ?](#quest-ce-que-dokploy-)
- [2. Avant de commencer](#2-avant-de-commencer)
  - [Ce dont vous avez besoin](#ce-dont-vous-avez-besoin)
  - [Generer votre cle SSH](#generer-votre-cle-ssh)
  - [Recuperer votre cle publique](#recuperer-votre-cle-publique)
- [3. Lancer le script](#3-lancer-le-script)
  - [Methode recommandee (avec cle SSH)](#methode-recommandee-avec-cle-ssh)
  - [Methode simple (sans cle SSH)](#methode-simple-sans-cle-ssh)
  - [Toutes les options](#toutes-les-options)
- [4. Se connecter en SSH apres le script](#4-se-connecter-en-ssh-apres-le-script)
  - [Avec cle SSH (automatique)](#avec-cle-ssh-automatique)
  - [Sans cle SSH (manuel)](#sans-cle-ssh-manuel)
  - [Port SSH personnalise](#port-ssh-personnalise)
  - [Simplifier avec un alias SSH](#simplifier-avec-un-alias-ssh)
- [5. Ce que le script a installe et configure](#5-ce-que-le-script-a-installe-et-configure)
  - [Les 12 etapes en detail](#les-12-etapes-en-detail)
  - [Ports ouverts](#ports-ouverts)
  - [Fichiers modifies](#fichiers-modifies)
- [6. Securite — Comprendre ce qui protege votre serveur](#6-securite--comprendre-ce-qui-protege-votre-serveur)
  - [SSH securise](#ssh-securise)
  - [Pare-feu UFW](#pare-feu-ufw)
  - [Docker et le pare-feu (probleme critique resolu)](#docker-et-le-pare-feu-probleme-critique-resolu)
  - [Fail2ban (anti brute-force)](#fail2ban-anti-brute-force)
  - [Mises a jour automatiques](#mises-a-jour-automatiques)
  - [Protection reseau (sysctl)](#protection-reseau-sysctl)
- [7. Backups automatiques](#7-backups-automatiques)
  - [Backup PostgreSQL](#backup-postgresql)
  - [Verifier les backups](#verifier-les-backups)
  - [Restaurer un backup](#restaurer-un-backup)
- [8. Perte d'acces — Recovery](#8-perte-dacces--recovery)
  - [Scenario 1 : Mac perdu ou vole](#scenario-1--mac-perdu-ou-vole)
  - [Scenario 2 : Cle SSH perdue (Mac fonctionnel)](#scenario-2--cle-ssh-perdue-mac-fonctionnel)
  - [Scenario 3 : Mot de passe dokploy oublie](#scenario-3--mot-de-passe-dokploy-oublie)
  - [Scenario 4 : IP bannie par Fail2ban](#scenario-4--ip-bannie-par-fail2ban)
  - [Scenario 5 : Config SSH cassee](#scenario-5--config-ssh-cassee)
- [9. Prevenir la perte d'acces](#9-prevenir-la-perte-dacces)
  - [Sauvegarder la cle privee SSH](#sauvegarder-la-cle-privee-ssh)
  - [Ajouter plusieurs cles SSH](#ajouter-plusieurs-cles-ssh)
  - [Utiliser le trousseau macOS](#utiliser-le-trousseau-macos)
  - [Checklist de securite personnelle](#checklist-de-securite-personnelle)
- [10. Maintenance courante](#10-maintenance-courante)
  - [Commandes utiles au quotidien](#commandes-utiles-au-quotidien)
  - [Surveiller l'espace disque](#surveiller-lespace-disque)
  - [Surveiller la memoire et le swap](#surveiller-la-memoire-et-le-swap)
  - [Mettre a jour le serveur manuellement](#mettre-a-jour-le-serveur-manuellement)
  - [Consulter les logs](#consulter-les-logs)
- [11. Depannage](#11-depannage)
- [12. Etapes suivantes apres le script](#12-etapes-suivantes-apres-le-script)
- [13. Glossaire](#13-glossaire)

---

## 1. Concepts de base

> Si vous etes deja a l'aise avec SSH, les cles publiques/privees et Docker,
> passez directement a la [section 2](#2-avant-de-commencer).

### Qu'est-ce qu'un VPS ?

Un **VPS** (Virtual Private Server) est un serveur virtuel heberge dans un
datacenter. C'est comme un ordinateur distant qui tourne 24h/24, sur lequel
vous installez vos applications (site web, API, base de donnees).

```
Votre Mac ----internet----> VPS (Ubuntu, dans un datacenter OVH)
                              ├── Docker
                              ├── PostgreSQL (base de donnees)
                              ├── FastAPI (backend)
                              └── React (frontend)
```

Fournisseurs courants : OVH, Hetzner, DigitalOcean, AWS, Scaleway.

### Qu'est-ce que SSH ?

**SSH** (Secure Shell) est le protocole qui permet de se connecter a distance
a un serveur via un terminal. C'est comme ouvrir un terminal directement
sur le serveur depuis votre Mac.

```bash
# Commande SSH de base
ssh utilisateur@adresse-ip-du-serveur

# Exemple concret
ssh dokploy@51.178.42.100
```

Quand vous tapez cette commande :
1. Votre Mac contacte le serveur sur le port 22 (ou un port personnalise)
2. Le serveur verifie votre identite (mot de passe ou cle SSH)
3. Si l'identite est verifiee, vous obtenez un terminal sur le serveur

### Qu'est-ce qu'une cle SSH ?

Une **cle SSH** est une paire de fichiers cryptographiques :

| Fichier | Emplacement | Role | A partager ? |
|---------|-------------|------|--------------|
| **Cle privee** | `~/.ssh/id_ed25519` | Prouve votre identite | **JAMAIS** (c'est votre mot de passe) |
| **Cle publique** | `~/.ssh/id_ed25519.pub` | Verifiee par le serveur | Oui, sans risque |

**Analogie** : la cle publique est un cadenas que vous posez sur la porte du serveur.
La cle privee est la seule clef qui ouvre ce cadenas. Vous pouvez donner le cadenas
a tout le monde, tant que vous gardez la clef.

```
                    Connexion SSH
Votre Mac                                    Serveur
┌─────────────────┐                  ┌─────────────────┐
│                  │   "C'est moi"   │                  │
│  Cle privee     │ ──────────────>  │  Cle publique    │
│  (id_ed25519)   │                  │  (authorized_    │
│                  │  "OK, entre"    │   keys)          │
│  Garde secrete !│ <──────────────  │                  │
└─────────────────┘                  └─────────────────┘
```

**Pourquoi c'est mieux qu'un mot de passe** :
- Un mot de passe peut etre devine par brute-force (essayer des millions de combinaisons)
- Une cle ED25519 a 256 bits d'entropie — il faudrait des milliards d'annees pour la deviner
- La cle privee ne transite jamais sur le reseau (contrairement au mot de passe)

### Qu'est-ce qu'un pare-feu ?

Un **pare-feu** (firewall) filtre le trafic reseau. Il decide quelles connexions
entrantes sont autorisees et lesquelles sont bloquees.

```
Internet                         Pare-feu (UFW)              Serveur
                                 ┌───────────────┐
  Port 22 (SSH)    ───────────>  │   AUTORISE    │ ────────>  SSH
  Port 80 (HTTP)   ───────────>  │   AUTORISE    │ ────────>  Traefik
  Port 443 (HTTPS) ───────────>  │   AUTORISE    │ ────────>  Traefik
  Port 3000        ───────────>  │   AUTORISE    │ ────────>  Dokploy UI
  Port 5432        ───────────>  │   BLOQUE      │ ────x      PostgreSQL
  Port 6379        ───────────>  │   BLOQUE      │ ────x      Redis
  Tout autre port  ───────────>  │   BLOQUE      │ ────x
                                 └───────────────┘
```

Sans pare-feu, TOUS les ports sont ouverts et n'importe qui peut tenter de
se connecter a votre base de donnees.

### Qu'est-ce que Docker ?

**Docker** permet de faire tourner des applications dans des **containers** isoles.
Chaque container a ses propres dependances et ne peut pas interagir avec les autres
(sauf si explicitement configure).

```
Serveur VPS
├── Container 1 : FastAPI + Python 3.12
├── Container 2 : PostgreSQL 16
├── Container 3 : React (build Nginx)
└── Container 4 : Traefik (reverse proxy + SSL)
```

C'est comme des mini-serveurs dans votre serveur, chacun independant.

### Qu'est-ce que Dokploy ?

**Dokploy** est une plateforme de deploiement (alternative a Heroku/Vercel)
que vous hebergez vous-meme. Il :
- Gere vos containers Docker
- Configure automatiquement les domaines et le SSL (via **Traefik**)
- Deploie automatiquement quand vous poussez du code sur Git
- Fournit une interface web d'administration sur le port **3000**

---

## 2. Avant de commencer

### Ce dont vous avez besoin

| Element | Obligatoire | Ou le trouver |
|---------|-------------|---------------|
| Un VPS avec Ubuntu 20.04+ ou Debian 11+ | Oui | OVH Manager, Hetzner, etc. |
| L'adresse IP du VPS | Oui | Interface de votre hebergeur |
| Le mot de passe root du VPS | Oui | Email de votre hebergeur apres creation |
| Un terminal sur votre Mac | Oui | Applications > Utilitaires > Terminal |
| Une cle SSH | Recommande | Generee ci-dessous |

### Generer votre cle SSH

> Si vous avez deja une cle SSH, passez a l'etape suivante.
> Pour verifier : `ls ~/.ssh/id_ed25519.pub` — si le fichier existe, vous en avez une.

Ouvrez le Terminal sur votre Mac :

```bash
# Generer une paire de cles ED25519 (algorithme moderne et securise)
ssh-keygen -t ed25519 -C "votre-email@example.com"
```

Le terminal vous pose 3 questions :

```
Enter file in which to save the key (/Users/vous/.ssh/id_ed25519):
```
Appuyez sur **Entree** (garder l'emplacement par defaut).

```
Enter passphrase (empty for no passphrase):
```
Deux choix :
- **Entree** (pas de passphrase) : connexion sans rien taper → plus pratique
- **Un mot de passe** : plus securise, mais demande a chaque connexion (sauf si vous utilisez le trousseau macOS, voir [section 9](#utiliser-le-trousseau-macos))

```
Enter same passphrase again:
```
Retapez la meme chose.

**Resultat** : deux fichiers crees dans `~/.ssh/` :
- `id_ed25519` — votre cle **privee** (ne la partagez JAMAIS)
- `id_ed25519.pub` — votre cle **publique** (a copier sur le serveur)

### Recuperer votre cle publique

```bash
cat ~/.ssh/id_ed25519.pub
```

Vous verrez quelque chose comme :
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGxPm7o... votre-email@example.com
```

**Copiez toute cette ligne.** Vous en aurez besoin pour lancer le script.

---

## 3. Lancer le script

### Premiere connexion au VPS vierge

```bash
# Depuis votre Mac, connectez-vous en root avec le mot de passe
# fourni par votre hebergeur
ssh root@IP_DU_VPS
```

Premiere connexion : le terminal demande de valider le fingerprint du serveur :
```
The authenticity of host '51.178.42.100' can't be established.
ED25519 key fingerprint is SHA256:abcdef123456...
Are you sure you want to continue connecting (yes/no)?
```
Tapez **yes** et appuyez sur Entree.

### Telecharger le script sur le VPS

```bash
# Telecharger le script
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/Docker/dockploy-deployment/quick-prepare-vps-for-dockploy/quick-prepare-vps.sh

# Rendre executable
chmod +x quick-prepare-vps.sh
```

### Methode recommandee (avec cle SSH)

C'est la methode la plus securisee. En une seule commande, le script :
- Cree l'utilisateur
- Installe votre cle publique
- **Desactive l'authentification par mot de passe SSH**

```bash
sudo SSH_PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGxPm7o... votre-email@example.com" \
     bash quick-prepare-vps.sh
```

> **Important** : collez votre **vraie** cle publique entre les guillemets
> (celle obtenue avec `cat ~/.ssh/id_ed25519.pub` sur votre Mac).

**Apres le script**, seule votre cle SSH permet de se connecter.
Plus aucun mot de passe n'est accepte via SSH.

### Methode simple (sans cle SSH)

Si vous preferez configurer la cle SSH apres :

```bash
sudo bash quick-prepare-vps.sh
```

Vous devrez ensuite :
1. Copier votre cle manuellement (`ssh-copy-id`)
2. Desactiver le mot de passe manuellement
3. Redemarrer SSH

Voir la [section 4 (Sans cle SSH)](#sans-cle-ssh-manuel) pour les etapes detaillees.

### Toutes les options

Le script accepte plusieurs variables d'environnement :

| Variable | Defaut | Description | Exemple |
|----------|--------|-------------|---------|
| `SSH_PUBKEY` | _(vide)_ | Cle publique SSH a installer | `"ssh-ed25519 AAAA..."` |
| `NEW_USER` | `dokploy` | Nom de l'utilisateur systeme | `"deployer"` |
| `SSH_PORT` | `22` | Port SSH | `2222` |
| `TIMEZONE` | `Africa/Douala` | Fuseau horaire | `"Europe/Paris"` |
| `SWAP_SIZE` | `2G` | Taille du swap | `"4G"` |

**Exemple avec tout personnalise** :

```bash
sudo NEW_USER="deployer" \
     SSH_PORT=2222 \
     TIMEZONE="Europe/Paris" \
     SWAP_SIZE="4G" \
     SSH_PUBKEY="ssh-ed25519 AAAA... email@example.com" \
     bash quick-prepare-vps.sh
```

---

## 4. Se connecter en SSH apres le script

### Avec cle SSH (automatique)

Si vous avez lance le script avec `SSH_PUBKEY`, c'est immediat :

```bash
# Depuis votre Mac — rien d'autre a taper que cette commande :
ssh dokploy@IP_DU_VPS
```

**Pas de mot de passe demande.** Votre cle privee (`~/.ssh/id_ed25519`)
s'authentifie automatiquement aupres du serveur.

> **Si le script a reduit le LoginGraceTime**, vous avez 30 secondes
> pour vous authentifier. Avec une cle SSH, c'est instantane.

**Verification** — vous devriez voir :

```
Welcome to Ubuntu 24.04.1 LTS (GNU/Linux 6.8.0-49-generic x86_64)
dokploy@vps-abc123:~$
```

### Sans cle SSH (manuel)

Si vous avez lance le script **sans** `SSH_PUBKEY`, l'auth par mot de passe
est toujours active. Voici les etapes pour basculer vers les cles :

**Etape 1** — Depuis votre Mac, copier la cle publique vers le serveur :

```bash
# ssh-copy-id envoie votre cle publique et l'ajoute au fichier
# authorized_keys sur le serveur
ssh-copy-id dokploy@IP_DU_VPS
```

Le serveur demande le mot de passe de `dokploy` (celui defini pendant le script).

**Etape 2** — Tester la connexion par cle. **Ouvrez un NOUVEAU terminal** :

```bash
ssh dokploy@IP_DU_VPS
# Si ca se connecte sans demander de mot de passe → la cle fonctionne
```

> **CRITIQUE** : ne fermez PAS l'ancienne session tant que le test n'a pas reussi.
> Si la cle ne marche pas et que vous fermez l'ancienne session,
> vous avez toujours le mot de passe pour vous reconnecter.

**Etape 3** — Desactiver l'auth par mot de passe (depuis le serveur) :

```bash
# Modifier la config SSH
sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Ajouter la restriction aux cles uniquement
echo "AuthenticationMethods publickey" | sudo tee -a /etc/ssh/sshd_config

# Redemarrer SSH pour appliquer
sudo systemctl restart sshd
```

**Etape 4** — Verifier que le mot de passe est bien desactive :

```bash
# Depuis un TROISIEME terminal, essayer avec un faux user
ssh fakeuser@IP_DU_VPS
# Resultat attendu : Permission denied (publickey)
# → Mot de passe SSH bien desactive
```

### Port SSH personnalise

Si vous avez change le port SSH (ex: 2222) :

```bash
# Ajouter -p suivi du port
ssh -p 2222 dokploy@IP_DU_VPS

# Pour ssh-copy-id aussi
ssh-copy-id -p 2222 dokploy@IP_DU_VPS
```

### Simplifier avec un alias SSH

Pour eviter de taper l'IP et le port a chaque fois, creez un raccourci.

**Sur votre Mac**, editez le fichier `~/.ssh/config` :

```bash
nano ~/.ssh/config
```

Ajoutez :

```
Host vps
    HostName 51.178.42.100
    User dokploy
    Port 22
    IdentityFile ~/.ssh/id_ed25519
```

Apres ca, il suffit de taper :

```bash
ssh vps
```

C'est equivalent a `ssh -i ~/.ssh/id_ed25519 -p 22 dokploy@51.178.42.100`.

Cet alias fonctionne aussi pour `scp` (copie de fichiers) :

```bash
# Copier un fichier vers le serveur
scp mon-fichier.txt vps:/home/dokploy/

# Copier un fichier depuis le serveur
scp vps:/backup/postgres/dump_20260313.sql.gz ./
```

---

## 5. Ce que le script a installe et configure

### Les 12 etapes en detail

```
Etape  1/12 : Mise a jour systeme
                apt update + upgrade + autoremove

Etape  2/12 : Outils essentiels
                curl, wget, git, vim, nano, htop, ufw, fail2ban,
                unattended-upgrades, etc.

Etape  3/12 : Fuseau horaire
                Africa/Douala (UTC+1) par defaut

Etape  4/12 : Utilisateur sudo
                Cree "dokploy" avec privileges sudo
                + installe la cle SSH si fournie

Etape  5/12 : Securisation SSH
                Root desactive, 3 tentatives max, cle SSH,
                timeout 30s, X11 desactive

Etape  6/12 : Pare-feu UFW
                Ports 22, 80, 443, 3000 ouverts
                Tout le reste bloque

Etape  7/12 : Protection Docker-UFW
                Empeche Docker de contourner le pare-feu
                (ports internes proteges)

Etape  8/12 : Fail2ban
                SSH : ban 24h apres 3 echecs
                Recidivistes : ban 7 jours

Etape  9/12 : Swap
                Fichier swap de 2G (evite les crashes OOM)

Etape 10/12 : Mises a jour auto
                Patchs de securite installes chaque nuit

Etape 11/12 : Optimisations kernel
                sysctl pour Docker, limites fichiers 65535,
                rotation logs Docker (max 30 MB/container),
                protection reseau anti-spoofing

Etape 12/12 : Repertoires et backups
                /opt/dokploy, /backup/postgres
                Cron quotidien backup PostgreSQL (retention 7 jours)
```

### Ports ouverts

| Port | Protocole | Service | Qui y accede |
|------|-----------|---------|--------------|
| 22 (ou custom) | TCP | SSH | Vous, depuis votre Mac |
| 80 | TCP | HTTP | Tout le monde (redirige vers 443) |
| 443 | TCP | HTTPS | Tout le monde (votre site/API) |
| 3000 | TCP | Dokploy UI | Vous, pour administrer |

Tous les autres ports sont **bloques** depuis l'exterieur, y compris :
- 5432 (PostgreSQL) — accessible uniquement entre containers Docker
- 6379 (Redis) — idem

### Fichiers modifies

| Fichier | Ce qui a ete modifie |
|---------|---------------------|
| `/etc/ssh/sshd_config` | Securisation SSH (root, port, cle) |
| `/etc/ufw/after.rules` | Protection Docker-UFW |
| `/etc/fail2ban/jail.local` | Config Fail2ban |
| `/etc/sysctl.conf` | Optimisations kernel |
| `/etc/security/limits.conf` | Limites fichiers ouverts |
| `/etc/docker/daemon.json` | Rotation logs Docker |
| `/etc/apt/apt.conf.d/20auto-upgrades` | Mises a jour auto |
| `/etc/apt/apt.conf.d/50unattended-upgrades` | Config mises a jour |
| `/etc/cron.d/backup-postgres` | Backup quotidien PostgreSQL |
| `/etc/fstab` | Montage swap au demarrage |

---

## 6. Securite — Comprendre ce qui protege votre serveur

### SSH securise

| Parametre | Valeur | Pourquoi |
|-----------|--------|----------|
| `PermitRootLogin` | `no` | Empeche la connexion directe en root |
| `MaxAuthTries` | `3` | Limite les tentatives de mot de passe |
| `LoginGraceTime` | `30` | 30 secondes pour s'authentifier (defaut 120) |
| `X11Forwarding` | `no` | Desactive le transfert graphique (inutile sur un serveur) |
| `PermitEmptyPasswords` | `no` | Interdit les comptes sans mot de passe |
| `PasswordAuthentication` | `no`* | Seules les cles SSH sont acceptees |
| `AllowUsers` | `dokploy` | Seul cet utilisateur peut se connecter |

*\*Uniquement si `SSH_PUBKEY` a ete fourni*

### Pare-feu UFW

UFW (Uncomplicated Firewall) bloque tout le trafic entrant par defaut
et n'autorise que les ports explicitement ouverts.

```bash
# Voir l'etat du pare-feu
sudo ufw status verbose

# Voir les regles numerotees
sudo ufw status numbered
```

Pour ouvrir un nouveau port (si necessaire plus tard) :
```bash
sudo ufw allow 8080/tcp comment 'Mon service'
sudo ufw reload
```

Pour fermer un port :
```bash
# Lister les regles avec numeros
sudo ufw status numbered

# Supprimer la regle numero X
sudo ufw delete X
```

### Docker et le pare-feu (probleme critique resolu)

**Le probleme** : Docker manipule directement `iptables` (le vrai pare-feu Linux)
pour exposer les ports des containers. Cela **contourne UFW**.

Exemple : si PostgreSQL est dans un container avec le port 5432 expose,
Docker ouvre ce port au monde entier, meme si UFW le bloque.

**La solution** : le script ajoute des regles dans `/etc/ufw/after.rules`
qui filtrent le trafic Docker via la chaine `DOCKER-USER`.

```
Internet ──> UFW ──> DOCKER-USER (nos regles) ──> Docker ──> Container
                         │
                         ├── Port 80  → AUTORISE (HTTP)
                         ├── Port 443 → AUTORISE (HTTPS)
                         ├── Port 3000 → AUTORISE (Dokploy)
                         └── Tout autre port → BLOQUE
```

Si vous ajoutez un nouveau service Docker qui doit etre accessible de l'exterieur,
vous devez l'autoriser a **deux endroits** :
1. UFW : `sudo ufw allow XXXX/tcp`
2. `/etc/ufw/after.rules` : ajouter `-A DOCKER-USER -p tcp --dport XXXX -j RETURN`
3. Recharger : `sudo ufw reload`

### Fail2ban (anti brute-force)

Fail2ban surveille les logs et bannit les IP qui echouent trop de fois.

```
Attaquant essaie de forcer SSH
  │
  ├── Echec 1 → note dans /var/log/auth.log
  ├── Echec 2 → note
  ├── Echec 3 → BANNI pendant 24 heures
  │
  └── Si banni 3 fois en 24h → BANNI 7 JOURS (recidive)
```

Commandes utiles :

```bash
# Voir l'etat de Fail2ban
sudo fail2ban-client status

# Voir les IP bannies sur SSH
sudo fail2ban-client status sshd

# Voir les recidivistes
sudo fail2ban-client status recidive

# Debannir une IP (si c'est la votre !)
sudo fail2ban-client set sshd unbanip 1.2.3.4
```

### Mises a jour automatiques

Le paquet `unattended-upgrades` installe automatiquement les patchs
de securite chaque nuit. Seules les mises a jour de **securite** sont
installees (pas les nouvelles versions de paquets, qui pourraient
casser des choses).

```bash
# Verifier que c'est actif
sudo systemctl status unattended-upgrades

# Voir les logs des mises a jour
sudo cat /var/log/unattended-upgrades/unattended-upgrades.log
```

Le serveur ne redemarrera **jamais** automatiquement. Si un reboot est
necessaire apres une mise a jour (rare), vous verrez :

```
*** System restart required ***
```

a la connexion SSH. Redemarrez manuellement quand ca vous arrange :
```bash
sudo reboot
```

### Protection reseau (sysctl)

Le script ajoute des protections reseau dans `/etc/sysctl.conf` :

| Parametre | Protection |
|-----------|-----------|
| `rp_filter = 1` | Anti-spoofing (bloque les paquets avec fausse IP source) |
| `accept_redirects = 0` | Bloque les redirections ICMP malveillantes |
| `send_redirects = 0` | Le serveur n'envoie pas de redirections |
| `icmp_echo_ignore_broadcasts = 1` | Ignore les pings broadcast (anti-smurf DDoS) |
| `accept_source_route = 0` | Bloque le source routing (anti-MITM) |

---

## 7. Backups automatiques

### Backup PostgreSQL

Le script installe un cron job qui chaque nuit a 3h du matin :
1. Execute `pg_dumpall` dans le container PostgreSQL
2. Compresse le dump en gzip
3. Enregistre dans `/backup/postgres/dump_YYYYMMDD.sql.gz`
4. Supprime les backups de plus de 7 jours

**Configuration** : `/etc/cron.d/backup-postgres`

> **Note** : le cron cherche d'abord le container nomme `audace_db`
> (nom defini dans le docker-compose.yml du backend RadioManager).
> En fallback, il cherche tout container base sur l'image `postgres`.
> Si votre container a un nom different, editez le fichier cron.

### Verifier les backups

```bash
# Lister les backups
ls -lh /backup/postgres/

# Exemple de sortie :
# -rw-r--r-- 1 root root 2.3M Mar 13 03:00 dump_20260313.sql.gz
# -rw-r--r-- 1 root root 2.3M Mar 12 03:00 dump_20260312.sql.gz
# ...

# Verifier qu'un backup n'est pas vide (> 0 octets)
file /backup/postgres/dump_20260313.sql.gz
# Attendu : gzip compressed data

# Verifier que le cron est bien actif
cat /etc/cron.d/backup-postgres
```

### Restaurer un backup

En cas de probleme, pour restaurer la base de donnees :

```bash
# 1. Trouver le backup a restaurer
ls -lh /backup/postgres/

# 2. Decompresser et injecter dans PostgreSQL
# (audace_db = nom du container defini dans docker-compose.yml)
gunzip < /backup/postgres/dump_20260313.sql.gz | \
  docker exec -i audace_db psql -U postgres

# 3. Verifier que les donnees sont la
docker exec -it audace_db psql -U postgres -c "\l"
```

> **Attention** : `pg_dumpall` restaure en remplacant. Les donnees actuelles
> seront ecrasees par celles du backup.

---

## 8. Perte d'acces — Recovery

### Scenario 1 : Mac perdu ou vole

**Situation** : votre Mac contenait la seule cle privee SSH.
Le mot de passe SSH est desactive. Vous ne pouvez plus vous connecter.

**Solution : Console KVM de votre hebergeur**

La console KVM est un acces direct au serveur, comme si vous aviez
un ecran et un clavier branches physiquement dessus. SSH n'est pas
implique → le blocage SSH ne compte pas.

**Instructions OVH** :
1. Connectez-vous a [OVH Manager](https://www.ovh.com/manager/)
2. Bare Metal Cloud → VPS → Cliquez sur votre VPS
3. Onglet **KVM** (ou **Console**)
4. Cliquez sur **Lancer le KVM**
5. Login : `dokploy`
6. Mot de passe : celui defini pendant le script

> C'est pour ca que le script demande un mot de passe
> MEME quand une cle SSH est fournie : le mot de passe sert pour
> KVM et pour `sudo`.

**Autres hebergeurs** :
- **Hetzner** : Cloud Console → Server → Console
- **DigitalOcean** : Droplet → Access → Launch Droplet Console
- **Scaleway** : Instances → Console

**Une fois connecte via KVM** :

```bash
# 1. Sur votre NOUVEAU Mac, generer une nouvelle cle
ssh-keygen -t ed25519 -C "nouveau-mac@example.com"
cat ~/.ssh/id_ed25519.pub
# Copiez la cle publique

# 2. Sur le VPS (via KVM), ajouter la nouvelle cle
echo "ssh-ed25519 AAAA...NOUVELLE_CLE..." >> /home/dokploy/.ssh/authorized_keys

# 3. (Optionnel) Supprimer l'ancienne cle
nano /home/dokploy/.ssh/authorized_keys
# Supprimez la ligne correspondant a l'ancien Mac

# 4. Tester depuis le nouveau Mac
ssh dokploy@IP_DU_VPS
```

### Scenario 2 : Cle SSH perdue (Mac fonctionnel)

**Situation** : vous avez supprime ou ecrase `~/.ssh/id_ed25519` par accident.

```bash
# 1. Generer une nouvelle cle
ssh-keygen -t ed25519 -C "email@example.com"

# 2. Se connecter via KVM (meme procedure que scenario 1)
#    OU si le mot de passe SSH est encore actif :
ssh dokploy@IP_DU_VPS   # tapez le mot de passe

# 3. Ajouter la nouvelle cle publique
echo "ssh-ed25519 AAAA...NOUVELLE_CLE..." >> ~/.ssh/authorized_keys
```

### Scenario 3 : Mot de passe dokploy oublie

**Situation** : la cle SSH fonctionne, mais vous ne pouvez pas faire `sudo`.

```bash
# Depuis KVM, connectez-vous en ROOT directement
# (KVM ignore la config SSH, le login root fonctionne)

# Changer le mot de passe de dokploy
passwd dokploy
```

Si le login root ne fonctionne pas non plus via KVM,
la plupart des hebergeurs offrent un **mode rescue** :
- OVH : VPS → Redemarrer en mode rescue
- Le serveur demarre sur un mini-systeme qui vous donne un acces root
- Depuis la, montez le disque et modifiez `/etc/shadow`

### Scenario 4 : IP bannie par Fail2ban

**Situation** : vous avez tape un mauvais mot de passe 3 fois
et votre IP est bloquee pendant 24 heures.

**Solution 1** — Attendre 24 heures.

**Solution 2** — Se connecter depuis une autre IP :
- Utilisez votre telephone en partage de connexion (IP differente)
- Utilisez un VPN (IP differente)

```bash
# Une fois connecte avec l'autre IP, debannir votre IP normale
sudo fail2ban-client set sshd unbanip VOTRE_IP_NORMALE
```

**Solution 3** — Console KVM :

```bash
# Via KVM, debannir votre IP
sudo fail2ban-client set sshd unbanip VOTRE_IP
```

### Scenario 5 : Config SSH cassee

**Situation** : apres une modification manuelle de sshd_config, SSH ne demarre plus.

```bash
# Via KVM :

# 1. Restaurer le backup cree par le script
ls /etc/ssh/sshd_config.backup.*
# Choisir le plus recent :
sudo cp /etc/ssh/sshd_config.backup.20260313_143000 /etc/ssh/sshd_config

# 2. Redemarrer SSH
sudo systemctl restart sshd

# 3. Tester
ssh dokploy@IP_DU_VPS
```

---

## 9. Prevenir la perte d'acces

### Sauvegarder la cle privee SSH

Votre cle privee est le fichier le plus important pour l'acces au serveur.
Sauvegardez-la dans un endroit sur.

**Methode 1 — Gestionnaire de mots de passe** (recommande) :

```bash
# Copier la cle privee
cat ~/.ssh/id_ed25519
```

Collez le contenu dans une note securisee de votre gestionnaire
(1Password, Bitwarden, KeePass).

Pour restaurer sur un nouveau Mac :
```bash
# Creer le dossier .ssh
mkdir -p ~/.ssh && chmod 700 ~/.ssh

# Coller la cle privee dans un fichier
nano ~/.ssh/id_ed25519
# Collez le contenu, sauvegardez

# Mettre les bonnes permissions (OBLIGATOIRE)
chmod 600 ~/.ssh/id_ed25519
```

**Methode 2 — Cle USB chiffree** :

```bash
# Copier sur une cle USB
cp ~/.ssh/id_ed25519 /Volumes/MA_CLE_USB/
cp ~/.ssh/id_ed25519.pub /Volumes/MA_CLE_USB/
```

Rangez la cle USB dans un endroit sur.

**Ce qu'il ne faut JAMAIS faire** :
- Envoyer la cle par email, Slack, WhatsApp, Teams
- La stocker sur Google Drive, Dropbox, iCloud (non chiffre)
- La mettre dans un repo Git (meme prive)
- La coller dans un chat ou un ticket

### Ajouter plusieurs cles SSH

La meilleure protection : avoir **plusieurs cles** autorisees.

```bash
# Sur le VPS, ajouter des cles supplementaires
echo "ssh-ed25519 AAAA...cle_pc_bureau..." >> ~/.ssh/authorized_keys
echo "ssh-ed25519 AAAA...cle_laptop_backup..." >> ~/.ssh/authorized_keys
```

Sources possibles de cles backup :
- Un deuxieme ordinateur (Mac du bureau, laptop perso)
- Un telephone (Termius, Blink Shell sur iOS)
- Une cle de secours generee et stockee dans un gestionnaire de mots de passe

### Utiliser le trousseau macOS

Si vous avez mis un passphrase sur votre cle SSH, macOS peut le retenir :

```bash
# Ajouter la cle a l'agent SSH avec stockage dans le trousseau macOS
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

Avantages :
- Le passphrase est stocke dans le Keychain macOS (chiffre)
- Pas besoin de le retaper a chaque connexion
- Si vous utilisez iCloud Keychain, le passphrase est synchronise
  entre vos appareils Apple

Pour que ca persiste apres un reboot, ajoutez dans `~/.ssh/config` :

```
Host *
    UseKeychain yes
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
```

### Checklist de securite personnelle

Cochez chaque element pour etre protege :

```
[ ] Cle SSH generee (ed25519)
[ ] Cle publique installee sur le serveur
[ ] Connexion sans mot de passe + testee
[ ] Cle privee sauvegardee (gestionnaire de mots de passe OU cle USB)
[ ] Au moins 2 cles autorisees sur le serveur
[ ] Mot de passe dokploy note (pour KVM et sudo)
[ ] Trousseau macOS configure (si passphrase)
[ ] Alias SSH configure dans ~/.ssh/config
[ ] Acces KVM teste une fois (savoir ou le trouver chez OVH)
```

---

## 10. Maintenance courante

### Commandes utiles au quotidien

```bash
# === CONNEXION ===
ssh vps                                   # Si alias configure
ssh dokploy@IP_DU_VPS                     # Sinon

# === ETAT GENERAL ===
htop                                      # Moniteur interactif (CPU, RAM, processus)
df -h                                     # Espace disque
free -h                                   # Memoire + swap
uptime                                    # Depuis combien de temps le serveur tourne

# === SECURITE ===
sudo ufw status verbose                   # Etat du pare-feu
sudo fail2ban-client status sshd          # IP bannies (SSH)
sudo fail2ban-client status recidive      # Recidivistes bannis
sudo systemctl status sshd                # Etat du service SSH
sudo cat /var/log/auth.log | tail -20     # Dernieres tentatives de connexion

# === DOCKER ===
docker ps                                 # Containers en cours
docker ps -a                              # Tous les containers (y compris arretes)
docker stats                              # Utilisation CPU/RAM par container
docker logs <container> --tail 50         # 50 derniers logs d'un container

# === BACKUPS ===
ls -lh /backup/postgres/                  # Liste des backups PostgreSQL
du -sh /backup/                           # Taille totale des backups

# === LOGS DU SCRIPT ===
ls /var/log/vps-prepare-*                 # Logs d'execution du script
```

### Surveiller l'espace disque

```bash
# Vue d'ensemble
df -h

# Trouver les gros fichiers/dossiers
sudo du -sh /var/lib/docker/*             # Espace Docker
sudo du -sh /backup/*                     # Espace backups
sudo du -sh /var/log/*                    # Espace logs

# Si le disque est presque plein :
# 1. Nettoyer Docker (images/containers inutilises)
docker system prune -a --volumes

# 2. Nettoyer les anciens backups
sudo find /backup -mtime +7 -delete

# 3. Nettoyer les logs
sudo journalctl --vacuum-time=7d
```

### Surveiller la memoire et le swap

```bash
# Usage memoire
free -h

# Exemple de sortie :
#               total    used    free    shared  buff/cache  available
# Mem:          3.8Gi   2.1Gi   200Mi    50Mi      1.5Gi      1.4Gi
# Swap:         2.0Gi   100Mi   1.9Gi

# Si le swap est tres utilise (> 50%), le serveur manque de RAM.
# Solutions :
# 1. Augmenter la RAM du VPS chez votre hebergeur
# 2. Optimiser les containers (limiter la memoire Docker)
# 3. Augmenter le swap : sudo fallocate -l 4G /swapfile2
```

### Mettre a jour le serveur manuellement

Les patchs de securite sont automatiques, mais pour les mises a jour
completes :

```bash
# Mise a jour standard
sudo apt update && sudo apt upgrade -y

# Nettoyage
sudo apt autoremove -y

# Si le terminal dit "*** System restart required ***" :
sudo reboot

# Attendre 30 secondes puis se reconnecter
ssh vps
```

### Consulter les logs

```bash
# Logs SSH (tentatives de connexion)
sudo tail -50 /var/log/auth.log

# Logs Fail2ban (bannissements)
sudo tail -50 /var/log/fail2ban.log

# Logs systeme generaux
sudo journalctl -xe --no-pager | tail -50

# Logs des mises a jour automatiques
sudo cat /var/log/unattended-upgrades/unattended-upgrades.log

# Logs du script de preparation
cat /var/log/vps-prepare-*.log
```

---

## 11. Depannage

| Probleme | Cause probable | Solution |
|----------|----------------|----------|
| `Connection refused` | SSH ne tourne pas ou mauvais port | KVM → `sudo systemctl start sshd` |
| `Permission denied (publickey)` | La cle SSH n'est pas sur le serveur | KVM → ajouter la cle dans `authorized_keys` |
| `Connection timed out` | IP bannie ou pare-feu bloque | Changer d'IP ou KVM → `sudo fail2ban-client set sshd unbanip IP` |
| `Host key verification failed` | Le serveur a ete reinstalle | `ssh-keygen -R IP_DU_VPS` sur votre Mac |
| `No space left on device` | Disque plein | `docker system prune -a` + nettoyer logs et backups |
| `OOM Killed` dans les logs | RAM insuffisante | Verifier swap (`free -h`), augmenter si besoin |
| `sudo: command not found` | Utilisateur pas dans le groupe sudo | KVM en root → `usermod -aG sudo dokploy` |
| SSH ne redemarre pas | Config sshd invalide | KVM → `sudo sshd -t` pour voir l'erreur, restaurer backup |
| Backup PostgreSQL vide (0 octets) | Container absent ou nom different | Verifier `docker ps`, adapter le cron |

---

## 12. Etapes suivantes apres le script

Maintenant que le VPS est prepare et securise, voici la suite :

```
1. REDEMARRER SSH
   sudo systemctl restart sshd

2. TESTER LA CONNEXION (nouveau terminal !)
   ssh dokploy@IP_DU_VPS

3. INSTALLER DOKPLOY
   curl -sSL https://dokploy.com/install.sh | sh

4. ACCEDER A L'INTERFACE DOKPLOY
   https://IP_DU_VPS:3000

5. CONFIGURER LES DNS
   dokploy.votre-domaine.com  → IP_DU_VPS
   app.votre-domaine.com      → IP_DU_VPS
   api.votre-domaine.com      → IP_DU_VPS

6. DEPLOYER RADIOMANAGER
   - Backend FastAPI (depuis le repo Git)
   - Frontend React (depuis le repo Git)
   - PostgreSQL (base de donnees)

7. VERIFIER LES BACKUPS (le lendemain)
   ls -lh /backup/postgres/
```

---

## 13. Glossaire

| Terme | Definition |
|-------|-----------|
| **SSH** | Secure Shell — protocole pour se connecter a distance a un serveur |
| **Cle SSH** | Paire cryptographique (publique + privee) pour s'authentifier sans mot de passe |
| **VPS** | Virtual Private Server — serveur virtuel loue chez un hebergeur |
| **KVM** | Keyboard Video Mouse — console d'acces direct au serveur (via l'hebergeur) |
| **UFW** | Uncomplicated Firewall — pare-feu simplifie pour Linux |
| **iptables** | Le vrai pare-feu Linux (UFW est un front-end simplifie pour iptables) |
| **Fail2ban** | Logiciel qui bannit les IP apres trop de tentatives echouees |
| **Docker** | Plateforme de containerisation (faire tourner des apps dans des containers isoles) |
| **Container** | Instance isolee d'une application (comme une mini machine virtuelle legere) |
| **Dokploy** | Plateforme de deploiement auto-hebergee (alternative a Heroku) |
| **Traefik** | Reverse proxy qui gere les domaines, le routage et le SSL automatiquement |
| **PostgreSQL** | Base de donnees relationnelle (utilisee par RadioManager) |
| **Swap** | Espace disque utilise comme memoire de secours quand la RAM est pleine |
| **OOM Killer** | Mecanisme Linux qui tue des processus quand la memoire est epuisee |
| **Sysctl** | Outil pour configurer les parametres du kernel Linux a chaud |
| **Cron** | Planificateur de taches Linux (execute des commandes a des heures precises) |
| **ED25519** | Algorithme de cle SSH moderne, rapide et tres securise (256 bits) |
| **Passphrase** | Mot de passe optionnel qui protege la cle privee SSH |
| **authorized_keys** | Fichier sur le serveur listant les cles publiques autorisees |
| **sshd_config** | Fichier de configuration du serveur SSH |
| **Brute-force** | Attaque qui essaie toutes les combinaisons possibles de mots de passe |
| **Spoofing** | Attaque ou l'on falsifie l'adresse IP source d'un paquet reseau |
| **DDoS** | Distributed Denial of Service — attaque qui submerge un serveur de requetes |
| **MITM** | Man In The Middle — attaque ou l'on intercepte les communications |
| **Idempotent** | Un script idempotent peut etre execute plusieurs fois sans effet secondaire |

---

*Document genere le 2026-03-13 — script quick-prepare-vps.sh v2.0*
*Projet RadioManager — Preparation VPS pour Dokploy*
