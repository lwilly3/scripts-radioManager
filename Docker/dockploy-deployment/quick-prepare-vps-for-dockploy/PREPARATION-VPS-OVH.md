# 🚀 Préparation VPS OVH pour Dokploy

> **Guide complet de préparation d'un VPS OVH avant installation de Dokploy**

## 📋 Table des matières

- [Prérequis](#-prérequis)
- [Étape 1 : Première connexion](#-étape-1--première-connexion)
- [Étape 2 : Mise à jour système](#-étape-2--mise-à-jour-système)
- [Étape 3 : Configuration réseau](#-étape-3--configuration-réseau)
- [Étape 4 : Sécurisation SSH](#-étape-4--sécurisation-ssh)
- [Étape 5 : Configuration pare-feu](#-étape-5--configuration-pare-feu)
- [Étape 6 : Optimisations système](#-étape-6--optimisations-système)
- [Étape 7 : Préparation Docker](#-étape-7--préparation-docker)
- [Étape 8 : Installation Dokploy](#-étape-8--installation-dokploy)
- [Vérifications finales](#-vérifications-finales)
- [Troubleshooting](#-troubleshooting)

---

## ✅ Prérequis

### Informations nécessaires

Avant de commencer, assurez-vous d'avoir :

- [ ] **Adresse IP du VPS** (ex: `51.178.xx.xx`)
- [ ] **Mot de passe root** (envoyé par email OVH)
- [ ] **Nom(s) de domaine** configuré(s) pointant vers l'IP du VPS
- [ ] **Client SSH** installé sur votre machine locale
  - Windows : PuTTY, Windows Terminal, ou WSL
  - macOS/Linux : Terminal natif

### Spécifications minimales recommandées

| Ressource | Minimum | Recommandé | Pour production |
|-----------|---------|------------|-----------------|
| **CPU** | 1 vCore | 2 vCores | 4 vCores |
| **RAM** | 2 GB | 4 GB | 8 GB |
| **Disque** | 20 GB | 40 GB | 80 GB+ |
| **Bande passante** | 100 Mbps | 250 Mbps | 500 Mbps+ |

**VPS OVH recommandés** :
- **Starter** : VPS Starter (2 vCores, 2GB RAM) - ~$5/mois - Tests/Dev
- **Intermédiaire** : VPS Value (2 vCores, 4GB RAM) - ~$10/mois - Petite prod
- **Production** : VPS Comfort (4 vCores, 8GB RAM) - ~$20/mois - Production

---

## 🔐 Étape 1 : Première connexion

### 1.1 Connexion SSH initiale

```bash
# Depuis votre machine locale
ssh root@51.178.xx.xx

# Vous serez invité à entrer le mot de passe root
# (celui envoyé par email OVH)
```

**⚠️ Première connexion** : Vous verrez un avertissement de fingerprint, tapez `yes` pour continuer.

### 1.2 Changer le mot de passe root

```bash
# Définir un nouveau mot de passe fort
passwd

# Exigences :
# - Minimum 16 caractères
# - Lettres majuscules et minuscules
# - Chiffres
# - Symboles spéciaux (@, #, !, etc.)

# Exemple de mot de passe fort :
# K8z!mP2@vL9$nQ5#xR7
```

**💡 Conseil** : Utilisez un gestionnaire de mots de passe (1Password, Bitwarden, KeePass).

### 1.3 Vérifier le système installé

```bash
# Vérifier la distribution
cat /etc/os-release

# Vérifier la version du kernel
uname -r

# Vérifier l'espace disque
df -h

# Vérifier la RAM
free -h

# Vérifier les CPU
nproc
lscpu
```

**Distributions supportées par Dokploy** :
- ✅ Ubuntu 20.04 LTS
- ✅ Ubuntu 22.04 LTS (Recommandé)
- ✅ Ubuntu 24.04 LTS
- ✅ Debian 11
- ✅ Debian 12
- ⚠️ CentOS/Rocky Linux (support expérimental)

---

## 🔄 Étape 2 : Mise à jour système

### 2.1 Mise à jour complète

```bash
# Mettre à jour la liste des paquets
apt update

# Mettre à niveau tous les paquets
apt upgrade -y

# Mise à niveau de la distribution (si nécessaire)
apt dist-upgrade -y

# Nettoyer les paquets obsolètes
apt autoremove -y
apt autoclean
```

**Temps estimé** : 5-10 minutes

### 2.2 Installer les outils essentiels

```bash
# Outils de base
apt install -y \
  curl \
  wget \
  git \
  vim \
  nano \
  htop \
  net-tools \
  dnsutils \
  ca-certificates \
  gnupg \
  lsb-release \
  software-properties-common \
  apt-transport-https \
  sudo \
  ufw \
  fail2ban \
  unzip

# Vérifier l'installation
which curl wget git vim
```

### 2.3 Configurer le fuseau horaire

```bash
# Lister les fuseaux disponibles pour l'Afrique
timedatectl list-timezones | grep Africa

# Fuseaux horaires africains courants :
# Africa/Douala       → Cameroun (UTC+1, recommandé)
# Africa/Lagos        → Nigeria (UTC+1)
# Africa/Kinshasa     → RD Congo (UTC+1)
# Africa/Abidjan      → Côte d'Ivoire (UTC+0)
# Africa/Dakar        → Sénégal (UTC+0)
# Africa/Cairo        → Égypte (UTC+2)

# Définir le fuseau horaire (Douala par défaut)
timedatectl set-timezone Africa/Douala

# Autres exemples :
# timedatectl set-timezone Africa/Lagos      # Nigeria
# timedatectl set-timezone Africa/Kinshasa   # RD Congo
# timedatectl set-timezone Europe/Paris      # France

# Vérifier
timedatectl
date
```

**💡 Pourquoi Africa/Douala ?**

- ✅ Fuseau horaire du Cameroun (WAT - West Africa Time)
- ✅ UTC+1 toute l'année (pas de changement heure d'été/hiver)
- ✅ Partagé avec : Nigeria, Niger, Tchad, Gabon, Congo, RCA
- ✅ Simplifie la gestion des timestamps pour les applications africaines

**Impact du fuseau horaire** :
```bash
# Timestamps dans les logs
/var/log/syslog
# Avant (UTC) : Dec 20 13:30:00
# Après (WAT) : Dec 20 14:30:00  (+1h)

# Cron jobs (exécution basée sur heure locale)
# Exemple : backup quotidien à 2h du matin (WAT)
0 2 * * * /usr/local/bin/backup.sh

# Base de données PostgreSQL
# Les timestamps sont stockés en UTC mais affichés en WAT
SELECT NOW();
# 2024-12-20 14:30:00+01  (WAT)
```

### 2.4 Configurer la locale

```bash
# Installer les locales françaises
apt install -y locales

# Générer les locales
locale-gen fr_FR.UTF-8
update-locale LANG=fr_FR.UTF-8

# Vérifier
locale
```

---

## 🌐 Étape 3 : Configuration réseau

### 3.1 Configurer le hostname

```bash
# Définir un nom d'hôte descriptif
hostnamectl set-hostname vps-dokploy-prod

# Vérifier
hostnamectl
hostname
```

### 3.2 Configurer /etc/hosts

```bash
# Éditer le fichier hosts
nano /etc/hosts

# Ajouter ces lignes (remplacer par votre IP et domaine)
127.0.0.1       localhost
51.178.xx.xx    vps-dokploy-prod.votre-domaine.com vps-dokploy-prod

# IPv6 (si activé)
::1             localhost ip6-localhost ip6-loopback
```

**Sauvegarder** : `Ctrl+O`, `Enter`, `Ctrl+X`

### 3.3 Vérifier la résolution DNS

```bash
# Tester la résolution DNS
nslookup google.com
dig google.com

# Tester votre domaine
nslookup votre-domaine.com

# Vérifier que l'IP correspond
ping -c 4 votre-domaine.com
```

**⚠️ Important** : Vos domaines doivent pointer vers l'IP du VPS **avant** l'installation de Dokploy pour que SSL fonctionne.

### 3.4 Configuration DNS chez OVH

Connectez-vous à l'espace client OVH et configurez :

```
# Zone DNS
Type   Nom                    Cible           TTL
A      @                      51.178.xx.xx    300
A      *                      51.178.xx.xx    300
AAAA   @                      2001:xxx::1     300 (si IPv6)
AAAA   *                      2001:xxx::1     300 (si IPv6)

# Sous-domaines spécifiques pour Dokploy
A      dokploy                51.178.xx.xx    300
A      api                    51.178.xx.xx    300
A      app                    51.178.xx.xx    300
```

**Propagation DNS** : Peut prendre 5 minutes à 24h (généralement < 1h).

---

## 🔒 Étape 4 : Sécurisation SSH

### 4.1 Créer un utilisateur sudo (ne pas utiliser root)

```bash
# Créer un nouvel utilisateur
adduser dokploy
# Suivre les invites pour définir un mot de passe

# Ajouter au groupe sudo
usermod -aG sudo dokploy

# Vérifier
groups dokploy
# Doit afficher : dokploy : dokploy sudo
```

### 4.2 Configurer l'authentification par clé SSH

**Sur votre machine locale** (pas sur le VPS) :

```bash
# Générer une paire de clés SSH (si vous n'en avez pas)
ssh-keygen -t ed25519 -C "votre-email@example.com"
# ou pour RSA (plus compatible)
ssh-keygen -t rsa -b 4096 -C "votre-email@example.com"

# Fichiers créés :
# - ~/.ssh/id_ed25519 (clé privée - À GARDER SECRET)
# - ~/.ssh/id_ed25519.pub (clé publique)

# Copier la clé publique vers le VPS
ssh-copy-id dokploy@51.178.xx.xx

# Tester la connexion sans mot de passe
ssh dokploy@51.178.xx.xx
```

**Sur Windows** (avec PuTTY) :
1. Utiliser PuTTYgen pour générer la clé
2. Sauvegarder la clé privée (.ppk)
3. Copier la clé publique dans `~/.ssh/authorized_keys` sur le VPS

### 4.3 Durcir la configuration SSH

```bash
# Backup de la config originale
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Éditer la configuration
sudo nano /etc/ssh/sshd_config
```

**Modifications recommandées** :

```bash
# === PORT SSH ===
# Par défaut : Port 22 (standard)
# Pour plus de sécurité, vous pouvez le changer (ex: Port 2222)
# ⚠️ Si vous changez le port, n'oubliez pas de l'autoriser dans UFW !
Port 22

# === SÉCURITÉ D'ACCÈS ===
# Désactiver root login (RECOMMANDÉ)
PermitRootLogin no

# Désactiver l'authentification par mot de passe (après avoir configuré les clés SSH)
PasswordAuthentication no
PubkeyAuthentication yes

# === LIMITES ET TIMEOUTS ===
# Limiter les tentatives de connexion
MaxAuthTries 3

# Timeout en cas d'inactivité (5 minutes)
ClientAliveInterval 300
ClientAliveCountMax 2

# === PROTOCOLE ET FONCTIONNALITÉS ===
# Utiliser uniquement le protocole SSH 2 (plus sécurisé)
Protocol 2

# Désactiver X11 forwarding (si non utilisé)
X11Forwarding no

# === WHITELIST D'UTILISATEURS ===
# Autoriser uniquement certains utilisateurs (RECOMMANDÉ)
AllowUsers dokploy

# Vous pouvez autoriser plusieurs utilisateurs :
# AllowUsers dokploy admin deployer
```

**💡 Conseil sur le port SSH** :

- **Port 22 (défaut)** :
  - ✅ Standard, facile à retenir
  - ✅ Pas besoin de spécifier `-p` dans les commandes SSH
  - ⚠️ Plus ciblé par les scans automatiques
  - 🛡️ Fail2ban suffit généralement pour la protection

- **Port personnalisé (ex: 2222, 2345)** :
  - ✅ Réduit les tentatives d'attaque automatiques (~99%)
  - ✅ "Security through obscurity" comme couche supplémentaire
  - ⚠️ Doit être entre 1024-65535 (éviter les ports réservés)
  - ⚠️ Vous devrez toujours spécifier `-p PORT` dans vos commandes

**Recommandation** : 
- **Gardez le port 22** si vous utilisez Fail2ban + clés SSH (sécurité suffisante)
- **Changez le port** si vous êtes sur un VPS avec beaucoup de trafic malveillant

**Sauvegarder** : `Ctrl+O`, `Enter`, `Ctrl+X`

### 4.4 Redémarrer SSH et tester

```bash
# Tester la configuration avant de redémarrer
sudo sshd -t

# Si OK, redémarrer SSH
sudo systemctl restart sshd

# Vérifier le statut
sudo systemctl status sshd
```

**⚠️ IMPORTANT** : **NE PAS fermer votre session actuelle** ! Ouvrez un **nouveau terminal** et testez la connexion :

```bash
# Dans un NOUVEAU terminal
ssh dokploy@51.178.xx.xx

# Si ça fonctionne, vous pouvez fermer l'ancienne session root
```

**Si connexion échoue** :
1. Retournez dans la session root originale (toujours ouverte)
2. Restaurez la config : `sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config`
3. Redémarrez SSH : `sudo systemctl restart sshd`

---

## 🛡️ Étape 5 : Configuration pare-feu

### 5.1 Installer et configurer UFW

```bash
# UFW est normalement déjà installé sur Ubuntu
# Sinon :
sudo apt install -y ufw

# Vérifier le statut
sudo ufw status
```

### 5.2 Configurer les règles de base

```bash
# Politique par défaut : bloquer tout
sudo ufw default deny incoming
sudo ufw default allow outgoing

# === AUTORISER SSH ===
# Utiliser le port SSH que vous avez configuré
sudo ufw allow 22/tcp comment 'SSH'

# Si vous avez changé le port SSH (ex: 2222) :
# sudo ufw allow 2222/tcp comment 'SSH'

# === AUTORISER HTTP/HTTPS (pour Dokploy et applications web) ===
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# === AUTORISER DOKPLOY (interface web) ===
sudo ufw allow 3000/tcp comment 'Dokploy UI'

# === DOCKER SWARM (optionnel, pour multi-serveurs uniquement) ===
# Décommentez ces lignes si vous utilisez Docker Swarm en cluster :
# sudo ufw allow 2377/tcp comment 'Docker Swarm management'
# sudo ufw allow 7946/tcp comment 'Docker Swarm node communication'
# sudo ufw allow 7946/udp comment 'Docker Swarm node communication'
# sudo ufw allow 4789/udp comment 'Docker overlay network'

# === POSTGRESQL (optionnel, seulement si accès externe requis) ===
# Par défaut, PostgreSQL dans Docker n'est PAS exposé publiquement (RECOMMANDÉ)
# Si vous devez y accéder depuis l'extérieur (déconseillé en production) :
# sudo ufw allow 5432/tcp comment 'PostgreSQL'
# Mieux : Utiliser un tunnel SSH ou VPN pour accéder à PostgreSQL

# === PERSONNALISÉ ===
# Ajoutez d'autres ports selon vos besoins
# sudo ufw allow 8080/tcp comment 'Mon application'
```

**💡 Note sur les ports** :

| Port | Service | Obligatoire | Commentaire |
|------|---------|-------------|-------------|
| 22 (ou custom) | SSH | ✅ | Accès au serveur |
| 80 | HTTP | ✅ | Redirection vers HTTPS |
| 443 | HTTPS | ✅ | Applications web sécurisées |
| 3000 | Dokploy UI | ✅ | Interface de gestion |
| 2377, 7946, 4789 | Docker Swarm | ❌ | Seulement si cluster multi-serveurs |
| 5432 | PostgreSQL | ❌ | À éviter (utiliser tunnel SSH) |

### 5.3 Activer le pare-feu

```bash
# Activer UFW
sudo ufw enable

# Vérifier les règles
sudo ufw status verbose

# Devrait afficher :
# Status: active
# To                         Action      From
# --                         ------      ----
# 22/tcp                     ALLOW       Anywhere
# 80/tcp                     ALLOW       Anywhere
# 443/tcp                    ALLOW       Anywhere
# 3000/tcp                   ALLOW       Anywhere
```

**⚠️ ATTENTION** : Si vous êtes connecté en SSH, assurez-vous d'avoir autorisé le port SSH **AVANT** d'activer UFW !

### 5.4 Règles supplémentaires (optionnelles)

```bash
# Limiter les tentatives de connexion SSH (protection brute-force)
sudo ufw limit 22/tcp

# Autoriser depuis une IP spécifique uniquement (plus sécurisé)
sudo ufw allow from 123.45.67.89 to any port 22

# Bloquer une IP spécifique
sudo ufw deny from 123.45.67.89

# Voir toutes les règles numérotées
sudo ufw status numbered

# Supprimer une règle par numéro
sudo ufw delete 5
```

---

## ⚡ Étape 6 : Optimisations système

### 6.1 Configurer Fail2ban (protection brute-force)

```bash
# Installer Fail2ban
sudo apt install -y fail2ban

# Créer une configuration locale
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Éditer la configuration
sudo nano /etc/fail2ban/jail.local
```

**Configuration recommandée** :

```ini
[DEFAULT]
bantime  = 3600        # Bannir pendant 1h
findtime = 600         # Fenêtre de temps 10 min
maxretry = 3           # 3 tentatives échouées max

[sshd]
enabled = true
port    = 22           # Adapter si vous avez changé le port
logpath = /var/log/auth.log
```

**Sauvegarder** : `Ctrl+O`, `Enter`, `Ctrl+X`

```bash
# Démarrer et activer Fail2ban
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# Vérifier le statut
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

### 6.2 Optimiser les paramètres système

```bash
# Éditer les paramètres kernel
sudo nano /etc/sysctl.conf
```

**Ajouter ces lignes à la fin** :

```bash
# Optimisations réseau Docker
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Optimisations TCP
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 600

# Limites de fichiers ouverts (pour Docker)
fs.file-max = 65535
fs.inotify.max_user_watches = 524288

# Swap (éviter l'utilisation excessive)
vm.swappiness = 10
```

**Appliquer les changements** :

```bash
sudo sysctl -p
```

### 6.3 Augmenter les limites de fichiers

```bash
# Éditer limits.conf
sudo nano /etc/security/limits.conf
```

**Ajouter** :

```
*               soft    nofile          65535
*               hard    nofile          65535
root            soft    nofile          65535
root            hard    nofile          65535
```

### 6.4 Configurer le Swap (si < 4GB RAM)

```bash
# Vérifier le swap existant
free -h
swapon --show

# Si pas de swap et que vous avez moins de 4GB RAM, en créer un
# Taille recommandée :
# - 2GB RAM → Swap 2GB
# - 4GB RAM → Swap 2GB
# - 8GB+ RAM → Swap optionnel (1-2GB)

# Créer un fichier swap de 2GB
sudo fallocate -l 2G /swapfile

# Sécuriser les permissions
sudo chmod 600 /swapfile

# Formater en swap
sudo mkswap /swapfile

# Activer le swap
sudo swapon /swapfile

# Rendre permanent au redémarrage
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Vérifier
free -h
swapon --show
```

**💡 Note sur le Swap** :

- **Pas de swap** : OK si vous avez 8GB+ RAM et monitoring actif
- **2GB swap** : Recommandé pour VPS avec 2-4GB RAM
- **4GB swap** : Si vous avez des pics de charge importants

**⚠️ Swap sur SSD** : Pas de problème, les SSD modernes supportent bien l'écriture.

---

## 🐳 Étape 7 : Préparation Docker

### 7.1 Vérifier les prérequis

```bash
# Vérifier qu'aucune version de Docker n'est installée
docker --version
docker-compose --version

# Si Docker est déjà installé (ancien), le supprimer
sudo apt remove docker docker-engine docker.io containerd runc
```

### 7.2 Nettoyer le système

```bash
# Supprimer les anciens paquets conflictuels
sudo apt remove -y docker docker-engine docker.io containerd runc

# Nettoyer complètement
sudo apt autoremove -y
sudo apt autoclean
```

### 7.3 Créer les répertoires de données

```bash
# Créer les répertoires pour Dokploy
sudo mkdir -p /opt/dokploy
sudo mkdir -p /var/lib/dokploy
sudo mkdir -p /var/log/dokploy

# Permissions
sudo chown -R dokploy:dokploy /opt/dokploy
sudo chown -R dokploy:dokploy /var/lib/dokploy
```

---

## 🚀 Étape 8 : Installation Dokploy

### 8.1 Vérifications pré-installation

```bash
# Checklist finale
echo "=== CHECKLIST PRÉ-INSTALLATION DOKPLOY ==="
echo ""

# 1. Système à jour
echo "1. Système à jour :"
apt list --upgradable 2>/dev/null | grep -v "Listing..." && echo "⚠️ Mises à jour disponibles" || echo "✅ À jour"

# 2. Espace disque
echo ""
echo "2. Espace disque :"
df -h / | tail -1 | awk '{if ($5+0 < 80) print "✅ Espace OK : "$5" utilisé"; else print "⚠️ Disque presque plein : "$5}'

# 3. RAM disponible
echo ""
echo "3. RAM disponible :"
free -h | grep "Mem:" | awk '{if ($2+0 >= 2) print "✅ RAM OK : "$2" total"; else print "⚠️ RAM insuffisante : "$2}'

# 4. DNS configuré
echo ""
echo "4. DNS configuré :"
if nslookup votre-domaine.com > /dev/null 2>&1; then
    echo "✅ DNS résolu"
else
    echo "⚠️ DNS non résolu - Configurez vos enregistrements DNS"
fi

# 5. Ports ouverts
echo ""
echo "5. Ports ouverts (UFW) :"
sudo ufw status | grep -E "80/tcp|443/tcp|3000/tcp" | head -3

# 6. SSH sécurisé
echo ""
echo "6. SSH sécurisé :"
grep "^PermitRootLogin no" /etc/ssh/sshd_config > /dev/null && echo "✅ Root login désactivé" || echo "⚠️ Root login encore actif"
grep "^PasswordAuthentication no" /etc/ssh/sshd_config > /dev/null && echo "✅ Auth par clé activée" || echo "⚠️ Auth par mot de passe encore active"

# 7. Fail2ban actif
echo ""
echo "7. Fail2ban :"
sudo systemctl is-active fail2ban > /dev/null && echo "✅ Actif" || echo "⚠️ Non actif"

echo ""
echo "==================================="
```

### 8.2 Installation de Dokploy

```bash
# Se connecter avec l'utilisateur dokploy (pas root)
su - dokploy

# Installer Dokploy (version officielle)
curl -sSL https://dokploy.com/install.sh | sh
```

**⏱️ Durée d'installation** : 3-5 minutes

**Ce que fait le script** :
1. ✅ Installe Docker et Docker Compose
2. ✅ Configure les groupes utilisateurs
3. ✅ Crée les volumes persistants
4. ✅ Démarre Dokploy
5. ✅ Configure Traefik (reverse proxy)

### 8.3 Suivre l'installation

```bash
# Vérifier les logs en temps réel
sudo journalctl -u dokploy -f

# Ou avec Docker
sudo docker logs -f dokploy
```

### 8.4 Vérifier que Dokploy est démarré

```bash
# Vérifier le conteneur
sudo docker ps | grep dokploy

# Vérifier le port d'écoute
sudo ss -tlnp | grep 3000

# Tester l'accès local
curl -I http://localhost:3000
```

**Réponse attendue** : `HTTP/1.1 200 OK`

---

## ✅ Vérifications finales

### 9.1 Accéder à l'interface Dokploy

```
https://51.178.xx.xx:3000
ou
https://dokploy.votre-domaine.com:3000
```

**Première connexion** :
1. Créer un compte administrateur
2. Email : votre-email@example.com
3. Mot de passe : (fort, 16+ caractères)
4. Confirmer le mot de passe

### 9.2 Configuration SSL pour Dokploy lui-même

Dans l'interface Dokploy :

```
Settings → General → Server URL
→ Entrer : https://dokploy.votre-domaine.com
→ Dokploy configurera automatiquement SSL via Traefik + Let's Encrypt
```

### 9.3 Tests de santé

```bash
# Vérifier Docker
sudo docker --version
sudo docker-compose --version

# Vérifier les services actifs
sudo systemctl status dokploy

# Vérifier les conteneurs
sudo docker ps -a

# Vérifier les volumes
sudo docker volume ls

# Vérifier les réseaux
sudo docker network ls

# Espace disque utilisé par Docker
sudo docker system df
```

### 9.4 Checklist post-installation

- [ ] ✅ Dokploy accessible via https://IP:3000
- [ ] ✅ Compte administrateur créé
- [ ] ✅ SSL configuré pour l'interface Dokploy
- [ ] ✅ Docker fonctionne correctement
- [ ] ✅ Traefik actif (reverse proxy)
- [ ] ✅ Logs accessibles et sans erreurs
- [ ] ✅ Firewall UFW actif avec bonnes règles
- [ ] ✅ Fail2ban protège SSH
- [ ] ✅ SSH sécurisé (clés uniquement, root désactivé)
- [ ] ✅ DNS configuré et résolu

---

## 🐛 Troubleshooting

### Problème : Dokploy ne démarre pas

```bash
# Vérifier les logs d'installation
cat /tmp/dokploy-install.log

# Vérifier Docker
sudo systemctl status docker

# Relancer Docker si nécessaire
sudo systemctl restart docker

# Réinstaller Dokploy (si échec complet)
sudo docker rm -f dokploy
curl -sSL https://dokploy.com/install.sh | sh
```

### Problème : Port 3000 déjà utilisé

```bash
# Identifier le processus
sudo ss -tlnp | grep 3000

# Tuer le processus (remplacer PID)
sudo kill -9 PID

# Ou changer le port de Dokploy
# Éditer docker-compose.yml de Dokploy
sudo nano /opt/dokploy/docker-compose.yml
# Changer 3000:3000 → 3001:3000
```

### Problème : SSL ne fonctionne pas

```bash
# Vérifier que DNS pointe vers votre IP
nslookup dokploy.votre-domaine.com

# Vérifier les logs Traefik
sudo docker logs traefik

# Forcer le renouvellement SSL
sudo docker exec dokploy certbot renew --force-renewal
```

### Problème : Connexion SSH perdue après config

```bash
# Si vous êtes sur le panel OVH, utilisez la console VNC
# Ou via le mode rescue OVH

# Restaurer la config SSH
cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
systemctl restart sshd

# Réactiver l'auth par mot de passe temporairement
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
```

### Problème : Firewall bloque l'accès

```bash
# Désactiver temporairement UFW pour tester
sudo ufw disable

# Si ça fonctionne, le problème vient des règles
sudo ufw enable

# Vérifier et corriger les règles
sudo ufw status numbered
sudo ufw allow 3000/tcp
```

---

## 📚 Ressources complémentaires

- **Documentation Dokploy** : https://docs.dokploy.com
- **Guide OVH VPS** : https://docs.ovh.com/fr/vps/
- **Docker Docs** : https://docs.docker.com/
- **Ubuntu Server Guide** : https://ubuntu.com/server/docs

---

## 🎯 Prochaines étapes

Après l'installation de Dokploy :

1. **Déployer votre premier projet** : [README.md](README.md)
2. **Configurer les variables d'environnement** : [VARIABLES-GUIDE.md](VARIABLES-GUIDE.md)
3. **Configurer les backups automatiques**
4. **Ajouter un monitoring** (Prometheus + Grafana)
5. **Configurer les alertes** (email/Slack)

---

<div align="center">

**🎉 Félicitations ! Votre VPS OVH est prêt pour Dokploy !**

**Questions ?** Ouvrez une [issue sur GitHub](https://github.com/lwilly3/scripts-radioManager/issues)

</div>
