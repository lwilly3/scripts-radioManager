# 📊 État du Serveur Après Préparation

> **Documentation complète de la configuration et de l'état du serveur après exécution du script `quick-prepare-vps.sh`**

## 📋 Table des matières

- [Vue d'ensemble](#-vue-densemble)
- [Configuration système](#-configuration-système)
- [Utilisateurs et permissions](#-utilisateurs-et-permissions)
- [Configuration SSH](#-configuration-ssh)
- [Pare-feu UFW](#-pare-feu-ufw)
- [Protection Fail2ban](#-protection-fail2ban)
- [Optimisations kernel](#-optimisations-kernel)
- [Structure des répertoires](#-structure-des-répertoires)
- [Services actifs](#-services-actifs)
- [Fichiers de configuration](#-fichiers-de-configuration)
- [Vérifications système](#-vérifications-système)
- [Comparaison avant/après](#-comparaison-avantaprès)

---

## 🎯 Vue d'ensemble

### État initial du VPS OVH

Lorsque vous recevez un VPS OVH fraîchement installé :

```
État AVANT le script
├── OS : Ubuntu 24.04/22.04 ou Debian 11/12 (minimal)
├── Utilisateur : root uniquement
├── SSH : Port 22, mot de passe activé, root accessible
├── Pare-feu : DÉSACTIVÉ (tous les ports ouverts)
├── Fail2ban : NON INSTALLÉ
├── Paquets : Installation minimale système
├── Timezone : UTC
├── Swap : Parfois absent
└── Optimisations : Aucune
```

### État après exécution du script

```
État APRÈS le script quick-prepare-vps.sh
├── OS : Mis à jour (derniers paquets de sécurité)
├── Utilisateurs : root + dokploy (avec sudo)
├── SSH : Sécurisé (root désactivé, tentatives limitées)
├── Pare-feu : UFW actif (ports 22, 80, 443, 3000 ouverts)
├── Fail2ban : Actif (protection brute-force SSH)
├── Paquets : 40+ outils essentiels installés
├── Timezone : Africa/Douala (UTC+1, Cameroun)
├── Swap : Configuré si nécessaire
├── Optimisations : Kernel optimisé pour Docker
└── Répertoires : /opt/dokploy, /var/lib/dokploy, /backup
```

**Résultat** : Serveur production-ready, sécurisé et optimisé pour Docker/Dokploy.

---

## ⚙️ Configuration système

### Paquets installés

Le script installe automatiquement **40+ paquets essentiels** :

#### Outils de base
```bash
curl               # Téléchargement HTTP/HTTPS
wget               # Alternative à curl
git                # Gestion de version
vim                # Éditeur de texte avancé
nano               # Éditeur simple pour débutants
htop               # Moniteur de processus interactif
```

#### Outils réseau
```bash
net-tools          # ifconfig, netstat, route
dnsutils           # nslookup, dig (DNS)
ca-certificates    # Certificats SSL racines
```

#### Sécurité
```bash
gnupg              # Chiffrement GPG
lsb-release        # Informations distribution
apt-transport-https # Support HTTPS pour apt
sudo               # Élévation de privilèges
ufw                # Pare-feu simplifié
fail2ban           # Protection brute-force
```

#### Utilitaires
```bash
software-properties-common # Gestion de PPA
unzip              # Décompression archives
```

### Timezone configurée

```bash
# Configuration par défaut
Timezone: Africa/Douala
Offset: UTC+1 (pas de changement été/hiver)
Emplacement: Douala, Cameroun

# Impact sur :
- Logs système (/var/log/*)
- Timestamps base de données
- Cron jobs
- Dates affichées dans les applications
```

**Vérifier** :
```bash
timedatectl
# Output:
#                Local time: ven. 2024-12-20 14:30:00 WAT
#            Universal time: ven. 2024-12-20 13:30:00 UTC
#                  RTC time: ven. 2024-12-20 13:30:00
#                 Time zone: Africa/Douala (WAT, +0100)
```

### Locale système

```bash
# Locale installée et activée
LANG=fr_FR.UTF-8
LANGUAGE=fr_FR:fr
LC_ALL=fr_FR.UTF-8

# Impact :
- Messages système en français
- Formats de date européens
- Tri alphabétique avec accents
- Support caractères spéciaux (é, à, ç, etc.)
```

---

## 👥 Utilisateurs et permissions

### Utilisateur `root`

```bash
État APRÈS le script :
├── Accès SSH : ❌ DÉSACTIVÉ (PermitRootLogin no)
├── Login mot de passe : ❌ DÉSACTIVÉ (à activer après clés SSH)
├── Utilisation : Uniquement via sudo depuis dokploy
└── Sécurité : ✅ Renforcée
```

**⚠️ Important** : Le compte root existe toujours mais n'est plus accessible directement en SSH.

### Utilisateur `dokploy`

```bash
Nom d'utilisateur : dokploy
UID/GID : Assigné dynamiquement (ex: 1001:1001)
Home : /home/dokploy
Shell : /bin/bash
Groupes : dokploy, sudo
Privilèges sudo : ✅ OUI (avec mot de passe)
Mot de passe : ✅ Défini par l'utilisateur (fort requis)
Clés SSH : ⏳ À configurer après le script
```

**Permissions sudo** :
```bash
# L'utilisateur dokploy peut exécuter des commandes root
sudo systemctl restart nginx     # ✅ Autorisé (avec mot de passe)
sudo docker ps                    # ✅ Autorisé
sudo apt update                   # ✅ Autorisé

# Vérifier les privilèges
sudo -l -U dokploy
```

### Structure /home/dokploy

```
/home/dokploy/
├── .bashrc              # Config shell
├── .bash_history        # Historique commandes
├── .profile             # Variables d'environnement
├── .ssh/                # Clés SSH (créé après ssh-copy-id)
│   └── authorized_keys  # Clés publiques autorisées
└── .cache/              # Cache utilisateur
```

---

## 🔒 Configuration SSH

### Fichier `/etc/ssh/sshd_config`

Le script modifie automatiquement la configuration SSH :

```bash
# === PORT ===
Port 22                          # Par défaut (ou personnalisé si choisi)

# === AUTHENTIFICATION ===
PermitRootLogin no               # ❌ Root ne peut plus se connecter
PubkeyAuthentication yes         # ✅ Clés SSH autorisées
PasswordAuthentication yes       # ⏳ TEMPORAIRE (à désactiver après config clés)
MaxAuthTries 3                   # 🛡️ 3 tentatives max avant déconnexion

# === TIMEOUTS ===
ClientAliveInterval 300          # Timeout 5 minutes inactivité
ClientAliveCountMax 2            # 2 tentatives avant déconnexion

# === SÉCURITÉ ===
Protocol 2                       # ✅ SSH Protocol 2 uniquement
X11Forwarding no                 # ❌ X11 désactivé (interface graphique)

# === WHITELIST ===
AllowUsers dokploy               # ✅ Seul dokploy peut se connecter
```

### Backup de configuration

```bash
Fichier original sauvegardé :
/etc/ssh/sshd_config.backup.YYYYMMDD_HHMMSS

Exemple :
/etc/ssh/sshd_config.backup.20241220_143000

# Restaurer si besoin :
sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### État du service SSH

```bash
Service : sshd (OpenSSH Server)
État : ✅ Actif et en écoute
Port : 22 (ou personnalisé)
Démarrage auto : ✅ Activé

# Vérifier
systemctl status sshd
# Output:
# ● ssh.service - OpenBSD Secure Shell server
#    Loaded: loaded
#    Active: active (running)
```

### Processus d'authentification

```
Connexion SSH
    ↓
Port 22 → SSH écoute
    ↓
Utilisateur autorisé ? → AllowUsers dokploy
    ✅ OUI               ❌ NON → Connexion refusée
    ↓
Méthode auth ?
    ├─→ Clé SSH ? → authorized_keys → ✅ Connexion
    └─→ Mot de passe ? → 3 tentatives max → Fail2ban si échec
```

---

## 🛡️ Pare-feu UFW

### Configuration par défaut

```bash
État : ✅ ACTIF
Politique entrante : DENY (tout bloqué par défaut)
Politique sortante : ALLOW (tout autorisé)

# Vérifier
sudo ufw status verbose
```

### Règles configurées

| Port | Protocole | Direction | Service | Commentaire |
|------|-----------|-----------|---------|-------------|
| 22 | TCP | IN | SSH | Accès administration serveur |
| 80 | TCP | IN | HTTP | Applications web (redirect HTTPS) |
| 443 | TCP | IN | HTTPS | Applications web sécurisées |
| 3000 | TCP | IN | Dokploy | Interface web Dokploy |

**Sortie complète de `ufw status`** :
```bash
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere              # SSH
80/tcp                     ALLOW       Anywhere              # HTTP
443/tcp                     ALLOW       Anywhere              # HTTPS
3000/tcp                    ALLOW       Anywhere              # Dokploy UI
22/tcp (v6)                ALLOW       Anywhere (v6)         # SSH
80/tcp (v6)                ALLOW       Anywhere (v6)         # HTTP
443/tcp (v6)               ALLOW       Anywhere (v6)         # HTTPS
3000/tcp (v6)              ALLOW       Anywhere (v6)         # Dokploy UI
```

### Ports bloqués (exemples)

```bash
❌ Port 5432 (PostgreSQL) → Bloqué par défaut (RECOMMANDÉ)
❌ Port 3306 (MySQL) → Bloqué
❌ Port 6379 (Redis) → Bloqué
❌ Port 8080 (Alt HTTP) → Bloqué
❌ Tous les autres ports → Bloqués
```

**⚠️ Important** : Les bases de données (PostgreSQL, MySQL) ne sont **PAS** exposées publiquement. Accès uniquement via :
- Conteneurs Docker (réseau interne)
- Tunnel SSH : `ssh -L 5432:localhost:5432 dokploy@VPS`
- VPN WireGuard (si configuré)

### Logs UFW

```bash
# Fichier de logs
/var/log/ufw.log

# Voir les tentatives bloquées
sudo tail -f /var/log/ufw.log

# Exemple de log :
# [UFW BLOCK] IN=eth0 SRC=123.45.67.89 DST=51.178.xx.xx PROTO=TCP DPT=5432
```

---

## 🚨 Protection Fail2ban

### Configuration `/etc/fail2ban/jail.local`

```ini
[DEFAULT]
# Durée du bannissement (en secondes)
bantime  = 3600                  # 1 heure (3600s)

# Fenêtre de temps pour compter les échecs
findtime = 600                   # 10 minutes

# Nombre max de tentatives échouées
maxretry = 3                     # 3 essais avant ban

# Action par défaut
banaction = iptables-multiport   # Bannir via iptables
action = %(action_mwl)s          # Ban + email + WHOIS + logs (si configuré)

[sshd]
enabled = true                   # Protection SSH active
port    = 22                     # Port SSH surveillé
logpath = /var/log/auth.log      # Fichier de logs analysé
maxretry = 3                     # 3 échecs = ban
```

**Note sur les notifications** :
- `%(action_mwl)s` = Bannir + Email avec WHOIS et logs
- Par défaut, les emails **ne sont PAS configurés**
- Pour activer les notifications, voir : [FAIL2BAN-EMAIL-NOTIFICATIONS.md](FAIL2BAN-EMAIL-NOTIFICATIONS.md)

### État du service

```bash
Service : fail2ban
État : ✅ Actif
Démarrage auto : ✅ Activé
Jails actives : sshd

# Vérifier
sudo systemctl status fail2ban
sudo fail2ban-client status
```

### Fonctionnement

```
Tentative de connexion SSH
    ↓
Fail2ban surveille /var/log/auth.log
    ↓
Mot de passe incorrect ?
    ✅ OUI → Compteur +1
    ❌ NON → OK
    ↓
Compteur ≥ 3 dans les 10 dernières minutes ?
    ✅ OUI → Bannir IP pendant 1h (iptables)
    ❌ NON → Autoriser nouvelle tentative
    ↓
IP bannie
    ├─→ Tentative de connexion → Rejetée automatiquement
    └─→ Après 1h → Débannissement automatique
```

### Commandes utiles

```bash
# Voir les IP bannies
sudo fail2ban-client status sshd

# Débannir une IP manuellement
sudo fail2ban-client set sshd unbanip 123.45.67.89

# Bannir une IP manuellement
sudo fail2ban-client set sshd banip 123.45.67.89

# Logs Fail2ban
sudo tail -f /var/log/fail2ban.log
```

### Exemple de scénario

```
Attaquant : 123.45.67.89
Action : Brute force SSH

14:30:00 → Tentative 1 : mot de passe incorrect ❌
14:30:05 → Tentative 2 : mot de passe incorrect ❌
14:30:10 → Tentative 3 : mot de passe incorrect ❌
14:30:11 → 🚨 BANNISSEMENT : IP 123.45.67.89 bloquée
14:30:15 → Tentative 4 : REJETÉE (IP bannie)
...
15:30:11 → Débannissement automatique (1h écoulée)
```

---

## ⚡ Optimisations kernel

### Fichier `/etc/sysctl.conf`

Le script ajoute ces paramètres à la fin du fichier :

```bash
# === Optimisations pour Docker et Dokploy ===

# Forwarding IP (REQUIS pour Docker)
net.ipv4.ip_forward = 1                    # ✅ Activer routage IPv4
net.ipv6.conf.all.forwarding = 1           # ✅ Activer routage IPv6

# Optimisations réseau TCP
net.core.somaxconn = 1024                  # ⬆️ File d'attente connexions
net.ipv4.tcp_max_syn_backlog = 2048        # ⬆️ SYN backlog
net.ipv4.tcp_fin_timeout = 30              # ⬇️ Timeout FIN_WAIT
net.ipv4.tcp_keepalive_time = 600          # ⬇️ Keepalive interval

# Limites de fichiers (IMPORTANT pour Docker)
fs.file-max = 65535                        # ⬆️ Max fichiers ouverts système
fs.inotify.max_user_watches = 524288       # ⬆️ Surveillance fichiers (Docker)
fs.inotify.max_user_instances = 512        # ⬆️ Instances inotify

# Optimisation mémoire
vm.swappiness = 10                         # ⬇️ Éviter swap (10%)
vm.dirty_ratio = 15                        # 15% RAM avant flush
vm.dirty_background_ratio = 5              # 5% RAM flush background
```

### Impact des optimisations

| Paramètre | Avant | Après | Effet |
|-----------|-------|-------|-------|
| `ip_forward` | 0 (off) | 1 (on) | ✅ Docker peut router le trafic |
| `somaxconn` | 128 | 1024 | ✅ +700% capacité connexions |
| `file-max` | ~100k | 65535 | ✅ Support plus de conteneurs |
| `inotify.max_user_watches` | 8192 | 524288 | ✅ +6400% surveillance fichiers |
| `swappiness` | 60 | 10 | ✅ Moins d'utilisation swap |

### Limites de fichiers `/etc/security/limits.conf`

```bash
# Ajouté à la fin du fichier

# Limites pour Docker et Dokploy
*               soft    nofile          65535
*               hard    nofile          65535
root            soft    nofile          65535
root            hard    nofile          65535
```

**Effet** : Chaque processus peut ouvrir jusqu'à 65535 fichiers simultanément (important pour Docker avec multiples conteneurs).

### Vérifier les paramètres

```bash
# Voir tous les paramètres kernel
sysctl -a

# Vérifier un paramètre spécifique
sysctl net.ipv4.ip_forward
# Output: net.ipv4.ip_forward = 1

# Vérifier les limites de fichiers
ulimit -n
# Output: 65535
```

---

## 📁 Structure des répertoires

### Répertoires créés

```
/
├── /opt/dokploy/              # Installation Dokploy
│   ├── docker-compose.yml     # Config Dokploy (après install)
│   ├── data/                  # Données Dokploy
│   └── traefik/               # Config Traefik
│
├── /var/lib/dokploy/          # Données persistantes
│   ├── volumes/               # Volumes Docker
│   └── databases/             # Bases de données
│
├── /var/log/dokploy/          # Logs Dokploy
│   ├── access.log
│   └── error.log
│
└── /backup/                   # Backups automatiques
    ├── db_20241220.sql
    ├── db_20241219.sql
    └── ...
```

### Permissions

```bash
/opt/dokploy
├── Propriétaire : dokploy:dokploy
└── Permissions : 755 (rwxr-xr-x)

/var/lib/dokploy
├── Propriétaire : dokploy:dokploy
└── Permissions : 755

/var/log/dokploy
├── Propriétaire : dokploy:dokploy
└── Permissions : 755

/backup
├── Propriétaire : root:root
└── Permissions : 755
```

### Espace disque recommandé

```
Usage typique après installation complète :

/opt/dokploy        → 500 MB - 1 GB
/var/lib/dokploy    → 5 GB - 50 GB (volumes Docker)
/var/log/dokploy    → 100 MB - 500 MB
/backup             → 1 GB - 10 GB (bases de données)

Total recommandé : 20 GB minimum (40 GB idéal)
```

---

## 🔄 Services actifs

### Liste des services systemd

```bash
# Services après le script

sshd.service          ✅ Active    # Serveur SSH
ufw.service           ✅ Active    # Pare-feu
fail2ban.service      ✅ Active    # Protection brute-force
systemd-timesyncd     ✅ Active    # Synchronisation heure (NTP)
cron.service          ✅ Active    # Tâches planifiées

# Services Docker (après installation Dokploy)
docker.service        ⏳ Installé après Dokploy
dokploy.service       ⏳ Installé après Dokploy
```

### Vérifier tous les services

```bash
# Liste des services actifs
systemctl list-units --type=service --state=running

# Vérifier un service spécifique
systemctl status sshd
systemctl status ufw
systemctl status fail2ban
```

### Services au démarrage

```bash
# Services activés au boot
systemctl list-unit-files --type=service --state=enabled

# Résultat attendu :
# sshd.service                           enabled
# ufw.service                            enabled
# fail2ban.service                       enabled
# cron.service                           enabled
```

---

## 📄 Fichiers de configuration

### Fichiers modifiés par le script

| Fichier | Chemin complet | Action | Backup |
|---------|---------------|--------|--------|
| SSH Config | `/etc/ssh/sshd_config` | ✏️ Modifié | ✅ Oui |
| UFW Rules | `/etc/ufw/user.rules` | ✏️ Modifié | ❌ Non (reset) |
| Fail2ban | `/etc/fail2ban/jail.local` | ➕ Créé | N/A |
| Sysctl | `/etc/sysctl.conf` | ➕ Ajout | ❌ Non |
| Limits | `/etc/security/limits.conf` | ➕ Ajout | ❌ Non |

### Fichiers de backup

```bash
/etc/ssh/sshd_config.backup.YYYYMMDD_HHMMSS

Exemple :
/etc/ssh/sshd_config.backup.20241220_143000
/etc/ssh/sshd_config.backup.20241220_100530

# Lister les backups
ls -lh /etc/ssh/sshd_config.backup.*
```

### Fichiers de logs

```bash
# Logs système
/var/log/syslog           # Logs généraux système
/var/log/auth.log         # Authentification (SSH, sudo)
/var/log/ufw.log          # Pare-feu UFW
/var/log/fail2ban.log     # Fail2ban
/var/log/kern.log         # Kernel

# Logs apt (installations)
/var/log/apt/history.log  # Historique paquets installés
/var/log/apt/term.log     # Sortie terminale apt
```

---

## ✅ Vérifications système

### Commandes de diagnostic

Après exécution du script, ces commandes vous permettent de vérifier l'état :

#### Système général

```bash
# Version OS
lsb_release -a
# Ubuntu 24.04.1 LTS

# Kernel
uname -r
# 6.8.0-49-generic

# Uptime
uptime
# up 1 hour, 0 users, load average: 0.15, 0.20, 0.18

# Espace disque
df -h /
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/vda1        40G  8.2G   30G  22% /

# Mémoire
free -h
# total        used        free      shared  buff/cache   available
# 4.0Gi       500Mi       2.8Gi      50Mi       700Mi       3.2Gi
```

#### Réseau

```bash
# IP publique
curl -4 ifconfig.me
# 51.178.xx.xx

# Ports en écoute
sudo ss -tlnp
# tcp   LISTEN 0      128          0.0.0.0:22         0.0.0.0:*
# tcp   LISTEN 0      128             [::]:22            [::]:*

# DNS
nslookup google.com
# Server:         127.0.0.53
# Address:        127.0.0.53#53
```

#### Sécurité

```bash
# UFW status
sudo ufw status numbered
# [1] 22/tcp                     ALLOW IN    Anywhere
# [2] 80/tcp                     ALLOW IN    Anywhere
# [3] 443/tcp                    ALLOW IN    Anywhere
# [4] 3000/tcp                   ALLOW IN    Anywhere

# Fail2ban status
sudo fail2ban-client status
# Number of jail:      1
# Jail list:   sshd

# SSH configuration
grep -E "^(Port|PermitRootLogin|PasswordAuthentication|AllowUsers)" /etc/ssh/sshd_config
# Port 22
# PermitRootLogin no
# AllowUsers dokploy
```

#### Utilisateurs

```bash
# Utilisateur courant
whoami
# dokploy

# Groupes de dokploy
groups dokploy
# dokploy : dokploy sudo

# Privilèges sudo
sudo -l -U dokploy
# User dokploy may run the following commands on vps:
#     (ALL : ALL) ALL
```

---

## 🔄 Comparaison avant/après

### Tableau récapitulatif

| Aspect | VPS OVH Initial | Après `quick-prepare-vps.sh` |
|--------|-----------------|------------------------------|
| **Utilisateurs** | root uniquement | root + dokploy (sudo) |
| **SSH root** | ✅ Autorisé | ❌ Désactivé |
| **SSH par mot de passe** | ✅ Activé | ⏳ Activé (à désactiver après clés) |
| **Pare-feu** | ❌ Désactivé | ✅ UFW actif (4 ports ouverts) |
| **Fail2ban** | ❌ Absent | ✅ Actif (protection SSH) |
| **Paquets installés** | ~150 (minimal) | ~200 (avec outils) |
| **Timezone** | UTC | **Africa/Douala (Cameroun)** |
| **Swap** | Variable | Configuré si <4GB RAM |
| **Kernel optimisé** | ❌ Non | ✅ Oui (Docker ready) |
| **Limites fichiers** | 1024 | 65535 |
| **Répertoires Dokploy** | ❌ Absents | ✅ Créés et configurés |
| **Backups SSH config** | ❌ Non | ✅ Oui (horodaté) |
| **Logs** | Basiques | Centralisés et organisés |
| **Sécurité globale** | ⭐⭐ (faible) | ⭐⭐⭐⭐⭐ (élevée) |

### Score de sécurité

#### Avant le script : 2/10 🔴

```
✅ OS à jour (si juste provisionné)
❌ Root accessible en SSH
❌ Pas de pare-feu
❌ Pas de protection brute-force
❌ Tous les ports ouverts
❌ Pas de limitation tentatives SSH
❌ Pas d'optimisations
```

#### Après le script : 8/10 🟢

```
✅ OS à jour
✅ Root désactivé en SSH
✅ Pare-feu actif et configuré
✅ Fail2ban protège SSH
✅ Ports minimaux ouverts
✅ Tentatives SSH limitées (3 max)
✅ Kernel optimisé
✅ Utilisateur non-root avec sudo
⚠️ Authentification par mot de passe encore active (étape suivante)
⚠️ Clés SSH à configurer
```

**Pour atteindre 10/10** :
1. Configurer l'authentification par clés SSH uniquement
2. Désactiver `PasswordAuthentication`
3. Ajouter monitoring (Prometheus/Grafana)
4. Configurer backups automatiques

---

## 🎯 Prochaines étapes recommandées

Après l'exécution du script, voici ce qu'il reste à faire :

### 1. Configurer les clés SSH (PRIORITAIRE)

```bash
# Sur votre machine locale
ssh-keygen -t ed25519 -C "votre-email@example.com"
ssh-copy-id dokploy@51.178.xx.xx

# Tester la connexion
ssh dokploy@51.178.xx.xx
```

### 2. Désactiver l'authentification par mot de passe

```bash
# Sur le serveur
sudo nano /etc/ssh/sshd_config
# Modifier : PasswordAuthentication no
sudo systemctl restart sshd
```

### 3. Installer Dokploy

```bash
curl -sSL https://dokploy.com/install.sh | sh
```

### 4. Configurer DNS

```bash
# Pointer vos domaines vers l'IP du VPS
# Dans l'interface OVH :
# A    @             51.178.xx.xx
# A    dokploy       51.178.xx.xx
# A    app           51.178.xx.xx
# A    api           51.178.xx.xx
```

### 5. Premier déploiement

Via l'interface Dokploy : `https://51.178.xx.xx:3000`

---

## 📚 Ressources

- **Documentation complète** : [PREPARATION-VPS-OVH.md](PREPARATION-VPS-OVH.md)
- **Guide Dokploy** : [README.md](README.md)
- **Variables d'environnement** : [VARIABLES-GUIDE.md](VARIABLES-GUIDE.md)
- **Migration** : [../MIGRATION.md](../MIGRATION.md)

---

<div align="center">

**✅ Votre serveur est maintenant sécurisé et prêt pour la production !**

**Questions ?** Ouvrez une [issue sur GitHub](https://github.com/lwilly3/scripts-radioManager/issues)

</div>
