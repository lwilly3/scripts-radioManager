# init-radioManager-frontend-server.sh - Documentation

## 📋 Vue d'ensemble

Ce script automatise la configuration complète d'un serveur Ubuntu 24.10 pour héberger un site web frontend basé sur **Vite** (framework de build moderne pour applications JavaScript/TypeScript). Il installe toutes les dépendances, clone le projet depuis Git, compile le code et configure Nginx avec SSL.

## 🎯 Objectif

Déployer un site web frontend complet avec :
- Installation de Node.js 18+
- Clonage du projet depuis GitHub
- Compilation avec Vite
- Configuration Nginx comme serveur web
- Certificat SSL Let's Encrypt (HTTPS)
- Configuration du pare-feu (UFW)
- Démarrage automatique au boot

## 📦 Prérequis

- **Système d'exploitation** : Ubuntu 24.10 fraîchement installé
- **Accès** : Privilèges root ou sudo
- **Réseau** : Connexion Internet stable
- **DNS** : Domaine configuré pointant vers l'IP du serveur
  - Exemple : `app.radioaudace.com`
- **Dépôt Git** : Projet Vite hébergé sur GitHub (accessible publiquement ou avec authentification)

## ⚙️ Variables de configuration

```bash
# Domaine du site web
DOMAIN="app.radioaudace.com"

# Répertoire où le site sera hébergé
SITE_DIR="/var/www/app-radioaudace"

# URL du dépôt Git contenant le projet
GIT_REPO="https://github.com/lwilly3/radioManager-SaaS"

# Dossier généré par la compilation Vite
BUILD_DIR="dist"

# Utilisateur actuel exécutant le script
USER=$(whoami)

# Adresse email pour l'enregistrement Certbot
EMAIL="lwilly32@gmail.com"
```

## 🚀 Installation

### Étape 1 : Téléchargement du script

```bash
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/radioManager/init-radioManager-frontend-server.sh -O init_frontend.sh
```

### Étape 2 : Rendre le script exécutable

```bash
chmod +x init_frontend.sh
```

### Étape 3 : Éditer les variables

```bash
nano init_frontend.sh
```

Modifiez au minimum :
- `DOMAIN` : Votre nom de domaine
- `EMAIL` : Votre adresse email
- `GIT_REPO` : URL de votre dépôt Git
- `SITE_DIR` : Répertoire d'installation (optionnel)

### Étape 4 : Exécution du script

```bash
sudo bash init_frontend.sh
```

## 📝 Processus d'installation détaillé

### 1. Vérification des privilèges

```bash
if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté avec sudo ou en tant que root."
    exit 1
fi
```

### 2. Mise à jour du système

```bash
apt update && apt upgrade -y
```

Met à jour tous les paquets système pour garantir la compatibilité et la sécurité.

### 3. Installation des prérequis

```bash
apt install -y nodejs npm git nginx certbot python3-certbot-nginx
```

Installe :
- **Node.js** : Runtime JavaScript
- **npm** : Gestionnaire de paquets Node.js
- **Git** : Contrôle de version
- **Nginx** : Serveur web
- **Certbot** : Certificats SSL gratuits

### 4. Vérification et mise à jour de Node.js

```bash
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    # Installation de Node.js 18+ via nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 18
    nvm use 18
fi
```

**Pourquoi ?** Vite 5 nécessite Node.js 18 ou supérieur.

### 5. Création du répertoire du site

```bash
mkdir -p "$SITE_DIR"
chown "$USER:$USER" "$SITE_DIR"
```

### 6. Clonage du dépôt Git

```bash
git clone "$GIT_REPO" "$SITE_DIR"
```

Clone le projet depuis GitHub dans le répertoire cible.

### 7. Installation des dépendances et compilation

```bash
cd "$SITE_DIR"
npm install          # Installe les dépendances
npm run build        # Compile le projet avec Vite
```

Crée le dossier `dist/` contenant les fichiers statiques optimisés.

### 8. Configuration de Nginx

Création du fichier `/etc/nginx/sites-available/app-radioaudace` :

```nginx
server {
    listen 80;
    server_name app.radioaudace.com;

    root /var/www/app-radioaudace/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

**Points clés** :
- `try_files` : Support du routage SPA (Single Page Application)
- `root` : Pointe vers le dossier `dist` généré par Vite

### 9. Activation du site

```bash
ln -s /etc/nginx/sites-available/app-radioaudace /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx
systemctl enable nginx
```

### 10. Configuration du pare-feu

```bash
apt install -y ufw
ufw allow 22/tcp        # SSH
ufw allow 'Nginx Full'  # HTTP + HTTPS
ufw --force enable
```

### 11. Configuration SSL avec Certbot

```bash
certbot --nginx -d "$DOMAIN" \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    --redirect
```

Configure automatiquement :
- Certificat SSL Let's Encrypt
- Redirection HTTP → HTTPS
- Renouvellement automatique

### 12. Redémarrage final

```bash
systemctl restart nginx
```

## 🔍 Vérification de l'installation

### Vérifier les services

```bash
# Vérifier Nginx
sudo systemctl status nginx

# Tester la configuration Nginx
sudo nginx -t

# Vérifier le pare-feu
sudo ufw status
```

### Tester le site

```bash
# Test local
curl -I http://localhost

# Test HTTPS
curl -I https://app.radioaudace.com

# Avec navigateur
# Ouvrez : https://app.radioaudace.com
```

### Vérifier le certificat SSL

```bash
# Lister les certificats
sudo certbot certificates

# Tester le SSL
openssl s_client -connect app.radioaudace.com:443 -servername app.radioaudace.com
```

## 📂 Structure des fichiers

```
/var/www/app-radioaudace/
├── dist/                    # Fichiers compilés (servis par Nginx)
│   ├── index.html
│   ├── assets/
│   │   ├── index-[hash].js
│   │   └── index-[hash].css
│   └── favicon.ico
├── src/                     # Code source
├── node_modules/            # Dépendances npm
├── package.json             # Configuration npm
├── vite.config.js           # Configuration Vite
└── .git/                    # Dépôt Git

/etc/nginx/sites-available/
└── app-radioaudace          # Configuration Nginx

/etc/nginx/sites-enabled/
└── app-radioaudace -> ../sites-available/app-radioaudace

/etc/letsencrypt/live/app.radioaudace.com/
├── fullchain.pem            # Certificat SSL
└── privkey.pem              # Clé privée SSL
```

## 🛠️ Maintenance

### Mettre à jour le site

Utilisez le script `update_frontend.sh` :

```bash
cd /var/www/app-radioaudace
git pull origin main
npm install
npm run build
sudo systemctl restart nginx
```

### Consulter les logs

```bash
# Logs Nginx (accès)
sudo tail -f /var/log/nginx/access.log

# Logs Nginx (erreurs)
sudo tail -f /var/log/nginx/error.log

# Logs système
sudo journalctl -u nginx -f
```

### Renouveler le certificat SSL

Le renouvellement est automatique, mais vous pouvez le forcer :

```bash
sudo certbot renew
sudo systemctl reload nginx
```

## 🎨 Configuration Vite

### vite.config.js

Exemple de configuration pour un projet Vue.js :

```javascript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  },
  server: {
    port: 3000,
    host: true
  }
})
```

### package.json

Scripts npm typiques :

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  }
}
```

## 🔧 Personnalisation

### Changer le port Nginx

Si vous voulez écouter sur un autre port :

```nginx
server {
    listen 8080;
    # ...
}
```

### Ajouter des en-têtes de sécurité

```nginx
server {
    # ...
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

### Configuration pour un domaine avec www

```nginx
server {
    listen 80;
    server_name www.app.radioaudace.com;
    return 301 https://app.radioaudace.com$request_uri;
}
```

### Support de plusieurs domaines

```bash
# Obtenir des certificats pour plusieurs domaines
sudo certbot --nginx -d app.radioaudace.com -d www.app.radioaudace.com
```

## ⚠️ Dépannage

### Problème : Node.js trop ancien

```bash
# Vérifier la version
node --version

# Installer via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.nvm/nvm.sh
nvm install 18
nvm use 18
```

### Problème : npm install échoue

```bash
# Nettoyer le cache npm
npm cache clean --force

# Supprimer node_modules et recommencer
rm -rf node_modules package-lock.json
npm install
```

### Problème : Erreur de compilation Vite

```bash
# Vérifier les logs de build
npm run build

# Mode verbose
npm run build -- --debug

# Vérifier vite.config.js
cat vite.config.js
```

### Problème : Nginx ne démarre pas

```bash
# Tester la configuration
sudo nginx -t

# Voir les détails de l'erreur
sudo journalctl -u nginx -n 50

# Vérifier les ports
sudo netstat -tlnp | grep :80
```

### Problème : Erreur SSL

```bash
# Vérifier que le domaine pointe vers le serveur
nslookup app.radioaudace.com

# Re-tenter l'obtention du certificat
sudo certbot --nginx -d app.radioaudace.com --force-renewal

# Vérifier les logs Certbot
sudo cat /var/log/letsencrypt/letsencrypt.log
```

### Problème : Site ne s'affiche pas correctement

```bash
# Vérifier les permissions
ls -la /var/www/app-radioaudace/dist/

# S'assurer que Nginx peut lire les fichiers
sudo chown -R www-data:www-data /var/www/app-radioaudace/dist/
sudo chmod -R 755 /var/www/app-radioaudace/dist/
```

## 🔒 Sécurité

### Limiter l'accès par IP

```nginx
location / {
    allow 203.0.113.0/24;  # Votre réseau
    deny all;
    try_files $uri $uri/ /index.html;
}
```

### Activer HTTP/2

```nginx
server {
    listen 443 ssl http2;  # Ajouter http2
    # ...
}
```

### Activer la compression

```nginx
server {
    # ...
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml+rss text/javascript;
    gzip_vary on;
}
```

## 📊 Performances

### Cache des fichiers statiques

```nginx
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### Optimisation Vite

```javascript
// vite.config.js
export default defineConfig({
  build: {
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true  // Supprimer les console.log
      }
    },
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', 'vue-router']  // Séparer les vendors
        }
      }
    }
  }
})
```

## 🔗 Frameworks supportés

Ce script fonctionne avec tous les frameworks Vite :

- **Vue.js** : `npm create vite@latest -- --template vue`
- **React** : `npm create vite@latest -- --template react`
- **Svelte** : `npm create vite@latest -- --template svelte`
- **Vanilla JS** : `npm create vite@latest -- --template vanilla`
- **TypeScript** : Toutes les variantes avec `-ts`

## 📚 Ressources

- [Documentation Vite](https://vitejs.dev/)
- [Documentation Nginx](https://nginx.org/en/docs/)
- [Certbot](https://certbot.eff.org/)
- [Let's Encrypt](https://letsencrypt.org/)

## 📞 Support

Pour toute question :
- Consultez les logs : `sudo tail -f /var/log/nginx/error.log`
- Testez la configuration : `sudo nginx -t`
- Vérifiez les processus : `ps aux | grep nginx`

## 📜 Notes importantes

- **Sauvegardez** toujours avant de mettre à jour
- **Testez** les modifications sur un environnement de développement d'abord
- **Documentez** vos personnalisations
- **Surveillez** les ressources (CPU, RAM, disque)
- **Planifiez** les mises à jour de sécurité régulières
