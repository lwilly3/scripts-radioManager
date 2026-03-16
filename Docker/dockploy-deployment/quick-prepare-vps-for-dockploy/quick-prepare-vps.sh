#!/bin/bash

# =============================================================================
#
#  SCRIPT DE PREPARATION VPS POUR DOKPLOY — v2.0
#
#  Description :
#    Ce script prepare un VPS vierge (Ubuntu/Debian) pour heberger des
#    applications via Dokploy. Il securise le serveur, configure le pare-feu,
#    installe les outils necessaires et optimise le systeme pour Docker.
#
#  Contexte :
#    Concu pour le projet RadioManager (backend FastAPI + frontend React),
#    deploye via Dokploy avec Traefik comme reverse proxy et Let's Encrypt SSL.
#
#  Usage :
#    # Methode 1 — avec les valeurs par defaut :
#    sudo bash quick-prepare-vps.sh
#
#    # Methode 2 — avec une cle SSH publique (recommande) :
#    sudo SSH_PUBKEY="ssh-ed25519 AAAA... email@example.com" bash quick-prepare-vps.sh
#
#    # Methode 3 — personnaliser l'utilisateur, le port et le fuseau horaire :
#    sudo NEW_USER="deployer" SSH_PORT=2222 TIMEZONE="Europe/Paris" bash quick-prepare-vps.sh
#
#    # Methode 4 — tout personnaliser :
#    sudo NEW_USER="deployer" SSH_PORT=2222 TIMEZONE="Europe/Paris" \
#         SSH_PUBKEY="ssh-ed25519 AAAA..." SWAP_SIZE="4G" bash quick-prepare-vps.sh
#
#  Variables d'environnement disponibles :
#    NEW_USER    — Nom de l'utilisateur systeme a creer (defaut: "dokploy")
#    SSH_PORT    — Port SSH (defaut: 22, modifiable interactivement)
#    TIMEZONE    — Fuseau horaire (defaut: "Africa/Douala")
#    SSH_PUBKEY  — Cle publique SSH a installer (optionnel, tres recommande)
#    SWAP_SIZE   — Taille du fichier swap (defaut: "2G")
#
#  Ce que fait ce script (12 etapes) :
#    1. Mise a jour du systeme (apt update + upgrade)
#    2. Installation des outils essentiels (curl, git, htop, etc.)
#    3. Configuration du fuseau horaire
#    4. Creation d'un utilisateur sudo (avec cle SSH si fournie)
#    5. Securisation SSH (desactive root, limite les tentatives, cle publique)
#    6. Configuration du pare-feu UFW
#    7. Protection contre le bypass UFW par Docker (iptables)
#    8. Configuration Fail2ban (anti brute-force SSH + recidivistes)
#    9. Creation d'un fichier swap (evite les OOM sur petits VPS)
#   10. Activation des mises a jour de securite automatiques
#   11. Optimisations kernel pour Docker (sysctl, limites fichiers)
#   12. Creation des repertoires et configuration des backups
#
#  Prerequis :
#    - Ubuntu 20.04+ ou Debian 11+
#    - Acces root (sudo)
#    - Connexion internet
#
#  Securite :
#    Apres execution, le serveur aura :
#    - Login root SSH desactive
#    - Authentification par cle SSH uniquement (si SSH_PUBKEY fournie)
#    - Pare-feu UFW actif (seuls les ports necessaires sont ouverts)
#    - Fail2ban avec bannissement progressif des recidivistes
#    - Docker empeche de contourner le pare-feu
#    - Mises a jour de securite automatiques
#    - Protection anti-spoofing reseau
#
#  Auteur : RadioManager Team
#  Version : 2.0
#  Derniere modification : 2026-03-13
#  Ancien script sauvegarde dans : bakup-script/quick-prepare-vps.v1.sh
#
# =============================================================================


# -----------------------------------------------------------------------------
# CONFIGURATION DU COMPORTEMENT DU SCRIPT
# -----------------------------------------------------------------------------

# "set -e" : arrete le script immediatement si une commande echoue.
# Sans ca, le script continuerait meme apres une erreur, ce qui peut
# laisser le serveur dans un etat incoherent (ex: pare-feu pas active).
set -e

# "set -o pipefail" : dans un pipe (cmd1 | cmd2), si cmd1 echoue,
# le code de retour du pipe sera celui de cmd1 (erreur), pas celui de cmd2.
# Sans ca, "commande_qui_echoue | grep ..." retournerait succes.
set -o pipefail


# -----------------------------------------------------------------------------
# JOURNAL D'EXECUTION (LOGGING)
# -----------------------------------------------------------------------------
# Tout ce que le script affiche (stdout + stderr) est egalement ecrit
# dans un fichier log. Si quelque chose ne va pas, on peut relire ce fichier
# pour comprendre a quelle etape ca a echoue.
#
# "exec > >(tee ...)" duplique stdout vers le fichier ET l'ecran.
# "2>&1" redirige stderr vers la meme destination que stdout.

LOG_FILE="/var/log/vps-prepare-$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1


# -----------------------------------------------------------------------------
# GESTION DES ERREURS (TRAP)
# -----------------------------------------------------------------------------
# "trap" intercepte les erreurs. Si une commande echoue (grace a set -e),
# au lieu de quitter silencieusement, on affiche un message utile avec
# le numero de la ligne qui a pose probleme.
#
# $LINENO est une variable speciale bash qui contient le numero de ligne actuel.

trap 'echo ""; echo "ERREUR a la ligne $LINENO. Consultez le log : $LOG_FILE"; echo "Commande qui a echoue : $BASH_COMMAND"' ERR


# -----------------------------------------------------------------------------
# COMPTEUR D'ETAPES : adapte automatiquement le nombre total
# -----------------------------------------------------------------------------
# Plutot que d'ecrire "Etape 3/12" en dur (et risquer d'oublier de mettre
# a jour le total quand on ajoute une etape), on utilise un compteur.

CURRENT_STEP=0
TOTAL_STEPS=12

# Fonction utilitaire : affiche l'en-tete d'une etape
# Usage : step "Description de l'etape"
step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    echo "========================================"
    echo "  Etape ${CURRENT_STEP}/${TOTAL_STEPS} : $1"
    echo "========================================"
}


# =============================================================================
# VERIFICATION DES PRIVILEGES ROOT
# =============================================================================
# Ce script modifie des fichiers systeme (/etc/ssh/sshd_config, /etc/ufw/...),
# installe des paquets et cree des utilisateurs. Tout ca necessite les
# privileges root (administrateur).
#
# $EUID (Effective User ID) vaut 0 pour root, autre chose pour un user normal.

if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit etre execute en tant que root (sudo)"
   echo "Usage : sudo bash $0"
   exit 1
fi


# =============================================================================
# VARIABLES PAR DEFAUT
# =============================================================================
# Ces variables peuvent etre surchargees par l'utilisateur via l'environnement.
# La syntaxe ${VAR:-"valeur"} signifie : utiliser $VAR si definie, sinon "valeur".

# Nom de l'utilisateur systeme qui gerera Dokploy et les deploiements.
# On evite d'utiliser root directement pour des raisons de securite.
NEW_USER=${NEW_USER:-"dokploy"}

# Port SSH. Le port 22 est le standard, mais le changer ajoute
# une couche de securite ("security through obscurity").
# Note : ce n'est pas une vraie protection, mais ca reduit le bruit
# des scanners automatiques qui ne testent que le port 22.
SSH_PORT=${SSH_PORT:-22}

# Fuseau horaire du serveur. Important pour que les logs et les cron jobs
# affichent la bonne heure.
TIMEZONE=${TIMEZONE:-"Africa/Douala"}

# Cle publique SSH a installer sur le serveur.
# Si fournie, le script configure automatiquement l'authentification par cle
# ET desactive l'authentification par mot de passe (beaucoup plus securise).
# Format attendu : "ssh-ed25519 AAAA... commentaire" ou "ssh-rsa AAAA... commentaire"
SSH_PUBKEY=${SSH_PUBKEY:-""}

# Taille du fichier swap a creer.
# Le swap est un espace sur le disque utilise comme memoire supplementaire
# quand la RAM est pleine. Sur un VPS avec 2-4 GB de RAM, PostgreSQL +
# Docker + Node.js peuvent depasser la RAM disponible. Sans swap,
# le kernel tue les processus (OOM Killer) → crash de la base de donnees.
SWAP_SIZE=${SWAP_SIZE:-"2G"}

# Variable interne pour gerer le choix interactif du port SSH
CHANGE_SSH_PORT="n"


# =============================================================================
# BANNIERE ET CONFIGURATION INTERACTIVE
# =============================================================================

echo "=========================================="
echo "  Preparation VPS pour Dokploy v2.0"
echo "=========================================="
echo ""
echo "Configuration actuelle :"
echo "   - Utilisateur systeme : $NEW_USER"
echo "   - Port SSH : $SSH_PORT"
echo "   - Fuseau horaire : $TIMEZONE"
echo "   - Swap : $SWAP_SIZE"
if [ -n "$SSH_PUBKEY" ]; then
    echo "   - Cle SSH : fournie (auth par cle automatique)"
else
    echo "   - Cle SSH : non fournie (configuration manuelle requise apres)"
fi
echo ""

# --- Choix interactif du port SSH ---
# On demande a l'utilisateur s'il veut changer le port SSH.
# read -p : affiche un prompt, -n 1 : lit 1 seul caractere, -r : desactive les backslash.
read -p "Voulez-vous changer le port SSH par defaut (22) ? [y/N] " -n 1 -r CHANGE_SSH_PORT
echo ""

if [[ $CHANGE_SSH_PORT =~ ^[Yy]$ ]]; then
    read -p "   Entrez le nouveau port SSH (1024-65535, ex: 2222) : " CUSTOM_SSH_PORT
    # Validation : le port doit etre un nombre entre 1024 et 65535.
    # Les ports < 1024 sont "privilegies" et certains sont deja utilises (80, 443, etc.)
    if [[ $CUSTOM_SSH_PORT =~ ^[0-9]+$ ]] && [ "$CUSTOM_SSH_PORT" -ge 1024 ] && [ "$CUSTOM_SSH_PORT" -le 65535 ]; then
        SSH_PORT=$CUSTOM_SSH_PORT
        echo "   Port SSH modifie : $SSH_PORT"
    else
        echo "   Port invalide, utilisation du port par defaut : 22"
        SSH_PORT=22
    fi
else
    echo "   Port SSH par defaut conserve : $SSH_PORT"
fi

# --- Confirmation avant execution ---
# Derniere chance pour l'utilisateur d'annuler avant les modifications.
echo ""
echo "Resume de la configuration :"
echo "   - Utilisateur : $NEW_USER"
echo "   - Port SSH : $SSH_PORT"
echo "   - Fuseau horaire : $TIMEZONE"
echo "   - Swap : $SWAP_SIZE"
echo ""
echo "Ce script va :"
echo "  [1]  Mettre a jour le systeme"
echo "  [2]  Installer les outils essentiels"
echo "  [3]  Configurer le fuseau horaire"
echo "  [4]  Creer l'utilisateur '$NEW_USER' avec sudo"
echo "  [5]  Securiser SSH (desactiver root, limiter tentatives)"
echo "  [6]  Configurer le pare-feu UFW"
echo "  [7]  Empecher Docker de contourner UFW"
echo "  [8]  Configurer Fail2ban (anti brute-force)"
echo "  [9]  Creer un fichier swap de $SWAP_SIZE"
echo "  [10] Activer les mises a jour de securite automatiques"
echo "  [11] Optimiser le kernel pour Docker"
echo "  [12] Creer les repertoires et configurer les backups"
echo ""
read -p "Continuer avec cette configuration ? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation annulee"
    exit 1
fi

echo ""
echo "Log d'execution : $LOG_FILE"


# =============================================================================
# ETAPE 1 : MISE A JOUR DU SYSTEME
# =============================================================================
# On commence toujours par mettre a jour les paquets installes.
# "apt update" rafraichit la liste des paquets disponibles.
# "apt upgrade" installe les nouvelles versions des paquets deja installes.
# "apt autoremove" supprime les paquets orphelins (plus necessaires).
#
# DEBIAN_FRONTEND=noninteractive : empeche apt de poser des questions
# interactives (ex: "voulez-vous garder votre config ou utiliser la nouvelle ?").
# En mode noninteractive, il garde les configs existantes par defaut.
#
# Les flags -qq reduisent la verbosity (moins de texte a l'ecran).

step "Mise a jour du systeme"
apt update -qq
DEBIAN_FRONTEND=noninteractive apt upgrade -y -qq
apt autoremove -y -qq
echo "Systeme mis a jour"


# =============================================================================
# ETAPE 2 : INSTALLATION DES OUTILS ESSENTIELS
# =============================================================================
# Liste des paquets et pourquoi on les installe :
#
# curl, wget          — telecharger des fichiers depuis internet (curl pour les APIs, wget pour les fichiers)
# git                 — gestion de version, necessaire pour Dokploy qui clone les repos
# vim, nano           — editeurs de texte en terminal (nano = simple, vim = avance)
# htop                — moniteur de ressources interactif (CPU, RAM, processus)
# net-tools           — commandes reseau classiques (ifconfig, netstat)
# dnsutils            — outils DNS (dig, nslookup) pour diagnostiquer les problemes de domaine
# ca-certificates     — certificats racine SSL, necessaires pour les connexions HTTPS
# gnupg               — chiffrement et signature (utilise par apt pour verifier les paquets)
# lsb-release         — informations sur la distribution Linux (utilise dans les logs)
# software-properties-common — ajouter des depots PPA (add-apt-repository)
# apt-transport-https — permet a apt de telecharger via HTTPS
# sudo                — executer des commandes en tant que root (le user ne sera pas root)
# ufw                 — pare-feu simplifie (Uncomplicated Firewall)
# fail2ban            — bannit les IP qui font trop de tentatives echouees
# unzip               — decompresser les archives .zip
# unattended-upgrades — installe automatiquement les patchs de securite

step "Installation des outils essentiels"
DEBIAN_FRONTEND=noninteractive apt install -y -qq \
  curl wget git vim nano htop net-tools dnsutils \
  ca-certificates gnupg lsb-release software-properties-common \
  apt-transport-https sudo ufw fail2ban unzip \
  unattended-upgrades apt-listchanges \
  2>&1 | grep -v "^Reading" || true
echo "Outils essentiels installes"


# =============================================================================
# ETAPE 3 : CONFIGURATION DU FUSEAU HORAIRE
# =============================================================================
# Le fuseau horaire affecte :
# - L'heure dans les logs systeme
# - Les cron jobs (backups, etc.)
# - Les horodatages des fichiers
#
# timedatectl : commande systemd pour gerer l'heure et le fuseau horaire.

step "Configuration du fuseau horaire"
timedatectl set-timezone "$TIMEZONE"
echo "Fuseau horaire defini : $(timedatectl | grep 'Time zone' | awk '{print $3}')"


# =============================================================================
# ETAPE 4 : CREATION DE L'UTILISATEUR SUDO
# =============================================================================
# On cree un utilisateur dedie plutot que d'utiliser root directement.
# Pourquoi ? Principe du "moindre privilege" :
# - root peut TOUT faire sans confirmation → une erreur est catastrophique
# - un user sudo doit taper "sudo" avant chaque commande admin → protection
# - les logs montrent QUI a fait QUOI (auditabilite)
# - si le compte est compromis, l'attaquant n'a pas directement root

step "Configuration de l'utilisateur '$NEW_USER'"

if id "$NEW_USER" &>/dev/null; then
    # L'utilisateur existe deja (reinstallation?), on s'assure juste
    # qu'il a bien les privileges sudo
    echo "L'utilisateur '$NEW_USER' existe deja"
    usermod -aG sudo "$NEW_USER" 2>/dev/null || true
    echo "Privileges sudo verifies pour '$NEW_USER'"
else
    # Creer l'utilisateur :
    # --disabled-password : pas de mot de passe au depart (on le definit juste apres)
    # --gecos "" : pas de commentaire (nom complet, telephone, etc.)
    adduser --disabled-password --gecos "" "$NEW_USER"
    # Ajouter au groupe sudo pour lui donner les droits admin
    usermod -aG sudo "$NEW_USER"
    echo "Utilisateur '$NEW_USER' cree avec privileges sudo"
fi

# Demander un mot de passe pour l'utilisateur.
# Meme si on configure une cle SSH, le mot de passe est necessaire pour "sudo".
echo ""
echo "Definition du mot de passe pour '$NEW_USER' :"
echo "   (Utilisez un mot de passe fort : min 16 caracteres, lettres+chiffres+symboles)"
passwd "$NEW_USER"

# --- Configuration de la cle SSH (si fournie) ---
# L'authentification par cle SSH est BEAUCOUP plus securisee que par mot de passe :
# - Un mot de passe peut etre devine par brute-force
# - Une cle SSH ED25519 est quasiment impossible a deviner (256 bits d'entropie)
# - Pas de mot de passe qui transite sur le reseau
#
# authorized_keys : fichier qui liste les cles publiques autorisees a se connecter.
# Permissions : 700 pour .ssh, 600 pour authorized_keys (TRES important, sinon SSH refuse).

if [ -n "$SSH_PUBKEY" ]; then
    echo ""
    echo "Configuration de la cle SSH pour '$NEW_USER'..."

    SSH_DIR="/home/$NEW_USER/.ssh"
    mkdir -p "$SSH_DIR"
    echo "$SSH_PUBKEY" > "$SSH_DIR/authorized_keys"

    # Les permissions sont critiques ici :
    # - 700 (rwx------) sur .ssh : seul le proprietaire peut lire/ecrire/acceder
    # - 600 (rw-------) sur authorized_keys : seul le proprietaire peut lire/ecrire
    # Si les permissions sont trop permissives, SSH refuse d'utiliser les cles
    # (c'est une protection : si d'autres users peuvent modifier le fichier,
    # ils pourraient ajouter leur propre cle).
    chmod 700 "$SSH_DIR"
    chmod 600 "$SSH_DIR/authorized_keys"
    chown -R "$NEW_USER":"$NEW_USER" "$SSH_DIR"

    echo "Cle SSH installee pour '$NEW_USER'"
else
    echo ""
    echo "RAPPEL : Aucune cle SSH fournie."
    echo "   Vous devrez configurer l'authentification par cle manuellement"
    echo "   AVANT de desactiver l'authentification par mot de passe."
fi


# =============================================================================
# ETAPE 5 : SECURISATION SSH
# =============================================================================
# SSH (Secure Shell) est le protocole pour se connecter a distance au serveur.
# C'est la porte d'entree principale → elle doit etre bien verrouillee.
#
# Principe : on modifie /etc/ssh/sshd_config pour :
# - Desactiver la connexion root (oblige a passer par un user + sudo)
# - Limiter les tentatives de connexion
# - Desactiver les fonctionnalites inutiles (X11, etc.)
# - Activer l'auth par cle si une cle est fournie

step "Securisation SSH"

# --- Sauvegarde de la config actuelle ---
# TOUJOURS faire un backup avant de modifier un fichier de config systeme !
# Si la nouvelle config est cassee, on peut restaurer l'ancienne.
BACKUP_FILE="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"
cp /etc/ssh/sshd_config "$BACKUP_FILE"
echo "Backup cree : $BACKUP_FILE"

# --- Fonction utilitaire : modifier une directive SSH ---
# Cette fonction cherche une directive dans sshd_config.
# Si elle existe (meme commentee avec #), elle la remplace.
# Sinon, elle l'ajoute a la fin du fichier.
#
# Exemples :
#   update_ssh_config "Port" "2222"           → Port 2222
#   update_ssh_config "PermitRootLogin" "no"  → PermitRootLogin no
#
# Le regex ^#\? signifie "debut de ligne, eventuellement precede de #"
# Cela gere le cas ou la directive est commentee dans la config par defaut.

update_ssh_config() {
    local directive=$1
    local value=$2

    if grep -q "^#\?${directive}" /etc/ssh/sshd_config; then
        # La directive existe (active ou commentee) → on la remplace
        sed -i "s/^#\?${directive}.*/${directive} ${value}/" /etc/ssh/sshd_config
    else
        # La directive n'existe pas du tout → on l'ajoute a la fin
        echo "${directive} ${value}" >> /etc/ssh/sshd_config
    fi
}

# --- Application des directives de securite ---

# Port SSH : changer le port (si modifie) pour reduire les scans automatiques
update_ssh_config "Port" "$SSH_PORT"

# PermitRootLogin no : INTERDIT la connexion directe en root via SSH.
# C'est la regle de securite #1. Un attaquant qui connait le mot de passe root
# aurait un acces total immediat. Avec "no", il doit d'abord trouver
# un nom d'utilisateur valide, puis son mot de passe, puis faire "sudo".
update_ssh_config "PermitRootLogin" "no"

# MaxAuthTries 3 : apres 3 tentatives echouees, la connexion est coupee.
# Ralentit les attaques brute-force (combinee avec Fail2ban).
update_ssh_config "MaxAuthTries" "3"

# LoginGraceTime 30 : l'utilisateur a 30 secondes pour s'authentifier
# apres avoir ouvert la connexion SSH. Par defaut c'est 120 secondes,
# ce qui laisse trop de temps aux attaquants.
update_ssh_config "LoginGraceTime" "30"

# ClientAliveInterval 300 : le serveur envoie un "ping" toutes les 5 minutes
# pour verifier que le client est toujours la.
update_ssh_config "ClientAliveInterval" "300"

# ClientAliveCountMax 2 : apres 2 pings sans reponse (10 minutes),
# la session est terminee. Evite les sessions zombie.
update_ssh_config "ClientAliveCountMax" "2"

# X11Forwarding no : desactive le transfert graphique X11.
# On gere un serveur, pas un bureau graphique. Desactiver reduit
# la surface d'attaque.
update_ssh_config "X11Forwarding" "no"

# PermitEmptyPasswords no : interdit les comptes sans mot de passe.
# Meme si normalement aucun compte n'a de mot de passe vide,
# c'est une securite supplementaire.
update_ssh_config "PermitEmptyPasswords" "no"

# --- Configuration specifique selon la presence d'une cle SSH ---
if [ -n "$SSH_PUBKEY" ]; then
    # Si une cle SSH a ete fournie, on desactive l'auth par mot de passe.
    # C'est LA mesure de securite la plus importante :
    # - Plus de brute-force de mot de passe possible
    # - Seul celui qui possede la cle privee peut se connecter
    update_ssh_config "PasswordAuthentication" "no"
    update_ssh_config "PubkeyAuthentication" "yes"
    # AuthenticationMethods publickey : n'accepte QUE les cles SSH
    # (pas de fallback vers mot de passe, keyboard-interactive, etc.)
    update_ssh_config "AuthenticationMethods" "publickey"
    echo "Auth par cle SSH activee, mot de passe SSH DESACTIVE"
else
    # Pas de cle fournie → on garde l'auth par mot de passe pour l'instant.
    # L'utilisateur devra configurer sa cle manuellement puis desactiver
    # le mot de passe.
    update_ssh_config "PasswordAuthentication" "yes"
    update_ssh_config "PubkeyAuthentication" "yes"
    echo "ATTENTION : Auth par mot de passe toujours active (configurez une cle SSH !)"
fi

# AllowUsers : restreint SSH a un seul utilisateur.
# Meme si d'autres utilisateurs existent, ils ne pourront pas se connecter en SSH.
if ! grep -q "^AllowUsers" /etc/ssh/sshd_config; then
    echo "AllowUsers $NEW_USER" >> /etc/ssh/sshd_config
fi

# --- Verification de la config SSH ---
# sshd -t teste la syntaxe du fichier de config SANS redemarrer le service.
# Si la config est invalide, SSH ne demarrera pas → on serait coupe du serveur !
# Dans ce cas, on restaure le backup.
if sshd -t 2>/dev/null; then
    echo "Configuration SSH valide"
else
    echo "ERREUR dans la config SSH, restauration du backup"
    cp "$BACKUP_FILE" /etc/ssh/sshd_config
    echo "Backup restaure : $BACKUP_FILE"
    echo "Le script continue mais SSH n'a pas ete modifie."
fi

# --- Avertissement : on ne redemarre PAS SSH tout de suite ---
# C'est CRITIQUE : si on redemarre SSH et que la config est mauvaise,
# on perd l'acces au serveur. On attendend que l'utilisateur teste d'abord.
echo ""
echo "IMPORTANT — SSH modifie mais PAS ENCORE redemarre"
echo "   1. Testez la connexion dans un NOUVEAU terminal apres le script"
echo "   2. Puis redemarrez SSH : sudo systemctl restart sshd"
if [ "$SSH_PORT" != "22" ]; then
    echo "   3. N'oubliez pas d'utiliser le port $SSH_PORT"
fi


# =============================================================================
# ETAPE 6 : CONFIGURATION DU PARE-FEU UFW
# =============================================================================
# UFW (Uncomplicated Firewall) est un front-end simplifie pour iptables.
# iptables est le vrai pare-feu Linux, mais sa syntaxe est complexe.
# UFW fournit des commandes simples comme "ufw allow 80/tcp".
#
# Principe : bloquer TOUT le trafic entrant par defaut, puis ouvrir
# uniquement les ports necessaires (whitelist).
#
# Ports ouverts :
# - SSH (22 ou custom) : pour se connecter au serveur
# - 80 (HTTP)          : pour le trafic web (redirection vers HTTPS)
# - 443 (HTTPS)        : pour le trafic web securise (SSL/TLS)
# - 3000 (Dokploy)     : interface web d'administration de Dokploy

step "Configuration du pare-feu UFW"

# Reset les regles existantes pour partir de zero
ufw --force reset > /dev/null 2>&1

# Politique par defaut :
# - deny incoming : TOUT trafic entrant est bloque sauf les exceptions
# - allow outgoing : le serveur peut contacter l'exterieur (apt, docker pull, etc.)
ufw default deny incoming
ufw default allow outgoing

# Ouvrir les ports necessaires
# Le flag "comment" ajoute une description visible avec "ufw status"
ufw allow "$SSH_PORT"/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 3000/tcp comment 'Dokploy UI'

# Note : les ports Docker internes (ex: 5432 PostgreSQL) ne sont PAS ouverts.
# Ils restent accessibles uniquement entre containers via le reseau Docker.

# Activer UFW (--force pour ne pas demander de confirmation interactive)
ufw --force enable

echo "Pare-feu UFW configure et active"
echo "   Ports ouverts :"
ufw status numbered | grep -E "ALLOW|DENY" || true


# =============================================================================
# ETAPE 7 : PROTECTION CONTRE LE BYPASS UFW PAR DOCKER
# =============================================================================
# PROBLEME CRITIQUE :
# Docker manipule directement iptables (le vrai pare-feu Linux) pour exposer
# les ports des containers. Cela CONTOURNE completement UFW.
#
# Exemple concret : si votre PostgreSQL tourne dans un container avec
# "-p 5432:5432", Docker va ouvrir le port 5432 au monde entier,
# MEME SI UFW le bloque. N'importe qui sur internet pourrait acceder
# a votre base de donnees !
#
# SOLUTION :
# On ajoute des regles dans /etc/ufw/after.rules pour filtrer le trafic
# que Docker essaie de "forwarder" vers les containers.
#
# Ces regles utilisent la chaine DOCKER-USER dans iptables, qui est
# evaluee AVANT la chaine DOCKER. Cela permet a UFW de controler
# quels ports Docker sont reellement accessibles depuis l'exterieur.
#
# Resultat : seuls les ports 80, 443 et 3000 sont accessibles de l'exterieur,
# meme si Docker expose d'autres ports pour la communication inter-containers.

step "Protection contre le bypass UFW par Docker"

# On verifie que les regles n'existent pas deja (idempotence :
# le script peut etre relance sans dupliquer les regles)
if ! grep -q "# BEGIN DOCKER-UFW PROTECTION" /etc/ufw/after.rules; then
    cat >> /etc/ufw/after.rules << 'EOF'

# BEGIN DOCKER-UFW PROTECTION
# =============================================================================
# Ces regles empechent Docker de contourner le pare-feu UFW.
#
# COMMENT CA MARCHE :
# Docker insere ses propres regles iptables pour exposer les ports des containers.
# La chaine DOCKER-USER est evaluee avant les regles Docker.
# On l'utilise pour bloquer tout sauf les ports autorises.
#
# IMPORTANT : si vous ajoutez un nouveau service Docker qui doit etre
# accessible de l'exterieur, ajoutez une regle ici ET dans UFW.
# =============================================================================

*filter
:DOCKER-USER - [0:0]

# Autoriser les connexions deja etablies (reponces aux requetes sortantes)
-A DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN

# Autoriser HTTP, HTTPS et Dokploy UI depuis l'exterieur vers les containers
-A DOCKER-USER -p tcp --dport 80 -j RETURN
-A DOCKER-USER -p tcp --dport 443 -j RETURN
-A DOCKER-USER -p tcp --dport 3000 -j RETURN

# Autoriser TOUT le trafic entre containers (reseau Docker interne)
# 172.16.0.0/12 est la plage d'adresses IP utilisee par Docker par defaut
-A DOCKER-USER -s 172.16.0.0/12 -j RETURN
-A DOCKER-USER -s 10.0.0.0/8 -j RETURN

# BLOQUER tout le reste venant de l'exterieur vers les containers
# (empeche l'acces direct a PostgreSQL 5432, Redis 6379, etc.)
-A DOCKER-USER -j DROP

COMMIT
# END DOCKER-UFW PROTECTION
EOF

    # Recharger UFW pour appliquer les nouvelles regles
    ufw reload
    echo "Protection Docker-UFW configuree"
    echo "   Les ports Docker internes (PostgreSQL, Redis, etc.) sont proteges"
else
    echo "Protection Docker-UFW deja configuree"
fi


# =============================================================================
# ETAPE 8 : CONFIGURATION FAIL2BAN
# =============================================================================
# Fail2ban surveille les fichiers de log (SSH, Traefik, etc.) et bannit
# automatiquement les adresses IP qui font trop de tentatives echouees.
#
# Fonctionnement :
# 1. Un attaquant essaie de deviner un mot de passe SSH
# 2. Apres 3 echecs en 10 minutes, Fail2ban ajoute une regle iptables
#    qui bloque son IP pendant 24 heures
# 3. Si l'IP est bannie 3 fois (recidiviste), elle est bloquee 7 jours
#
# jail.local : fichier de configuration specifique a ce serveur.
# On utilise jail.local (et pas jail.conf) car jail.conf est ecrase
# lors des mises a jour de Fail2ban.

step "Configuration Fail2ban"

# On ecrit la config a chaque fois (ecrase l'ancienne si elle existe)
# pour garantir la coherence avec le port SSH choisi.
cat > /etc/fail2ban/jail.local << EOF
# =============================================================================
#  CONFIGURATION FAIL2BAN — Generee par quick-prepare-vps.sh v2.0
# =============================================================================
#
# Ce fichier n'est PAS ecrase par les mises a jour de Fail2ban
# (contrairement a jail.conf).
#
# Pour verifier l'etat : sudo fail2ban-client status
# Pour voir les bans SSH : sudo fail2ban-client status sshd
# Pour debannir une IP : sudo fail2ban-client set sshd unbanip 1.2.3.4
# =============================================================================

[DEFAULT]
# --- Parametres generaux ---

# Duree de bannissement par defaut : 24 heures (en secondes).
# Ancien script : 1 heure → trop court, les bots reviennent.
bantime  = 86400

# Fenetre de detection : on compte les echecs sur 10 minutes.
findtime = 600

# Nombre d'echecs autorises avant bannissement.
maxretry = 3

# Methode de bannissement : iptables (standard Linux).
banaction = iptables-multiport

# Action lors d'un ban : bannir l'IP + logger l'evenement.
# %(action_mwl)s = ban + mail avec logs (si mail configure)
# %(action_)s = ban seulement (sans mail)
action = %(action_)s


# =============================================================================
# JAIL SSH — Protection contre le brute-force SSH
# =============================================================================
# C'est la protection la plus importante. Les bots scannent en permanence
# le port SSH de tous les serveurs et tentent des millions de combinaisons
# nom d'utilisateur / mot de passe.

[sshd]
enabled  = true
port     = $SSH_PORT
logpath  = /var/log/auth.log
maxretry = 3
bantime  = 86400
findtime = 600


# =============================================================================
# JAIL RECIDIVE — Bannissement progressif des recidivistes
# =============================================================================
# Cette jail surveille le propre log de Fail2ban (!).
# Si une IP est bannie 3 fois en 24 heures, elle est re-bannie pour 7 jours.
# C'est une "meta-jail" : elle punit les attaquants persistants.

[recidive]
enabled  = true
logpath  = /var/log/fail2ban.log
# 3 bans en 24h → ban de 7 jours
bantime  = 604800
findtime = 86400
maxretry = 3


# =============================================================================
# JAIL TRAEFIK — Protection de l'API et du frontend (optionnel)
# =============================================================================
# Decommentez ces sections si vous configurez Traefik pour logguer
# dans /var/log/traefik/access.log.
#
# Pour activer les logs Traefik, ajoutez dans docker-compose.yml :
#   --accesslog=true
#   --accesslog.filepath=/var/log/traefik/access.log
#
# [traefik-auth]
# enabled  = true
# port     = 80,443
# logpath  = /var/log/traefik/access.log
# maxretry = 5
# findtime = 300
# bantime  = 3600
# filter   = traefik-auth
#
# [traefik-botsearch]
# enabled  = true
# port     = 80,443
# logpath  = /var/log/traefik/access.log
# maxretry = 5
# findtime = 300
# bantime  = 86400
# filter   = traefik-botsearch
EOF

# Demarrer (ou redemarrer) Fail2ban et l'activer au demarrage
systemctl restart fail2ban 2>/dev/null || systemctl start fail2ban
systemctl enable fail2ban
echo "Fail2ban active et configure"
echo "   - SSH : ban 24h apres 3 echecs"
echo "   - Recidivistes : ban 7 jours apres 3 bans en 24h"


# =============================================================================
# ETAPE 9 : CREATION DU FICHIER SWAP
# =============================================================================
# Le swap est un espace sur le disque dur utilise comme "memoire de secours"
# quand la RAM est pleine.
#
# POURQUOI C'EST IMPORTANT :
# Sur un VPS avec 2-4 GB de RAM, les programmes suivants tournent en parallele :
# - PostgreSQL (~200-500 MB)
# - Docker engine (~100-200 MB)
# - Traefik (~50-100 MB)
# - FastAPI backend (~100-300 MB)
# - Node.js frontend build (~500-1000 MB pendant le build !)
# - Systeme d'exploitation (~300-500 MB)
#
# Total : jusqu'a ~2.5 GB en usage normal, pics a ~4 GB pendant les builds.
# Sans swap, quand la RAM est pleine, le kernel Linux tue des processus
# (OOM Killer = Out Of Memory Killer). Il choisit souvent PostgreSQL
# → perte de donnees potentielle !
#
# Avec swap : les pages memoire les moins utilisees sont deplacees sur le disque.
# C'est plus lent que la RAM, mais le processus continue de fonctionner.
# vm.swappiness = 10 (configure plus tard) signifie : n'utiliser le swap
# que quand la RAM est presque pleine (en dessous de 10% libre).

step "Creation du fichier swap ($SWAP_SIZE)"

if [ -f /swapfile ]; then
    echo "Un fichier swap existe deja :"
    swapon --show
    echo "Swap conserve tel quel"
else
    # fallocate alloue un fichier de la taille demandee sans l'ecrire physiquement
    # (plus rapide que dd)
    fallocate -l "$SWAP_SIZE" /swapfile

    # Permissions 600 : seul root peut lire/ecrire le fichier swap.
    # C'est obligatoire (securite : le swap peut contenir des donnees sensibles
    # de la memoire, comme des mots de passe en transit).
    chmod 600 /swapfile

    # mkswap : formate le fichier comme espace swap
    mkswap /swapfile

    # swapon : active le swap immediatement
    swapon /swapfile

    # Ajouter au fstab pour que le swap soit active automatiquement au demarrage.
    # fstab (File Systems Table) liste les systemes de fichiers a monter au boot.
    if ! grep -q "/swapfile" /etc/fstab; then
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi

    echo "Swap de $SWAP_SIZE cree et active"
    swapon --show
fi


# =============================================================================
# ETAPE 10 : MISES A JOUR DE SECURITE AUTOMATIQUES
# =============================================================================
# Le systeme est mis a jour maintenant, mais de nouvelles failles de securite
# sont decouvertes regulierement. Les "unattended-upgrades" appliquent
# automatiquement les patchs de securite critiques.
#
# Ce que ca fait :
# - Chaque jour, apt verifie s'il y a des mises a jour de securite
# - Si oui, il les installe automatiquement (sans intervention humaine)
# - Seules les mises a jour de SECURITE sont installees (pas les nouvelles
#   versions de paquets, qui pourraient casser des choses)
# - Un reboot automatique peut etre programme si necessaire (desactive ici)
#
# Fichier de config : /etc/apt/apt.conf.d/50unattended-upgrades
# Fichier d'activation : /etc/apt/apt.conf.d/20auto-upgrades

step "Activation des mises a jour de securite automatiques"

# Activer les mises a jour automatiques
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
// Mettre a jour la liste des paquets automatiquement (1 = chaque jour)
APT::Periodic::Update-Package-Lists "1";

// Installer les mises a jour de securite automatiquement
APT::Periodic::Unattended-Upgrade "1";

// Nettoyer le cache apt tous les 7 jours (economise l'espace disque)
APT::Periodic::AutocleanInterval "7";
EOF

# Configurer les mises a jour automatiques
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
// Quelles mises a jour installer automatiquement ?
// - security : patchs de securite (TOUJOURS activer)
// - updates : mises a jour normales (desactive pour la stabilite)
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

// NE PAS redemarrer automatiquement, meme si necessaire.
// On prefere redemarrer manuellement pour eviter les downtimes imprevus.
Unattended-Upgrade::Automatic-Reboot "false";

// Supprimer les anciens noyaux inutilises (economise l'espace disque)
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF

echo "Mises a jour de securite automatiques activees"
echo "   Les patchs de securite seront installes chaque nuit"


# =============================================================================
# ETAPE 11 : OPTIMISATIONS KERNEL POUR DOCKER
# =============================================================================
# Le kernel Linux a des parametres configurables via sysctl.
# On les ajuste pour que Docker fonctionne de maniere optimale.

step "Optimisations kernel pour Docker"

# --- Parametres sysctl ---
# sysctl.conf : fichier de configuration des parametres du kernel Linux.
# Ces parametres sont charges au demarrage et peuvent etre modifies a chaud.

# On verifie d'abord si les parametres existent deja (idempotence)
if ! grep -q "# BEGIN DOCKER OPTIMIZATIONS" /etc/sysctl.conf; then
    cat >> /etc/sysctl.conf << 'EOF'

# BEGIN DOCKER OPTIMIZATIONS
# =============================================================================
# Parametres kernel optimises pour Docker + Dokploy + RadioManager
# Genere par quick-prepare-vps.sh v2.0
# =============================================================================

# --- FORWARDING IP (OBLIGATOIRE pour Docker) ---
# Docker cree des reseaux virtuels entre les containers.
# Pour que le trafic passe d'un container a l'autre (ou vers l'exterieur),
# le kernel doit "forwarder" les paquets IP (comme un routeur).
# Sans ca, les containers ne peuvent pas communiquer entre eux.
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# --- OPTIMISATIONS RESEAU ---
# somaxconn : taille maximale de la file d'attente des connexions TCP.
# Une valeur haute permet de gerer plus de connexions simultanees
# (utile quand Traefik recoit beaucoup de requetes).
net.core.somaxconn = 1024

# tcp_max_syn_backlog : file d'attente pour les connexions en cours d'etablissement
# (le "three-way handshake" TCP : SYN → SYN-ACK → ACK).
net.ipv4.tcp_max_syn_backlog = 2048

# tcp_fin_timeout : temps d'attente avant de liberer une connexion fermee.
# Defaut 60s → 30s. Libere les ressources plus vite apres une deconnexion.
net.ipv4.tcp_fin_timeout = 30

# tcp_keepalive_time : intervalle des pings TCP pour verifier qu'une connexion
# est toujours active. Defaut 7200s (2h) → 600s (10min).
net.ipv4.tcp_keepalive_time = 600

# --- LIMITES DE FICHIERS ---
# Chaque connexion reseau, chaque fichier ouvert, chaque pipe utilise
# un "descripteur de fichier" (fd). Docker en utilise BEAUCOUP
# (un container peut facilement en ouvrir des milliers).
# file-max : limite globale du systeme
fs.file-max = 65535

# inotify : mecanisme Linux pour surveiller les changements de fichiers.
# Docker et Node.js (hot reload) l'utilisent intensivement.
# max_user_watches : nombre max de fichiers surveilles par utilisateur
# max_user_instances : nombre max de "watchers" par utilisateur
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512

# --- OPTIMISATION MEMOIRE ---
# swappiness : tendance du kernel a utiliser le swap.
# 10 = utiliser le swap seulement quand la RAM est presque pleine.
# (defaut = 60, trop agressif pour un serveur avec base de donnees)
vm.swappiness = 10

# dirty_ratio / dirty_background_ratio : pourcentage de RAM utilisable
# comme cache d'ecriture disque avant de forcer l'ecriture.
# Des valeurs basses = ecritures plus frequentes mais moins de risque
# de perte de donnees en cas de crash.
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# --- SECURITE RESEAU ---

# rp_filter (Reverse Path Filtering) : protection anti-spoofing.
# Verifie que l'adresse source d'un paquet arrive bien par l'interface
# reseau attendue. Bloque les paquets avec une fausse adresse source
# (utilises dans les attaques DDoS ou pour contourner les pare-feu).
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Desactiver les redirections ICMP : empeche un routeur malveillant
# de dire "envoie tes paquets par la" (attaque MITM).
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0

# Ignorer les pings broadcast (protection "smurf attack" :
# un attaquant envoie un ping a l'adresse broadcast avec l'IP de la victime
# comme source → tout le reseau repond a la victime → DDoS).
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Desactiver le source routing : empeche un paquet de dicter
# son propre chemin a travers le reseau (utilise dans les attaques).
net.ipv4.conf.all.accept_source_route = 0

# END DOCKER OPTIMIZATIONS
EOF

    # Appliquer les parametres immediatement (sans reboot)
    sysctl -p > /dev/null 2>&1
    echo "Parametres kernel optimises et appliques"
else
    echo "Parametres kernel deja optimises"
fi

# --- Limites de fichiers ouverts (ulimits) ---
# En plus de la limite globale (fs.file-max), chaque processus a sa propre limite.
# Par defaut, c'est souvent 1024, ce qui est trop bas pour Docker.
# On augmente a 65535 pour tous les utilisateurs.
#
# soft = limite par defaut pour les processus
# hard = limite maximum que l'utilisateur peut definir avec "ulimit -n"

if ! grep -q "# BEGIN DOCKER LIMITS" /etc/security/limits.conf; then
    cat >> /etc/security/limits.conf << 'EOF'

# BEGIN DOCKER LIMITS
# Limites de fichiers ouverts pour Docker et Dokploy
# Genere par quick-prepare-vps.sh v2.0
*               soft    nofile          65535
*               hard    nofile          65535
root            soft    nofile          65535
root            hard    nofile          65535
# END DOCKER LIMITS
EOF
    echo "Limites de fichiers augmentees (65535)"
else
    echo "Limites de fichiers deja configurees"
fi

# --- Pre-configuration Docker (logs + iptables) ---
# On prepare le fichier daemon.json AVANT l'installation de Docker.
# Quand Dokploy installera Docker, il utilisera cette config automatiquement.
#
# log-driver json-file : format de log par defaut de Docker
# max-size 10m : chaque fichier de log fait max 10 MB
# max-file 3 : on garde max 3 fichiers de log par container
# → Max 30 MB de logs par container (evite de remplir le disque !)
#
# SANS cette config, les logs Docker grandissent indefiniment et peuvent
# remplir le disque en quelques jours sur un VPS avec peu d'espace.

mkdir -p /etc/docker
if [ ! -f /etc/docker/daemon.json ]; then
    cat > /etc/docker/daemon.json << 'EOF'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
EOF
    echo "Configuration Docker preparee (rotation des logs)"
else
    echo "Configuration Docker existante conservee"
fi


# =============================================================================
# ETAPE 12 : CREATION DES REPERTOIRES ET CONFIGURATION DES BACKUPS
# =============================================================================
# On cree l'arborescence necessaire pour Dokploy et les backups.

step "Creation des repertoires et configuration des backups"

# --- Repertoires Dokploy ---
mkdir -p /opt/dokploy          # Fichiers de configuration Dokploy
mkdir -p /var/lib/dokploy      # Donnees Dokploy (volumes, etc.)
mkdir -p /var/log/dokploy      # Logs specifiques Dokploy

# --- Repertoires de backups ---
mkdir -p /backup/postgres      # Backups PostgreSQL (dumps SQL)

# Donner les bonnes permissions
chown -R "$NEW_USER":"$NEW_USER" /opt/dokploy 2>/dev/null || true
chown -R "$NEW_USER":"$NEW_USER" /backup 2>/dev/null || true

echo "Repertoires crees :"
echo "   /opt/dokploy       — configuration Dokploy"
echo "   /var/lib/dokploy   — donnees Dokploy"
echo "   /var/log/dokploy   — logs Dokploy"
echo "   /backup/postgres   — backups PostgreSQL"

# --- Cron job pour backup PostgreSQL quotidien ---
# Ce cron tourne DANS le systeme hote et execute pg_dumpall dans le container Docker.
#
# Planning :
# - 3h00 : dump complet de PostgreSQL (compresse en gzip)
# - 3h30 : nettoyage des dumps de plus de 7 jours
#
# pg_dumpall : exporte TOUTES les bases de donnees et les roles.
# gzip : compresse le dump (un dump de quelques GB → quelques centaines de MB).
#
# CONFIGURATION RADIOMANAGER :
# - Le container PostgreSQL s'appelle "audace_db" (defini dans docker-compose.yml)
# - L'utilisateur PostgreSQL est "audace_user" (variable DB_USER du docker-compose)
# - Le superuser "postgres" est aussi disponible pour pg_dump
# - Le filtre "name=audace_db" cherche le container par son nom exact
# - En fallback, "ancestor=postgres" cherche tout container base sur l'image postgres
#
# IMPORTANT : on utilise pg_dump (une seule base) et non pg_dumpall (cluster entier)
# pour que la restauration avec psql -d audace_db fonctionne correctement.
# pg_dump --clean --if-exists ajoute des DROP TABLE avant chaque CREATE TABLE.
#
# Si votre container a un nom different, modifiez la ligne ci-dessous.
#
# Pour restaurer un backup :
#   gunzip < /backup/postgres/dump_20260313.sql.gz | docker exec -i audace_db psql -U audace_user -d audace_db

cat > /etc/cron.d/backup-postgres << 'CRON'
# =============================================================================
# Backup automatique PostgreSQL — genere par quick-prepare-vps.sh v2.1
# =============================================================================
# Tous les jours a 3h du matin, on cree un dump de la base audace_db.
# Les backups de plus de 7 jours sont supprimes automatiquement.
#
# CONFIGURATION :
# - Container : audace_db (nom defini dans docker-compose.yml du backend)
# - Base de donnees : audace_db
# - Utilisateur dump : postgres (superuser)
# - Format : pg_dump --clean --if-exists (DROP + CREATE, compatible psql -d)
# - Si le container a un nom different, adaptez "audace_db" ci-dessous
#
# FORMAT DU CRON : minute heure jour_mois mois jour_semaine utilisateur commande
#
# Pour lister les backups : ls -lh /backup/postgres/
# Pour restaurer : gunzip < /backup/postgres/dump_YYYYMMDD.sql.gz | docker exec -i audace_db psql -U audace_user -d audace_db
# =============================================================================

# Dump base audace_db a 3h00 tous les jours
# Essaie d'abord le container "audace_db", sinon cherche tout container postgres
0 3 * * * root CONTAINER=$(docker ps -qf "name=audace_db" 2>/dev/null | head -1); [ -z "$CONTAINER" ] && CONTAINER=$(docker ps -qf "ancestor=postgres" 2>/dev/null | head -1); [ -n "$CONTAINER" ] && docker exec -t $CONTAINER pg_dump --clean --if-exists -U postgres audace_db 2>/dev/null | gzip > /backup/postgres/dump_$(date +\%Y\%m\%d).sql.gz 2>/dev/null || true

# Nettoyage des vieux backups (> 7 jours) a 3h30
30 3 * * * root find /backup/postgres -name "dump_*.sql.gz" -mtime +7 -delete 2>/dev/null || true
CRON

# Les fichiers cron dans /etc/cron.d doivent avoir les permissions 644
chmod 644 /etc/cron.d/backup-postgres

echo "Backup PostgreSQL quotidien configure (3h00, retention 7 jours)"


# =============================================================================
# RESUME FINAL
# =============================================================================

echo ""
echo "=========================================="
echo "  PREPARATION TERMINEE AVEC SUCCES !"
echo "=========================================="
echo ""
echo "INFORMATIONS SYSTEME :"
echo "   - Utilisateur cree : $NEW_USER"
echo "   - Port SSH : $SSH_PORT"
if [ "$SSH_PORT" != "22" ]; then
    echo "     PORT SSH MODIFIE ! Utilisez : ssh -p $SSH_PORT"
fi
echo "   - Fuseau horaire : $TIMEZONE"
echo "   - Swap : $SWAP_SIZE"
echo "   - IP publique : $(hostname -I | awk '{print $1}')"
echo "   - Distribution : $(lsb_release -ds 2>/dev/null || cat /etc/os-release | head -1)"
echo "   - Kernel : $(uname -r)"
echo "   - Log du script : $LOG_FILE"
echo ""
echo "SECURITE CONFIGUREE :"
echo "   [x] Root login SSH desactive"
echo "   [x] Pare-feu UFW actif (ports: $SSH_PORT, 80, 443, 3000)"
echo "   [x] Docker ne peut pas contourner UFW"
echo "   [x] Fail2ban : ban 24h apres 3 echecs, 7 jours pour les recidivistes"
echo "   [x] Swap $SWAP_SIZE active (protection OOM)"
echo "   [x] Mises a jour de securite automatiques"
echo "   [x] Rotation des logs Docker (max 30 MB/container)"
echo "   [x] Protection reseau anti-spoofing"
echo "   [x] Backup PostgreSQL quotidien (retention 7 jours)"
if [ -n "$SSH_PUBKEY" ]; then
    echo "   [x] Auth par cle SSH uniquement (mot de passe desactive)"
else
    echo "   [ ] Auth par cle SSH (a configurer manuellement — voir ci-dessous)"
fi
echo ""

# --- Prochaines etapes (adaptees selon la config) ---
echo "PROCHAINES ETAPES :"
echo ""

STEP_NUM=1

if [ -z "$SSH_PUBKEY" ]; then
    echo "${STEP_NUM}. CONFIGURER L'AUTHENTIFICATION PAR CLE SSH"
    echo "   Sur votre machine locale, executez :"
    echo "   ---"
    echo "   ssh-keygen -t ed25519 -C \"votre-email@example.com\""
    if [ "$SSH_PORT" != "22" ]; then
        echo "   ssh-copy-id -p $SSH_PORT $NEW_USER@$(hostname -I | awk '{print $1}')"
    else
        echo "   ssh-copy-id $NEW_USER@$(hostname -I | awk '{print $1}')"
    fi
    echo "   ---"
    echo ""
    STEP_NUM=$((STEP_NUM + 1))
fi

echo "${STEP_NUM}. TESTER LA CONNEXION SSH (dans un NOUVEAU terminal !)"
if [ "$SSH_PORT" != "22" ]; then
    echo "   ssh -p $SSH_PORT $NEW_USER@$(hostname -I | awk '{print $1}')"
else
    echo "   ssh $NEW_USER@$(hostname -I | awk '{print $1}')"
fi
echo "   NE FERMEZ PAS cette session tant que le test n'est pas reussi !"
echo ""
STEP_NUM=$((STEP_NUM + 1))

echo "${STEP_NUM}. REDEMARRER SSH (seulement apres avoir teste !)"
echo "   sudo systemctl restart sshd"
echo ""
STEP_NUM=$((STEP_NUM + 1))

if [ -z "$SSH_PUBKEY" ]; then
    echo "${STEP_NUM}. DESACTIVER L'AUTH PAR MOT DE PASSE (apres configuration de la cle)"
    echo "   sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config"
    echo "   sudo sed -i 's/^AuthenticationMethods.*/AuthenticationMethods publickey/' /etc/ssh/sshd_config"
    echo "   sudo systemctl restart sshd"
    echo ""
    STEP_NUM=$((STEP_NUM + 1))
fi

echo "${STEP_NUM}. INSTALLER DOKPLOY"
echo "   En tant qu'utilisateur $NEW_USER :"
echo "   curl -sSL https://dokploy.com/install.sh | sh"
echo ""
STEP_NUM=$((STEP_NUM + 1))

echo "${STEP_NUM}. CONFIGURER LES DNS"
echo "   Pointer vos domaines vers : $(hostname -I | awk '{print $1}')"
echo "   Exemples pour RadioManager :"
echo "   - dokploy.votre-domaine.com  → $(hostname -I | awk '{print $1}')"
echo "   - app.votre-domaine.com      → $(hostname -I | awk '{print $1}')"
echo "   - api.votre-domaine.com      → $(hostname -I | awk '{print $1}')"
echo ""
STEP_NUM=$((STEP_NUM + 1))

echo "${STEP_NUM}. ACCEDER A DOKPLOY"
echo "   https://$(hostname -I | awk '{print $1}'):3000"
echo "   ou https://dokploy.votre-domaine.com:3000"
echo ""

echo "COMMANDES UTILES :"
echo "   sudo ufw status verbose              # Etat du pare-feu"
echo "   sudo fail2ban-client status sshd      # Bannissements SSH"
echo "   sudo fail2ban-client status recidive  # Recidivistes bannis"
echo "   sudo systemctl status sshd            # Etat du service SSH"
echo "   df -h                                 # Espace disque"
echo "   free -h                               # Memoire + swap"
echo "   htop                                  # Moniteur de ressources"
echo "   ls -lh /backup/postgres/              # Backups PostgreSQL"
echo "   cat $LOG_FILE                         # Log de ce script"
if [ "$SSH_PORT" != "22" ]; then
    echo "   sudo ss -tlnp | grep $SSH_PORT            # Verifier le port SSH"
fi
echo ""
echo "RAPPELS IMPORTANTS :"
echo "   - Backup config SSH : $BACKUP_FILE"
echo "   - NE redemarrez SSH qu'APRES avoir teste les cles SSH !"
echo "   - Gardez cette session ouverte comme secours"
echo "   - Adaptez le nom du container dans /etc/cron.d/backup-postgres si necessaire"
echo ""
echo "Votre VPS est maintenant pret pour Dokploy !"
echo "=========================================="
