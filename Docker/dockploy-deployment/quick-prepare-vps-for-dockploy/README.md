# Quick Prepare VPS pour Dokploy — v2.0

[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20|%2022.04%20|%2020.04-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Debian](https://img.shields.io/badge/Debian-11%20|%2012-A81D33?logo=debian&logoColor=white)](https://www.debian.org/)
[![Security](https://img.shields.io/badge/Security-Hardened-green.svg)](https://github.com/lwilly3/scripts-radioManager)
[![Version](https://img.shields.io/badge/Version-2.0-blue.svg)]()

> Script automatique de preparation et securisation d'un VPS pour Dokploy.
> Concu pour le projet **RadioManager** (FastAPI + React + PostgreSQL).

---

## Quick Start

### Methode recommandee (avec cle SSH)

```bash
# Sur votre Mac d'abord — recuperer votre cle publique :
cat ~/.ssh/id_ed25519.pub
# (Si le fichier n'existe pas : ssh-keygen -t ed25519 -C "email@example.com")

# Sur le VPS (connecte en root) — lancer le script :
sudo SSH_PUBKEY="ssh-ed25519 AAAA...votre-cle..." bash quick-prepare-vps.sh
```

Apres le script :
```bash
# Depuis votre Mac — connexion directe sans mot de passe :
ssh dokploy@IP_DU_VPS
```

### Methode simple

```bash
sudo bash quick-prepare-vps.sh
```

---

## Ce que fait le script (12 etapes)

```
Etape  1  Mise a jour systeme (apt update + upgrade)
Etape  2  Installation outils essentiels (curl, git, htop, fail2ban, etc.)
Etape  3  Configuration fuseau horaire (Africa/Douala par defaut)
Etape  4  Creation utilisateur sudo + cle SSH (si fournie)
Etape  5  Securisation SSH (root desactive, cle obligatoire, timeout 30s)
Etape  6  Pare-feu UFW (ports 22, 80, 443, 3000)
Etape  7  Protection Docker-UFW (empeche Docker de contourner le pare-feu)
Etape  8  Fail2ban (ban 24h + recidivistes 7 jours)
Etape  9  Swap 2G (evite les crashes OOM)
Etape 10  Mises a jour de securite automatiques (unattended-upgrades)
Etape 11  Optimisations kernel Docker (sysctl, limites fichiers, rotation logs)
Etape 12  Repertoires + backup PostgreSQL quotidien (retention 7 jours)
```

### Avant / Apres

```
VPS vierge                              Apres le script
├── Root uniquement                     ├── Utilisateur sudo dedie
├── Pas de pare-feu                     ├── UFW actif + Docker protege
├── SSH ouvert a tous                   ├── SSH restreint (cle uniquement)
├── Pas de protection brute-force       ├── Fail2ban (24h ban + 7j recidive)
├── Pas de swap                         ├── Swap 2G (anti-OOM)
├── Pas de mises a jour auto            ├── Patchs securite automatiques
├── Pas de rotation logs                ├── Logs Docker 30 MB max/container
├── Pas de backups                      ├── Backup PostgreSQL quotidien
└── Pas de hardening reseau             └── Anti-spoofing, anti-redirect, etc.
```

---

## Options

| Variable | Defaut | Description |
|----------|--------|-------------|
| `SSH_PUBKEY` | _(vide)_ | Cle publique SSH — active l'auth par cle et desactive le mot de passe |
| `NEW_USER` | `dokploy` | Nom de l'utilisateur systeme |
| `SSH_PORT` | `22` | Port SSH (modifiable interactivement aussi) |
| `TIMEZONE` | `Africa/Douala` | Fuseau horaire |
| `SWAP_SIZE` | `2G` | Taille du fichier swap |

```bash
# Exemple avec tout personnalise
sudo NEW_USER="deployer" SSH_PORT=2222 TIMEZONE="Europe/Paris" \
     SWAP_SIZE="4G" SSH_PUBKEY="ssh-ed25519 AAAA..." \
     bash quick-prepare-vps.sh
```

---

## Connexion SSH apres le script

| Methode | Commande |
|---------|----------|
| Avec cle SSH (recommande) | `ssh dokploy@IP` |
| Port personnalise | `ssh -p 2222 dokploy@IP` |
| Alias SSH | `ssh vps` (apres configuration `~/.ssh/config`) |

Pour configurer un alias SSH sur votre Mac :

```
# Dans ~/.ssh/config
Host vps
    HostName IP_DU_VPS
    User dokploy
    Port 22
    IdentityFile ~/.ssh/id_ed25519
```

Puis : `ssh vps` suffit.

---

## Apres le script — Prochaines etapes

```
1. Redemarrer SSH           sudo systemctl restart sshd
2. Tester la connexion      ssh dokploy@IP  (dans un nouveau terminal !)
3. Installer Dokploy        curl -sSL https://dokploy.com/install.sh | sh
4. Configurer les DNS       dokploy/app/api.domaine.com → IP_DU_VPS
5. Acceder a Dokploy        https://IP_DU_VPS:3000
6. Deployer RadioManager    Backend + Frontend + PostgreSQL via Dokploy
7. Verifier les backups     ls -lh /backup/postgres/  (le lendemain)
8. Ameliorations v2.1       Backup off-site + Monitoring (voir ci-dessous)
```

> **Une fois les services valides**, voir **[PROCHAINES-AMELIORATIONS.md](PROCHAINES-AMELIORATIONS.md)**
> pour ajouter le backup off-site (Backblaze B2) et le monitoring (Uptime Kuma + Telegram).

---

## Commandes utiles

```bash
# Securite
sudo ufw status verbose                   # Etat pare-feu
sudo fail2ban-client status sshd          # IP bannies SSH
sudo fail2ban-client status recidive      # Recidivistes
sudo fail2ban-client set sshd unbanip IP  # Debannir une IP

# Monitoring
htop                                      # CPU, RAM, processus
df -h                                     # Espace disque
free -h                                   # Memoire + swap
docker stats                              # Ressources par container

# Backups
ls -lh /backup/postgres/                  # Lister les backups PostgreSQL

# Logs
sudo tail -50 /var/log/auth.log           # Tentatives SSH
sudo tail -50 /var/log/fail2ban.log       # Bannissements
cat /var/log/vps-prepare-*.log            # Log du script
```

---

## Perte d'acces — Recovery rapide

| Scenario | Solution |
|----------|----------|
| Mac perdu | Console KVM OVH + mot de passe dokploy → ajouter nouvelle cle SSH |
| Cle SSH supprimee | KVM ou `ssh-copy-id` si mot de passe encore actif |
| IP bannie par Fail2ban | Changer d'IP (4G telephone) ou KVM → debannir |
| Config SSH cassee | KVM → restaurer backup (`/etc/ssh/sshd_config.backup.*`) |
| Mot de passe oublie | KVM en root → `passwd dokploy` |

**Prevention** : sauvegarder la cle privee dans un gestionnaire de mots de passe
(1Password, Bitwarden) et ajouter plusieurs cles SSH sur le serveur.

> Pour les procedures detaillees de chaque scenario, voir le
> **[Guide complet VPS](GUIDE-COMPLET-VPS.md#8-perte-dacces--recovery)**.

---

## Documentation

| Document | Contenu |
|----------|---------|
| **[MISE-EN-OEUVRE.md](MISE-EN-OEUVRE.md)** | Tutoriel pas a pas : du VPS vierge a Dokploy, avec precautions et implications |
| **[GUIDE-COMPLET-VPS.md](GUIDE-COMPLET-VPS.md)** | Guide exhaustif : concepts, SSH, securite, recovery, maintenance, glossaire |
| **[PERSISTANCE-ET-RESTAURATION.md](PERSISTANCE-ET-RESTAURATION.md)** | Volumes Docker, backups PostgreSQL, restauration et reconstruction complete |
| [PREPARATION-VPS-OVH.md](PREPARATION-VPS-OVH.md) | Guide manuel de preparation (avant le script) |
| [POST-INSTALLATION-STATE.md](POST-INSTALLATION-STATE.md) | Etat attendu du serveur apres preparation |
| [FAIL2BAN-EMAIL-NOTIFICATIONS.md](FAIL2BAN-EMAIL-NOTIFICATIONS.md) | Configurer les alertes email Fail2ban |
| **[PROCHAINES-AMELIORATIONS.md](PROCHAINES-AMELIORATIONS.md)** | Backup off-site (Backblaze B2) + Monitoring (Uptime Kuma + Telegram) |

---

## Nouveautes v2.0 (par rapport a v1.0)

| Amelioration | v1.0 | v2.0 |
|-------------|------|------|
| Cle SSH automatique | Manuel apres le script | `SSH_PUBKEY=...` auto |
| Docker bypass UFW | Pas gere (ports internes exposes) | Regles `DOCKER-USER` |
| Fail2ban | 1h de ban, pas de recidive | 24h + 7 jours recidivistes |
| Swap | Absent | 2G par defaut, configurable |
| Mises a jour securite | Manuelles | `unattended-upgrades` automatique |
| Logs Docker | Pas de rotation (disque plein) | Max 30 MB par container |
| Hardening reseau | Basique | Anti-spoofing, anti-redirect, anti-source-route |
| SSH renforce | `Protocol 2` (obsolete) | `LoginGraceTime 30`, `PermitEmptyPasswords no` |
| Backup PostgreSQL | Absent | Cron quotidien, retention 7 jours |
| Logging script | Pas de log | `tee` vers fichier + `trap ERR` |
| Idempotence | Duplication si relance | Marqueurs `BEGIN/END` |

L'ancien script est sauvegarde dans `bakup-script/quick-prepare-vps.v1.sh`.

---

## Prerequis

- **OS** : Ubuntu 20.04+ ou Debian 11+
- **RAM** : 2 GB minimum (4 GB recommande)
- **CPU** : 1 vCore minimum (2 recommande)
- **Disque** : 20 GB minimum (40 GB recommande)
- **Acces** : root SSH ou console KVM

---

## FAQ

**Q: Le script peut-il etre lance plusieurs fois ?**
Oui, il est idempotent. Il detecte les configurations existantes et ne les duplique pas.

**Q: Et si je perds mon Mac ?**
Console KVM de votre hebergeur + mot de passe `dokploy`. Voir [GUIDE-COMPLET-VPS.md](GUIDE-COMPLET-VPS.md#scenario-1--mac-perdu-ou-vole).

**Q: Quel mot de passe retenir ?**
Celui du user `dokploy` — il sert pour `sudo` et la connexion KVM d'urgence.

**Q: Mon port PostgreSQL est-il protege ?**
Oui. Le script empeche Docker de l'exposer publiquement via les regles `DOCKER-USER`.

**Q: Comment voir le log du script ?**
`cat /var/log/vps-prepare-*.log`

**Q: Fonctionne sur CentOS/Rocky ?**
Non, Ubuntu et Debian uniquement.

---

<div align="center">

**[Mise en oeuvre](MISE-EN-OEUVRE.md)** | **[Guide complet](GUIDE-COMPLET-VPS.md)** | **[Persistance & Restauration](PERSISTANCE-ET-RESTAURATION.md)** | **[Prochaines ameliorations](PROCHAINES-AMELIORATIONS.md)** | **[Preparation manuelle](PREPARATION-VPS-OVH.md)**

</div>
