#!/bin/bash

# Ce script configure un serveur Ubuntu 24.10 fraîchement installé pour héberger une API et un flux Icecast.
# Il automatise les étapes tirées de vos historiques shell, incluant mise à jour, installation de logiciels,
# configuration réseau, et déploiement d'une application Python.

# Instructions pour exécuter le script :
# 1. Créez un fichier nommé 'setup_server.sh' et copiez ce contenu dedans :
#    - Exemple : nano setup_server.sh, puis collez le script et sauvegardez (Ctrl+O, Enter, Ctrl+X).
# 2. Rendez le script exécutable :
#    - Commande : chmod +x setup_server.sh
# 3. Éditez les variables ci-dessous si nécessaire :
#    - AUDACE_PASSWORD : Mot de passe pour l'utilisateur 'audace' (laissez vide pour une invite interactive).
#    - DB_PASSWORD : Mot de passe pour PostgreSQL.
#    - ADMIN_EMAIL : Votre email pour Certbot.
# 4. Exécutez le script avec sudo :
#    - Commande : sudo bash setup_server.sh
# 5. Suivez les invites si un mot de passe est requis.
# 6. Vérifiez les services après exécution avec les commandes affichées en fin de script.

# Vérification des privilèges root
# - Vérifie si l'utilisateur a les droits root (EUID = 0). Sinon, arrête le script avec un message d'erreur.
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root ou avec sudo."
   exit 1
fi

# Déclaration des variables
# - AUDACE_PASSWORD : Mot de passe pour l'utilisateur 'audace'. Laissez vide pour une invite interactive.
# - ICE_CAST_CONFIG_URL : URL GitHub pour télécharger le fichier de configuration Icecast.
# - APP_DIR : Répertoire de travail principal pour l'application de l'utilisateur 'audace'.
# - VENV_DIR : Sous-répertoire pour l'environnement virtuel Python.
# - API_REPO : URL du dépôt Git contenant l'API.
# - DB_USER et DB_PASSWORD : Identifiants pour PostgreSQL.
# - ADMIN_EMAIL : Email utilisé pour les certificats SSL via Certbot.
AUDACE_PASSWORD=""  # Laissez vide pour demander à l'utilisateur pendant l'exécution
ICE_CAST_CONFIG_URL="https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/config-audaceStream-IceCast.xml"
APP_DIR="/home/audace/app"
VENV_DIR="$APP_DIR/venv"
API_REPO="https://github.com/lwilly3/api.audace.git"
DB_USER="audace"
DB_PASSWORD="VOTRE_MOT_DE_PASSE_SECURISÉ"  # À remplacer par un mot de passe sécurisé avant exécution
ADMIN_EMAIL="admin@example.com"  # À remplacer par votre adresse email réelle

# Fonction pour gérer les erreurs
# - Vérifie le code de retour de la dernière commande ($?).
# - Si différent de 0 (erreur), affiche un message avec le contexte et arrête le script.
check_error() {
    if [ $? -ne 0 ]; then
        echo "Erreur lors de l'exécution de la dernière commande : $1. Arrêt du script."
        exit 1
    fi
}

# Vérification et demande du mot de passe pour audace si non défini
# - Si AUDACE_PASSWORD est vide ou non défini, demande à l'utilisateur de le saisir.
if [ -z "$AUDACE_PASSWORD" ]; then
    echo "Le mot de passe pour l'utilisateur 'audace' n'est pas défini."
    read -s -p "Entrez le mot de passe pour l'utilisateur 'audace' : " AUDACE_PASSWORD
    echo ""  # Nouvelle ligne après l'entrée
    if [ -z "$AUDACE_PASSWORD" ]; then
        echo "Erreur : Aucun mot de passe fourni. Arrêt du script."
        exit 1
    fi
fi

# Message initial pour indiquer le début du processus
echo "Démarrage de la configuration du serveur Ubuntu 24.10..."

# 1. Mise à jour du serveur
# - Met à jour les listes de paquets, installe les mises à jour disponibles, et nettoie les paquets obsolètes.
echo "Mise à jour du serveur..."
apt update -y && apt upgrade -y && apt dist-upgrade -y && apt autoremove -y
check_error "Mise à jour du système"

# 2. Installation et configuration d'Icecast2
# - Installe Icecast2, un serveur de streaming audio.
echo "Installation d'Icecast2..."
apt install icecast2 -y
check_error "Installation d'Icecast2"

# - Télécharge le fichier de configuration personnalisé depuis GitHub et le place dans /etc/icecast2/.
# - Redémarre Icecast pour appliquer la nouvelle configuration et l'active au démarrage.
echo "Récupération de la configuration Icecast depuis GitHub..."
wget -O /etc/icecast2/icecast.xml "$ICE_CAST_CONFIG_URL"
check_error "Téléchargement du fichier Icecast XML"
systemctl restart icecast2
check_error "Redémarrage d'Icecast2"
systemctl enable icecast2

# 3. Installation et configuration de Nginx
# - Installe Nginx (serveur web/proxy) et Certbot (pour les certificats SSL).
echo "Installation de Nginx et Certbot..."
apt install nginx certbot python3-certbot-nginx -y
check_error "Installation de Nginx et Certbot"

# - Crée un fichier de configuration Nginx pour radio.audace.ovh.
# - Configure un reverse proxy vers Icecast (port 8000) avec SSL sur le port 443.
# - Redirige le trafic HTTP (port 80) vers HTTPS.
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
    return 301 https://\$host\$request_uri;
}
EOF

# - Crée un fichier de configuration Nginx pour api.radio.audace.ovh.
# - Configure un reverse proxy vers l'API (port 8002) avec SSL sur le port 443.
# - Redirige également le trafic HTTP vers HTTPS.
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

# - Active les deux sites en créant des liens symboliques dans sites-enabled.
# - Teste la configuration Nginx pour s'assurer qu'elle est valide.
ln -s /etc/nginx/sites-available/radio.audace.ovh /etc/nginx/sites-enabled/ 2>/dev/null
ln -s /etc/nginx/sites-available/api.radio.audace.ovh /etc/nginx/sites-enabled/ 2>/dev/null
nginx -t
check_error "Test de la configuration Nginx"

# - Utilise Certbot pour obtenir et installer des certificats SSL pour les deux domaines.
# - Les options --non-interactive et --agree-tos automatisent le processus.
echo "Configuration des certificats SSL avec Certbot..."
certbot --nginx -d radio.audace.ovh --non-interactive --agree-tos -m "$ADMIN_EMAIL"
check_error "Certbot pour radio.audace.ovh"
certbot --nginx -d api.radio.audace.ovh --non-interactive --agree-tos -m "$ADMIN_EMAIL"
check_error "Certbot pour api.radio.audace.ovh"
systemctl reload nginx
check_error "Rechargement de Nginx"

# 4. Installation et configuration de PostgreSQL
# - Installe PostgreSQL et ses extensions contribuées.
echo "Installation de PostgreSQL..."
apt install postgresql postgresql-contrib -y
check_error "Installation de PostgreSQL"

# - Crée un utilisateur PostgreSQL et une base de données pour l'API.
# - Ignore les erreurs si l'utilisateur ou la base existe déjà (2>/dev/null).
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || echo "Utilisateur $DB_USER existe déjà"
sudo -u postgres createdb audace_db -O $DB_USER 2>/dev/null || echo "Base audace_db existe déjà"
check_error "Configuration de PostgreSQL"

# 5. Préparation de l'environnement virtuel
# - Installe les outils nécessaires pour Python (venv, pip, git).
echo "Préparation de l'environnement virtuel..."
apt install python3-venv python3-pip git -y
check_error "Installation des outils Python"

# - Crée un utilisateur 'audace' avec le mot de passe défini et lui donne des privilèges sudo.
# - Crée le répertoire de l'application et en donne la propriété à 'audace'.
adduser --disabled-password --gecos "" audace 2>/dev/null || echo "Utilisateur audace existe déjà"
echo "audace:$AUDACE_PASSWORD" | chpasswd  # Définit le mot de passe pour audace
check_error "Définition du mot de passe pour audace"
usermod -aG sudo audace
mkdir -p $APP_DIR
chown audace:audace $APP_DIR

# - Exécute des commandes en tant qu'utilisateur 'audace' pour configurer l'environnement virtuel.
# - Clone le dépôt Git de l'API et installe les dépendances Python.
su - audace -c "
cd $APP_DIR
python3 -m venv $VENV_DIR
source $VENV_DIR/bin/activate
git clone $API_REPO src
cd src
pip install -r requirements.txt
"
check_error "Configuration de l'environnement virtuel"

# - Crée un fichier .env avec l'URL de la base de données pour l'API.
cat <<EOF > $APP_DIR/.env
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost/audace_db
EOF
chown audace:audace $APP_DIR/.env

# 6. Configuration de l'API avec Alembic
# - Initialise Alembic pour gérer les migrations de la base de données.
# - Crée une migration initiale et l'applique.
echo "Configuration d'Alembic..."
su - audace -c "
cd $APP_DIR/src
source $VENV_DIR/bin/activate
pip install alembic
alembic init alembic || echo 'Alembic déjà initialisé'
sed -i 's|sqlalchemy.url = .*|sqlalchemy.url = postgresql://$DB_USER:$DB_PASSWORD@localhost/audace_db|' alembic.ini 2>/dev/null
alembic revision --autogenerate -m 'Initial migration'
alembic upgrade head
"
check_error "Configuration d'Alembic"

# 7. Lancement de l'API avec Uvicorn et Gunicorn
# - Installe Gunicorn, un serveur WSGI pour exécuter l'API en production.
# - Installe uvloop pour améliorer les performances des tâches asynchrones avec Uvicorn.
# - Installe httptools pour optimiser le parsing des requêtes HTTP.
echo "Installation de Gunicorn, uvloop et httptools..."
su - audace -c "
cd $APP_DIR/src
source $VENV_DIR/bin/activate
pip install gunicorn uvloop httptools
"
check_error "Installation de Gunicorn, uvloop et httptools"

# 8. Création et gestion d'un service systemd
# - Crée un fichier de service systemd pour lancer by l'API automatiquement au démarrage.
# - Utilise Gunicorn avec 2 workers pour gérer les requêtes.
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

# - Recharge les services, démarre l'API et l'active au démarrage.
systemctl daemon-reload
systemctl start api
systemctl enable api
check_error "Configuration du service systemd"

# 9. Configuration du pare-feu (UFW)
# - Installe et configure le pare-feu UFW pour sécuriser les ports nécessaires.
echo "Configuration du pare-feu UFW..."
apt install ufw -y
ufw allow http    # Port 80 pour HTTP
ufw allow https   # Port 443 pour HTTPS
ufw allow ssh     # Port 22 pour SSH
ufw allow 5432/tcp  # Port PostgreSQL
ufw allow 8000/tcp  # Port Icecast
ufw allow 8002/tcp  # Port API
ufw --force enable  # Active le pare-feu sans demander de confirmation
check_error "Configuration de UFW"

# 10. Changement du fuseau horaire
# - Définit le fuseau horaire du serveur à Africa/Douala.
echo "Changement du fuseau horaire à Africa/Douala..."
timedatectl set-timezone Africa/Douala
check_error "Changement du fuseau horaire"

# Messages finaux
# - Indique que la configuration est terminée et donne des instructions pour vérifier les services.
echo "Configuration terminée avec succès !"
echo "Vérifiez les services :"
echo "  - Icecast2: systemctl status icecast2"
echo "  - Nginx: systemctl status nginx"
echo "  - API: systemctl status api"
echo "Flux Icecast : https://radio.audace.ovh/stream.mp3"
echo "API : https://api.radio.audace.ovh"