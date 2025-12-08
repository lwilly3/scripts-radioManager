# 📧 Configuration des Notifications Email Fail2ban

> **Guide complet pour configurer les alertes email lors des bannissements SSH**

## 📋 Table des matières

- [Vue d'ensemble](#-vue-densemble)
- [Prérequis](#-prérequis)
- [Méthode 1 : Gmail / Google Workspace](#-méthode-1--gmail--google-workspace)
- [Méthode 2 : Service SMTP externe (SendGrid, Mailgun)](#-méthode-2--service-smtp-externe-sendgrid-mailgun)
- [Méthode 3 : Serveur SMTP local (Postfix)](#-méthode-3--serveur-smtp-local-postfix)
- [Configuration Fail2ban](#-configuration-fail2ban)
- [Test des notifications](#-test-des-notifications)
- [Personnalisation des emails](#-personnalisation-des-emails)
- [Dépannage](#-dépannage)
- [Alternatives aux emails](#-alternatives-aux-emails)

---

## 🎯 Vue d'ensemble

Par défaut, Fail2ban banni les IP malveillantes mais **ne vous prévient pas**. La configuration `%(action_mwl)s` permet d'envoyer un email à chaque bannissement avec :

- 📧 **Adresse IP bannie**
- 🕐 **Date et heure du bannissement**
- 📝 **Logs des tentatives échouées**
- 🔍 **Informations WHOIS de l'IP**

**Avantages** :
- ✅ Alertes en temps réel des attaques
- ✅ Traçabilité complète
- ✅ Détection des anomalies
- ✅ Audit de sécurité

---

## 📦 Prérequis

```bash
# 1. Fail2ban installé (déjà fait par quick-prepare-vps.sh)
sudo systemctl status fail2ban

# 2. Installer les outils d'envoi d'emails
sudo apt update
sudo apt install -y mailutils ssmtp whois

# mailutils : commande 'mail' pour envoyer des emails
# ssmtp : client SMTP léger
# whois : informations sur les IP bannies
```

---

## 📧 Méthode 1 : Gmail / Google Workspace

### 1.1 Prérequis Gmail

**⚠️ Important** : Google a désactivé l'authentification par mot de passe classique. Vous devez :
1. Activer la **2FA** (authentification à deux facteurs)
2. Générer un **mot de passe d'application**

### 1.2 Créer un mot de passe d'application Google

```
1. Connectez-vous à votre compte Google
2. Allez sur : https://myaccount.google.com/security
3. Section "Se connecter à Google"
4. Cliquez sur "Mots de passe des applications"
5. Sélectionnez :
   - Application : "Autre (nom personnalisé)"
   - Nom : "Fail2ban VPS"
6. Cliquez "Générer"
7. Copiez le mot de passe de 16 caractères (format : xxxx xxxx xxxx xxxx)
```

### 1.3 Configurer SSMTP pour Gmail

```bash
# Éditer la configuration SSMTP
sudo nano /etc/ssmtp/ssmtp.conf
```

**Contenu** :

```bash
# filepath: /etc/ssmtp/ssmtp.conf
# Configuration SSMTP pour Gmail

# Serveur SMTP Gmail
root=votre-email@gmail.com
mailhub=smtp.gmail.com:587
rewriteDomain=gmail.com
hostname=vps-dokploy-prod

# Authentification
AuthUser=votre-email@gmail.com
AuthPass=xxxx xxxx xxxx xxxx  # Mot de passe d'application (sans espaces)
FromLineOverride=YES
UseSTARTTLS=YES
UseTLS=YES

# Debug (optionnel, commenter en production)
# Debug=YES
```

**⚠️ Sécuriser le fichier** :

```bash
# Le fichier contient un mot de passe, le protéger
sudo chmod 600 /etc/ssmtp/ssmtp.conf
sudo chown root:root /etc/ssmtp/ssmtp.conf
```

### 1.4 Configurer le mappage des utilisateurs

```bash
# Éditer revaliases
sudo nano /etc/ssmtp/revaliases
```

**Contenu** :

```bash
# filepath: /etc/ssmtp/revaliases
# Mappage utilisateur local → email

root:votre-email@gmail.com:smtp.gmail.com:587
dokploy:votre-email@gmail.com:smtp.gmail.com:587
```

### 1.5 Tester l'envoi d'email

```bash
# Test simple
echo "Test email depuis VPS Dokploy" | mail -s "Test Fail2ban" votre-email@gmail.com

# Vérifier les logs
sudo tail -f /var/log/mail.log
# ou
sudo journalctl -u ssmtp -f
```

**Résultat attendu** :
- ✅ Email reçu dans la boîte de réception Gmail
- ⚠️ Si dans les spams, marquer comme "Pas un spam"

---

## 🔧 Méthode 2 : Service SMTP externe (SendGrid, Mailgun)

### Option A : SendGrid (100 emails/jour gratuit)

#### 2.1 Créer un compte SendGrid

```
1. Allez sur : https://sendgrid.com/
2. Créez un compte gratuit (Free Plan)
3. Vérifiez votre email
4. Créez une clé API :
   - Settings → API Keys → Create API Key
   - Nom : "Fail2ban VPS"
   - Permissions : "Mail Send" (Full Access)
   - Copiez la clé (format : SG.xxxxxxxxxxxxxx)
```

#### 2.2 Configurer SSMTP pour SendGrid

```bash
sudo nano /etc/ssmtp/ssmtp.conf
```

**Contenu** :

```bash
# filepath: /etc/ssmtp/ssmtp.conf
# Configuration SendGrid

root=votre-email@example.com
mailhub=smtp.sendgrid.net:587
hostname=vps-dokploy-prod

# Authentification SendGrid
AuthUser=apikey
AuthPass=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # Votre clé API
FromLineOverride=YES
UseSTARTTLS=YES
UseTLS=YES
```

### Option B : Mailgun (5000 emails/mois gratuit)

#### 2.3 Créer un compte Mailgun

```
1. Allez sur : https://www.mailgun.com/
2. Créez un compte (Free Trial)
3. Vérifiez votre domaine ou utilisez le sandbox
4. Récupérez les credentials SMTP :
   - Sending → Domain Settings → SMTP credentials
   - Host : smtp.mailgun.org
   - Port : 587
   - Username : postmaster@votre-domaine.mailgun.org
   - Password : (affiché dans l'interface)
```

#### 2.4 Configurer SSMTP pour Mailgun

```bash
sudo nano /etc/ssmtp/ssmtp.conf
```

**Contenu** :

```bash
# filepath: /etc/ssmtp/ssmtp.conf
# Configuration Mailgun

root=votre-email@example.com
mailhub=smtp.mailgun.org:587
hostname=vps-dokploy-prod

# Authentification Mailgun
AuthUser=postmaster@votre-domaine.mailgun.org
AuthPass=votre-mot-de-passe-mailgun
FromLineOverride=YES
UseSTARTTLS=YES
UseTLS=YES
```

---

## 📮 Méthode 3 : Serveur SMTP local (Postfix)

**Avantages** :
- ✅ Autonome (pas de service externe)
- ✅ Pas de limites d'envoi
- ✅ Contrôle total

**Inconvénients** :
- ⚠️ Configuration plus complexe
- ⚠️ Risque de spam (IP blacklistée)
- ⚠️ Nécessite configuration DNS (SPF, DKIM, DMARC)

### 3.1 Installer Postfix

```bash
# Installation
sudo apt install -y postfix mailutils

# Lors de l'installation, choisir :
# - Configuration : "Site Internet"
# - Nom du système mail : vps-dokploy-prod.votre-domaine.com
```

### 3.2 Configurer Postfix

```bash
sudo nano /etc/postfix/main.cf
```

**Modifications** :

```bash
# filepath: /etc/postfix/main.cf
# ...existing code...

# Configuration de base
myhostname = vps-dokploy-prod.votre-domaine.com
mydestination = $myhostname, localhost.$mydomain, localhost
relayhost =

# Limiter aux connexions locales uniquement (sécurité)
inet_interfaces = loopback-only
inet_protocols = ipv4

# Taille maximale des messages
message_size_limit = 10240000

# ...existing code...
```

### 3.3 Redémarrer Postfix

```bash
sudo systemctl restart postfix
sudo systemctl enable postfix
sudo systemctl status postfix
```

### 3.4 Tester Postfix

```bash
echo "Test Postfix depuis VPS" | mail -s "Test Fail2ban" votre-email@example.com
```

---

## ⚙️ Configuration Fail2ban

### 4.1 Configurer les actions avec email

```bash
sudo nano /etc/fail2ban/jail.local
```

**Configuration complète** :

```ini
# filepath: /etc/fail2ban/jail.local
[DEFAULT]
# Durée du bannissement (1 heure)
bantime  = 3600

# Fenêtre de temps (10 minutes)
findtime = 600

# Nombre de tentatives avant ban
maxretry = 3

# === CONFIGURATION EMAIL ===
# Email de destination des alertes
destemail = votre-email@gmail.com

# Email expéditeur (nom du serveur)
sender = fail2ban@vps-dokploy-prod

# Nom d'expéditeur affiché
sendername = Fail2ban VPS Dokploy

# === ACTIONS ===
# action_mw  : Bannir + email avec WHOIS
# action_mwl : Bannir + email avec WHOIS + logs
# action_    : Bannir uniquement (pas d'email)

# Action par défaut (email + logs)
action = %(action_mwl)s

# Ou pour email simple sans logs
# action = %(action_mw)s

# Bannissement via iptables
banaction = iptables-multiport

# === JAIL SSH ===
[sshd]
enabled = true
port    = 22
logpath = /var/log/auth.log
maxretry = 3

# Surcharge de l'action pour SSH (optionnel)
# action = %(action_mwl)s
```

### 4.2 Redémarrer Fail2ban

```bash
# Vérifier la configuration
sudo fail2ban-client -t

# Redémarrer Fail2ban
sudo systemctl restart fail2ban

# Vérifier le statut
sudo systemctl status fail2ban
sudo fail2ban-client status sshd
```

---

## 🧪 Test des notifications

### 5.1 Tester manuellement un bannissement

```bash
# Option 1 : Bannir manuellement une IP de test
sudo fail2ban-client set sshd banip 1.2.3.4

# Option 2 : Simuler des tentatives échouées (ATTENTION : risque de vous bannir !)
# Depuis une autre machine :
# ssh utilisateur-inexistant@votre-vps-ip  (répéter 3 fois avec mauvais mot de passe)
```

### 5.2 Vérifier la réception de l'email

**Email reçu devrait contenir** :

```
Objet : [Fail2ban] sshd: banned 1.2.3.4 from vps-dokploy-prod

Hi,

The IP 1.2.3.4 has just been banned by Fail2Ban after
3 attempts against sshd.

Here is more information about 1.2.3.4:

% WHOIS Information:
NetRange:       1.2.3.0 - 1.2.3.255
CIDR:           1.2.3.0/24
Organization:   Example ISP
Country:        US

Lines containing IP: 1.2.3.4 in /var/log/auth.log:

Dec 20 14:30:15 sshd[12345]: Failed password for invalid user admin from 1.2.3.4 port 54321
Dec 20 14:30:18 sshd[12346]: Failed password for invalid user admin from 1.2.3.4 port 54322
Dec 20 14:30:21 sshd[12347]: Failed password for invalid user admin from 1.2.3.4 port 54323

Regards,
Fail2ban
```

### 5.3 Débannir l'IP de test

```bash
sudo fail2ban-client set sshd unbanip 1.2.3.4
```

---

## 🎨 Personnalisation des emails

### 6.1 Personnaliser le contenu de l'email

```bash
# Copier le fichier d'action par défaut
sudo cp /etc/fail2ban/action.d/sendmail-whois-lines.conf /etc/fail2ban/action.d/sendmail-custom.conf

# Éditer
sudo nano /etc/fail2ban/action.d/sendmail-custom.conf
```

**Exemple de personnalisation** :

```ini
# filepath: /etc/fail2ban/action.d/sendmail-custom.conf
[Definition]

# Option : commande pour envoyer l'email
actionstart = echo "Fail2ban est démarré sur <hostname>" | mail -s "[Fail2ban] <name> démarré" <dest>

actionstop = echo "Fail2ban est arrêté sur <hostname>" | mail -s "[Fail2ban] <name> arrêté" <dest>

# Bannissement avec message personnalisé
actionban = printf "%%b" "Bonjour,\n
            \n
            🚨 ALERTE SÉCURITÉ 🚨\n
            \n
            Une adresse IP a été bannie par Fail2ban :\n
            \n
            📍 IP bannie : <ip>\n
            🖥️  Serveur : <hostname>\n
            🔒 Service : <name>\n
            🕐 Date/Heure : $(date)\n
            ⚠️  Tentatives : <failures> échecs en <findtime> secondes\n
            ⏱️  Durée du ban : <bantime> secondes\n
            \n
            📊 INFORMATIONS WHOIS :\n
            $(whois <ip> | grep -E 'NetRange|CIDR|Organization|Country')\n
            \n
            📝 LOGS DES TENTATIVES :\n
            $(grep '<ip>' <logpath> | tail -n 10)\n
            \n
            🔐 Action recommandée : Vérifier si cette IP est légitime\n
            \n
            Pour débannir : sudo fail2ban-client set <name> unbanip <ip>\n
            \n
            Cordialement,\n
            Système de sécurité Fail2ban\n
            " | mail -s "🚨 [Fail2ban] <ip> bannie sur <hostname>" <dest>

actionunban =

[Init]
name = default
dest = root
logpath = /var/log/faillog
```

### 6.2 Utiliser l'action personnalisée

```bash
sudo nano /etc/fail2ban/jail.local
```

```ini
# filepath: /etc/fail2ban/jail.local
[sshd]
enabled = true
port    = 22
logpath = /var/log/auth.log
maxretry = 3
action = sendmail-custom[name=SSH, dest=votre-email@gmail.com]
```

---

## 🐛 Dépannage

### Problème : Emails non reçus

```bash
# 1. Vérifier les logs mail
sudo tail -f /var/log/mail.log
# ou
sudo journalctl -u fail2ban -f

# 2. Vérifier la config SSMTP
cat /etc/ssmtp/ssmtp.conf

# 3. Tester l'envoi manuel
echo "Test" | mail -s "Test" votre-email@gmail.com

# 4. Vérifier que mailutils est installé
which mail
# Output attendu : /usr/bin/mail
```

### Problème : Erreur d'authentification Gmail

```bash
# Erreur typique :
# ssmtp: Authorization failed (535 5.7.8 Username and Password not accepted)

# Solutions :
# 1. Vérifier que 2FA est activé sur Gmail
# 2. Régénérer un mot de passe d'application
# 3. Vérifier qu'il n'y a pas d'espaces dans AuthPass
# 4. Tester avec un autre compte Gmail
```

### Problème : Emails dans les spams

```bash
# Causes possibles :
# 1. IP du VPS blacklistée
# 2. Pas de SPF/DKIM configuré
# 3. Serveur SMTP non reconnu

# Solutions :
# 1. Utiliser un service SMTP externe (SendGrid, Mailgun)
# 2. Configurer SPF/DKIM si Postfix local
# 3. Marquer comme "Pas un spam" dans Gmail
```

### Problème : Trop d'emails (spam)

```bash
# Limiter les notifications

sudo nano /etc/fail2ban/jail.local
```

```ini
# filepath: /etc/fail2ban/jail.local
[DEFAULT]
# ...existing code...

# N'envoyer qu'un email par heure maximum pour la même IP
bantime  = 3600
findtime = 3600  # 1 heure

# Ou désactiver temporairement les emails
action = %(action_)s  # Bannir sans email
```

---

## 🔔 Alternatives aux emails

### Option 1 : Notifications Slack

```bash
# Installer le webhook Slack
sudo apt install -y curl jq

# Créer un webhook Slack :
# https://api.slack.com/messaging/webhooks

# Éditer l'action Fail2ban
sudo nano /etc/fail2ban/action.d/slack-notify.conf
```

```ini
# filepath: /etc/fail2ban/action.d/slack-notify.conf
[Definition]

actionban = curl -X POST -H 'Content-type: application/json' \
            --data '{"text":"🚨 IP bannie: <ip> sur <name>"}' \
            https://hooks.slack.com/services/VOTRE/WEBHOOK/URL
```

### Option 2 : Notifications Discord

```bash
sudo nano /etc/fail2ban/action.d/discord-notify.conf
```

```ini
# filepath: /etc/fail2ban/action.d/discord-notify.conf
[Definition]

actionban = curl -X POST -H "Content-Type: application/json" \
            -d '{"content":"🚨 **Fail2ban Alert**\nIP: <ip>\nService: <name>\nServer: <hostname>"}' \
            https://discord.com/api/webhooks/VOTRE_WEBHOOK_ID
```

### Option 3 : Notifications Telegram

```bash
# Créer un bot Telegram :
# https://t.me/BotFather

sudo nano /etc/fail2ban/action.d/telegram-notify.conf
```

```ini
# filepath: /etc/fail2ban/action.d/telegram-notify.conf
[Definition]

actionban = curl -s -X POST https://api.telegram.org/bot<bot_token>/sendMessage \
            -d chat_id=<chat_id> \
            -d text="🚨 IP bannie: <ip> sur <name> (<hostname>)"

[Init]
bot_token = VOTRE_BOT_TOKEN
chat_id = VOTRE_CHAT_ID
```

---

## 📚 Ressources

- **Documentation Fail2ban** : https://fail2ban.readthedocs.io/
- **Configuration Gmail** : https://support.google.com/accounts/answer/185833
- **SendGrid Docs** : https://docs.sendgrid.com/
- **Mailgun Docs** : https://documentation.mailgun.com/

---

## ✅ Checklist de configuration

- [ ] **SSMTP installé** (`mailutils`, `ssmtp`, `whois`)
- [ ] **Compte email configuré** (Gmail, SendGrid, ou Mailgun)
- [ ] **Mot de passe d'application généré** (si Gmail)
- [ ] **Fichier `/etc/ssmtp/ssmtp.conf` configuré**
- [ ] **Permissions sécurisées** (`chmod 600` sur ssmtp.conf)
- [ ] **Test d'envoi réussi** (`echo "Test" | mail ...`)
- [ ] **Fail2ban configuré** (`destemail` et `action` définis)
- [ ] **Fail2ban redémarré** (`systemctl restart fail2ban`)
- [ ] **Test de bannissement** (email reçu)
- [ ] **Email pas dans les spams** (marquer comme légitime)

---

<div align="center">

**✅ Vos notifications Fail2ban sont maintenant opérationnelles !**

**Questions ?** Ouvrez une [issue sur GitHub](https://github.com/lwilly3/scripts-radioManager/issues)

</div>