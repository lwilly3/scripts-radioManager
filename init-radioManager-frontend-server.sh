#!/bin/bash

# Description :
# Ce script configure un serveur Ubuntu 24.10 pour héberger un site frontend basé sur Vite.
# Il met à jour le système, installe les dépendances, clone un dépôt Git, compile le projet,
# configure Nginx comme serveur web, active un pare-feu et sécurise le site avec un certificat SSL via Certbot.

# Variables personnalisables :
DOMAIN="app.radioaudace.com"          # Domaine du site web
SITE_DIR="/var/www/app-radioaudace"   # Répertoire où le site sera hébergé
GIT_REPO="https://github.com/lwilly3/radioManager-SaaS"  # URL du dépôt Git contenant le projet
BUILD_DIR="dist"                      # Dossier généré par la compilation Vite
USER=$(whoami)                        # Utilisateur actuel exécutant le script
EMAIL="lwilly32@gmail.com"            # Adresse email pour l'enregistrement Certbot

# Vérification des privilèges root
# Le script nécessite des privilèges administratifs pour installer des paquets et configurer des services.
if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté avec sudo ou en tant que root."
    exit 1
fi

# Étape 1 : Mise à jour du système
# Assure que le système est à jour pour éviter des problèmes de compatibilité.
echo "Mise à jour du système Ubuntu 24.10..."
apt update && apt upgrade -y

# Étape 2 : Installation des prérequis
# Installe les outils nécessaires : Node.js, npm, Git, Nginx et Certbot.
echo "Installation de Node.js, npm, Git, Nginx et Certbot..."
apt install -y nodejs npm git nginx certbot python3-certbot-nginx

# Vérification et mise à jour de Node.js
# Vite 5 nécessite Node.js 18 ou supérieur. Si la version est inférieure, installe via nvm.
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
echo "Version de Node.js installée : v$NODE_VERSION"
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "Node.js 18+ est requis pour Vite 5. Installation via nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    # Charge nvm dans la session courante
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 18
    nvm use 18
    # Met à jour le PATH pour utiliser la nouvelle version de Node.js
    export PATH="$NVM_DIR/versions/node/v18.*/bin:$PATH"
fi

# Étape 3 : Configuration du projet frontend avec Vite
# Crée le répertoire du site et ajuste les permissions.
echo "Création du répertoire pour le site..."
mkdir -p "$SITE_DIR"
chown "$USER:$USER" "$SITE_DIR"

# Clonage du dépôt Git
# Si un dépôt est spécifié, clone le projet dans le répertoire cible.
if [ ! -z "$GIT_REPO" ]; then
    echo "Clonage du dépôt Git : $GIT_REPO..."
    git clone "$GIT_REPO" "$SITE_DIR"
    if [ $? -ne 0 ]; then
        echo "Erreur lors du clonage du dépôt. Vérifiez l'URL ou les permissions."
        exit 1
    fi
    cd "$SITE_DIR"
else
    echo "Aucun dépôt Git spécifié. Veuillez transférer vos fichiers manuellement dans $SITE_DIR."
    mkdir -p "$SITE_DIR/$BUILD_DIR"
    exit 1
fi

# Installation des dépendances et compilation
# Vérifie la présence d'un fichier package.json, installe les dépendances et compile avec Vite.
if [ -f "$SITE_DIR/package.json" ]; then
    echo "Installation des dépendances npm et compilation du projet avec Vite..."
    cd "$SITE_DIR"
    npm install
    npm run build
    if [ ! -d "$SITE_DIR/$BUILD_DIR" ]; then
        echo "Erreur : le dossier $BUILD_DIR n'a pas été créé. Vérifiez la configuration de Vite dans vite.config.js."
        exit 1
    fi
else
    echo "Aucun fichier package.json détecté dans $SITE_DIR. Assurez-vous que le dépôt est correct."
    exit 1
fi

# Étape 4 : Configuration de Nginx
# Crée un fichier de configuration Nginx pour servir les fichiers statiques générés par Vite.
echo "Configuration de Nginx..."
NGINX_CONFIG="/etc/nginx/sites-available/app-radioaudace"
cat > "$NGINX_CONFIG" <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    root $SITE_DIR/$BUILD_DIR;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;  # Supporte le routage SPA (Single Page Application) de Vite
    }
}
EOL

# Active le site et redémarre Nginx
# Crée un lien symbolique pour activer le site et teste/redémarre le service.
ln -s "$NGINX_CONFIG" /etc/nginx/sites-enabled/ 2>/dev/null || echo "Lien symbolique déjà existant."
nginx -t && systemctl restart nginx
systemctl enable nginx  # Assure que Nginx démarre automatiquement au reboot

# Étape 5 : Configuration du pare-feu
# Configure ufw pour autoriser SSH et les ports HTTP/HTTPS.
echo "Configuration du pare-feu..."
apt install -y ufw
ufw allow 22/tcp  # Ouvre le port SSH (par défaut : 22)
ufw allow 'Nginx Full'  # Ouvre les ports 80 (HTTP) et 443 (HTTPS)
ufw --force enable  # Active le pare-feu sans confirmation

# Étape 6 : Mise en place de SSL avec Certbot
# Configure un certificat SSL pour sécuriser le site avec HTTPS.
echo "Configuration de SSL avec Certbot..."
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL" --redirect
if [ $? -eq 0 ]; then
    echo "SSL configuré avec succès !"
else
    echo "Échec de la configuration SSL. Vérifiez que le domaine $DOMAIN pointe vers cette IP et exécutez 'sudo certbot --nginx -d $DOMAIN' manuellement."
fi

# Redémarrage final de Nginx
# Applique toutes les modifications, y compris la redirection HTTPS.
systemctl restart nginx

# Message de fin
# Confirme que tout est terminé et fournit une indication pour le dépannage.
echo "Configuration terminée ! Votre site Vite est accessible à https://$DOMAIN."
echo "Vérifiez les logs si nécessaire : sudo tail -f /var/log/nginx/error.log"