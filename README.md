# scripts-radioManager
####################################################################################################
  
                          Scripts pour radioManager

####################################################################################################

Bienvenue dans le dépôt scripts-radioManager ! Ce dépôt contient des scripts Bash utilisés pour configurer, déployer et gérer les composants backend et frontend de l’application radioManager, une solution de streaming audio et de gestion d’API. Ces scripts automatisent l’installation et la maintenance d’un serveur Ubuntu 24.10 hébergeant une API, un serveur Icecast, et un frontend basé sur Vite.

Contenu du dépôt
Voici une liste des fichiers présents dans ce dépôt avec une brève description :

# API-setup_server.sh
Configure un serveur Ubuntu 24.10 pour héberger une API (via FastAPI) et un flux Icecast. Installe les dépendances, configure Nginx, PostgreSQL, un environnement virtuel Python, et sécurise le tout avec un pare-feu et des certificats SSL.

# acript-autoStart-radioManager.sh
Script exécuté au démarrage du serveur pour s’assurer que le frontend (app.radioaudace.com) est actif. Vérifie Nginx, construit le frontend si nécessaire, et met à jour le code depuis Git (optionnel).

# config-audaceStream-IceCast.xml
Fichier de configuration personnalisé pour Icecast, définissant un point de montage /stream.mp3 avec un bitrate de 32 kbps, accessible publiquement.

# init-radioManager-frontend-server.sh
Configure un serveur Ubuntu 24.10 pour héberger un site frontend basé sur Vite. Installe Node.js, clone le dépôt Git du frontend, construit le projet, et configure Nginx avec SSL.

# update_frontend.sh
Met à jour le frontend en récupérant les dernières modifications du dépôt Git, recompilant avec Vite, et redémarrant Nginx.

# README.md
Ce fichier ! Fournit une vue d’ensemble et des instructions pour utiliser les scripts.


/////////////////////////////////////////////////////////////////////////////////////////

                                        Prérequis

//////////////////////////////////////////////////////////////////////////////////////////
Pour utiliser ces scripts, vous devez disposer de :

Un serveur Ubuntu 24.10 fraîchement installé.
Un accès root ou des privilèges sudo.
Une connexion Internet pour télécharger les dépendances et les fichiers depuis GitHub.
Des noms de domaine configurés (ex. radio.audace.ovh, api.radio.audace.ovh, app.radioaudace.com) pointant vers l’IP de votre serveur pour les certificats SSL via Certbot.
Installation et utilisation

1. Configuration du backend (API et Icecast)
Le script API-setup_server.sh configure l’API et le serveur Icecast.

Étapes :
Téléchargez le script :
bash

Collapse

Wrap

Copy
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/API-setup_server.sh -O setup_server.sh
Rendez-le exécutable :
bash

Collapse

Wrap

Copy
chmod +x setup_server.sh
Éditez les variables dans le script (au début du fichier) :
AUDACE_PASSWORD : Mot de passe pour l’utilisateur audace (optionnel, une invite apparaîtra si vide).
DB_PASSWORD : Mot de passe pour PostgreSQL.
ADMIN_EMAIL : Votre email pour Certbot.
Exécutez le script :
bash

Collapse

Wrap

Copy
sudo bash setup_server.sh
Vérifiez les services :
bash

Collapse

Wrap

Copy
systemctl status icecast2
systemctl status nginx
systemctl status api
Résultat attendu :
Icecast disponible sur https://radio.audace.ovh/stream.mp3.
API accessible sur https://api.radio.audace.ovh.
2. Configuration du frontend
Le script init-radioManager-frontend-server.sh configure le frontend basé sur Vite.

Étapes :
Téléchargez le script :
bash

Collapse

Wrap

Copy
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/init-radioManager-frontend-server.sh -O init_frontend.sh
Rendez-le exécutable :
bash

Collapse

Wrap

Copy
chmod +x init_frontend.sh
Éditez les variables si nécessaire (ex. DOMAIN, EMAIL).
Exécutez le script :
bash

Collapse

Wrap

Copy
sudo bash init_frontend.sh
Vérifiez le site :
Ouvrez https://app.radioaudace.com dans un navigateur.
3. Mise à jour du frontend
Le script update_frontend.sh met à jour le frontend existant.

Étapes :
Téléchargez le script :
bash

Collapse

Wrap

Copy
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/update_frontend.sh -O update_frontend.sh
Rendez-le exécutable :
bash

Collapse

Wrap

Copy
chmod +x update_frontend.sh
Exécutez le script :
bash

Collapse

Wrap

Copy
sudo bash update_frontend.sh
Consultez les logs si nécessaire :
bash

Collapse

Wrap

Copy
cat /var/log/update_frontend.log
4. Démarrage automatique du frontend
Le script acript-autoStart-radioManager.sh s’exécute au démarrage pour garantir que le frontend est actif.

Étapes :
Téléchargez le script :
bash

Collapse

Wrap

Copy
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/acript-autoStart-radioManager.sh -O /usr/local/bin/start-radioaudace.sh
Rendez-le exécutable :
bash

Collapse

Wrap

Copy
chmod +x /usr/local/bin/start-radioaudace.sh
Créez un service systemd :
bash

Collapse

Wrap

Copy
sudo nano /etc/systemd/system/start-radioaudace.service
Ajoutez ce contenu :
ini

Collapse

Wrap

Copy
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
Activez le service :
bash

Collapse

Wrap

Copy
sudo systemctl enable start-radioaudace.service
sudo systemctl start start-radioaudace.service
Vérifiez les logs après un redémarrage :
bash

Collapse

Wrap

Copy
cat /var/log/start_radioaudace.log
Configuration Icecast
Le fichier config-audaceStream-IceCast.xml est utilisé par API-setup_server.sh pour configurer Icecast. Il définit :

Un point de montage /stream.mp3 avec un bitrate de 32 kbps.
Une limite de 200 auditeurs.
Des mots de passe par défaut (D3faultpass) pour les sources, relais et admin (à modifier pour la sécurité).
Pour personnaliser davantage, éditez ce fichier avant d’exécuter le script.

Dépannage
Logs Nginx : sudo tail -f /var/log/nginx/error.log
Logs Icecast : sudo tail -f /var/log/icecast2/error.log
Logs API : sudo journalctl -u api
Logs Frontend : cat /var/log/update_frontend.log ou cat /var/log/start_radioaudace.log
Si Certbot échoue, vérifiez que vos domaines pointent correctement vers l’IP du serveur via les enregistrements DNS.

Contributions
Les contributions sont les bienvenues ! Si vous souhaitez améliorer ces scripts :

Forkez le dépôt.
Créez une branche pour vos modifications.
Soumettez une pull request.



Licence
Ce projet est sous licence libre.