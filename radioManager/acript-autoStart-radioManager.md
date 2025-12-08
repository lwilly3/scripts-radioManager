# acript-autoStart-radioManager.sh - Documentation

## 📋 Vue d'ensemble

Ce script s'exécute automatiquement au **démarrage du serveur** pour garantir que le site web `app.radioaudace.com` est opérationnel. Il vérifie et démarre Nginx, s'assure que le frontend Vite est compilé, et peut optionnellement mettre à jour le code depuis Git.

## 🎯 Objectif

Assurer la disponibilité du site frontend après un redémarrage du serveur en :
- Démarrant automatiquement Nginx
- Vérifiant la présence du dossier de build (dist)
- Recompilant le frontend si nécessaire
- (Optionnel) Mettant à jour depuis Git
- Vérifiant l'accessibilité du site

## 📦 Prérequis

- Frontend déjà installé (via `init-radioManager-frontend-server.sh`)
- Nginx configuré
- Node.js et npm installés
- Projet Vite dans `/var/www/app-radioaudace`
- Privilèges root (exécution via systemd)

## ⚙️ Variables de configuration

```bash
# Domaine du site web
DOMAIN="app.radioaudace.com"

# Répertoire du site
SITE_DIR="/var/www/app-radioaudace"

# URL du dépôt Git
GIT_REPO="https://github.com/lwilly3/radioManager-SaaS"

# Dossier de build Vite
BUILD_DIR="dist"

# Fichier de log
LOG_FILE="/var/log/start_radioaudace.log"
```

## 🚀 Installation

### Étape 1 : Télécharger le script

```bash
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/radioManager/acript-autoStart-radioManager.sh -O start-radioaudace.sh
```

### Étape 2 : Placer le script

```bash
sudo mv start-radioaudace.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/start-radioaudace.sh
```

### Étape 3 : Créer le service systemd

Créez le fichier `/etc/systemd/system/start-radioaudace.service` :

```bash
sudo nano /etc/systemd/system/start-radioaudace.service
```

Contenu :

```ini
[Unit]
Description=Démarre le site radioaudace après un reboot
After=network.target

[Service]
ExecStart=/usr/local/bin/start-radioaudace.sh
Type=oneshot
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
```

### Étape 4 : Activer le service

```bash
# Recharger systemd
sudo systemctl daemon-reload

# Activer le service au démarrage
sudo systemctl enable start-radioaudace.service

# Tester le service
sudo systemctl start start-radioaudace.service
```

## 📝 Processus d'exécution

### 1. Vérification des privilèges

```bash
if [ "$EUID" -ne 0 ]; then
    log "Erreur : Ce script doit être exécuté avec sudo ou en tant que root."
    exit 1
fi
```

### 2. Vérification du répertoire

```bash
if [ ! -d "$SITE_DIR" ]; then
    log "Erreur : Le répertoire $SITE_DIR n'existe pas."
    exit 1
fi
```

### 3. Démarrage de Nginx

```bash
log "Démarrage de Nginx..."
systemctl enable nginx
systemctl start nginx
```

- Active Nginx au démarrage
- Démarre Nginx immédiatement
- Vérifie le succès de l'opération

### 4. Vérification du build

```bash
cd "$SITE_DIR"
if [ ! -d "$BUILD_DIR" ]; then
    log "Le dossier $BUILD_DIR n'existe pas. Reconstruction..."
    if [ -f "package.json" ]; then
        npm install
        npm run build
    fi
fi
```

Si le dossier `dist` n'existe pas :
- Installe les dépendances npm
- Compile le projet avec Vite
- Vérifie la création du dossier

### 5. Mise à jour Git (optionnelle)

Par défaut commentée, à décommenter si nécessaire :

```bash
# if [ -d ".git" ]; then
#     log "Mise à jour du dépôt Git depuis $GIT_REPO..."
#     git fetch origin
#     git pull origin main
#     npm install
#     npm run build
# fi
```

### 6. Vérification finale

```bash
curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" | grep -q "200"
if [ $? -eq 0 ]; then
    log "Le site est actif et accessible à https://$DOMAIN."
else
    log "Avertissement : Le site ne semble pas accessible."
fi
```

Teste l'accessibilité du site via une requête HTTP.

## 📂 Structure des fichiers

```
/usr/local/bin/
└── start-radioaudace.sh           # Script de démarrage

/etc/systemd/system/
└── start-radioaudace.service      # Service systemd

/var/log/
└── start_radioaudace.log          # Fichier de log

/var/www/app-radioaudace/
├── dist/                           # Build Vite
├── node_modules/                   # Dépendances npm
├── package.json                    # Configuration npm
└── .git/                           # Dépôt Git (optionnel)
```

## 🔍 Vérification

### Vérifier le service

```bash
# Statut du service
sudo systemctl status start-radioaudace.service

# Voir les logs systemd
sudo journalctl -u start-radioaudace.service
```

### Consulter les logs du script

```bash
# Afficher les logs
cat /var/log/start_radioaudace.log

# Suivre en temps réel
tail -f /var/log/start_radioaudace.log
```

### Tester le démarrage

```bash
# Tester manuellement
sudo /usr/local/bin/start-radioaudace.sh

# Tester après un reboot
sudo reboot
# Attendre le redémarrage, puis :
cat /var/log/start_radioaudace.log
```

## 🎛️ Options de configuration

### Activer la mise à jour automatique Git

Décommentez cette section dans le script :

```bash
if [ -d ".git" ]; then
    log "Mise à jour du dépôt Git depuis $GIT_REPO..."
    echo "Mise à jour du dépôt Git depuis $GIT_REPO..."
    git fetch origin
    git pull origin main
    if [ $? -ne 0 ]; then
        log "Erreur lors de la mise à jour du dépôt Git."
        echo "Erreur lors de la mise à jour du dépôt Git."
    else
        npm install
        npm run build
        log "Frontend mis à jour et recompilé avec succès."
        echo "Frontend mis à jour et recompilé avec succès."
    fi
fi
```

⚠️ **Attention** : Cette option met à jour le site à chaque redémarrage du serveur.

### Changer le domaine

Modifiez la variable `DOMAIN` dans le script :

```bash
DOMAIN="votre-nouveau-domaine.com"
```

### Personnaliser le log

```bash
LOG_FILE="/chemin/personnalisé/logs/startup.log"
```

## 🛠️ Maintenance

### Désactiver le démarrage automatique

```bash
sudo systemctl disable start-radioaudace.service
```

### Supprimer le service

```bash
sudo systemctl stop start-radioaudace.service
sudo systemctl disable start-radioaudace.service
sudo rm /etc/systemd/system/start-radioaudace.service
sudo systemctl daemon-reload
```

### Forcer une reconstruction au prochain démarrage

```bash
# Supprimer le dossier dist
sudo rm -rf /var/www/app-radioaudace/dist

# Au prochain redémarrage, le script le reconstruit automatiquement
sudo reboot
```

## ⚠️ Dépannage

### Problème : Le script ne s'exécute pas au démarrage

```bash
# Vérifier si le service est activé
sudo systemctl is-enabled start-radioaudace.service

# Vérifier les erreurs systemd
sudo journalctl -u start-radioaudace.service -n 50

# Vérifier les dépendances
systemctl list-dependencies start-radioaudace.service
```

### Problème : Nginx ne démarre pas

```bash
# Vérifier la configuration Nginx
sudo nginx -t

# Consulter les logs Nginx
sudo tail -f /var/log/nginx/error.log

# Redémarrer manuellement
sudo systemctl restart nginx
```

### Problème : Le build échoue

```bash
# Vérifier Node.js et npm
node --version
npm --version

# Tester la compilation manuellement
cd /var/www/app-radioaudace
npm install
npm run build

# Vérifier les logs
cat /var/log/start_radioaudace.log
```

### Problème : Le site n'est pas accessible

```bash
# Vérifier Nginx
sudo systemctl status nginx

# Vérifier les certificats SSL
sudo certbot certificates

# Tester localement
curl -I http://localhost

# Vérifier le DNS
nslookup app.radioaudace.com
```

## 🔒 Sécurité

### Permissions du script

```bash
# Le script doit être exécutable par root uniquement
sudo chown root:root /usr/local/bin/start-radioaudace.sh
sudo chmod 750 /usr/local/bin/start-radioaudace.sh
```

### Protection du fichier de log

```bash
# Limiter l'accès en lecture
sudo chmod 640 /var/log/start_radioaudace.log
sudo chown root:adm /var/log/start_radioaudace.log
```

### Rotation des logs

Créez `/etc/logrotate.d/start-radioaudace` :

```bash
/var/log/start_radioaudace.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 640 root adm
}
```

## 📊 Monitoring

### Alertes par email

Ajoutez cette fonction au script :

```bash
send_alert() {
    echo "$1" | mail -s "RadioAudace Startup Alert" admin@example.com
}

# Utilisation
if [ $? -ne 0 ]; then
    send_alert "Erreur lors du démarrage de Nginx"
fi
```

### Intégration avec un système de monitoring

```bash
# Envoyer des métriques à un service (ex: Datadog, Prometheus)
curl -X POST "https://api.monitoring.com/metrics" \
    -d "service=radioaudace&status=started&timestamp=$(date +%s)"
```

## 📚 Cas d'usage

### Scénario 1 : Redémarrage automatique après une panne

Le serveur redémarre automatiquement après une coupure électrique. Le script :
1. Démarre Nginx
2. Vérifie que le build existe
3. Le site est accessible en quelques secondes

### Scénario 2 : Mise à jour système

Après une mise à jour du système nécessitant un reboot :
1. Le serveur redémarre
2. Le script vérifie l'intégrité du build
3. Reconstruit si nécessaire
4. Le site est opérationnel

### Scénario 3 : Déploiement automatique

Avec la mise à jour Git activée :
1. Push du code sur GitHub
2. Redémarrage du serveur (manuel ou planifié)
3. Le script récupère la dernière version
4. Compile et déploie automatiquement

## 🔗 Scripts connexes

- **`init-radioManager-frontend-server.sh`** : Installation initiale du frontend
- **`update_frontend.sh`** : Mise à jour manuelle du frontend
- **`API-setup_server.sh`** : Installation du backend API

## 📞 Support

### Logs à consulter

```bash
# Logs du script
cat /var/log/start_radioaudace.log

# Logs systemd
sudo journalctl -u start-radioaudace.service

# Logs Nginx
sudo tail -f /var/log/nginx/error.log
```

### Commandes de diagnostic

```bash
# Vérifier tous les services
sudo systemctl status nginx
sudo systemctl status start-radioaudace.service

# Tester l'accessibilité
curl -I https://app.radioaudace.com

# Vérifier le build
ls -la /var/www/app-radioaudace/dist/
```

## 📜 Bonnes pratiques

1. **Testez toujours** le script manuellement avant de l'activer au démarrage
2. **Surveillez les logs** régulièrement pour détecter les anomalies
3. **Désactivez la mise à jour Git** en production (préférez un processus de déploiement contrôlé)
4. **Configurez des alertes** pour être notifié en cas d'échec
5. **Documentez** toute modification du script

## 🎓 Améliorations possibles

- Ajouter des notifications Slack/Discord
- Intégrer avec un système de CI/CD
- Ajouter des health checks plus avancés
- Implémenter un système de rollback automatique
- Créer un dashboard de monitoring
