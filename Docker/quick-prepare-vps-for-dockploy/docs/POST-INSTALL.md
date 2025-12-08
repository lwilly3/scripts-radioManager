# 📊 État du Serveur Après Préparation

> **Documentation complète de l'état du serveur après exécution du script**

[Retour au README principal](../README.md) | [Guide d'utilisation](USAGE.md)

## Vérifications Système

- **Système d'exploitation** : Ubuntu 24.10
- **Architecture** : x86_64
- **Mémoire** : 2 Go (2048 Mo)
- **Espace disque** : 20 Go libres
- **CPU** : 2 cœurs

## Services Actifs

| Service         | Statut   | Port     |
|-----------------|----------|-----------|
| SSH             | Actif    | 22        |
| Nginx           | Actif    | 80, 443   |
| PostgreSQL      | Actif    | 5432      |
| Icecast2        | Actif    | 8000      |
| API FastAPI     | Actif    | 8001      |

## État des Conteneurs Docker

| Nom du conteneur         | Statut   | Ports               |
|--------------------------|----------|---------------------|
| radiomanager-frontend    | Actif    | 80->80/tcp          |
| api-audace               | Actif    | 8000->8000/tcp      |
| postgres                 | Actif    | 5432->5432/tcp      |
| icecast                  | Actif    | 8001->8001/tcp      |

## Logs Récents

- **Nginx** : `/var/log/nginx/access.log` et `/var/log/nginx/error.log`
- **API FastAPI** : `/var/log/your_api/your_api.log`
- **Icecast** : `/var/log/icecast2/error.log`
- **PostgreSQL** : `/var/log/postgresql/postgresql-12-main.log`

## Tâches Cron Actives

- **root** : `crontab -l`
- **www-data** : `crontab -l -u www-data`

## Utilisateurs Système

| Nom d'utilisateur | Type         | Dernière connexion |
|-------------------|--------------|--------------------|
| root              | Administrateur | 2024-12-01 10:00   |
| deploy            | Standard     | 2024-12-01 09:30   |
| www-data          | Système      | 2024-12-01 08:45   |

## Groupes Système

- `sudo` : root, deploy
- `www-data` : www-data

## Fichiers et Répertoires Importants

- **Code source** : `/var/www/html/`
- **Certificats SSL** : `/etc/letsencrypt/live/`
- **Fichiers de configuration** :
  - Nginx : `/etc/nginx/sites-available/default`
  - PostgreSQL : `/etc/postgresql/12/main/postgresql.conf`
  - Icecast : `/etc/icecast2/icecast.xml`

## Variables d'Environnement

- `DJANGO_SECRET_KEY` : Changé
- `DATABASE_URL` : Changé
- `REDIS_URL` : Non défini
- `ALLOWED_HOSTS` : `['localhost', '127.0.0.1']`

## 📚 Ressources

- **Guide d'utilisation** : [USAGE.md](USAGE.md)
- **Préparation VPS** : [PREPARATION.md](PREPARATION.md)
- **Configuration Fail2ban** : [FAIL2BAN-EMAIL.md](FAIL2BAN-EMAIL.md)
- **Variables d'environnement** : [VARIABLES.md](VARIABLES.md)
- **Migration** : [MIGRATION.md](MIGRATION.md)