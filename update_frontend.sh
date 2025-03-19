#!/bin/bash

# Description :
# Ce script automatise la mise à jour du frontend d'un site web hébergé sur un serveur.
# Il récupère les dernières modifications depuis un dépôt Git, recompilé avec npm/Vite,
# et redémarre Nginx pour appliquer les changements.

# Variables de configuration :
DOMAIN="app.radioaudace.com"          # Domaine du site web
SITE_DIR="/var/www/app-radioaudace"   # Répertoire où le site est hébergé
GIT_REPO="https://github.com/lwilly3/radioManager-SaaS"  # URL du dépôt Git
BUILD_DIR="dist"                      # Dossier généré par la compilation
USER=$(whoami)                        # Nom de l'utilisateur exécutant le script
LOG_FILE="/var/log/update_frontend.log"  # Fichier de log pour enregistrer les événements

# Fonction : log
# Enregistre un message avec un horodatage dans le fichier de log spécifié.
# Paramètre : $1 - Message à enregistrer
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Vérification des privilèges root
# Le script doit être exécuté avec sudo ou en tant que root pour fonctionner correctement.
if [ "$EUID" -ne 0 ]; then
    log "Erreur : Ce script doit être exécuté avec sudo ou en tant que root."
    exit 1
fi

# Vérification de l'existence du répertoire du site
# Si le répertoire n'existe pas, le script s'arrête pour éviter des erreurs.
if [ ! -d "$SITE_DIR" ]; then
    log "Erreur : Le répertoire $SITE_DIR n’existe pas."
    exit 1
fi

# Changement vers le répertoire du site
cd "$SITE_DIR"

# Vérification que le répertoire est un dépôt Git
# Si aucun dossier .git n'est trouvé, le script s'arrête.
if [ ! -d ".git" ]; then
    log "Erreur : $SITE_DIR n’est pas un dépôt Git."
    exit 1
fi

# Mise à jour du dépôt Git
# Récupère les dernières modifications depuis le dépôt distant et met à jour la branche principale.
log "Récupération des dernières modifications depuis $GIT_REPO..."
git fetch origin
git pull origin main
if [ $? -ne 0 ]; then
    log "Erreur lors de la mise à jour du dépôt Git."
    exit 1
fi

# Compilation du frontend
# Installe les dépendances npm et construit le projet avec Vite.
log "Installation des dépendances npm et recompilation avec Vite..."
npm install
npm run build
# Vérifie que le dossier de build a été créé avec succès.
if [ ! -d "$SITE_DIR/$BUILD_DIR" ]; then
    log "Erreur : le dossier $BUILD_DIR n’a pas été créé."
    exit 1
fi

# Redémarrage du serveur Nginx
# Applique les modifications en redémarrant le service Nginx.
log "Redémarrage de Nginx..."
systemctl restart nginx
if [ $? -ne 0 ]; then
    log "Erreur lors du redémarrage de Nginx."
    exit 1
fi

# Confirmation de succès
# Indique que le processus s'est terminé correctement et que le site est accessible.
log "Mise à jour terminée avec succès ! Site accessible à https://$DOMAIN."