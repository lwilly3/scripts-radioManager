# Script_installation_N8N_sur_EC2_AmazonLinux.sh - Documentation

## 📋 Vue d'ensemble

Ce script automatise l'installation de **N8N** (plateforme d'automatisation workflow) sur une instance **Amazon EC2 avec Amazon Linux**. N8N est une alternative open-source à Zapier/Make pour l'automatisation de tâches et l'intégration de services.

## 🎯 Objectif

Déployer N8N sur une instance EC2 Amazon Linux avec :
- Installation de Node.js
- Configuration de N8N en tant que service systemd
- Configuration du reverse proxy Nginx
- Certificat SSL avec Let's Encrypt
- Configuration du pare-feu
- Démarrage automatique au boot

## 📦 Prérequis

- **Instance** : EC2 Amazon Linux 2 ou Amazon Linux 2023
- **Accès** : SSH avec privilèges sudo
- **DNS** : Domaine configuré pointant vers l'IP publique de l'instance
- **Réseau** : 
  - Ports 22, 80, 443 ouverts dans le Security Group
  - Connexion Internet stable

## 🔧 Architecture déployée

```
Internet
   ↓
[Route 53 / DNS]
   ↓
[Security Group: 80, 443]
   ↓
[EC2 Instance]
   ├── Nginx (reverse proxy) :80 → :443
   │   └── SSL/TLS (Let's Encrypt)
   └── N8N :5678
       └── Node.js runtime
```

## ⚙️ Variables de configuration

```bash
# Domaine pour accéder à N8N
N8N_DOMAIN="n8n.votre-domaine.com"

# Email pour Let's Encrypt
ADMIN_EMAIL="admin@votre-domaine.com"

# Port interne de N8N
N8N_PORT=5678

# Répertoire d'installation
N8N_DIR="/opt/n8n"

# Utilisateur système pour N8N
N8N_USER="n8n"
```

## 🚀 Installation

### Étape 1 : Téléchargement du script

```bash
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/N8N/Script_installation_N8N_sur_EC2_AmazonLinux.sh -O install_n8n.sh
```

### Étape 2 : Rendre le script exécutable

```bash
chmod +x install_n8n.sh
```

### Étape 3 : Éditer les variables

```bash
nano install_n8n.sh
```

Modifiez au minimum :
- `N8N_DOMAIN` : Votre nom de domaine
- `ADMIN_EMAIL` : Votre email

### Étape 4 : Exécution du script

```bash
sudo bash install_n8n.sh
```

## 📝 Processus d'installation

### 1. Mise à jour du système

```bash
sudo yum update -y
```

### 2. Installation de Node.js

```bash
# Installation de Node.js LTS via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.nvm/nvm.sh
nvm install --lts
nvm use --lts
```

### 3. Installation de N8N

```bash
# Installation globale de N8N
npm install -g n8n

# Ou installation locale dans /opt/n8n
mkdir -p /opt/n8n
cd /opt/n8n
npm init -y
npm install n8n
```

### 4. Création de l'utilisateur système

```bash
sudo useradd -r -s /bin/false n8n
sudo chown -R n8n:n8n /opt/n8n
```

### 5. Configuration du service systemd

Création du fichier `/etc/systemd/system/n8n.service` :

```ini
[Unit]
Description=N8N Workflow Automation
After=network.target

[Service]
Type=simple
User=n8n
WorkingDirectory=/opt/n8n
Environment="N8N_HOST=0.0.0.0"
Environment="N8N_PORT=5678"
Environment="N8N_PROTOCOL=https"
Environment="WEBHOOK_URL=https://n8n.votre-domaine.com/"
ExecStart=/usr/bin/node /opt/n8n/node_modules/n8n/bin/n8n start
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### 6. Installation de Nginx

```bash
sudo amazon-linux-extras install nginx1 -y
# Ou pour Amazon Linux 2023
sudo yum install nginx -y
```

### 7. Configuration Nginx

```nginx
server {
    listen 80;
    server_name n8n.votre-domaine.com;
    
    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support pour l'interface N8N
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### 8. Installation de Certbot et SSL

```bash
# Installation de Certbot
sudo yum install certbot python3-certbot-nginx -y

# Obtention du certificat
sudo certbot --nginx -d n8n.votre-domaine.com \
    --email admin@votre-domaine.com \
    --agree-tos --redirect --non-interactive
```

### 9. Démarrage des services

```bash
sudo systemctl daemon-reload
sudo systemctl enable n8n
sudo systemctl start n8n
sudo systemctl enable nginx
sudo systemctl start nginx
```

## 🔍 Vérification de l'installation

### Vérifier les services

```bash
# Vérifier N8N
sudo systemctl status n8n

# Vérifier Nginx
sudo systemctl status nginx

# Vérifier que N8N écoute sur le port 5678
sudo netstat -tlnp | grep 5678

# Vérifier les logs N8N
sudo journalctl -u n8n -f
```

### Accéder à l'interface web

Ouvrez votre navigateur : `https://n8n.votre-domaine.com`

## 📂 Structure des fichiers

```
/opt/n8n/
├── node_modules/        # Modules Node.js
├── package.json         # Configuration npm
└── .n8n/                # Données N8N (workflows, credentials)

/etc/systemd/system/
└── n8n.service          # Service systemd

/etc/nginx/
├── nginx.conf
└── conf.d/
    └── n8n.conf         # Configuration Nginx pour N8N

/var/log/
├── nginx/
│   ├── access.log
│   └── error.log
└── journal/             # Logs systemd (journalctl)
```

## 🔐 Configuration avancée

### Variables d'environnement N8N

Éditez `/etc/systemd/system/n8n.service` :

```ini
Environment="N8N_BASIC_AUTH_ACTIVE=true"
Environment="N8N_BASIC_AUTH_USER=admin"
Environment="N8N_BASIC_AUTH_PASSWORD=VotreMotDePasse"
Environment="N8N_ENCRYPTION_KEY=VotreCléSecrète"
Environment="DB_TYPE=postgresdb"
Environment="DB_POSTGRESDB_HOST=localhost"
Environment="DB_POSTGRESDB_DATABASE=n8n"
Environment="DB_POSTGRESDB_USER=n8n"
Environment="DB_POSTGRESDB_PASSWORD=MotDePasse"
```

Puis rechargez :

```bash
sudo systemctl daemon-reload
sudo systemctl restart n8n
```

### Utiliser PostgreSQL au lieu de SQLite

```bash
# Installer PostgreSQL
sudo yum install postgresql15-server -y
sudo postgresql-setup --initdb
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Créer la base de données
sudo -u postgres psql
CREATE DATABASE n8n;
CREATE USER n8n WITH PASSWORD 'votre_mot_de_passe';
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
\q
```

## 🛠️ Maintenance

### Mettre à jour N8N

Utilisez le script `Script_MAJ_N8N.sh` (à créer) :

```bash
# Arrêter N8N
sudo systemctl stop n8n

# Mettre à jour
cd /opt/n8n
npm update n8n

# Redémarrer
sudo systemctl start n8n
```

### Sauvegarder les données

```bash
# Sauvegarder le répertoire .n8n
sudo tar -czf n8n-backup-$(date +%Y%m%d).tar.gz /opt/n8n/.n8n/

# Copier vers S3
aws s3 cp n8n-backup-*.tar.gz s3://votre-bucket/backups/
```

### Consulter les logs

```bash
# Logs N8N en temps réel
sudo journalctl -u n8n -f

# Logs Nginx
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

## 🔒 Sécurité

### Activer l'authentification basique

```bash
# Générer un mot de passe sécurisé
openssl rand -base64 32
```

Ajouter dans le service N8N :

```ini
Environment="N8N_BASIC_AUTH_ACTIVE=true"
Environment="N8N_BASIC_AUTH_USER=admin"
Environment="N8N_BASIC_AUTH_PASSWORD=MotDePasseGénéré"
```

### Restreindre l'accès par IP

Dans Nginx :

```nginx
location / {
    allow 203.0.113.0/24;  # Votre réseau
    deny all;
    
    proxy_pass http://localhost:5678;
    # ...
}
```

## ⚠️ Dépannage

### Problème : N8N ne démarre pas

```bash
# Vérifier les logs
sudo journalctl -u n8n -n 50 --no-pager

# Tester N8N manuellement
sudo -u n8n node /opt/n8n/node_modules/n8n/bin/n8n start
```

### Problème : Erreur de connexion WebSocket

Vérifiez la configuration Nginx :

```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

### Problème : Erreur SSL

```bash
# Re-générer le certificat
sudo certbot --nginx -d n8n.votre-domaine.com --force-renewal

# Vérifier la configuration
sudo nginx -t
sudo systemctl reload nginx
```

## 📊 Monitoring

### Surveiller les ressources

```bash
# CPU et mémoire
top -p $(pgrep -f n8n)

# Espace disque
df -h /opt/n8n
```

### CloudWatch (AWS)

```bash
# Installer l'agent CloudWatch
sudo yum install amazon-cloudwatch-agent -y

# Configurer pour surveiller les logs N8N
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```

## 🔗 Intégrations disponibles

N8N supporte plus de 400 intégrations :
- **Cloud** : AWS, Google Cloud, Azure
- **Notifications** : Slack, Discord, Telegram
- **Base de données** : PostgreSQL, MySQL, MongoDB
- **API** : HTTP Request, Webhook
- **CRM** : HubSpot, Salesforce
- **Et bien plus...**

## 📚 Ressources

- [Documentation officielle N8N](https://docs.n8n.io/)
- [Communauté N8N](https://community.n8n.io/)
- [N8N sur GitHub](https://github.com/n8n-io/n8n)
- [Templates de workflows](https://n8n.io/workflows/)

## 📞 Support

Pour toute question :
- Consultez les logs : `sudo journalctl -u n8n -f`
- Forum N8N : https://community.n8n.io/
- GitHub Issues : https://github.com/n8n-io/n8n/issues

## 📜 Notes

- N8N est gratuit et open-source (licence Apache 2.0)
- Pour un usage en production, utilisez PostgreSQL au lieu de SQLite
- Configurez des sauvegardes régulières des données
- Surveillez l'utilisation des ressources (CPU/RAM)
