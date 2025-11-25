
#!/bin/bash
################################################################################
# Installation et Configuration Complète de WG-Easy v15 + Nginx HTTPS

################################################################################
#
# Description:
#   Ce script automatise l'installation de WireGuard Easy (WG-Easy) v15 dans
#   un conteneur Docker, avec un reverse proxy Nginx configuré en HTTPS via
#   Let's Encrypt (Certbot). Il gère tous les prérequis et la validation SSL.
#
# Usage:
#   sudo bash install-wg-easy-nginx.sh
#
# Prérequis:
#   - Ubuntu/Debian
#   - Accès root (sudo)
#   - Domaine DNS pointant vers le serveur
#   - Ports 80 et 443 disponibles
#
# Variables de configuration:
WG_HOST="vps.monassurance.net"      # Remplacer par votre domaine
WG_PORT="51820"                      # Port UDP pour WireGuard (ne pas modifier)
WG_WEB_PORT="51821"                  # Port interne TCP pour l'interface web WG-Easy
ADMIN_EMAIL="admin@vps.monassurance.net"  # Email pour Certbot
TZ="Africa/Douala"                   # Fuseau horaire
CERTBOT_DIR="/var/www/certbot"       # Répertoire pour validation Certbot
NGINX_CONF="/etc/nginx/sites-available/wg-easy"  # Config Nginx
################################################################################

set -e  # Arrêter immédiatement en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Pas de couleur

################################################################################
# FONCTION: Affichage avec couleur
################################################################################
print_step() { echo -e "${BLUE}==> $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ Erreur: $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

################################################################################
# FONCTION: Vérifier si un domaine est valide
################################################################################
validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        print_error "Format de domaine invalide: $domain"
        return 1
    fi
    return 0
}

################################################################################
# DÉBUT DU SCRIPT
################################################################################
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║    Installation WG-Easy v15 + Nginx HTTPS (Let's Encrypt)     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Vérifier que le script s'exécute en tant que root
if [[ $EUID -ne 0 ]]; then
    print_error "Ce script doit être exécuté avec sudo"
    exit 1
fi

# Valider le domaine
if ! validate_domain "$WG_HOST"; then exit 1; fi

################################################################################
# INSTALLATION DES DÉPENDANCES
################################################################################
print_step "Vérification et installation des dépendances système"
sudo apt-get update > /dev/null 2>&1
PACKAGES=("docker.io" "nginx" "certbot" "python3-certbot-nginx" "curl" "wget")
for package in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $package"; then
        print_success "$package déjà installé"
    else
        print_step "Installation de $package..."
        sudo apt-get install -y "$package" > /dev/null 2>&1
        print_success "$package installé"
    fi
done

# Démarrer Docker
print_step "Démarrage du service Docker"
sudo systemctl enable docker > /dev/null 2>&1
sudo systemctl start docker > /dev/null 2>&1
print_success "Docker démarré et activé"

################################################################################
# NETTOYAGE DES ANCIENNES INSTALLATIONS
################################################################################
print_step "Nettoyage des anciennes installations WG-Easy et Nginx"
if sudo docker ps -a -q --filter "name=wg-easy" | grep -q .; then
    print_warning "Arrêt du conteneur WG-Easy existant..."
    sudo docker ps -a -q --filter "name=wg-easy" | xargs -r sudo docker rm -f
    print_success "Conteneur supprimé"
else
    print_success "Aucun conteneur existant à supprimer"
fi

if sudo docker volume ls -q | grep -q "wg-easy-config"; then
    print_warning "Suppression du volume WG-Easy existant..."
    sudo docker volume rm wg-easy-config
    print_success "Volume supprimé"
else
    print_success "Aucun volume existant à supprimer"
fi

if [[ -f "/etc/nginx/sites-enabled/wg-easy" ]] || [[ -f "/etc/nginx/sites-available/wg-easy" ]]; then
    print_warning "Suppression des anciennes configurations Nginx..."
    sudo rm -f /etc/nginx/sites-enabled/wg-easy*
    sudo rm -f /etc/nginx/sites-available/wg-easy*
    sudo nginx -t && sudo systemctl reload nginx
    print_success "Anciennes configs Nginx supprimées et Nginx rechargé"
else
    print_success "Aucune ancienne configuration Nginx à supprimer"
fi

# Créer un nouveau volume
print_step "Création d'un nouveau volume WG-Easy"
sudo docker volume create wg-easy-config
print_success "Volume créé"

################################################################################
# LANCEMENT DU CONTENEUR WG-EASY (v15)
################################################################################
print_step "Lancement du conteneur WG-Easy v15 (HTTP interne)"
sudo docker run -d \
  --name wg-easy \
  --restart always \
  -e WG_HOST="$WG_HOST" \
  -e WG_PORT="$WG_PORT" \
  -e TZ="$TZ" \
  -p $WG_PORT:$WG_PORT/udp \
  -p $WG_WEB_PORT:$WG_WEB_PORT/tcp \
  -v wg-easy-config:/etc/wireguard \
  -v /lib/modules:/lib/modules:ro \
  --cap-add NET_ADMIN \
  --cap-add SYS_MODULE \
  --sysctl net.ipv4.ip_forward=1 \
  --sysctl net.ipv4.conf.all.src_valid_mark=1 \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 \
  --sysctl net.ipv6.conf.all.forwarding=1 \
  --sysctl net.ipv6.conf.default.forwarding=1 \
  ghcr.io/wg-easy/wg-easy:15.1.0
print_success "Conteneur WG-Easy lancé"

sleep 15
if sudo docker ps | grep -q "wg-easy"; then
    print_success "Conteneur WG-Easy actif et en cours d'exécution"
else
    print_error "Le conteneur WG-Easy n'a pas démarré correctement"
    sudo docker logs wg-easy
    exit 1
fi

################################################################################
# CONFIGURATION NGINX - HTTPS
################################################################################
print_step "Configuration Nginx pour HTTPS"
sudo mkdir -p "$CERTBOT_DIR"

sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80;
    server_name $WG_HOST;

    location / {
        return 301 https://\$host\$request_uri;
    }

    location /.well-known/acme-challenge/ {
        root $CERTBOT_DIR;
    }
}

server {
    listen 443 ssl http2;
    server_name $WG_HOST;

    ssl_certificate /etc/letsencrypt/live/$WG_HOST/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$WG_HOST/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://127.0.0.1:$WG_WEB_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/wg-easy
sudo nginx -t && sudo systemctl reload nginx
print_success "Nginx configuré pour HTTPS et redémarrage terminé"

################################################################################
# CERTIFICAT LET'S ENCRYPT
################################################################################
print_step "Obtention du certificat SSL Let's Encrypt"
sudo certbot --nginx -d "$WG_HOST" --email "$ADMIN_EMAIL" --agree-tos --redirect --non-interactive
print_success "Certific at SSL installé"

################################################################################
# RÉSUMÉ FINAL
################################################################################
echo
echo -e "${GREEN}✓ Installation terminée !${NC}"
echo -e "${BLUE}Interface Web: https://$WG_HOST${NC}"
echo -e "${BLUE}Port WireGuard: $WG_PORT/UDP${NC}"