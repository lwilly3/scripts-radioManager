# 🚀 Quick Prepare VPS - Guide d'Utilisation

[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20|%2022.04-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Debian](https://img.shields.io/badge/Debian-11%20|%2012-A81D33?logo=debian&logoColor=white)](https://www.debian.org/)
[![Security](https://img.shields.io/badge/Security-Hardened-green.svg)](https://github.com/lwilly3/scripts-radioManager)

> **Script automatique de préparation et sécurisation de VPS pour Dokploy**

## 📋 Table des matières

- [Vue d'ensemble](#-vue-densemble)
- [Ce que fait le script](#-ce-que-fait-le-script)
- [Prérequis](#-prérequis)
- [Installation rapide](#-installation-rapide)
- [Guide d'utilisation détaillé](#-guide-dutilisation-détaillé)
- [Options et personnalisation](#-options-et-personnalisation)
- [Que faire après le script](#-que-faire-après-le-script)
- [Vérifications post-installation](#-vérifications-post-installation)
- [Dépannage](#-dépannage)
- [FAQ](#-faq)

---

## 🎯 Vue d'ensemble

Le script `quick-prepare-vps.sh` est un outil **tout-en-un** pour préparer automatiquement un VPS (Virtual Private Server) fraîchement installé. Il transforme un serveur de base en une **plateforme sécurisée, optimisée et production-ready** pour héberger Dokploy et vos applications.

### Pourquoi utiliser ce script ?

**Avant le script** :
```
VPS basique ❌
├── Utilisateur root uniquement
├── Pas de pare-feu
├── SSH non sécurisé
├── Pas de protection anti-intrusion
├── Système non optimisé
└── Vulnérable aux attaques
```

**Après le script** :
```
Serveur production-ready ✅
├── Utilisateur non-root avec sudo
├── Pare-feu UFW actif
├── SSH durci et sécurisé
├── Fail2ban (protection brute-force)
├── Kernel optimisé pour Docker
└── Score sécurité : 8/10
```

### Temps requis

| Étape | Durée |
|-------|-------|
| Téléchargement du script | 10 secondes |
| Exécution du script | 3-5 minutes |
| Configuration clés SSH | 2 minutes |
| **Total** | **~7 minutes** |

---

## ✨ Ce que fait le script

### Étape par étape

```
📦 Étape 1/7 : Mise à jour système
    ├── apt update && apt upgrade
    ├── Installation derniers patchs sécurité
    └── Nettoyage paquets obsolètes

🔧 Étape 2/7 : Installation outils essentiels
    ├── curl, wget, git, vim, nano
    ├── htop (monitoring)
    ├── net-tools, dnsutils (réseau)
    ├── ufw (pare-feu)
    ├── fail2ban (sécurité)
    └── 40+ paquets indispensables

🌍 Étape 3/7 : Configuration fuseau horaire
    └── Africa/Douala (UTC+1, Cameroun)

👤 Étape 4/7 : Création utilisateur dokploy
    ├── Utilisateur non-root
    ├── Privilèges sudo
    └── Mot de passe sécurisé

🔒 Étape 5/7 : Sécurisation SSH
    ├── Désactivation login root
    ├── Limitation tentatives (3 max)
    ├── Timeout inactivité (5 min)
    └── Backup configuration

🛡️ Étape 6/7 : Configuration pare-feu UFW
    ├── Ports 22, 80, 443, 3000 ouverts
    ├── Politique DENY par défaut
    └── Activation pare-feu

🚨 Étape 7/7 : Installation Fail2ban
    ├── Protection brute-force SSH
    ├── Bannissement automatique (1h)
    └── Configuration jail SSH

⚡ Bonus : Optimisations système
    ├── Paramètres kernel Docker
    ├── Limites fichiers (65535)
    └── Swap si nécessaire
```

### Résultat final

| Composant | État |
|-----------|------|
| **Système** | ✅ Mis à jour |
| **Utilisateurs** | ✅ dokploy créé avec sudo |
| **SSH** | ✅ Sécurisé (root désactivé) |
| **Pare-feu** | ✅ UFW actif |
| **Anti-intrusion** | ✅ Fail2ban actif |
| **Optimisations** | ✅ Kernel Docker-ready |
| **Timezone** | ✅ Africa/Douala (UTC+1) |
| **Répertoires** | ✅ /opt/dokploy, /backup créés |

---

## 📦 Prérequis

### Serveur

- **VPS neuf ou existant** (OVH, Hetzner, DigitalOcean, AWS, etc.)
- **OS supportés** :
  - Ubuntu 24.04 LTS ✅ (Recommandé)
  - Ubuntu 22.04 LTS ✅
  - Ubuntu 20.04 LTS ✅
  - Debian 12 ✅
  - Debian 11 ✅
- **Ressources minimales** :
  - RAM : 2 GB minimum (4 GB recommandé)
  - CPU : 1 vCore minimum (2 vCores recommandé)
  - Disque : 20 GB minimum (40 GB recommandé)
  - Connexion Internet stable

### Accès

- **Connexion SSH** active (port 22)
- **Privilèges root** ou accès `sudo`
- **Mot de passe root** ou clé SSH

### Sur votre machine locale

- **Terminal** :
  - Linux/macOS : Terminal natif
  - Windows : PowerShell, WSL, ou PuTTY
- **Client SSH** installé

### Optionnel mais recommandé

- **Nom de domaine** configuré (pour SSL après Dokploy)
- **Clé SSH** générée sur votre machine locale
- **Sauvegarde** de votre mot de passe root

---

## ⚡ Installation rapide

### Méthode 1 : Commande unique (Recommandé)

```bash
# Télécharger et exécuter en une ligne
wget -qO- https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/Docker/dockploy-deployment/quick-prepare-vps.sh | sudo bash
```

**⚠️ Attention** : Vous serez invité à entrer :
- Changement port SSH ? (répondez `N` pour garder le port 22)
- Mot de passe pour l'utilisateur `dokploy`
- Confirmation pour lancer

---

### Méthode 2 : Téléchargement puis exécution (Plus de contrôle)

```bash
# 1. Télécharger le script
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/Docker/dockploy-deployment/quick-prepare-vps.sh

# 2. Vérifier le contenu (optionnel mais recommandé)
less quick-prepare-vps.sh

# 3. Rendre exécutable
chmod +x quick-prepare-vps.sh

# 4. Exécuter avec sudo
sudo bash quick-prepare-vps.sh
```

---

### Méthode 3 : Avec variables d'environnement prédéfinies

```bash
# Définir les variables avant exécution
export NEW_USER="dokploy"
export TIMEZONE="Africa/Douala"
export SSH_PORT="22"

# Télécharger et exécuter
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/Docker/dockploy-deployment/quick-prepare-vps.sh
sudo bash quick-prepare-vps.sh
```

---

## 📖 Guide d'utilisation détaillé

### Étape 1 : Connexion SSH au serveur

```bash
# Remplacer 51.178.xx.xx par l'IP de votre VPS
ssh root@51.178.xx.xx

# Si vous avez une clé SSH configurée
ssh -i ~/.ssh/ma_cle_ssh root@51.178.xx.xx
```

**Première connexion** : Vous devrez accepter le fingerprint du serveur (tapez `yes`).

---

### Étape 2 : Téléchargement du script

```bash
# Depuis votre VPS (connecté en SSH)
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/Docker/dockploy-deployment/quick-prepare-vps.sh

# Vérifier que le fichier est téléchargé
ls -lh quick-prepare-vps.sh
# Output attendu : -rw-r--r-- 1 root root ~15K Dec 20 14:30 quick-prepare-vps.sh
```

---

### Étape 3 : Exécution du script

```bash
# Rendre le script exécutable
chmod +x quick-prepare-vps.sh

# Lancer avec sudo (ou directement en root)
sudo bash quick-prepare-vps.sh
```

**Ce qui se passe** :

1. **Vérification privilèges** : Le script vérifie qu'il est exécuté en root
2. **Affichage configuration** : Résumé des paramètres par défaut
3. **Question port SSH** : Vous pouvez garder le port 22 ou le changer

```
🔧 Voulez-vous changer le port SSH par défaut (22) ? [y/N]
```

**Recommandation** : Appuyez sur `N` ou `Entrée` pour garder le port 22 (plus simple pour débuter).

4. **Résumé configuration** :

```
📋 Résumé de la configuration :
   - Utilisateur : dokploy
   - Port SSH : 22
   - Fuseau horaire : Africa/Douala (Douala, Cameroun)

Ce script va :
  ✅ Mettre à jour le système
  ✅ Installer les outils essentiels
  ✅ Créer l'utilisateur 'dokploy' avec privilèges sudo
  ✅ Sécuriser SSH (désactiver root, limiter tentatives)
  ✅ Configurer UFW (ports 22, 80, 443, 3000)
  ✅ Installer et configurer Fail2ban
  ✅ Optimiser les paramètres système pour Docker

❓ Continuer avec cette configuration ? [y/N]
```

**Tapez `y` puis `Entrée`** pour confirmer.

5. **Exécution automatique** : Le script s'exécute (3-5 minutes)

---

### Étape 4 : Définir les mots de passe

**À un moment, le script demandera** :

```
🔐 Définition du mot de passe pour 'dokploy' :
   (Utilisez un mot de passe fort : min 16 caractères, lettres+chiffres+symboles)
New password:
```

**Consignes pour un mot de passe fort** :
- ✅ Minimum 16 caractères
- ✅ Lettres majuscules et minuscules
- ✅ Chiffres
- ✅ Symboles (@, #, !, $, %, etc.)

**Exemple** : `K8z!mP2@vL9$nQ5#xR7`

**💡 Conseil** : Utilisez un gestionnaire de mots de passe (Bitwarden, 1Password, KeePass).

**Vous devrez taper le mot de passe 2 fois** :
1. Première saisie
2. Confirmation

---

### Étape 5 : Attendre la fin de l'exécution

Le script affiche sa progression :

```
📦 Étape 1/7 : Mise à jour du système...
✅ Système mis à jour

🔧 Étape 2/7 : Installation des outils essentiels...
✅ Outils essentiels installés

🌍 Étape 3/7 : Configuration fuseau horaire...
✅ Fuseau horaire défini : Africa/Douala

👤 Étape 4/7 : Configuration de l'utilisateur 'dokploy'...
✅ Utilisateur 'dokploy' créé avec privilèges sudo

🔒 Étape 5/7 : Sécurisation SSH...
✅ Configuration SSH valide

⚠️ IMPORTANT - SSH MODIFIÉ MAIS PAS ENCORE REDÉMARRÉ
   [Instructions affichées...]

🛡️ Étape 6/7 : Configuration du pare-feu UFW...
✅ Pare-feu UFW configuré et activé

🚨 Étape 7/7 : Configuration Fail2ban...
✅ Fail2ban activé et configuré

⚡ Étape bonus : Optimisations système pour Docker...
✅ Paramètres kernel optimisés pour Docker

📁 Création des répertoires Dokploy...
✅ Répertoires créés
```

---

### Étape 6 : Rapport final

À la fin, le script affiche un **rapport complet** :

```
==========================================
✅ PRÉPARATION TERMINÉE AVEC SUCCÈS !
==========================================

📊 INFORMATIONS SYSTÈME :
   - Utilisateur créé : dokploy
   - Port SSH : 22
   - Fuseau horaire : Africa/Douala
   - IP publique : 51.178.xx.xx
   - Distribution : Ubuntu 24.04.1 LTS
   - Kernel : 6.8.0-49-generic

🔒 SÉCURITÉ CONFIGURÉE :
   ✅ Root login désactivé
   ✅ Pare-feu UFW actif
   ✅ Fail2ban protège SSH
   ✅ Limites de tentatives SSH : 3
   ✅ Ports ouverts : 22, 80, 443, 3000

📋 PROCHAINES ÉTAPES CRITIQUES :

1. 🔑 CONFIGURER L'AUTHENTIFICATION PAR CLÉ SSH
   Sur votre machine locale, exécutez :
   ---
   ssh-keygen -t ed25519 -C "votre-email@example.com"
   ssh-copy-id dokploy@51.178.xx.xx
   ---

2. 🧪 TESTER LA CONNEXION SSH (NOUVEAU TERMINAL !)
   ssh dokploy@51.178.xx.xx
   ⚠️ NE FERMEZ PAS cette session avant d'avoir testé !

3. 🔒 DÉSACTIVER L'AUTHENTIFICATION PAR MOT DE PASSE
   [Instructions...]

4. 🚀 INSTALLER DOKPLOY
   En tant qu'utilisateur dokploy :
   curl -sSL https://dokploy.com/install.sh | sh

5. 🌐 CONFIGURER LES DNS
   Pointer vos domaines vers : 51.178.xx.xx

6. 🔍 ACCÉDER À DOKPLOY
   Une fois installé, accédez à :
   https://51.178.xx.xx:3000

🛠️ COMMANDES UTILES :
   sudo ufw status verbose          # État du pare-feu
   sudo fail2ban-client status sshd # Bannissements SSH
   sudo systemctl status sshd       # État du service SSH
   df -h                            # Espace disque
   free -h                          # Mémoire disponible

⚠️ RAPPEL IMPORTANT :
   - Ne redémarrez SSH qu'APRÈS avoir testé les clés SSH !
   - Gardez cette session ouverte en backup de secours

🎉 Votre VPS est maintenant prêt pour Dokploy !
==========================================
```

**⚠️ IMPORTANT** : **NE PAS FERMER** cette session SSH avant d'avoir configuré et testé les clés SSH !

---

## 🎛️ Options et personnalisation

### Variables d'environnement disponibles

| Variable | Valeur par défaut | Description | Exemple |
|----------|-------------------|-------------|---------|
| `NEW_USER` | `dokploy` | Nom de l'utilisateur à créer | `NEW_USER=admin` |
| `SSH_PORT` | `22` | Port SSH (22 recommandé) | `SSH_PORT=2222` |
| `TIMEZONE` | `Africa/Douala` | Fuseau horaire du serveur | `TIMEZONE=Europe/Paris` |

### Personnalisation avant exécution

```bash
# Exemple 1 : Changer le nom d'utilisateur
export NEW_USER="admin"
sudo bash quick-prepare-vps.sh

# Exemple 2 : Utiliser un port SSH personnalisé
export SSH_PORT="2222"
sudo bash quick-prepare-vps.sh

# Exemple 3 : Changer le fuseau horaire
export TIMEZONE="Europe/Paris"
sudo bash quick-prepare-vps.sh

# Exemple 4 : Tout personnaliser
export NEW_USER="admin"
export SSH_PORT="2222"
export TIMEZONE="Europe/Paris"
sudo bash quick-prepare-vps.sh
```

### Fuseaux horaires disponibles

```bash
# Lister tous les fuseaux horaires
timedatectl list-timezones

# Fuseaux horaires africains courants
Africa/Douala       # Cameroun (UTC+1) - PAR DÉFAUT
Africa/Lagos        # Nigeria (UTC+1)
Africa/Kinshasa     # RD Congo (UTC+1)
Africa/Abidjan      # Côte d'Ivoire (UTC)
Africa/Dakar        # Sénégal (UTC)
Africa/Cairo        # Égypte (UTC+2)
Africa/Johannesburg # Afrique du Sud (UTC+2)

# Autres
Europe/Paris        # France (UTC+1)
America/New_York    # États-Unis Est (UTC-5)
Asia/Tokyo          # Japon (UTC+9)
```

---

## 🎯 Que faire après le script

### 1. Configurer les clés SSH (OBLIGATOIRE)

**Sur votre machine locale** (pas sur le VPS) :

```bash
# Générer une paire de clés SSH (si vous n'en avez pas)
ssh-keygen -t ed25519 -C "votre-email@example.com"

# Appuyez sur Entrée pour accepter l'emplacement par défaut
# Optionnel : Définir une passphrase pour plus de sécurité

# Copier la clé publique vers le VPS
ssh-copy-id dokploy@51.178.xx.xx

# Entrez le mot de passe dokploy une dernière fois
```

**Résultat** : Votre clé publique est ajoutée dans `/home/dokploy/.ssh/authorized_keys`

---

### 2. Tester la connexion par clé SSH

**Dans un NOUVEAU terminal** (gardez l'ancien ouvert) :

```bash
# Tester la connexion
ssh dokploy@51.178.xx.xx

# Si ça fonctionne sans demander de mot de passe : ✅ Parfait !
# Si ça demande encore le mot de passe : ❌ Vérifier la clé
```

**Vérifications si ça ne fonctionne pas** :

```bash
# Sur le VPS, vérifier que la clé est bien présente
cat ~/.ssh/authorized_keys

# Vérifier les permissions
ls -la ~/.ssh/
# Attendu :
# drwx------ 2 dokploy dokploy  4096 Dec 20 14:30 .ssh
# -rw------- 1 dokploy dokploy   400 Dec 20 14:30 authorized_keys

# Si les permissions sont incorrectes
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

---

### 3. Désactiver l'authentification par mot de passe

**Une fois la connexion par clé fonctionnelle** :

```bash
# Sur le VPS (connecté avec dokploy)
sudo nano /etc/ssh/sshd_config

# Modifier cette ligne :
PasswordAuthentication no

# Sauvegarder : Ctrl+O, Entrée, Ctrl+X

# Redémarrer SSH
sudo systemctl restart sshd
```

**Vérifier** :

```bash
# Depuis un nouveau terminal (sans clé SSH)
ssh utilisateur-inexistant@51.178.xx.xx
# Devrait afficher : Permission denied (publickey)
# C'est normal et souhaité !
```

---

### 4. Installer Dokploy

```bash
# Sur le VPS (connecté avec dokploy)
curl -sSL https://dokploy.com/install.sh | sh

# Attendre la fin de l'installation (3-5 minutes)
```

**Accéder à l'interface** :

```
https://51.178.xx.xx:3000
ou
https://votre-domaine.com:3000
```

---

### 5. Configurer DNS (si vous avez un domaine)

**Dans votre interface d'hébergement de domaine (ex: OVH, Cloudflare)** :

```
Type   Nom        Valeur           TTL
A      @          51.178.xx.xx     300
A      dokploy    51.178.xx.xx     300
A      app        51.178.xx.xx     300
A      api        51.178.xx.xx     300
A      *          51.178.xx.xx     300  (optionnel, wildcard)
```

**Vérifier la propagation DNS** :

```bash
# Sur votre machine locale
nslookup dokploy.votre-domaine.com

# Devrait retourner : 51.178.xx.xx
```

---

## ✅ Vérifications post-installation

### Checklist de sécurité

```bash
# 1. Vérifier UFW
sudo ufw status verbose
# Attendu : Status: active

# 2. Vérifier Fail2ban
sudo fail2ban-client status
# Attendu : Number of jail: 1, Jail list: sshd

# 3. Vérifier SSH
sudo systemctl status sshd
# Attendu : active (running)

# 4. Vérifier que root ne peut plus se connecter
grep "^PermitRootLogin" /etc/ssh/sshd_config
# Attendu : PermitRootLogin no

# 5. Vérifier les ports ouverts
sudo ss -tlnp | grep LISTEN
# Attendu : 22 (SSH), autres fermés par défaut

# 6. Vérifier l'utilisateur dokploy
groups dokploy
# Attendu : dokploy : dokploy sudo

# 7. Vérifier le fuseau horaire
timedatectl | grep "Time zone"
# Attendu : Africa/Douala (WAT, +0100)

# 8. Vérifier l'espace disque
df -h /
# Vérifier qu'il reste au moins 50% libre

# 9. Vérifier la RAM
free -h
# Vérifier qu'il y a au moins 1GB libre

# 10. Vérifier les backups SSH
ls -la /etc/ssh/sshd_config.backup.*
# Attendu : fichier(s) de backup présent(s)
```

---

## 🐛 Dépannage

### Problème : Je n'arrive plus à me connecter en SSH

**Cause** : SSH redémarré avant configuration des clés

**Solution** :
1. **Utilisez la console VNC** de votre hébergeur (OVH, Hetzner, etc.)
2. Connectez-vous en tant que `dokploy` (avec le mot de passe défini)
3. Restaurez la config SSH :
```bash
sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
sudo systemctl restart sshd
```

---

### Problème : Port 22 bloqué

```bash
# Vérifier UFW
sudo ufw status
# Si le port 22 n'est pas autorisé :
sudo ufw allow 22/tcp
sudo ufw reload
```

---

### Problème : Fail2ban a banni mon IP

```bash
# Vérifier les IP bannies
sudo fail2ban-client status sshd

# Débannir votre IP
sudo fail2ban-client set sshd unbanip VOTRE_IP
```

---

### Problème : Script s'arrête avec une erreur

**Erreur courante** : "Package install failed"

```bash
# Vérifier la connexion Internet
ping -c 4 google.com

# Réessayer
sudo bash quick-prepare-vps.sh
```

---

### Problème : L'utilisateur dokploy n'a pas les droits sudo

```bash
# Ajouter manuellement au groupe sudo
sudo usermod -aG sudo dokploy

# Vérifier
groups dokploy
```

---

## ❓ FAQ

### Q: Puis-je exécuter le script plusieurs fois ?

**R** : Oui, le script est **idempotent**. Il détecte ce qui est déjà configuré et ne le refait pas.

---

### Q: Est-ce que le script supprime des données existantes ?

**R** : Non. Le script :
- ✅ Crée des fichiers de backup (SSH config)
- ✅ Ne supprime aucun utilisateur existant
- ✅ Ne touche pas aux données utilisateur
- ✅ Ajoute seulement des configurations

---

### Q: Que faire si je perds l'accès SSH ?

**R** : Utilisez la **console VNC** de votre hébergeur :
1. OVH : Manager → VPS → KVM
2. Hetzner : Robot Panel → Console
3. DigitalOcean : Droplet → Access → Console

---

### Q: Puis-je changer le mot de passe dokploy après ?

**R** : Oui :
```bash
sudo passwd dokploy
```

---

### Q: Comment désinstaller Fail2ban si besoin ?

**R** :
```bash
sudo systemctl stop fail2ban
sudo apt remove fail2ban
```

---

### Q: Le script fonctionne-t-il sur CentOS / Rocky Linux ?

**R** : Non, actuellement supporté uniquement sur **Ubuntu** et **Debian**. Support prévu en version 2.1.

---

### Q: Combien d'espace disque le script utilise-t-il ?

**R** : Environ **500 MB** pour :
- Paquets système
- Outils installés
- Mises à jour

---

### Q: Puis-je utiliser un autre nom que "dokploy" ?

**R** : Oui :
```bash
export NEW_USER="admin"
sudo bash quick-prepare-vps.sh
```

---

### Q: Comment voir les logs du script ?

**R** : Le script affiche tout en temps réel. Pour garder une trace :
```bash
sudo bash quick-prepare-vps.sh 2>&1 | tee installation.log
```

---

## 📚 Ressources complémentaires

### Documentation associée

- **État du serveur après préparation** : [POST-INSTALLATION-STATE.md](POST-INSTALLATION-STATE.md)
- **Guide complet de préparation VPS** : [PREPARATION-VPS-OVH.md](PREPARATION-VPS-OVH.md)
- **Configuration Fail2ban emails** : [FAIL2BAN-EMAIL-NOTIFICATIONS.md](FAIL2BAN-EMAIL-NOTIFICATIONS.md)
- **Variables d'environnement** : [VARIABLES-GUIDE.md](VARIABLES-GUIDE.md)
- **Guide Dokploy** : [README.md](README.md)

### Support

- **Issues GitHub** : [github.com/lwilly3/scripts-radioManager/issues](https://github.com/lwilly3/scripts-radioManager/issues)
- **Discussions** : [github.com/lwilly3/scripts-radioManager/discussions](https://github.com/lwilly3/scripts-radioManager/discussions)

---

## 🎓 Pour aller plus loin

### Après l'installation de Dokploy

1. **Déployer votre première application** : Suivre le [guide Dokploy](README.md)
2. **Configurer les notifications Fail2ban** : [FAIL2BAN-EMAIL-NOTIFICATIONS.md](FAIL2BAN-EMAIL-NOTIFICATIONS.md)
3. **Ajouter du monitoring** : Prometheus + Grafana via Dokploy
4. **Configurer des backups automatiques** : Cron + S3 ou Backblaze

---

<div align="center">

**✅ Félicitations ! Votre VPS est maintenant sécurisé et prêt pour Dokploy !**

**Questions ?** Ouvrez une [issue sur GitHub](https://github.com/lwilly3/scripts-radioManager/issues)

Made with ❤️ for secure deployments

</div>
