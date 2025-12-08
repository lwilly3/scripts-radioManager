# update_frontend.sh - Documentation

## 📋 Vue d'ensemble

Ce script automatise la **mise à jour du frontend** d'un site web hébergé sur un serveur. Il récupère les dernières modifications depuis un dépôt Git, recompile le projet avec Vite, et redémarre Nginx pour appliquer les changements.

## 🎯 Objectif

Effectuer une mise à jour complète du frontend en :
- Récupérant le code depuis Git (dernières modifications)
- Installant les nouvelles dépendances npm
- Recompilant avec Vite
- Redémarrant Nginx
- Enregistrant les opérations dans un fichier log

## 📦 Prérequis

- Frontend déjà installé (via `init-radioManager-frontend-server.sh`)
- Dépôt Git initialisé dans le répertoire du site
- Node.js et npm installés
- Nginx configuré
- Privilèges sudo pour redémarrer Nginx

## ⚙️ Variables de configuration

```bash
# Domaine du site web
DOMAIN="app.radioaudace.com"

# Répertoire où le site est hébergé
SITE_DIR="/var/www/app-radioaudace"

# URL du dépôt Git
GIT_REPO="https://github.com/lwilly3/radioManager-SaaS"

# Dossier généré par la compilation
BUILD_DIR="dist"

# Nom de l'utilisateur exécutant le script
USER=$(whoami)

# Fichier de log pour enregistrer les événements
LOG_FILE="/var/log/update_frontend.log"
```

## 🚀 Utilisation

### Exécution manuelle

```bash
# Télécharger le script
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/radioManager/update_frontend.sh -O update_frontend.sh

# Rendre exécutable
chmod +x update_frontend.sh

# Exécuter
sudo bash update_frontend.sh
```

### Automatisation avec cron

Pour des mises à jour régulières :

```bash
# Éditer le crontab
sudo crontab -e

# Ajouter une mise à jour quotidienne à 3h du matin
0 3 * * * /usr/local/bin/update_frontend.sh >> /var/log/update_frontend.log 2>&1

# Ou une mise à jour hebdomadaire (dimanche à 2h)
0 2 * * 0 /usr/local/bin/update_frontend.sh >> /var/log/update_frontend.log 2>&1
```

### Via webhook GitHub

Configuration d'un endpoint pour déploiement automatique après un push :

```bash
# Installer webhook
sudo apt install webhook -y

# Créer la configuration
sudo nano /etc/webhook.conf
```

```json
[
  {
    "id": "update-frontend",
    "execute-command": "/usr/local/bin/update_frontend.sh",
    "command-working-directory": "/var/www/app-radioaudace",
    "response-message": "Mise à jour en cours..."
  }
]
```

## 📝 Processus de mise à jour

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

### 3. Vérification du dépôt Git

```bash
cd "$SITE_DIR"
if [ ! -d ".git" ]; then
    log "Erreur : $SITE_DIR n'est pas un dépôt Git."
    exit 1
fi
```

### 4. Récupération des modifications Git

```bash
log "Récupération des dernières modifications depuis $GIT_REPO..."
git fetch origin
git pull origin main
```

Récupère et applique les dernières modifications de la branche `main`.

### 5. Installation des dépendances

```bash
log "Installation des dépendances npm..."
npm install
```

Installe les nouvelles dépendances ou met à jour les existantes.

### 6. Compilation avec Vite

```bash
log "Recompilation avec Vite..."
npm run build
```

Génère les fichiers statiques optimisés dans le dossier `dist/`.

### 7. Vérification du build

```bash
if [ ! -d "$SITE_DIR/$BUILD_DIR" ]; then
    log "Erreur : le dossier $BUILD_DIR n'a pas été créé."
    exit 1
fi
```

### 8. Redémarrage de Nginx

```bash
log "Redémarrage de Nginx..."
systemctl restart nginx
```

Applique les modifications en redémarrant le serveur web.

### 9. Confirmation

```bash
log "Mise à jour terminée avec succès ! Site accessible à https://$DOMAIN."
```

## 📂 Structure du script complet

```bash
#!/bin/bash

# Script de mise à jour du frontend
# Usage: sudo bash update_frontend.sh

DOMAIN="app.radioaudace.com"
SITE_DIR="/var/www/app-radioaudace"
GIT_REPO="https://github.com/lwilly3/radioManager-SaaS"
BUILD_DIR="dist"
USER=$(whoami)
LOG_FILE="/var/log/update_frontend.log"

# Fonction de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Vérification des privilèges root
if [ "$EUID" -ne 0 ]; then
    log "Erreur : Ce script doit être exécuté avec sudo ou en tant que root."
    exit 1
fi

# Vérification du répertoire
if [ ! -d "$SITE_DIR" ]; then
    log "Erreur : Le répertoire $SITE_DIR n'existe pas."
    exit 1
fi

cd "$SITE_DIR"

# Vérification Git
if [ ! -d ".git" ]; then
    log "Erreur : $SITE_DIR n'est pas un dépôt Git."
    exit 1
fi

# Mise à jour Git
log "Récupération des dernières modifications depuis $GIT_REPO..."
git fetch origin
git pull origin main
if [ $? -ne 0 ]; then
    log "Erreur lors de la mise à jour du dépôt Git."
    exit 1
fi

# Installation des dépendances
log "Installation des dépendances npm et recompilation avec Vite..."
npm install
npm run build

# Vérification du build
if [ ! -d "$SITE_DIR/$BUILD_DIR" ]; then
    log "Erreur : le dossier $BUILD_DIR n'a pas été créé."
    exit 1
fi

# Redémarrage Nginx
log "Redémarrage de Nginx..."
systemctl restart nginx
if [ $? -ne 0 ]; then
    log "Erreur lors du redémarrage de Nginx."
    exit 1
fi

log "Mise à jour terminée avec succès ! Site accessible à https://$DOMAIN."
```

## 🔍 Vérification après mise à jour

### Consulter les logs

```bash
# Afficher les logs de mise à jour
cat /var/log/update_frontend.log

# Suivre en temps réel
tail -f /var/log/update_frontend.log
```

### Vérifier le site

```bash
# Test HTTP
curl -I https://app.radioaudace.com

# Test du contenu
curl https://app.radioaudace.com | grep -i "title"
```

### Vérifier Nginx

```bash
# Statut du service
sudo systemctl status nginx

# Logs Nginx
sudo tail -f /var/log/nginx/error.log
```

## 🎯 Cas d'usage

### Scénario 1 : Mise à jour manuelle après développement

```bash
# Développeur push le code sur GitHub
git push origin main

# Sur le serveur, exécuter le script
sudo bash update_frontend.sh

# Le site est mis à jour en quelques secondes
```

### Scénario 2 : Déploiement continu (CI/CD)

Avec GitHub Actions :

```yaml
name: Deploy Frontend

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_KEY }}
          script: sudo /usr/local/bin/update_frontend.sh
```

### Scénario 3 : Rollback rapide

```bash
# Revenir à une version antérieure
cd /var/www/app-radioaudace
git log --oneline  # Voir l'historique
git checkout <commit-hash>
npm install
npm run build
sudo systemctl restart nginx
```

## 🛡️ Sécurité

### Gestion des erreurs améliorée

```bash
set -e  # Arrêter en cas d'erreur

# Sauvegarder avant mise à jour
BACKUP_DIR="/var/backups/frontend"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
tar -czf "$BACKUP_DIR/frontend-$TIMESTAMP.tar.gz" "$SITE_DIR/dist"

# Restauration en cas d'échec
trap 'restore_backup' ERR

restore_backup() {
    log "Erreur détectée, restauration du backup..."
    tar -xzf "$BACKUP_DIR/frontend-$TIMESTAMP.tar.gz" -C "$SITE_DIR"
    systemctl restart nginx
}
```

### Notifications

```bash
# Notification par email
send_notification() {
    echo "$1" | mail -s "Frontend Update" admin@example.com
}

# Notification Slack
notify_slack() {
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$1\"}" \
        "$SLACK_WEBHOOK_URL"
}
```

## 🔧 Personnalisation

### Mise à jour d'une branche spécifique

```bash
BRANCH="develop"
git pull origin $BRANCH
```

### Nettoyer avant la mise à jour

```bash
# Supprimer les fichiers non suivis
git clean -fd

# Réinitialiser les modifications locales
git reset --hard origin/main
```

### Mise à jour avec tests

```bash
# Exécuter les tests avant le build
npm run test
if [ $? -ne 0 ]; then
    log "Tests échoués, annulation de la mise à jour"
    exit 1
fi

npm run build
```

### Mode verbose

```bash
# Afficher plus d'informations
npm run build -- --debug
```

## ⚠️ Dépannage

### Problème : Conflits Git

```bash
# Réinitialiser le dépôt local
cd /var/www/app-radioaudace
git reset --hard origin/main
git pull origin main
```

### Problème : Erreur npm install

```bash
# Nettoyer et réinstaller
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

### Problème : Build échoue

```bash
# Vérifier Node.js
node --version  # Doit être >= 18

# Vérifier l'espace disque
df -h

# Augmenter la mémoire Node.js
export NODE_OPTIONS="--max-old-space-size=4096"
npm run build
```

### Problème : Nginx ne redémarre pas

```bash
# Tester la configuration
sudo nginx -t

# Voir les erreurs
sudo journalctl -u nginx -n 50
```

## 📊 Monitoring

### Historique des mises à jour

```bash
# Voir l'historique complet
cat /var/log/update_frontend.log

# Filtrer les erreurs
grep "Erreur" /var/log/update_frontend.log

# Statistiques
grep "Mise à jour terminée" /var/log/update_frontend.log | wc -l
```

### Dashboard de déploiement

Créez un script de monitoring :

```bash
#!/bin/bash
echo "=== Statut du déploiement ==="
echo "Dernière mise à jour :"
tail -1 /var/log/update_frontend.log
echo ""
echo "Version déployée :"
cd /var/www/app-radioaudace && git log -1 --oneline
echo ""
echo "Statut Nginx :"
systemctl is-active nginx
```

## 🚀 Optimisations

### Cache NPM

```bash
# Utiliser un cache NPM local
npm config set cache /var/cache/npm --global
```

### Builds parallèles

```bash
# Utiliser plusieurs CPU pour le build
npm run build -- --parallel
```

### Préchargement des dépendances

```bash
# Installer les dépendances avant le pull
npm ci  # Installation propre depuis package-lock.json
```

## 🔗 Intégration CI/CD

### GitLab CI

```yaml
deploy:
  stage: deploy
  script:
    - ssh user@server "sudo /usr/local/bin/update_frontend.sh"
  only:
    - main
```

### Jenkins

```groovy
pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                sh 'ssh user@server "sudo /usr/local/bin/update_frontend.sh"'
            }
        }
    }
}
```

## 📚 Ressources

- [Documentation Git](https://git-scm.com/doc)
- [Documentation npm](https://docs.npmjs.com/)
- [Documentation Vite](https://vitejs.dev/)
- [Best practices déploiement](https://vitejs.dev/guide/build.html)

## 📞 Support

En cas de problème :
1. Consultez les logs : `cat /var/log/update_frontend.log`
2. Vérifiez Git : `cd /var/www/app-radioaudace && git status`
3. Testez le build : `npm run build`
4. Vérifiez Nginx : `sudo nginx -t`

## 📋 Checklist post-mise à jour

- [ ] Code récupéré depuis Git
- [ ] Dépendances installées
- [ ] Build réussi
- [ ] Nginx redémarré
- [ ] Site accessible
- [ ] Aucune erreur dans les logs
- [ ] Fonctionnalités testées

## 📜 Bonnes pratiques

1. **Toujours tester** en environnement de développement d'abord
2. **Sauvegarder** avant chaque mise à jour
3. **Planifier** les mises à jour pendant les heures creuses
4. **Documenter** les changements
5. **Monitorer** les logs après déploiement
6. **Avoir un plan de rollback** en cas de problème
