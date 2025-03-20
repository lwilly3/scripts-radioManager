#!/bin/bash

# Ce script configure un serveur Ubuntu 24.10 fraîchement installé pour héberger une API et un flux Icecast.
# Il automatise les étapes tirées de vos historiques shell, incluant mise à jour, installation de logiciels,
# configuration réseau, et déploiement d'une application Python avec FastAPI.

# Instructions pour exécuter le script :
# 1. Créez un fichier nommé 'setup_server.sh' et copiez ce contenu dedans :
#    - Exemple : nano setup_server.sh, puis collez le script et sauvegardez (Ctrl+O, Enter, Ctrl+X).
# 2. Rendez le script exécutable :
#    - Commande : chmod +x setup_server.sh
# 3. Les variables peuvent être définies ici ou via l'environnement (export). Si non définies, des invites interactives apparaîtront.
# 4. Exécutez le script avec sudo :
#    - Commande : sudo bash setup_server.sh
# 5. Suivez les invites pour entrer les informations demandées si nécessaire.
# 6. Vérifiez les services après exécution avec les commandes affichées en fin de script.

# Vérification des privilèges root
# - Objectif : S'assurer que le script a les droits nécessaires pour modifier le système.
# - Pourquoi : Les opérations comme l'installation de paquets ou la création d'utilisateurs nécessitent des privilèges root.
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root ou avec sudo."
   exit 1
fi

# Déclaration des variables avec documentation
# - AUDACE_PASSWORD : Mot de passe pour l'utilisateur système 'audace' qui exécutera l'API.
#   - Valeur par défaut : Vide (invite interactive si non défini).
#   - Utilisation : Définit le mot de passe pour l'utilisateur Linux 'audace'.
AUDACE_PASSWORD=""

# - ICE_CAST_CONFIG_URL : URL du fichier de configuration Icecast à télécharger depuis GitHub.
#   - Valeur par défaut : Lien vers votre fichier personnalisé dans le dépôt scripts-radioManager.
#   - Utilisation : Configure le serveur Icecast avec des paramètres spécifiques (ex. /stream.mp3).
ICE_CAST_CONFIG_URL="https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/config-audaceStream-IceCast.xml"

# - APP_DIR : Répertoire de travail principal pour l'application de l'utilisateur 'audace'.
#   - Valeur par défaut : /home/audace/app
#   - Utilisation : Contient l'environnement virtuel Python et le code source de l'API.
APP_DIR="/home/audace/app"

# - VENV_DIR : Sous-répertoire pour l'environnement virtuel Python.
#   - Valeur par défaut : $APP_DIR/venv
#   - Utilisation : Héberge les dépendances Python isolées pour l'API.
VENV_DIR="$APP_DIR/venv"

# - API_REPO : URL du dépôt Git contenant le code source de l'API FastAPI.
#   - Valeur par défaut : https://github.com/lwilly3/api.audace.git
#   - Utilisation : Cloné dans $APP_DIR/src pour déployer l'API.
API_REPO="https://github.com/lwilly3/api.audace.git"

# - DB_USER : Nom d'utilisateur pour se connecter à la base de données PostgreSQL.
#   - Valeur par défaut : Vide (invite interactive avec 'audace' comme suggestion).
#   - Utilisation : Utilisateur PostgreSQL créé pour gérer la base de l'API.
DB_USER=""

# - DB_PASSWORD : Mot de passe pour l'utilisateur de la base de données PostgreSQL.
#   - Valeur par défaut : Vide (invite interactive obligatoire).
#   - Utilisation : Sécurise l'accès à la base de données.
DB_PASSWORD=""

# - DB_NAME : Nom de la base de données PostgreSQL à créer.
#   - Valeur par défaut : Vide (invite interactive avec 'audace_db' comme suggestion).
#   - Utilisation : Base de données utilisée par l'API pour stocker les données.
DB_NAME=""

# - DB_HOSTNAME : Hôte sur lequel PostgreSQL est exécuté.
#   - Valeur par défaut : localhost (modifiable via invite).
#   - Utilisation : Définit l'emplacement du serveur de base de données (local par défaut).
DB_HOSTNAME="localhost"

# - DB_PORT : Port sur lequel PostgreSQL écoute.
#   - Valeur par défaut : 5432 (port standard de PostgreSQL, modifiable via invite).
#   - Utilisation : Configure la connexion au serveur PostgreSQL.
DB_PORT="5432"

# - ACCESS_TOKEN_EXPIRATION_MINUTE : Durée d'expiration des jetons d'accès JWT (en minutes).
#   - Valeur par défaut : Vide (invite interactive avec '30' comme suggestion).
#   - Utilisation : Contrôle la validité des tokens dans l'API FastAPI pour l'authentification.
ACCESS_TOKEN_EXPIRATION_MINUTE=""

# - ALGORITHM : Algorithme de signature pour les jetons JWT.
#   - Valeur par défaut : Vide (invite interactive avec 'HS256' comme suggestion).
#   - Utilisation : Définit la méthode de signature (ex. HMAC-SHA256) pour sécuriser les tokens.
ALGORITHM=""

# - SECRET_KEY : Clé secrète pour signer les jetons JWT ou autres mécanismes de chiffrement.
#   - Valeur par défaut : Vide (invite interactive obligatoire).
#   - Utilisation : Utilisée par FastAPI pour garantir l'intégrité des tokens JWT.
SECRET_KEY=""

# - ADMIN_EMAIL : Adresse email pour l'enregistrement des certificats SSL via Certbot.
#   - Valeur par défaut : admin@example.com (invite interactive si non modifié).
#   - Utilisation : Requis par Certbot pour les notifications et la gestion des certificats.
ADMIN_EMAIL="admin@example.com"

# Fonction pour gérer les erreurs
# - Objectif : Vérifier si une commande a échoué et arrêter le script avec un message clair.
# - Pourquoi : Permet de détecter et signaler les problèmes immédiatement pour éviter des erreurs en cascade.
check_error() {
    if [ $? -ne 0 ]; then
        echo "Erreur lors de l'exécution de la dernière commande : $1. Arrêt du script."
        exit 1
    fi
}

# Étape 0 : Demande interactive des variables si non définies
# - Objectif : Permettre à l'utilisateur de personnaliser les paramètres clés avant l'exécution.
# - Pourquoi : Offre une flexibilité tout en évitant des valeurs codées en dur non sécurisées.
if [ -z "$AUDACE_PASSWORD" ]; then
    echo "Le mot de passe pour l'utilisateur 'audace' n'est pas défini."
    read -s -p "Entrez le mot de passe pour l'utilisateur 'audace' : " AUDACE_PASSWORD
    echo ""
    [ -z "$AUDACE_PASSWORD" ] && { echo "Erreur : Mot de passe requis."; exit 1; }
fi

if [ -z "$DB_USER" ]; then
    echo "Le nom d'utilisateur de la base de données n'est pas défini."
    read -p "Entrez le nom d'utilisateur de la base de données (par défaut : audace) : " DB_USER
    [ -z "$DB_USER" ] && DB_USER="audace"
fi

if [ -z "$DB_PASSWORD" ]; then
    echo "Le mot de passe de la base de données n'est pas défini."
    read -s -p "Entrez le mot de passe de la base de données : " DB_PASSWORD
    echo ""
    [ -z "$DB_PASSWORD" ] && { echo "Erreur : Mot de passe requis."; exit 1; }
fi

if [ -z "$DB_NAME" ]; then
    echo "Le nom de la base de données n'est pas défini."
    read -p "Entrez le nom de la base de données (par défaut : audace_db) : " DB_NAME
    [ -z "$DB_NAME" ] && DB_NAME="audace_db"
fi

if [ -z "$DB_HOSTNAME" ]; then
    echo "L'hôte de la base de données n'est pas défini."
    read -p "Entrez l'hôte de la base de données (par défaut : localhost) : " DB_HOSTNAME
    [ -z "$DB_HOSTNAME" ] && DB_HOSTNAME="localhost"
fi

if [ -z "$DB_PORT" ]; then
    echo "Le port de la base de données n'est pas défini."
    read -p "Entrez le port de la base de données (par défaut : 5432) : " DB_PORT
    [ -z "$DB_PORT" ] && DB_PORT="5432"
fi

if [ -z "$ACCESS_TOKEN_EXPIRATION_MINUTE" ]; then
    echo "La durée d'expiration du jeton d'accès n'est pas définie."
    read -p "Entrez la durée d'expiration du jeton (en minutes, par défaut : 30) : " ACCESS_TOKEN_EXPIRATION_MINUTE
    [ -z "$ACCESS_TOKEN_EXPIRATION_MINUTE" ] && ACCESS_TOKEN_EXPIRATION_MINUTE="30"
fi

if [ -z "$ALGORITHM" ]; then
    echo "L'algorithme de signature JWT n'est pas défini."
    read -p "Entrez l'algorithme JWT (par défaut : HS256) : " ALGORITHM
    [ -z "$ALGORITHM" ] && ALGORITHM="HS256"
fi

if [ -z "$SECRET_KEY" ]; then
    echo "La clé secrète JWT n'est pas définie."
    read -s -p "Entrez la clé secrète JWT : " SECRET_KEY
    echo ""
    [ -z "$SECRET_KEY" ] && { echo "Erreur : Clé secrète requise."; exit 1; }
fi

if [ -z "$ADMIN_EMAIL" ]; then
    echo "L'email pour Certbot n'est pas défini."
    read -p "Entrez votre email pour Certbot : " ADMIN_EMAIL
    [ -z "$ADMIN_EMAIL" ] && { echo "Erreur : Email requis."; exit 1; }
fi

# Étape 1 : Mise à jour du serveur
# - Objectif : Mettre à jour les paquets système pour garantir compatibilité et sécurité.
# - Pourquoi : Un système obsolète peut causer des échecs d'installation ou des vulnérabilités.
echo "Mise à jour du serveur..."
apt update -y && apt upgrade -y && apt dist-upgrade -y && apt autoremove -y
check_error "Mise à jour du système"

# Étape 2 : Installation et configuration d'Icecast2
# - Objectif : Installer et configurer un serveur de streaming audio Icecast.
# - Pourquoi : Permet de diffuser un flux audio accessible via https://radio.audace.ovh/stream.mp3.
echo "Installation d'Icecast2..."
apt install icecast2 -y
check_error "Installation d'Icecast2"
wget -O /etc/icecast2/icecast.xml "$ICE_CAST_CONFIG_URL"
check_error "Téléchargement du fichier Icecast XML"
systemctl restart icecast2
check_error "Redémarrage d'Icecast2"
systemctl enable icecast2  # Active Icecast au démarrage du serveur

# Étape 3 : Installation et configuration de Nginx
# - Objectif : Installer Nginx comme serveur web/proxy et Certbot pour les certificats SSL.
# - Pourquoi : Nginx sert de reverse proxy pour Icecast et l'API, avec SSL pour sécuriser les connexions.
echo "Installation de Nginx et Certbot..."
apt install nginx certbot python3-certbot-nginx -y
check_error "Installation de Nginx et Certbot"

# - Configuration Nginx pour radio.audace.ovh
# - Reverse proxy vers Icecast (port 8000) avec SSL.
cat <<EOF > /etc/nginx/sites-available/radio.audace.ovh
server {
    server_name radio.audace.ovh;
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_intercept_errors on;
    }
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/radio.audace.ovh/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/radio.audace.ovh/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}
server {
    listen 80;
    server_name radio.audace.ovh;
    return 301 https://\$host\$request_uri;  # Redirige HTTP vers HTTPS
}
EOF

# - Configuration Nginx pour api.radio.audace.ovh
# - Reverse proxy vers l'API (port 8002) avec SSL.
cat <<EOF > /etc/nginx/sites-available/api.radio.audace.ovh
server {
    listen 80;
    server_name api.radio.audace.ovh;
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    server_name api.radio.audace.ovh;
    ssl_certificate /etc/letsencrypt/live/api.radio.audace.ovh/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.radio.audace.ovh/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    location / {
        proxy_pass http://127.0.0.1:8002;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# - Activation des sites Nginx et configuration SSL
ln -s /etc/nginx/sites-available/radio.audace.ovh /etc/nginx/sites-enabled/ 2>/dev/null
ln -s /etc/nginx/sites-available/api.radio.audace.ovh /etc/nginx/sites-enabled/ 2>/dev/null
nginx -t  # Teste la configuration Nginx
check_error "Test de la configuration Nginx"
certbot --nginx -d radio.audace.ovh --non-interactive --agree-tos -m "$ADMIN_EMAIL"
check_error "Certbot pour radio.audace.ovh"
certbot --nginx -d api.radio.audace.ovh --non-interactive --agree-tos -m "$ADMIN_EMAIL"
check_error "Certbot pour api.radio.audace.ovh"
systemctl reload nginx
check_error "Rechargement de Nginx"

# Étape 4 : Installation et configuration de PostgreSQL
# - Objectif : Installer une base de données PostgreSQL pour stocker les données de l'API.
# - Pourquoi : L'API FastAPI a besoin d'une base persistante pour fonctionner.
echo "Installation de PostgreSQL..."
apt install postgresql postgresql-contrib -y
check_error "Installation de PostgreSQL"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || echo "Utilisateur $DB_USER existe déjà"
sudo -u postgres createdb "$DB_NAME" -O "$DB_USER" 2>/dev/null || echo "Base $DB_NAME existe déjà"
check_error "Configuration de PostgreSQL"

# Étape 5 : Préparation de l'environnement virtuel
# - Objectif : Configurer un environnement Python isolé et cloner le code de l'API.
# - Pourquoi : Assure que les dépendances de l'API sont installées sans interférer avec le système.
echo "Préparation de l'environnement virtuel..."
apt install python3-venv python3-pip git -y
check_error "Installation des outils Python"
adduser --disabled-password --gecos "" audace 2>/dev/null || echo "Utilisateur audace existe déjà"
echo "audace:$AUDACE_PASSWORD" | chpasswd
check_error "Définition du mot de passe pour audace"
usermod -aG sudo audace  # Ajoute des privilèges sudo à 'audace'
mkdir -p "$APP_DIR"
chown audace:audace "$APP_DIR"

su - audace -c "
cd $APP_DIR
python3 -m venv $VENV_DIR
source $VENV_DIR/bin/activate
git clone $API_REPO src
cd src
pip install -r requirements.txt
"
check_error "Configuration de l'environnement virtuel"

# - Création du fichier .env
# - Contient les variables pour la connexion à la base de données et la configuration JWT.
cat <<EOF > "$APP_DIR/.env"
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/$DB_NAME
ACCESS_TOKEN_EXPIRATION_MINUTE=$ACCESS_TOKEN_EXPIRATION_MINUTE
ALGORITHM=$ALGORITHM
SECRET_KEY=$SECRET_KEY
EOF
chown audace:audace "$APP_DIR/.env"

# Étape 6 : Configuration de l'API avec Alembic
# - Objectif : Initialiser et appliquer les migrations de la base de données avec Alembic.
# - Pourquoi : Crée les tables nécessaires dans PostgreSQL pour que l'API fonctionne.
echo "Configuration d'Alembic..."
su - audace -c "
cd $APP_DIR/src
source $VENV_DIR/bin/activate
pip install alembic
alembic init alembic || echo 'Alembic déjà initialisé'
sed -i 's|sqlalchemy.url = .*|sqlalchemy.url = postgresql://$DB_USER:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/$DB_NAME|' alembic.ini 2>/dev/null
alembic revision --autogenerate -m 'Initial migration'
alembic upgrade head
"
check_error "Configuration d'Alembic"

# Étape 7 : Lancement de l'API avec Uvicorn et Gunicorn
# - Objectif : Installer les outils pour exécuter l'API en production.
# - Pourquoi : Gunicorn et Uvicorn permettent de gérer les requêtes de manière performante.
echo "Installation de Gunicorn, uvloop et httptools..."
su - audace -c "
cd $APP_DIR/src
source $VENV_DIR/bin/activate
pip install gunicorn uvloop httptools
"
check_error "Installation de Gunicorn, uvloop et httptools"

# Étape 8 : Création et gestion d'un service systemd
# - Objectif : Configurer l'API pour qu'elle démarre automatiquement avec le serveur.
# - Pourquoi : Assure une disponibilité continue sans intervention manuelle.
echo "Création du service systemd pour l'API..."
cat <<EOF > /etc/systemd/system/api.service
[Unit]
Description=API Service
After=network.target

[Service]
User=audace
Group=audace
WorkingDirectory=$APP_DIR/src
EnvironmentFile=$APP_DIR/.env
ExecStart=$VENV_DIR/bin/gunicorn -w 2 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:8002
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start api
systemctl enable api
check_error "Configuration du service systemd"

# Étape 9 : Configuration du pare-feu (UFW)
# - Objectif : Sécuriser le serveur en limitant les ports accessibles.
# - Pourquoi : Protège contre les accès non autorisés tout en permettant les services nécessaires.
echo "Configuration du pare-feu UFW..."
apt install ufw -y
ufw allow http    # Port 80 pour HTTP
ufw allow https   # Port 443 pour HTTPS
ufw allow ssh     # Port 22 pour SSH
ufw allow "$DB_PORT/tcp"  # Port PostgreSQL dynamique
ufw allow 8000/tcp  # Port Icecast
ufw allow 8002/tcp  # Port API
ufw --force enable
check_error "Configuration de UFW"

# Étape 10 : Changement du fuseau horaire
# - Objectif : Définir le fuseau horaire du serveur à Africa/Douala.
# - Pourquoi : Assure que les horodatages (logs, base de données) sont corrects pour votre localisation.
echo "Changement du fuseau horaire à Africa/Douala..."
timedatectl set-timezone Africa/Douala
check_error "Changement du fuseau horaire"

# Messages finaux
# - Objectif : Confirmer la fin de l'exécution et guider l'utilisateur pour la vérification.
# - Pourquoi : Facilite le dépannage et la validation du déploiement.
echo "Configuration terminée avec succès !"
echo "Vérifiez les services :"
echo "  - Icecast2: systemctl status icecast2"
echo "  - Nginx: systemctl status nginx"
echo "  - API: systemctl status api"
echo "Flux Icecast : https://radio.audace.ovh/stream.mp3"
echo "API : https://api.radio.audace.ovh"