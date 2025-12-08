# Script_MAJ_N8N.sh - Documentation

## 📋 Vue d'ensemble

Ce script automatise la **mise à jour de N8N** sur une instance EC2 Amazon Linux ou tout serveur Linux. Il permet de passer à la dernière version de N8N de manière sécurisée avec sauvegarde automatique.

## 🎯 Objectif

Effectuer une mise à jour de N8N en :
- Créant une sauvegarde avant la mise à jour
- Arrêtant le service N8N proprement
- Mettant à jour les packages npm
- Redémarrant le service
- Vérifiant le bon fonctionnement
- Conservant un rollback possible en cas de problème

## 📦 Prérequis

- N8N déjà installé (via `Script_installation_N8N_sur_EC2_AmazonLinux.sh`)
- Accès SSH avec privilèges sudo
- Service systemd configuré pour N8N
- Espace disque suffisant pour la sauvegarde

## ⚙️ Variables de configuration

```bash
# Répertoire d'installation de N8N
N8N_DIR="/opt/n8n"

# Répertoire de sauvegarde
BACKUP_DIR="/opt/n8n-backups"

# Nom du service systemd
SERVICE_NAME="n8n"

# Conserver les X dernières sauvegardes
KEEP_BACKUPS=5
```

## 🚀 Utilisation

### Exécution simple

```bash
# Télécharger le script
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/N8N/Script_MAJ_N8N.sh -O update_n8n.sh

# Rendre exécutable
chmod +x update_n8n.sh

# Exécuter
sudo bash update_n8n.sh
```

### Automatisation avec cron

Pour des mises à jour automatiques (à utiliser avec précaution) :

```bash
# Éditer le crontab
sudo crontab -e

# Ajouter une mise à jour hebdomadaire (dimanche à 3h du matin)
0 3 * * 0 /usr/local/bin/update_n8n.sh >> /var/log/n8n-update.log 2>&1
```

## 📝 Processus de mise à jour

### 1. Vérifications préalables

```bash
# Vérifier que N8N est installé
if [ ! -d "$N8N_DIR" ]; then
    echo "N8N n'est pas installé dans $N8N_DIR"
    exit 1
fi

# Vérifier la version actuelle
CURRENT_VERSION=$(cd $N8N_DIR && npm list n8n --depth=0 | grep n8n@ | awk '{print $2}')
echo "Version actuelle : $CURRENT_VERSION"
```

### 2. Sauvegarde automatique

```bash
# Créer le répertoire de sauvegarde
mkdir -p $BACKUP_DIR

# Nom de la sauvegarde avec timestamp
BACKUP_NAME="n8n-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

# Arrêter N8N
systemctl stop n8n

# Créer l'archive
tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C /opt n8n

# Vérifier la sauvegarde
if [ -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
    echo "✓ Sauvegarde créée : $BACKUP_NAME"
else
    echo "✗ Erreur lors de la sauvegarde"
    exit 1
fi
```

### 3. Mise à jour de N8N

```bash
cd $N8N_DIR

# Mise à jour de N8N
npm update n8n

# Ou installation de la dernière version spécifique
npm install n8n@latest

# Vérifier la nouvelle version
NEW_VERSION=$(npm list n8n --depth=0 | grep n8n@ | awk '{print $2}')
echo "Nouvelle version : $NEW_VERSION"
```

### 4. Redémarrage du service

```bash
# Redémarrer N8N
systemctl start n8n

# Attendre le démarrage complet
sleep 10

# Vérifier le statut
systemctl status n8n

# Vérifier que N8N répond
curl -s http://localhost:5678 > /dev/null
if [ $? -eq 0 ]; then
    echo "✓ N8N est opérationnel"
else
    echo "✗ N8N ne répond pas"
    exit 1
fi
```

### 5. Nettoyage des anciennes sauvegardes

```bash
# Conserver seulement les X dernières sauvegardes
cd $BACKUP_DIR
ls -t n8n-backup-*.tar.gz | tail -n +$((KEEP_BACKUPS + 1)) | xargs -r rm
```

## 🔄 Script complet

Voici un exemple de script complet :

```bash
#!/bin/bash

# Script de mise à jour N8N avec sauvegarde
# Usage: sudo bash Script_MAJ_N8N.sh

set -e  # Arrêter en cas d'erreur

# Configuration
N8N_DIR="/opt/n8n"
BACKUP_DIR="/opt/n8n-backups"
SERVICE_NAME="n8n"
KEEP_BACKUPS=5

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Mise à jour de N8N ===${NC}"

# Vérification des privilèges
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Ce script doit être exécuté avec sudo${NC}"
   exit 1
fi

# Vérification de l'installation
if [ ! -d "$N8N_DIR" ]; then
    echo -e "${RED}N8N n'est pas installé dans $N8N_DIR${NC}"
    exit 1
fi

# Version actuelle
cd $N8N_DIR
CURRENT_VERSION=$(npm list n8n --depth=0 2>/dev/null | grep n8n@ | awk '{print $2}' || echo "inconnu")
echo -e "${YELLOW}Version actuelle : $CURRENT_VERSION${NC}"

# Création du répertoire de sauvegarde
mkdir -p $BACKUP_DIR

# Sauvegarde
echo -e "${YELLOW}Création de la sauvegarde...${NC}"
BACKUP_NAME="n8n-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

systemctl stop n8n
tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C /opt n8n

if [ -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
    echo -e "${GREEN}✓ Sauvegarde créée : $BACKUP_NAME${NC}"
else
    echo -e "${RED}✗ Erreur lors de la sauvegarde${NC}"
    systemctl start n8n
    exit 1
fi

# Mise à jour
echo -e "${YELLOW}Mise à jour de N8N...${NC}"
cd $N8N_DIR
npm update n8n

# Nouvelle version
NEW_VERSION=$(npm list n8n --depth=0 2>/dev/null | grep n8n@ | awk '{print $2}' || echo "inconnu")
echo -e "${GREEN}Nouvelle version : $NEW_VERSION${NC}"

# Redémarrage
echo -e "${YELLOW}Redémarrage de N8N...${NC}"
systemctl start n8n
sleep 10

# Vérification
if systemctl is-active --quiet n8n; then
    echo -e "${GREEN}✓ N8N est actif${NC}"
else
    echo -e "${RED}✗ N8N ne s'est pas démarré correctement${NC}"
    echo -e "${YELLOW}Restauration de la sauvegarde...${NC}"
    systemctl stop n8n
    rm -rf $N8N_DIR
    tar -xzf "$BACKUP_DIR/$BACKUP_NAME" -C /opt
    systemctl start n8n
    exit 1
fi

# Test HTTP
curl -s http://localhost:5678 > /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ N8N répond correctement${NC}"
else
    echo -e "${RED}✗ N8N ne répond pas sur le port 5678${NC}"
fi

# Nettoyage des anciennes sauvegardes
echo -e "${YELLOW}Nettoyage des anciennes sauvegardes...${NC}"
cd $BACKUP_DIR
ls -t n8n-backup-*.tar.gz | tail -n +$((KEEP_BACKUPS + 1)) | xargs -r rm
echo -e "${GREEN}✓ Conservation des $KEEP_BACKUPS dernières sauvegardes${NC}"

echo -e "${GREEN}=== Mise à jour terminée avec succès ===${NC}"
echo -e "${YELLOW}De $CURRENT_VERSION vers $NEW_VERSION${NC}"
```

## 🔍 Vérification après mise à jour

### Vérifier le service

```bash
# Statut du service
sudo systemctl status n8n

# Logs en temps réel
sudo journalctl -u n8n -f
```

### Vérifier l'interface web

```bash
# Test local
curl -I http://localhost:5678

# Test depuis l'extérieur
curl -I https://n8n.votre-domaine.com
```

### Vérifier la version

Accédez à l'interface web N8N :
- Cliquez sur votre avatar (en bas à gauche)
- La version est affichée dans le menu

## 🔙 Restauration d'une sauvegarde

En cas de problème après la mise à jour :

```bash
# Lister les sauvegardes disponibles
ls -lh /opt/n8n-backups/

# Arrêter N8N
sudo systemctl stop n8n

# Restaurer une sauvegarde
sudo rm -rf /opt/n8n
sudo tar -xzf /opt/n8n-backups/n8n-backup-YYYYMMDD-HHMMSS.tar.gz -C /opt

# Redémarrer
sudo systemctl start n8n

# Vérifier
sudo systemctl status n8n
```

## 📊 Surveillance

### Logs de mise à jour

Pour suivre l'historique des mises à jour :

```bash
# Rediriger la sortie vers un fichier log
sudo bash Script_MAJ_N8N.sh 2>&1 | tee -a /var/log/n8n-updates.log

# Consulter l'historique
cat /var/log/n8n-updates.log
```

### Notifications

Ajoutez des notifications par email ou Slack :

```bash
# Exemple avec mail
echo "N8N mis à jour de $CURRENT_VERSION vers $NEW_VERSION" | \
    mail -s "N8N Mise à jour" admin@votre-domaine.com

# Exemple avec Slack webhook
curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"N8N mis à jour: $CURRENT_VERSION → $NEW_VERSION\"}" \
    https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

## ⚠️ Dépannage

### Problème : La mise à jour échoue

```bash
# Vérifier l'espace disque
df -h /opt

# Vérifier les permissions
ls -la /opt/n8n

# Vérifier npm
npm --version
node --version
```

### Problème : N8N ne redémarre pas

```bash
# Consulter les logs
sudo journalctl -u n8n -n 100 --no-pager

# Tester manuellement
cd /opt/n8n
sudo -u n8n node node_modules/n8n/bin/n8n start
```

### Problème : Perte de données

Les workflows et credentials sont sauvegardés dans `.n8n/` :

```bash
# Vérifier le contenu de la sauvegarde
tar -tzf /opt/n8n-backups/n8n-backup-*.tar.gz | grep .n8n
```

## 🔐 Sécurité

### Sauvegarder sur S3 (AWS)

```bash
# Copier la sauvegarde vers S3
aws s3 cp "$BACKUP_DIR/$BACKUP_NAME" s3://votre-bucket/n8n-backups/

# Avec chiffrement
aws s3 cp "$BACKUP_DIR/$BACKUP_NAME" s3://votre-bucket/n8n-backups/ \
    --sse AES256
```

### Chiffrer les sauvegardes locales

```bash
# Chiffrer avec GPG
gpg --symmetric --cipher-algo AES256 "$BACKUP_DIR/$BACKUP_NAME"

# Déchiffrer
gpg --decrypt "$BACKUP_DIR/$BACKUP_NAME.gpg" > "$BACKUP_DIR/$BACKUP_NAME"
```

## 📚 Ressources

- [N8N Changelog](https://github.com/n8n-io/n8n/releases)
- [Guide de mise à jour N8N](https://docs.n8n.io/hosting/installation/updating/)
- [Forum N8N](https://community.n8n.io/)

## 📋 Checklist post-mise à jour

- [ ] Service N8N actif
- [ ] Interface web accessible
- [ ] Workflows existants fonctionnels
- [ ] Credentials préservés
- [ ] Webhooks toujours actifs
- [ ] Logs sans erreur critique
- [ ] Sauvegarde créée et vérifiée
- [ ] Documentation mise à jour

## 📞 Support

En cas de problème :
1. Consultez les logs : `sudo journalctl -u n8n -f`
2. Vérifiez la sauvegarde : `ls -lh /opt/n8n-backups/`
3. Restaurez si nécessaire
4. Contactez la communauté N8N

## 📜 Notes importantes

- Testez toujours les mises à jour en environnement de développement d'abord
- Faites des sauvegardes manuelles avant les mises à jour majeures
- Consultez le changelog avant de mettre à jour
- Planifiez les mises à jour pendant les périodes de faible activité
