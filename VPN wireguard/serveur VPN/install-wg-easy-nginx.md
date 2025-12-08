# install-wg-easy-nginx.sh - Documentation

## 📋 Vue d'ensemble

Ce script automatise l'installation complète de **WireGuard Easy (WG-Easy) v15** dans un conteneur Docker avec un reverse proxy **Nginx** configuré en **HTTPS** via Let's Encrypt. WG-Easy offre une interface web moderne pour gérer facilement les clients VPN WireGuard.

## 🎯 Objectif

Déployer une solution VPN WireGuard complète avec :
- Serveur WireGuard dans un conteneur Docker
- Interface web WG-Easy pour la gestion
- Reverse proxy Nginx avec SSL/TLS
- Certificat Let's Encrypt gratuit
- Configuration automatisée et sécurisée

## 🔧 Composants installés

| Composant | Version | Rôle |
|-----------|---------|------|
| **WG-Easy** | v15.1.0 | Interface web pour WireGuard |
| **Docker** | Dernière | Conteneurisation |
| **Nginx** | Dernière | Reverse proxy |
| **Certbot** | Dernière | Certificats SSL Let's Encrypt |
| **WireGuard** | Dernière | Protocole VPN |

## 📦 Prérequis

- **Système d'exploitation** : Ubuntu/Debian
- **Accès** : Privilèges root (sudo)
- **DNS** : Domaine pointant vers l'IP publique du serveur
  - Exemple : `vps.monassurance.net`
- **Ports** : 
  - 80/tcp (HTTP - validation Certbot)
  - 443/tcp (HTTPS - interface web)
  - 51820/udp (WireGuard)
- **Réseau** : IP publique fixe recommandée

## ⚙️ Variables de configuration

```bash
# Domaine pour accéder à l'interface web
WG_HOST="vps.monassurance.net"

# Port UDP pour WireGuard
WG_PORT="51820"

# Port interne TCP pour l'interface web WG-Easy
WG_WEB_PORT="51821"

# Email pour Certbot (notifications Let's Encrypt)
ADMIN_EMAIL="admin@vps.monassurance.net"

# Fuseau horaire
TZ="Africa/Douala"

# Répertoire pour validation Certbot
CERTBOT_DIR="/var/www/certbot"

# Configuration Nginx
NGINX_CONF="/etc/nginx/sites-available/wg-easy"
```

## 🚀 Installation

### Étape 1 : Téléchargement du script

```bash
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/VPN%20wireguard/serveur%20VPN/install-wg-easy-nginx.sh -O install-wg-easy.sh
```

### Étape 2 : Éditer les variables

```bash
nano install-wg-easy.sh
```

Modifiez :
- `WG_HOST` : Votre nom de domaine
- `ADMIN_EMAIL` : Votre email
- `TZ` : Votre fuseau horaire

### Étape 3 : Rendre le script exécutable

```bash
chmod +x install-wg-easy.sh
```

### Étape 4 : Exécution du script

```bash
sudo bash install-wg-easy.sh
```

## 📝 Processus d'installation détaillé

### 1. Vérification des privilèges

```bash
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté avec sudo"
    exit 1
fi
```

### 2. Validation du domaine

```bash
validate_domain() {
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        echo "Format de domaine invalide"
        return 1
    fi
}
```

### 3. Installation des dépendances

```bash
PACKAGES=("docker.io" "nginx" "certbot" "python3-certbot-nginx" "curl" "wget")
for package in "${PACKAGES[@]}"; do
    apt-get install -y "$package"
done
```

### 4. Nettoyage des anciennes installations

```bash
# Supprimer les anciens conteneurs
docker ps -a -q --filter "name=wg-easy" | xargs -r docker rm -f

# Supprimer les anciens volumes
docker volume rm wg-easy-config

# Supprimer les anciennes configs Nginx
rm -f /etc/nginx/sites-enabled/wg-easy*
rm -f /etc/nginx/sites-available/wg-easy*
```

### 5. Création du volume Docker

```bash
docker volume create wg-easy-config
```

### 6. Lancement du conteneur WG-Easy

```bash
docker run -d \
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
  --cap-add NET_RAW \
  --sysctl net.ipv4.ip_forward=1 \
  --sysctl net.ipv4.conf.all.src_valid_mark=1 \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 \
  --sysctl net.ipv6.conf.all.forwarding=1 \
  --sysctl net.ipv6.conf.default.forwarding=1 \
  ghcr.io/wg-easy/wg-easy:15.1.0
```

**Paramètres clés** :
- `--restart always` : Redémarrage automatique
- `--cap-add` : Capacités nécessaires pour WireGuard
- `--sysctl` : Configuration réseau du noyau

### 7. Configuration Nginx

```nginx
server {
    listen 80;
    server_name vps.monassurance.net;
    
    location / {
        return 301 https://$host$request_uri;
    }
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}

server {
    listen 443 ssl http2;
    server_name vps.monassurance.net;
    
    ssl_certificate /etc/letsencrypt/live/vps.monassurance.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/vps.monassurance.net/privkey.pem;
    
    location / {
        proxy_pass http://127.0.0.1:51821;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 8. Obtention du certificat SSL

```bash
certbot --nginx \
    -d "$WG_HOST" \
    --email "$ADMIN_EMAIL" \
    --agree-tos \
    --redirect \
    --non-interactive
```

## 🌐 Accès à l'interface web

Une fois l'installation terminée, accédez à :

```
https://vps.monassurance.net
```

### Première connexion

1. **Mot de passe par défaut** : Consultez les logs Docker
   ```bash
   docker logs wg-easy
   ```

2. **Changez immédiatement le mot de passe** dans les paramètres

## 👥 Gestion des clients VPN

### Ajouter un client

1. Connectez-vous à l'interface web
2. Cliquez sur "Add Client"
3. Donnez un nom au client (ex: "Laptop-John")
4. Téléchargez le fichier de configuration ou scannez le QR code

### Configurer un client

#### Sur Android/iOS
1. Installez l'app **WireGuard** depuis le store
2. Scannez le QR code affiché dans WG-Easy
3. Activez la connexion

#### Sur Windows/Mac/Linux
1. Installez **WireGuard**
2. Importez le fichier de configuration `.conf`
3. Activez la connexion

### Exemple de configuration client

```ini
[Interface]
PrivateKey = <clé-privée-générée>
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <clé-publique-serveur>
Endpoint = vps.monassurance.net:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

## 🔍 Vérification de l'installation

### Vérifier Docker

```bash
# Statut du conteneur
docker ps | grep wg-easy

# Logs
docker logs wg-easy

# Inspecter
docker inspect wg-easy
```

### Vérifier Nginx

```bash
# Statut
sudo systemctl status nginx

# Tester la configuration
sudo nginx -t

# Logs
sudo tail -f /var/log/nginx/error.log
```

### Vérifier le certificat SSL

```bash
# Lister les certificats
sudo certbot certificates

# Tester SSL
openssl s_client -connect vps.monassurance.net:443 -servername vps.monassurance.net
```

### Tester la connexion VPN

```bash
# Depuis un client connecté, tester la connexion
ping 10.8.0.1

# Vérifier l'IP publique
curl ifconfig.me
```

## 📂 Structure des fichiers

```
/var/lib/docker/volumes/wg-easy-config/
└── _data/
    └── etc/wireguard/
        ├── wg0.conf          # Configuration WireGuard
        └── clients/          # Configurations clients

/etc/nginx/sites-available/
└── wg-easy                   # Configuration Nginx

/etc/letsencrypt/live/vps.monassurance.net/
├── fullchain.pem            # Certificat SSL
└── privkey.pem              # Clé privée SSL

/var/www/certbot/            # Répertoire validation Certbot
```

## 🛠️ Maintenance

### Mettre à jour WG-Easy

```bash
# Arrêter et supprimer l'ancien conteneur
docker stop wg-easy
docker rm wg-easy

# Relancer avec la nouvelle version
docker run -d \
  --name wg-easy \
  --restart always \
  -e WG_HOST="vps.monassurance.net" \
  -e WG_PORT="51820" \
  -e TZ="Africa/Douala" \
  -p 51820:51820/udp \
  -p 51821:51821/tcp \
  -v wg-easy-config:/etc/wireguard \
  -v /lib/modules:/lib/modules:ro \
  --cap-add NET_ADMIN \
  --cap-add SYS_MODULE \
  --cap-add NET_RAW \
  --sysctl net.ipv4.ip_forward=1 \
  --sysctl net.ipv4.conf.all.src_valid_mark=1 \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 \
  --sysctl net.ipv6.conf.all.forwarding=1 \
  --sysctl net.ipv6.conf.default.forwarding=1 \
  ghcr.io/wg-easy/wg-easy:latest
```

### Sauvegarder la configuration

```bash
# Sauvegarder le volume Docker
docker run --rm \
  -v wg-easy-config:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/wg-easy-backup-$(date +%Y%m%d).tar.gz /data

# Copier la sauvegarde ailleurs
scp wg-easy-backup-*.tar.gz user@backup-server:/backups/
```

### Restaurer une sauvegarde

```bash
# Restaurer le volume
docker run --rm \
  -v wg-easy-config:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/wg-easy-backup-YYYYMMDD.tar.gz -C /

# Redémarrer le conteneur
docker restart wg-easy
```

### Renouveler le certificat SSL

Le renouvellement est automatique, mais vous pouvez le forcer :

```bash
sudo certbot renew --force-renewal
sudo systemctl reload nginx
```

## 🔒 Sécurité

### Changer le mot de passe de l'interface

1. Connectez-vous à l'interface web
2. Accédez aux paramètres
3. Changez le mot de passe

### Activer l'authentification à deux facteurs

WG-Easy ne supporte pas nativement 2FA, mais vous pouvez :
- Utiliser un VPN pour accéder à l'interface
- Restreindre l'accès par IP dans Nginx

### Restreindre l'accès par IP

```nginx
location / {
    allow 203.0.113.0/24;  # Votre réseau
    deny all;
    proxy_pass http://127.0.0.1:51821;
}
```

### Configurer un pare-feu

```bash
# Installer UFW
sudo apt install ufw -y

# Autoriser SSH, HTTPS et WireGuard
sudo ufw allow 22/tcp
sudo ufw allow 443/tcp
sudo ufw allow 51820/udp

# Activer
sudo ufw enable
```

## 📊 Monitoring

### Consulter les logs

```bash
# Logs WG-Easy
docker logs -f wg-easy

# Logs Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Statistiques clients

L'interface web affiche :
- Nombre de clients connectés
- Bande passante utilisée
- Dernière connexion de chaque client

### Monitoring avancé

```bash
# Surveiller les connexions actives
sudo docker exec wg-easy wg show

# Trafic réseau
sudo iftop -i wg0
```

## ⚠️ Dépannage

### Problème : Le conteneur ne démarre pas

```bash
# Vérifier les logs
docker logs wg-easy

# Vérifier les modules du noyau
lsmod | grep wireguard

# Charger le module manuellement
sudo modprobe wireguard
```

### Problème : Interface web inaccessible

```bash
# Vérifier Nginx
sudo nginx -t
sudo systemctl status nginx

# Vérifier les ports
sudo netstat -tlnp | grep 51821
sudo netstat -tlnp | grep 443
```

### Problème : Clients ne peuvent pas se connecter

```bash
# Vérifier que le port UDP est ouvert
sudo ufw status | grep 51820

# Vérifier la configuration WireGuard
sudo docker exec wg-easy wg show

# Tester depuis l'extérieur
nc -u -v vps.monassurance.net 51820
```

### Problème : Erreur SSL

```bash
# Vérifier le domaine DNS
nslookup vps.monassurance.net

# Re-générer le certificat
sudo certbot --nginx -d vps.monassurance.net --force-renewal

# Vérifier les logs Certbot
sudo cat /var/log/letsencrypt/letsencrypt.log
```

## 🌍 Cas d'usage

### Accès distant au réseau d'entreprise

Configurez les routes pour accéder au LAN local :

```bash
# Dans le conteneur WG-Easy
docker exec -it wg-easy sh
wg set wg0 peer <public-key> allowed-ips 10.8.0.2/32,192.168.1.0/24
```

### VPN pour tous les appareils

Utilisez `AllowedIPs = 0.0.0.0/0` pour router tout le trafic.

### Split-tunneling

Configurez uniquement certaines routes dans `AllowedIPs`.

## 📚 Ressources

- [WG-Easy GitHub](https://github.com/wg-easy/wg-easy)
- [WireGuard Documentation](https://www.wireguard.com/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Let's Encrypt](https://letsencrypt.org/)

## 📞 Support

En cas de problème :
1. Consultez les logs : `docker logs wg-easy`
2. Vérifiez Nginx : `sudo nginx -t`
3. Testez le certificat : `sudo certbot certificates`
4. Communauté WG-Easy : https://github.com/wg-easy/wg-easy/issues

## 📜 Notes importantes

- WireGuard nécessite un noyau Linux moderne (>= 5.6)
- Le port 51820/udp doit être accessible depuis Internet
- Le domaine DNS doit pointer vers l'IP publique du serveur
- Changez le mot de passe par défaut immédiatement
- Sauvegardez régulièrement la configuration
