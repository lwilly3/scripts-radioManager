#!/bin/bash

# Description :
# Ce script s'exécute au démarrage du serveur pour garantir que le site 'app.radioaudace.com'
# est actif. Il vérifie et démarre Nginx, s'assure que le frontend est construit, et met à jour
# le code depuis Git si nécessaire.

# Variables de configuration :
DOMAIN="app.radioaudace.com"          # Domaine du site web
SITE_DIR="/var/www/app-radioaudace"   # Répertoire où le site est hébergé
GIT_REPO="https://github.com/lwilly3/radioManager-SaaS"  # URL du dépôt Git
BUILD_DIR="dist"                      # Dossier généré par la compilation Vite
LOG_FILE="/var/log/start_radioaudace.log"  # Fichier de log pour ce script

# Fonction : log
# Enregistre un message avec un horodatage dans le fichier de log.
# Paramètre : $1 - Message à enregistrer
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Vérification des privilèges root
# Le script doit être exécuté avec sudo ou en tant que root pour gérer les services.
if [ "$EUID" -ne 0 ]; then
    log "Erreur : Ce script doit être exécuté avec sudo ou en tant que root."
    echo "Erreur : Ce script doit être exécuté avec sudo ou en tant que root."
    exit 1
fi

# Étape 1 : Vérification de l'existence du répertoire du site
# Si le répertoire n'existe pas, le script s'arrête.
if [ ! -d "$SITE_DIR" ]; then
    log "Erreur : Le répertoire $SITE_DIR n’existe pas."
    echo "Erreur : Le répertoire $SITE_DIR n’existe pas."
    exit 1
fi

# Étape 2 : Démarrage de Nginx
# Assure que Nginx est actif et configuré pour démarrer automatiquement.
log "Démarrage de Nginx..."
systemctl enable nginx  # Active Nginx au démarrage du serveur
systemctl start nginx  # Démarre Nginx immédiatement
if [ $? -ne 0 ]; then
    log "Erreur : Échec du démarrage de Nginx."
    echo "Erreur : Échec du démarrage de Nginx."
    exit 1
fi

# Étape 3 : Vérification du dossier de build
# Si le dossier dist n'existe pas, tente de reconstruire le frontend.
cd "$SITE_DIR"
if [ ! -d "$BUILD_DIR" ]; then
    log "Le dossier $BUILD_DIR n'existe pas. Tentative de reconstruction du frontend..."
    echo "Le dossier $BUILD_DIR n'existe pas. Tentative de reconstruction..."
    if [ -f "package.json" ]; then
        npm install
        npm run build
        if [ $? -ne 0 ] || [ ! -d "$BUILD_DIR" ]; then
            log "Erreur : Échec de la reconstruction du frontend."
            echo "Erreur : Échec de la reconstruction du frontend."
            exit 1
        fi
    else
        log "Erreur : Aucun fichier package.json trouvé dans $SITE_DIR."
        echo "Erreur : Aucun fichier package.json trouvé dans $SITE_DIR."
        exit 1
    fi
fi

# Étape 4 : Mise à jour optionnelle depuis Git (commentée par défaut)
# Décommentez cette section si vous voulez une mise à jour automatique au démarrage.
# if [ -d ".git" ]; then
#     log "Mise à jour du dépôt Git depuis $GIT_REPO..."
#     echo "Mise à jour du dépôt Git depuis $GIT_REPO..."
#     git fetch origin
#     git pull origin main
#     if [ $? -ne 0 ]; then
#         log "Erreur lors de la mise à jour du dépôt Git."
#         echo "Erreur lors de la mise à jour du dépôt Git."
#     else
#         npm install
#         npm run build
#         log "Frontend mis à jour et recompilé avec succès."
#         echo "Frontend mis à jour et recompilé avec succès."
#     fi
# fi

# Étape 5 : Vérification finale
# Teste que le site est accessible via une requête curl.
log "Vérification de l'accessibilité du site..."
echo "Vérification de l'accessibilité du site..."
curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" | grep -q "200"
if [ $? -eq 0 ]; then
    log "Le site est actif et accessible à https://$DOMAIN."
    echo "Le site est actif et accessible à https://$DOMAIN."
else
    log "Avertissement : Le site ne semble pas accessible à https://$DOMAIN."
    echo "Avertissement : Le site ne semble pas accessible. Vérifiez les logs Nginx : sudo tail -f /var/log/nginx/error.log"
fi

# Fin
log "Script terminé."
echo "Script terminé."




#############################################################################



############################ RED ME. ########################################


#############################################################################





# Étapes pour l’exécuter au démarrage :
# Sauvegarde du script :
# Enregistrez ce script sous /usr/local/bin/start-radioaudace.sh (ou un autre emplacement de votre choix).
# Rendez-le exécutable :
# bash

# Collapse

# Wrap

# Copy
# chmod +x /usr/local/bin/start-radioaudace.sh
# Ajout au démarrage via systemd :
# Créez un service systemd pour exécuter le script au démarrage :
# bash

# Collapse

# Wrap

# Copy
# sudo nano /etc/systemd/system/start-radioaudace.service
# Ajoutez ce contenu :
# ini

# Collapse

# Wrap

# Copy
# [Unit]
# Description=Démarre le site radioaudace après un reboot
# After=network.target

# [Service]
# ExecStart=/usr/local/bin/start-radioaudace.sh
# Type=oneshot
# RemainAfterExit=yes
# User=root

# [Install]
# WantedBy=multi-user.target
# Activez et testez le service :
# bash

# Collapse

# Wrap

# Copy
# sudo systemctl enable start-radioaudace.service
# sudo systemctl start start-radioaudace.service
# Vérification :
# Redémarrez le serveur (sudo reboot) et vérifiez le log :
# bash

# Collapse

# Wrap

# Copy
# cat /var/log/start_radioaudace.log
# Assurez-vous que Nginx est en marche et que le site est accessible.