#!/bin/bash

# Script de préparation rapide d'un VPS OVH pour Dokploy
# Usage: sudo bash quick-prepare-vps.sh

set -e

echo "=========================================="
echo "🚀 Préparation VPS OVH pour Dokploy"
echo "=========================================="
echo ""

# Vérifier les privilèges root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Ce script doit être exécuté en tant que root (sudo)"
   exit 1
fi

# Variables par défaut
NEW_USER=${NEW_USER:-"dokploy"}
SSH_PORT=${SSH_PORT:-22}
TIMEZONE=${TIMEZONE:-"Africa/Douala"}  # Timezone par défaut : Douala, Cameroun
CHANGE_SSH_PORT="n"

# Bannière d'information
echo "📌 Configuration par défaut :"
echo "   - Utilisateur système : $NEW_USER"
echo "   - Port SSH : $SSH_PORT (standard)"
echo "   - Fuseau horaire : $TIMEZONE"
echo ""

# Demander si l'utilisateur veut changer le port SSH
read -p "🔧 Voulez-vous changer le port SSH par défaut (22) ? [y/N] " -n 1 -r CHANGE_SSH_PORT
echo ""

if [[ $CHANGE_SSH_PORT =~ ^[Yy]$ ]]; then
    read -p "   Entrez le nouveau port SSH (ex: 2222) : " CUSTOM_SSH_PORT
    if [[ $CUSTOM_SSH_PORT =~ ^[0-9]+$ ]] && [ $CUSTOM_SSH_PORT -ge 1024 ] && [ $CUSTOM_SSH_PORT -le 65535 ]; then
        SSH_PORT=$CUSTOM_SSH_PORT
        echo "   ✅ Port SSH modifié : $SSH_PORT"
    else
        echo "   ⚠️  Port invalide, utilisation du port par défaut : 22"
        SSH_PORT=22
    fi
else
    echo "   ℹ️  Port SSH par défaut conservé : $SSH_PORT"
fi

# Demander confirmation globale
echo ""
echo "📋 Résumé de la configuration :"
echo "   - Utilisateur : $NEW_USER"
echo "   - Port SSH : $SSH_PORT"
echo "   - Fuseau horaire : $TIMEZONE (Douala, Cameroun)"
echo ""
echo "Ce script va :"
echo "  ✅ Mettre à jour le système"
echo "  ✅ Installer les outils essentiels"
echo "  ✅ Créer l'utilisateur '$NEW_USER' avec privilèges sudo"
echo "  ✅ Sécuriser SSH (désactiver root, limiter tentatives)"
echo "  ✅ Configurer UFW (ports $SSH_PORT, 80, 443, 3000)"
echo "  ✅ Installer et configurer Fail2ban"
echo "  ✅ Optimiser les paramètres système pour Docker"
echo ""
read -p "❓ Continuer avec cette configuration ? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Installation annulée"
    exit 1
fi

# Étape 1: Mise à jour système
echo ""
echo "📦 Étape 1/7 : Mise à jour du système..."
apt update -qq
DEBIAN_FRONTEND=noninteractive apt upgrade -y -qq
apt autoremove -y -qq
echo "✅ Système mis à jour"

# Étape 2: Installation outils essentiels
echo ""
echo "🔧 Étape 2/7 : Installation des outils essentiels..."
DEBIAN_FRONTEND=noninteractive apt install -y -qq \
  curl wget git vim nano htop net-tools dnsutils \
  ca-certificates gnupg lsb-release software-properties-common \
  apt-transport-https sudo ufw fail2ban unzip \
  2>&1 | grep -v "^Reading" || true
echo "✅ Outils essentiels installés"

# Étape 3: Configuration fuseau horaire
echo ""
echo "🌍 Étape 3/7 : Configuration fuseau horaire..."
timedatectl set-timezone "$TIMEZONE"
echo "✅ Fuseau horaire défini : $(timedatectl | grep 'Time zone' | awk '{print $3}')"

# Étape 4: Création utilisateur sudo
echo ""
echo "👤 Étape 4/7 : Configuration de l'utilisateur '$NEW_USER'..."
if id "$NEW_USER" &>/dev/null; then
    echo "⚠️  L'utilisateur '$NEW_USER' existe déjà"
    usermod -aG sudo "$NEW_USER" 2>/dev/null || true
    echo "✅ Privilèges sudo vérifiés pour '$NEW_USER'"
else
    adduser --disabled-password --gecos "" "$NEW_USER"
    usermod -aG sudo "$NEW_USER"
    echo "✅ Utilisateur '$NEW_USER' créé avec privilèges sudo"
fi

# Définir un mot de passe pour l'utilisateur
echo ""
echo "🔐 Définition du mot de passe pour '$NEW_USER' :"
echo "   (Utilisez un mot de passe fort : min 16 caractères, lettres+chiffres+symboles)"
passwd "$NEW_USER"

# Étape 5: Sécurisation SSH
echo ""
echo "🔒 Étape 5/7 : Sécurisation SSH..."

# Backup config SSH avec timestamp
BACKUP_FILE="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"
cp /etc/ssh/sshd_config "$BACKUP_FILE"
echo "   📄 Backup créé : $BACKUP_FILE"

# Fonction pour modifier ou ajouter une directive SSH
update_ssh_config() {
    local directive=$1
    local value=$2
    
    if grep -q "^#\?${directive}" /etc/ssh/sshd_config; then
        sed -i "s/^#\?${directive}.*/${directive} ${value}/" /etc/ssh/sshd_config
    else
        echo "${directive} ${value}" >> /etc/ssh/sshd_config
    fi
}

# Modifications SSH de sécurité
update_ssh_config "Port" "$SSH_PORT"
update_ssh_config "PermitRootLogin" "no"
update_ssh_config "MaxAuthTries" "3"
update_ssh_config "ClientAliveInterval" "300"
update_ssh_config "ClientAliveCountMax" "2"
update_ssh_config "Protocol" "2"
update_ssh_config "X11Forwarding" "no"

# Ajouter AllowUsers si pas déjà présent
if ! grep -q "^AllowUsers" /etc/ssh/sshd_config; then
    echo "AllowUsers $NEW_USER" >> /etc/ssh/sshd_config
fi

# Tester la config SSH
if sshd -t 2>/dev/null; then
    echo "✅ Configuration SSH valide"
else
    echo "⚠️  Erreur dans la config SSH, restauration du backup"
    cp "$BACKUP_FILE" /etc/ssh/sshd_config
    exit 1
fi

# Avertissement important
echo ""
echo "⚠️  IMPORTANT - SSH MODIFIÉ MAIS PAS ENCORE REDÉMARRÉ"
echo "   Pour éviter de vous couper l'accès :"
echo "   1. Configurez d'abord vos clés SSH (voir instructions ci-dessous)"
echo "   2. Testez la connexion dans un NOUVEAU terminal"
echo "   3. Puis redémarrez SSH avec : sudo systemctl restart sshd"
if [ "$SSH_PORT" != "22" ]; then
    echo "   4. N'oubliez pas d'utiliser le port $SSH_PORT pour SSH"
fi

# Étape 6: Configuration UFW
echo ""
echo "🛡️  Étape 6/7 : Configuration du pare-feu UFW..."

# Reset UFW pour éviter les conflits
ufw --force reset > /dev/null 2>&1

# Règles par défaut
ufw default deny incoming
ufw default allow outgoing

# Autoriser le port SSH (celui choisi par l'utilisateur)
ufw allow "$SSH_PORT"/tcp comment 'SSH'

# Autoriser HTTP/HTTPS pour Dokploy et applications
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Autoriser le port Dokploy (interface web)
ufw allow 3000/tcp comment 'Dokploy UI'

# Règles supplémentaires pour Docker Swarm (commentées par défaut)
# Décommentez si vous utilisez Docker Swarm en multi-serveurs
# ufw allow 2377/tcp comment 'Docker Swarm'
# ufw allow 7946/tcp comment 'Docker Swarm'
# ufw allow 7946/udp comment 'Docker Swarm'
# ufw allow 4789/udp comment 'Docker Overlay'

# Activer UFW
ufw --force enable

echo "✅ Pare-feu UFW configuré et activé"
echo ""
echo "   📋 Ports ouverts :"
ufw status numbered | grep -E "ALLOW|DENY"

# Étape 7: Configuration Fail2ban
echo ""
echo "🚨 Étape 7/7 : Configuration Fail2ban..."

# Créer une config locale si elle n'existe pas
if [ ! -f /etc/fail2ban/jail.local ]; then
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
# Durée de bannissement (en secondes)
bantime  = 3600

# Fenêtre de temps pour compter les échecs (en secondes)
findtime = 600

# Nombre maximum de tentatives échouées avant bannissement
maxretry = 3

# Actions par défaut
banaction = iptables-multiport
action = %(action_mwl)s

[sshd]
enabled = true
port    = $SSH_PORT
logpath = /var/log/auth.log
maxretry = 3

# Protection Nginx (optionnel, décommenter si nécessaire)
# [nginx-http-auth]
# enabled = true
# port    = 80,443
# logpath = /var/log/nginx/error.log

# [nginx-limit-req]
# enabled = true
# port    = 80,443
# logpath = /var/log/nginx/error.log
EOF
    echo "✅ Configuration Fail2ban créée"
else
    echo "⚠️  /etc/fail2ban/jail.local existe déjà"
    # Vérifier si le port SSH est correct
    if grep -q "^port" /etc/fail2ban/jail.local; then
        sed -i "s/^port.*/port    = $SSH_PORT/" /etc/fail2ban/jail.local
        echo "✅ Port SSH mis à jour dans Fail2ban"
    fi
fi

# Démarrer Fail2ban
systemctl restart fail2ban 2>/dev/null || systemctl start fail2ban
systemctl enable fail2ban
echo "✅ Fail2ban activé et configuré"

# Optimisations système pour Docker
echo ""
echo "⚡ Étape bonus : Optimisations système pour Docker..."

# Vérifier si les paramètres existent déjà
if ! grep -q "# Optimisations pour Docker" /etc/sysctl.conf; then
    cat >> /etc/sysctl.conf << 'EOF'

# === Optimisations pour Docker et Dokploy ===
# Activer le forwarding IP (requis pour Docker)
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Optimisations réseau
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 600

# Limites de fichiers (important pour Docker)
fs.file-max = 65535
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512

# Optimisation mémoire
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF
    sysctl -p > /dev/null 2>&1
    echo "✅ Paramètres kernel optimisés pour Docker"
else
    echo "⚠️  Paramètres système déjà optimisés"
fi

# Augmenter les limites de fichiers ouverts
if ! grep -q "^* soft nofile" /etc/security/limits.conf; then
    cat >> /etc/security/limits.conf << 'EOF'

# Limites pour Docker et Dokploy
*               soft    nofile          65535
*               hard    nofile          65535
root            soft    nofile          65535
root            hard    nofile          65535
EOF
    echo "✅ Limites de fichiers augmentées"
fi

# Créer les répertoires pour Dokploy
echo ""
echo "📁 Création des répertoires Dokploy..."
mkdir -p /opt/dokploy
mkdir -p /var/lib/dokploy
mkdir -p /var/log/dokploy
mkdir -p /backup

# Permissions appropriées
chown -R "$NEW_USER":"$NEW_USER" /opt/dokploy 2>/dev/null || true
echo "✅ Répertoires créés"

# Résumé final avec informations importantes
echo ""
echo "=========================================="
echo "✅ PRÉPARATION TERMINÉE AVEC SUCCÈS !"
echo "=========================================="
echo ""
echo "📊 INFORMATIONS SYSTÈME :"
echo "   - Utilisateur créé : $NEW_USER"
echo "   - Port SSH : $SSH_PORT"
if [ "$SSH_PORT" != "22" ]; then
    echo "     ⚠️  PORT SSH MODIFIÉ ! Utilisez : ssh -p $SSH_PORT"
fi
echo "   - Fuseau horaire : $TIMEZONE"
echo "   - IP publique : $(hostname -I | awk '{print $1}')"
echo "   - Distribution : $(lsb_release -ds)"
echo "   - Kernel : $(uname -r)"
echo ""
echo "🔒 SÉCURITÉ CONFIGURÉE :"
echo "   ✅ Root login désactivé"
echo "   ✅ Pare-feu UFW actif"
echo "   ✅ Fail2ban protège SSH"
echo "   ✅ Limites de tentatives SSH : 3"
echo "   ✅ Ports ouverts : $SSH_PORT, 80, 443, 3000"
echo ""
echo "📋 PROCHAINES ÉTAPES CRITIQUES :"
echo ""
echo "1. 🔑 CONFIGURER L'AUTHENTIFICATION PAR CLÉ SSH"
echo "   Sur votre machine locale, exécutez :"
echo "   ---"
if [ "$SSH_PORT" != "22" ]; then
    echo "   ssh-keygen -t ed25519 -C \"votre-email@example.com\""
    echo "   ssh-copy-id -p $SSH_PORT $NEW_USER@$(hostname -I | awk '{print $1}')"
else
    echo "   ssh-keygen -t ed25519 -C \"votre-email@example.com\""
    echo "   ssh-copy-id $NEW_USER@$(hostname -I | awk '{print $1}')"
fi
echo "   ---"
echo ""
echo "2. 🧪 TESTER LA CONNEXION SSH (NOUVEAU TERMINAL !)"
if [ "$SSH_PORT" != "22" ]; then
    echo "   ssh -p $SSH_PORT $NEW_USER@$(hostname -I | awk '{print $1}')"
else
    echo "   ssh $NEW_USER@$(hostname -I | awk '{print $1}')"
fi
echo "   ⚠️  NE FERMEZ PAS cette session avant d'avoir testé !"
echo ""
echo "3. 🔒 DÉSACTIVER L'AUTHENTIFICATION PAR MOT DE PASSE"
echo "   Si la connexion par clé fonctionne :"
echo "   sudo nano /etc/ssh/sshd_config"
echo "   → Modifier : PasswordAuthentication no"
echo "   → Sauvegarder et quitter"
echo "   sudo systemctl restart sshd"
echo ""
echo "4. 🚀 INSTALLER DOKPLOY"
echo "   En tant qu'utilisateur $NEW_USER :"
echo "   curl -sSL https://dokploy.com/install.sh | sh"
echo ""
echo "5. 🌐 CONFIGURER LES DNS"
echo "   Pointer vos domaines vers : $(hostname -I | awk '{print $1}')"
echo "   Exemples :"
echo "   - dokploy.votre-domaine.com → $(hostname -I | awk '{print $1}')"
echo "   - app.votre-domaine.com → $(hostname -I | awk '{print $1}')"
echo "   - api.votre-domaine.com → $(hostname -I | awk '{print $1}')"
echo ""
echo "6. 🔍 ACCÉDER À DOKPLOY"
echo "   Une fois installé, accédez à :"
echo "   https://$(hostname -I | awk '{print $1}'):3000"
echo "   ou"
echo "   https://dokploy.votre-domaine.com:3000"
echo ""
echo "🛠️  COMMANDES UTILES :"
echo "   sudo ufw status verbose          # État du pare-feu"
echo "   sudo fail2ban-client status sshd # Bannissements SSH"
echo "   sudo systemctl status sshd       # État du service SSH"
echo "   df -h                            # Espace disque"
echo "   free -h                          # Mémoire disponible"
echo "   htop                             # Moniteur de ressources"
if [ "$SSH_PORT" != "22" ]; then
    echo "   sudo ss -tlnp | grep $SSH_PORT       # Vérifier que SSH écoute sur le port $SSH_PORT"
fi
echo ""
echo "📚 DOCUMENTATION :"
echo "   - Préparation VPS : Docker/dockploy-deployment/PREPARATION-VPS-OVH.md"
echo "   - Guide Dokploy : Docker/dockploy-deployment/README.md"
echo "   - Variables d'environnement : Docker/dockploy-deployment/VARIABLES-GUIDE.md"
echo ""
echo "⚠️  RAPPEL IMPORTANT :"
echo "   - Backup de la config SSH : $BACKUP_FILE"
echo "   - Ne redémarrez SSH qu'APRÈS avoir testé les clés SSH !"
echo "   - Gardez cette session ouverte en backup de secours"
echo ""
echo "🎉 Votre VPS est maintenant prêt pour Dokploy !"
echo "=========================================="
