# 🚀 Quick Prepare VPS - Guide d'Utilisation

> **Guide complet d'utilisation du script quick-prepare-vps.sh**

[Retour au README principal](../README.md)

## 📋 Navigation

- [Vue d'ensemble](#vue-densemble)
- [Installation](#installation)
- [Que faire après](#que-faire-après-le-script)
- [Dépannage](#dépannage)

## 🎯 Vue d'ensemble

Le script `quick-prepare-vps.sh` a été conçu pour simplifier et automatiser la préparation de votre serveur VPS avant le déploiement des applications RadioManager et API Audace. Il effectue les tâches suivantes :

1. **Mise à jour du système** : Installation des dernières mises à jour de sécurité et des paquets.
2. **Configuration du pare-feu** : Ouverture des ports nécessaires (22, 80, 443) et fermeture des autres.
3. **Installation des outils essentiels** : `git`, `curl`, `wget`, `nano`, `ufw`, etc.
4. **Configuration de la timezone** : Réglage sur `Africa/Douala` (UTC+1) par défaut.
5. **Création d'un utilisateur non-root** : Pour des raisons de sécurité, un nouvel utilisateur est créé pour les opérations quotidiennes.
6. **Configuration de SSH** : Sécurisation de l'accès SSH (changement du port, désactivation de l'authentification par mot de passe, etc.).
7. **Installation de Docker et Docker Compose** : Pour le déploiement des applications dans des conteneurs.
8. **Configuration de Docker** : Ajout de l'utilisateur au groupe Docker, configuration du daemon Docker.
9. **Installation de Certbot** : Pour la gestion des certificats SSL Let's Encrypt.
10. **Configuration de Fail2ban** : Protection contre les tentatives de connexion par force brute.

## ⚡ Installation rapide

### Méthode 1 : Commande unique (Recommandé)

```bash
# Télécharger et exécuter en une ligne
wget -qO- https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/Docker/quick-prepare-vps-for-dockploy/quick-prepare-vps.sh | sudo bash
```

### Méthode 2 : Téléchargement puis exécution (Plus de contrôle)

```bash
# 1. Télécharger le script
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

## 🚀 Que faire après le script

Une fois le script exécuté, voici les étapes recommandées :

1. **Redémarrer le serveur** : Pour appliquer toutes les modifications.
2. **Se connecter avec le nouvel utilisateur** : Utilisez l'utilisateur non-root créé par le script.
3. **Vérifier l'état des services** : Assurez-vous que tous les services nécessaires sont actifs (Docker, SSH, etc.).
4. **Configurer votre nom de domaine** : Pointez votre nom de domaine vers l'adresse IP de votre serveur.
5. **Installer les applications** : Suivez les instructions spécifiques à chaque application (API Audace, RadioManager, etc.).

## 🛠️ Dépannage

En cas de problème, voici quelques pistes de dépannage :

- **Vérifier les logs** : Consultez les fichiers de log pour identifier d'éventuelles erreurs.
- **Vérifier l'état des services** : Assurez-vous que tous les services nécessaires sont en cours d'exécution.
- **Revoir les configurations** : Vérifiez les fichiers de configuration pour détecter d'éventuelles erreurs.
- **Consulter la documentation** : Reportez-vous à la documentation spécifique de chaque application pour des instructions détaillées.

## 📚 Documentation associée

- **Préparation complète** : [PREPARATION.md](PREPARATION.md)
- **État post-installation** : [POST-INSTALL.md](POST-INSTALL.md)
- **Configuration Fail2ban** : [FAIL2BAN-EMAIL.md](FAIL2BAN-EMAIL.md)
- **Variables d'environnement** : [VARIABLES.md](VARIABLES.md)
- **Migration Docker** : [MIGRATION.md](MIGRATION.md)