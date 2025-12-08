# 📧 Configuration des Notifications Email Fail2ban

> **Guide complet pour configurer les alertes email lors des bannissements SSH**

[Retour au README principal](../README.md) | [Guide d'utilisation](USAGE.md)

---

## Table des matières

- [Introduction](#-introduction)
- [Prérequis](#-prérequis)
- [Configuration de Fail2ban](#-configuration-de-fail2ban)
- [Tests de réception](#-tests-de-réception)
- [Dépannage](#-dépannage)
- [Ressources et liens utiles](#-ressources-et-liens-utiles)

---

## 🎯 Introduction

Fail2ban est un outil puissant pour protéger votre serveur contre les tentatives de connexion par force brute. Ce guide se concentre sur la configuration des notifications par email afin d'être alerté immédiatement en cas de problème.

---

## 📋 Prérequis

Avant de commencer, assurez-vous que :

- Vous avez un serveur fonctionnant sous Ubuntu 24.10.
- Vous avez installé et configuré Fail2ban. Si ce n'est pas le cas, consultez le [guide d'installation de Fail2ban](https://www.fail2ban.org/wiki/index.php?title=Installation).

---

## ⚙️ Configuration de Fail2ban

1. **Éditez le fichier de configuration de Fail2ban** :

   ```bash
   sudo nano /etc/fail2ban/jail.local
   ```

2. **Ajoutez ou modifiez les lignes suivantes** :

   ```ini
   [DEFAULT]
   # Adresse email de l'expéditeur
   sender = fail2ban@votre-domaine.com

   # Adresse email du destinataire (vous)
   dest = votre-email@domaine.com

   # Sujet des emails
   action = %(action_mwl)s

   # Filtre pour les notifications par email
   [sshd]
   enabled = true
   port    = ssh
   filter  = sshd
   logpath = /var/log/auth.log
   maxretry = 3
   ```

3. **Configurez l'action par défaut pour envoyer des emails** :

   ```ini
   [DEFAULT]
   # Action par défaut
   action = %(action_mwl)s

   # Pour envoyer des emails, décommentez la ligne suivante
   # action = %(action_mwl)s
   ```

4. **Sauvegardez et fermez le fichier**.

---

## 📬 Tests de réception

Pour tester si la configuration fonctionne, vous pouvez forcer un échec de connexion SSH (par exemple, en utilisant un mot de passe incorrect plusieurs fois). Vous devriez recevoir un email de notification à l'adresse spécifiée.

---

## 🛠️ Dépannage

Si vous ne recevez pas d'email :

- Vérifiez les logs de Fail2ban :

  ```bash
  sudo tail -f /var/log/fail2ban.log
  ```

- Assurez-vous que le service Fail2ban est en cours d'exécution :

  ```bash
  sudo systemctl status fail2ban
  ```

- Testez l'envoi d'email depuis le serveur :

  ```bash
  echo "Test Fail2ban" | mail -s "Test Email" votre-email@domaine.com
  ```

---

## 📚 Ressources et liens utiles

- [Documentation officielle de Fail2ban](https://www.fail2ban.org/wiki/index.php?title=Documentation)
- [Guide de configuration avancée](https://www.fail2ban.org/wiki/index.php?title=Configuration)

---

**Note** : Voir [POST-INSTALL.md](POST-INSTALL.md) pour plus de détails sur la configuration Fail2ban par défaut.