# script-wireguard-client-mikrotik - Documentation

## 📋 Vue d'ensemble

Ce script de configuration permet de transformer un **routeur MikroTik** en client VPN WireGuard pour se connecter à un serveur WG-Easy. Il configure l'interface WireGuard, les routes, le pare-feu et le NAT pour permettre aux clients du réseau local d'accéder aux ressources via le tunnel VPN.

## 🎯 Objectif

Configurer un routeur MikroTik pour :
- Se connecter à un serveur WireGuard
- Router le trafic vers des réseaux distants via le VPN
- Permettre aux clients locaux d'accéder aux ressources VPN
- Maintenir une connexion persistante avec keepalive
- Configurer le pare-feu et le NAT

## 🔧 Architecture

```
Internet
   ↓
[Serveur WireGuard]
   ↓ VPN 10.8.0.0/24
[Routeur MikroTik] 10.8.0.254
   ↓ LAN
[Réseau local 192.168.1.0/24]
[Réseau streaming 192.168.20.0/24]
```

## 📦 Prérequis

- **Routeur MikroTik** avec RouterOS 7.x ou supérieur
- **Accès** : Winbox, WebFig ou SSH
- **Serveur WireGuard** : Serveur WG-Easy configuré
- **Clés WireGuard** : 
  - Clé privée du routeur
  - Clé publique du serveur
  - Clé pré-partagée (optionnelle)
- **Paramètres réseau** :
  - Adresse IP du serveur VPN
  - Port du serveur (51820)
  - Plages d'adresses autorisées

## ⚙️ Variables de configuration

### À personnaliser avant l'application

```routeros
# Clé privée du routeur MikroTik (générée dans WG-Easy)
private-key=""

# Clé publique du serveur WireGuard
public-key=""

# Clé pré-partagée (optionnelle, pour sécurité renforcée)
preshared-key=""

# Adresse du serveur VPN
endpoint-address=mon.domaine.com
endpoint-port=51820

# Adresse IP du routeur dans le VPN
address=10.8.0.254/24

# Réseaux accessibles via le VPN
allowed-address=10.8.0.0/24,192.168.1.0/24,192.168.20.0/24
```

## 🚀 Installation

### Étape 1 : Générer les clés dans WG-Easy

1. Connectez-vous à l'interface WG-Easy
2. Créez un nouveau client nommé "MikroTik-Router"
3. Téléchargez le fichier de configuration
4. Extrayez les clés :
   - **PrivateKey** : Clé privée du routeur
   - **PublicKey** (du serveur) : Dans la section `[Peer]`
   - **PresharedKey** : Si disponible

### Étape 2 : Accéder au routeur MikroTik

Via **Winbox** :
- Téléchargez Winbox depuis mikrotik.com
- Connectez-vous avec l'IP du routeur

Via **SSH** :
```bash
ssh admin@192.168.88.1
```

Via **WebFig** :
- Ouvrez http://192.168.88.1 dans un navigateur

### Étape 3 : Appliquer la configuration

Copiez-collez les commandes une par une dans le terminal RouterOS.

## 📝 Configuration détaillée

### 1. Configuration de l'interface WireGuard

```routeros
/interface wireguard
add name=wg-vpn listen-port=51820 mtu=1420 \
    private-key="VOTRE_CLÉ_PRIVÉE_ICI"
```

**Paramètres** :
- `name` : Nom de l'interface (wg-vpn)
- `listen-port` : Port local (51820)
- `mtu` : Taille maximale des paquets (1420 recommandé)
- `private-key` : Clé privée générée dans WG-Easy

### 2. Configuration du peer (serveur)

```routeros
/interface wireguard peers
add interface=wg-vpn public-key="CLÉ_PUBLIQUE_SERVEUR" \
    preshared-key="CLÉ_PRÉPARTAGÉE" \
    endpoint-address=mon.domaine.com endpoint-port=51820 \
    allowed-address=10.8.0.0/24,192.168.1.0/24,192.168.20.0/24 \
    persistent-keepalive=25
```

**Paramètres** :
- `public-key` : Clé publique du serveur
- `endpoint-address` : Domaine ou IP du serveur
- `endpoint-port` : Port du serveur (51820)
- `allowed-address` : Réseaux accessibles via le VPN
- `persistent-keepalive` : Maintien de la connexion (25 secondes)

### 3. Configuration de l'adresse IP

```routeros
/ip address
add address=10.8.0.254/24 interface=wg-vpn network=10.8.0.0
```

**Pourquoi .254 ?** Convention pour identifier un routeur (au lieu de .1 ou .2).

### 4. Configuration DNS

```routeros
/ip dns
set allow-remote-requests=yes servers=1.1.1.1
```

Utilise Cloudflare DNS (1.1.1.1) pour la résolution.

### 5. Configuration des routes

```routeros
/ip route
add dst-address=10.8.0.0/24 gateway=wg-vpn comment="Réseau VPN"
add dst-address=192.168.1.0/24 gateway=wg-vpn comment="LAN principal via WG"
add dst-address=192.168.20.0/24 gateway=wg-vpn comment="LAN streaming via WG"
```

**Explication** :
- Route le trafic vers les réseaux spécifiés via le tunnel VPN
- `192.168.1.0/24` : Réseau principal distant
- `192.168.20.0/24` : Réseau secondaire (ex: streaming)

### 6. Configuration du pare-feu

```routeros
/ip firewall filter
add chain=input action=accept in-interface=wg-vpn comment="WG: autoriser entrée"
add chain=forward action=accept in-interface=wg-vpn comment="WG -> LAN"
add chain=forward action=accept out-interface=wg-vpn comment="LAN -> WG"
add chain=input action=accept protocol=icmp comment="Ping OK"
```

**Règles importantes** :
- Autorise le trafic entrant depuis le VPN
- Autorise le forwarding VPN ↔ LAN
- Autorise ICMP (ping) pour le diagnostic

### 7. Configuration du NAT

```routeros
/ip firewall nat
add chain=srcnat action=masquerade out-interface=wg-vpn comment="Masquerade vers VPN"
```

**Masquerade** : Traduit les adresses IP locales vers l'IP VPN du routeur.

## 🔍 Vérification de la configuration

### Vérifier l'interface WireGuard

```routeros
/interface wireguard print
/interface wireguard peers print detail
```

Doit afficher :
- Interface : wg-vpn
- Status : running
- Peer : connected

### Vérifier les routes

```routeros
/ip route print where gateway=wg-vpn
```

Doit montrer les 3 routes configurées.

### Tester la connectivité

```routeros
# Ping vers le serveur VPN
/ping 10.8.0.1

# Ping vers un appareil du réseau distant
/ping 192.168.1.10

# Tracer la route
/tool traceroute 192.168.1.10
```

### Vérifier le pare-feu

```routeros
/ip firewall filter print where in-interface=wg-vpn
```

### Statistiques du peer

```routeros
/interface wireguard peers print stats
```

Affiche :
- Dernière connexion (last-handshake)
- Données transmises/reçues
- Endpoint actuel

## 📊 Monitoring

### Surveiller les connexions

```routeros
# Voir les connexions actives
/ip firewall connection print where connection-state=established

# Statistiques de l'interface
/interface print stats where name=wg-vpn

# Logs en temps réel
/log print follow where topics~"wireguard"
```

### Dashboard Winbox

Dans Winbox :
1. Ouvrez "Interfaces"
2. Double-cliquez sur "wg-vpn"
3. Consultez les statistiques (traffic, RX/TX)

### Graphiques

```routeros
# Activer les graphiques pour l'interface
/tool graphing interface add interface=wg-vpn store-on-disk=yes
```

## 🛠️ Maintenance

### Renouveler les clés

Générez de nouvelles clés dans WG-Easy et mettez à jour :

```routeros
/interface wireguard set wg-vpn private-key="NOUVELLE_CLÉ_PRIVÉE"
/interface wireguard peers set [find interface=wg-vpn] public-key="NOUVELLE_CLÉ_PUBLIQUE_SERVEUR"
```

### Changer le serveur

```routeros
/interface wireguard peers set [find interface=wg-vpn] \
    endpoint-address=nouveau-serveur.com \
    endpoint-port=51820
```

### Désactiver temporairement le VPN

```routeros
/interface wireguard disable wg-vpn
```

### Réactiver

```routeros
/interface wireguard enable wg-vpn
```

## 🔒 Sécurité

### Utiliser une clé pré-partagée

```routeros
/interface wireguard peers set [find interface=wg-vpn] \
    preshared-key="VOTRE_CLÉ_PRÉPARTAGÉE"
```

### Limiter les réseaux accessibles

Modifiez `allowed-address` pour restreindre :

```routeros
/interface wireguard peers set [find interface=wg-vpn] \
    allowed-address=10.8.0.0/24,192.168.1.10/32
```

### Activer le logging

```routeros
/system logging
add topics=wireguard action=memory
```

### Sauvegarder la configuration

```routeros
# Export complet
/export file=backup-wireguard

# Télécharger via FTP ou SFTP
# Ou copier depuis Files dans Winbox
```

## ⚠️ Dépannage

### Problème : Peer ne se connecte pas

```routeros
# Vérifier les logs
/log print where topics~"wireguard"

# Vérifier le endpoint
/interface wireguard peers print detail

# Tester la résolution DNS
/tool dns-lookup vps.monassurance.net

# Vérifier la connexion Internet
/ping 8.8.8.8
```

### Problème : Pas de handshake

```routeros
# Vérifier les clés
/interface wireguard print
/interface wireguard peers print detail

# Forcer une reconnexion
/interface wireguard peers disable [find interface=wg-vpn]
/interface wireguard peers enable [find interface=wg-vpn]
```

### Problème : Routes ne fonctionnent pas

```routeros
# Vérifier les routes
/ip route print where gateway=wg-vpn

# Vérifier le forwarding
/ip firewall filter print where chain=forward

# Tester le NAT
/ip firewall nat print where out-interface=wg-vpn
```

### Problème : Clients locaux ne peuvent pas utiliser le VPN

```routeros
# Vérifier le masquerade
/ip firewall nat print where action=masquerade

# Vérifier le pare-feu
/ip firewall filter print where out-interface=wg-vpn
```

## 🎯 Cas d'usage

### Cas 1 : Accès site à site

Connecter deux réseaux locaux via VPN :
- Site A : 192.168.1.0/24
- Site B : 192.168.20.0/24

Configuration : Autorisez les deux réseaux dans `allowed-address`.

### Cas 2 : Accès distant pour télétravail

Les employés se connectent au VPN et accèdent au réseau de l'entreprise via le routeur MikroTik.

### Cas 3 : Redondance Internet

Utilisez le VPN comme backup si la connexion principale tombe :

```routeros
/ip route
add dst-address=0.0.0.0/0 gateway=wg-vpn distance=2 comment="VPN backup"
```

## 📚 Ressources

- [MikroTik WireGuard Documentation](https://help.mikrotik.com/docs/display/ROS/WireGuard)
- [WireGuard Official Site](https://www.wireguard.com/)
- [MikroTik Forum](https://forum.mikrotik.com/)
- [RouterOS Manual](https://wiki.mikrotik.com/wiki/Manual:TOC)

## 📞 Support

### Commandes de diagnostic

```routeros
# Export de la config (sans mots de passe)
/export hide-sensitive file=diagnostic

# Informations système
/system resource print

# Version RouterOS
/system package print where name=routeros
```

### Communauté

- Forum MikroTik : https://forum.mikrotik.com/
- Reddit : r/mikrotik
- Discord : Communauté MikroTik

## 📋 Checklist de configuration

- [ ] Clés WireGuard générées
- [ ] Interface wg-vpn créée
- [ ] Peer configuré avec le serveur
- [ ] Adresse IP assignée (10.8.0.254/24)
- [ ] Routes ajoutées
- [ ] Règles de pare-feu configurées
- [ ] NAT masquerade activé
- [ ] DNS configuré
- [ ] Connexion testée (ping)
- [ ] Configuration sauvegardée

## 📜 Notes importantes

- **Keepalive** : Essentiel pour maintenir la connexion derrière NAT
- **MTU** : 1420 évite la fragmentation
- **Allowed-address** : Définit les réseaux routés via le VPN
- **Sauvegarde** : Exportez régulièrement la configuration
- **Sécurité** : Utilisez des clés fortes et changez-les périodiquement
- **Monitoring** : Surveillez les logs pour détecter les problèmes
