# config-audaceStream-IceCast.xml - Documentation

## 📋 Vue d'ensemble

Ce fichier de configuration XML définit les paramètres du serveur de streaming audio **Icecast2** pour le projet RadioManager Audace. Il configure un point de montage pour diffuser un flux audio MP3 accessible publiquement.

## 🎯 Objectif

Configurer un serveur Icecast pour diffuser un flux audio en streaming avec :
- Point de montage dédié : `/stream.mp3`
- Format : MP3
- Bitrate : 32 kbps
- Accès public sans authentification
- Support CORS pour l'intégration web

## 🔧 Configuration principale

### Informations du serveur

```xml
<location>Earth</location>
<admin>icemaster@localhost</admin>
<hostname>audace</hostname>
```

- **Location** : Localisation géographique (arbitraire)
- **Admin** : Contact administrateur
- **Hostname** : Nom d'hôte du serveur

### Port d'écoute

```xml
<listen-socket>
    <port>8000</port>
</listen-socket>
```

Le serveur Icecast écoute sur le **port 8000** (HTTP).

### Authentification

```xml
<authentication>
    <source-password>D3faultpass</source-password>
    <relay-password>D3faultpass</relay-password>
    <admin-user>admin</admin-user>
    <admin-password>D3faultpass</admin-password>
</authentication>
```

⚠️ **IMPORTANT** : Changez ces mots de passe par défaut en production !

- **source-password** : Mot de passe pour les sources de streaming
- **relay-password** : Mot de passe pour les relais
- **admin-user/admin-password** : Identifiants pour l'interface d'administration

## 📡 Point de montage : /stream.mp3

### Configuration détaillée

```xml
<mount type="normal">
    <mount-name>/stream.mp3</mount-name>
    <public>1</public>
    <max-listeners>200</max-listeners>
    <bitrate>32</bitrate>
    <format>MP3</format>
    <authentication type="none" />
    <http-headers>
        <header name="Access-Control-Allow-Origin" value="*" />
    </http-headers>
</mount>
```

### Paramètres expliqués

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| **mount-name** | `/stream.mp3` | URL du flux : `http://server:8000/stream.mp3` |
| **public** | `1` | Visible dans les annuaires publics |
| **max-listeners** | `200` | Nombre maximum d'auditeurs simultanés |
| **bitrate** | `32` | Qualité audio en kbps (économique pour la radio vocale) |
| **format** | `MP3` | Format audio (compatible tous navigateurs) |
| **authentication** | `none` | Aucune authentification requise pour l'écoute |
| **CORS** | `*` | Autorise l'intégration dans n'importe quel site web |

## 🎧 Accès au flux

Une fois Icecast configuré avec Nginx (via le script `API-setup_server.sh`), le flux est accessible via :

```
https://radio.audace.ovh/stream.mp3
```

### Tester le flux

```bash
# Avec curl
curl -I https://radio.audace.ovh/stream.mp3

# Avec ffplay (FFmpeg)
ffplay https://radio.audace.ovh/stream.mp3

# Avec VLC
vlc https://radio.audace.ovh/stream.mp3
```

## 🔒 Sécurité

### En-têtes HTTP CORS

```xml
<http-headers>
    <header name="Access-Control-Allow-Origin" value="*" />
</http-headers>
```

Permet l'accès depuis n'importe quelle origine (nécessaire pour les lecteurs web).

Pour restreindre à un domaine spécifique :

```xml
<header name="Access-Control-Allow-Origin" value="https://app.radioaudace.com" />
```

## 📊 Limites du serveur

```xml
<limits>
    <clients>500</clients>
    <sources>5</sources>
    <queue-size>524288</queue-size>
    <client-timeout>30</client-timeout>
    <header-timeout>15</header-timeout>
    <source-timeout>10</source-timeout>
    <burst-on-connect>1</burst-on-connect>
    <burst-size>65535</burst-size>
</limits>
```

### Explication des limites

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| **clients** | 500 | Nombre maximum de clients connectés |
| **sources** | 5 | Nombre maximum de sources de streaming |
| **queue-size** | 524288 | Taille de la file d'attente (512 KB) |
| **client-timeout** | 30s | Délai avant déconnexion client inactif |
| **burst-on-connect** | Activé | Envoie des données immédiatement à la connexion |
| **burst-size** | 64 KB | Taille du burst initial |

## 📂 Chemins importants

```xml
<paths>
    <basedir>/usr/share/icecast2</basedir>
    <logdir>/var/log/icecast2</logdir>
    <webroot>/usr/share/icecast2/web</webroot>
    <adminroot>/usr/share/icecast2/admin</adminroot>
</paths>
```

### Fichiers de logs

- **access.log** : Journal des connexions
- **error.log** : Journal des erreurs
- Niveau de log : **3 (Info)** - 4=Debug, 2=Warn, 1=Error

## 🛠️ Administration

### Interface web d'administration

Accessible via : `http://server:8000/admin/`

Identifiants par défaut :
- **Utilisateur** : `admin`
- **Mot de passe** : `D3faultpass`

⚠️ **Changez ces identifiants en production !**

### Statistiques en temps réel

- `http://server:8000/status.xsl` - Interface web des statistiques
- `http://server:8000/status-json.xsl` - Statistiques en JSON

## 🎙️ Diffuser vers Icecast

### Avec OBS Studio (plugin)

```
URL : icecast://radio.audace.ovh:8000/stream.mp3
Mot de passe source : D3faultpass
```

### Avec FFmpeg

```bash
ffmpeg -re -i input.mp3 \
  -codec:a libmp3lame -b:a 32k \
  -content_type audio/mpeg \
  -f mp3 \
  icecast://source:D3faultpass@radio.audace.ovh:8000/stream.mp3
```

### Avec Liquidsoap

```liquidsoap
output.icecast(
  %mp3(bitrate=32),
  host="radio.audace.ovh",
  port=8000,
  password="D3faultpass",
  mount="/stream.mp3",
  source
)
```

## 🔧 Personnalisation

### Changer le bitrate

Pour une meilleure qualité audio :

```xml
<bitrate>128</bitrate>  <!-- Au lieu de 32 -->
```

### Limiter le nombre d'auditeurs

```xml
<max-listeners>50</max-listeners>  <!-- Au lieu de 200 -->
```

### Activer l'authentification

```xml
<authentication type="htpasswd">
    <option name="filename" value="/etc/icecast2/listeners.htpasswd"/>
</authentication>
```

## 📝 Intégration avec Nginx

Le script `API-setup_server.sh` configure automatiquement Nginx comme reverse proxy :

```nginx
server {
    listen 443 ssl http2;
    server_name radio.audace.ovh;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_buffering off;
    }
}
```

Avantages :
- SSL/TLS (HTTPS)
- Certificat Let's Encrypt
- Meilleure performance
- Masquage du port 8000

## 🔍 Dépannage

### Problème : Impossible de se connecter

```bash
# Vérifier qu'Icecast est actif
systemctl status icecast2

# Vérifier les logs
sudo tail -f /var/log/icecast2/error.log

# Vérifier que le port est ouvert
netstat -tlnp | grep 8000
```

### Problème : Pas de son

1. Vérifier qu'une source diffuse vers `/stream.mp3`
2. Consulter l'interface admin : `http://server:8000/admin/`
3. Vérifier les statistiques : `http://server:8000/status.xsl`

### Problème : CORS bloqué

Vérifier les en-têtes HTTP :

```bash
curl -I https://radio.audace.ovh/stream.mp3 | grep -i access-control
```

Doit retourner :
```
Access-Control-Allow-Origin: *
```

## 📚 Ressources

- [Documentation officielle Icecast](https://icecast.org/docs/)
- [Configuration de référence](https://icecast.org/docs/icecast-2.4.1/config-file.html)
- [Sources audio compatibles](https://icecast.org/apps/)

## ⚙️ Modification du fichier

Pour appliquer des modifications :

```bash
# Éditer la configuration
sudo nano /etc/icecast2/icecast.xml

# Tester la syntaxe
icecast2 -c /etc/icecast2/icecast.xml

# Redémarrer le service
sudo systemctl restart icecast2
```

## 📜 Notes importantes

- Le bitrate de 32 kbps est optimisé pour la voix (radio parlée)
- Pour de la musique, préférez 128 kbps ou plus
- Le CORS ouvert (`*`) facilite l'intégration mais réduit le contrôle
- Changez toujours les mots de passe par défaut en production
