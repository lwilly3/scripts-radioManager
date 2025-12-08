# 🚀 Quick Prepare VPS for Dokploy

[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20|%2022.04-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Debian](https://img.shields.io/badge/Debian-11%20|%2012-A81D33?logo=debian&logoColor=white)](https://www.debian.org/)
[![Security](https://img.shields.io/badge/Security-Hardened-green.svg)](https://github.com/lwilly3/scripts-radioManager)

> **Script automatique de préparation et sécurisation de VPS pour Dokploy**

## 📋 Vue d'ensemble

Le script `quick-prepare-vps.sh` transforme un VPS fraîchement installé en serveur **sécurisé, optimisé et production-ready** pour Dokploy en 7 minutes.

### Ce que fait le script

- ✅ Mise à jour système complète
- ✅ Installation de 40+ outils essentiels
- ✅ Création utilisateur non-root avec sudo
- ✅ Sécurisation SSH (désactivation root, limitations)
- ✅ Configuration pare-feu UFW
- ✅ Installation Fail2ban (anti-brute-force)
- ✅ Optimisations kernel pour Docker
- ✅ Configuration fuseau horaire (Africa/Douala par défaut)

### Score de sécurité

**Avant** : 2/10 🔴 → **Après** : 8/10 🟢

---

## ⚡ Quick Start

### Installation en une commande

```bash
# Télécharger et exécuter en une ligne
wget -qO- https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/Docker/quick-prepare-vps-for-dockploy/quick-prepare-vps.sh | sudo bash
```

**⚠️ Attention** : Vous serez invité à entrer :
- Changement port SSH ? (répondez `N` pour garder le port 22)
- Mot de passe pour l'utilisateur `dokploy`
- Confirmation pour lancer

---

### Méthode 2 : Téléchargement puis exécution (Plus de contrôle)

```bash
# 1. Télécharger
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/Docker/quick-prepare-vps-for-dockploy/quick-prepare-vps.sh

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
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/Docker/quick-prepare-vps-for-dockploy/quick-prepare-vps.sh
sudo bash quick-prepare-vps.sh
```

**⏱️ Temps total** : 5-7 minutes

---

## 📚 Documentation

### Guides principaux

| Document | Description | Quand l'utiliser |
|----------|-------------|------------------|
| **[USAGE.md](docs/USAGE.md)** | 🌟 Guide d'utilisation détaillé | **Commencez ici** |
| [PREPARATION.md](docs/PREPARATION.md) | Préparation complète VPS OVH | Configuration avancée |
| [POST-INSTALL.md](docs/POST-INSTALL.md) | État du serveur après script | Vérifications |

### Guides spécialisés

| Document | Description | Niveau |
|----------|-------------|--------|
| [FAIL2BAN-EMAIL.md](docs/FAIL2BAN-EMAIL.md) | Notifications email Fail2ban | Intermédiaire |
| [VARIABLES.md](docs/VARIABLES.md) | Variables d'environnement | Avancé |
| [MIGRATION.md](docs/MIGRATION.md) | Migration vers Docker | Expérimenté |

---

## 🎯 Prérequis

### Serveur

- **VPS** : OVH, Hetzner, DigitalOcean, AWS, etc.
- **OS** : Ubuntu 22.04/24.04 LTS ou Debian 11/12
- **RAM** : 2 GB minimum (4 GB recommandé)
- **Disque** : 20 GB minimum (40 GB recommandé)

### Accès

- Connexion SSH active (port 22)
- Privilèges root ou sudo
- Client SSH sur votre machine locale

---

## 🔧 Configuration

### Variables par défaut

```bash
NEW_USER="dokploy"           # Utilisateur créé
SSH_PORT="22"                # Port SSH (standard)
TIMEZONE="Africa/Douala"     # Fuseau horaire (UTC+1)
```

### Personnalisation

```bash
# Modifier avant exécution
export NEW_USER="admin"
export SSH_PORT="2222"
export TIMEZONE="Europe/Paris"
sudo bash quick-prepare-vps.sh
```

**Voir** : [docs/VARIABLES.md](docs/VARIABLES.md) pour toutes les options

---

## 📋 Après l'installation

### Étapes critiques

1. **Configurer les clés SSH** (obligatoire)
2. Tester la connexion SSH
3. Désactiver l'authentification par mot de passe
4. Installer Dokploy
5. Configurer DNS

**Guide complet** : [docs/USAGE.md](docs/USAGE.md#que-faire-après-le-script)

---

## ✅ Vérifications

```bash
# Statut sécurité
sudo ufw status
sudo fail2ban-client status
sudo systemctl status sshd

# Utilisateur
groups dokploy

# Timezone
timedatectl
```

**Checklist complète** : [docs/POST-INSTALL.md](docs/POST-INSTALL.md)

---

## 🆘 Support

### Problèmes courants

- **Connexion SSH perdue** → Utiliser console VNC hébergeur
- **Port 22 bloqué** → `sudo ufw allow 22/tcp`
- **IP bannie Fail2ban** → `sudo fail2ban-client set sshd unbanip IP`

**Guide dépannage** : [docs/USAGE.md#dépannage](docs/USAGE.md#dépannage)

### Obtenir de l'aide

- **Issues GitHub** : [github.com/lwilly3/scripts-radioManager/issues](https://github.com/lwilly3/scripts-radioManager/issues)
- **Discussions** : [github.com/lwilly3/scripts-radioManager/discussions](https://github.com/lwilly3/scripts-radioManager/discussions)

---

## 📁 Structure du projet

```
quick-prepare-vps-for-dockploy/
├── README.md                    # Ce fichier
├── quick-prepare-vps.sh         # Script principal
├── docs/
│   ├── USAGE.md                 # Guide d'utilisation complet
│   ├── PREPARATION.md           # Préparation VPS détaillée
│   ├── POST-INSTALL.md          # État post-installation
│   ├── FAIL2BAN-EMAIL.md        # Configuration email Fail2ban
│   ├── VARIABLES.md             # Guide variables d'env
│   └── MIGRATION.md             # Guide de migration
└── examples/
    └── .env.example             # Template configuration
```

---

## 🎓 Ressources complémentaires

- **Documentation Dokploy** : https://docs.dokploy.com/
- **Guide Ubuntu Server** : https://ubuntu.com/server/docs
- **Fail2ban Docs** : https://fail2ban.readthedocs.io/

---

## 📜 Changelog

### Version 2.0 (Décembre 2024)

- ✅ Réorganisation documentation
- ✅ Amélioration script (validation, logs)
- ✅ Fuseau horaire Africa/Douala par défaut
- ✅ Guide Fail2ban email complet
- ✅ Documentation variables d'environnement

### Version 1.0 (Novembre 2024)

- ✅ Première version du script
- ✅ Documentation de base

---

<div align="center">

**✨ Prêt à sécuriser votre VPS ?**

**[📖 Lire le guide d'utilisation](docs/USAGE.md)** | **[🚀 Télécharger le script](quick-prepare-vps.sh)**

Made with ❤️ for secure deployments

</div>
