# Mise en oeuvre — Guide pas a pas

> Ce document est un tutoriel pratique. Il vous prend par la main,
> du VPS vierge jusqu'a Dokploy fonctionnel, en expliquant chaque action
> et ses consequences.
>
> **Public** : debutant a intermediaire. Aucune connaissance serveur requise.
>
> **Temps total** : environ 15-20 minutes.

---

## Table des matieres

- [Phase 1 — Preparer votre Mac (5 min)](#phase-1--preparer-votre-mac-5-min)
- [Phase 2 — Premiere connexion au VPS vierge (2 min)](#phase-2--premiere-connexion-au-vps-vierge-2-min)
- [Phase 3 — Telecharger et lancer le script (5 min)](#phase-3--telecharger-et-lancer-le-script-5-min)
- [Phase 4 — Tester et activer SSH (3 min)](#phase-4--tester-et-activer-ssh-3-min)
- [Phase 5 — Installer Dokploy (5 min)](#phase-5--installer-dokploy-5-min)
- [Phase 6 — Configurer les DNS](#phase-6--configurer-les-dns)
- [Phase 7 — Verifications finales](#phase-7--verifications-finales)
- [Precautions et implications](#precautions-et-implications)
- [Checklist recapitulative](#checklist-recapitulative)

---

## Phase 1 — Preparer votre Mac (5 min)

> **Ou** : sur votre Mac, dans le Terminal.
> **Pourquoi** : creer la cle SSH qui servira a vous connecter au serveur
> sans mot de passe.

### Etape 1.1 — Ouvrir le Terminal

Sur votre Mac :
- Appuyez sur **Cmd + Espace** (Spotlight)
- Tapez **Terminal**
- Appuyez sur **Entree**

Une fenetre noire (ou blanche) s'ouvre avec un curseur qui clignote.
C'est votre terminal. Toutes les commandes ci-dessous s'y tapent.

### Etape 1.2 — Verifier si vous avez deja une cle SSH

```bash
ls ~/.ssh/id_ed25519.pub
```

**Deux resultats possibles :**

```
# RESULTAT A — La cle existe deja :
/Users/votre-nom/.ssh/id_ed25519.pub
→ Passez directement a l'etape 1.4
```

```
# RESULTAT B — La cle n'existe pas :
ls: /Users/votre-nom/.ssh/id_ed25519.pub: No such file or directory
→ Continuez a l'etape 1.3
```

### Etape 1.3 — Generer une cle SSH (seulement si elle n'existe pas)

```bash
ssh-keygen -t ed25519 -C "votre-email@example.com"
```

> **Qu'est-ce que cette commande fait ?**
> Elle cree deux fichiers :
> - `~/.ssh/id_ed25519` — La cle **privee** (votre "mot de passe secret")
> - `~/.ssh/id_ed25519.pub` — La cle **publique** (un "cadenas" a donner au serveur)

Le terminal pose 3 questions :

```
Enter file in which to save the key (/Users/votre-nom/.ssh/id_ed25519):
```
**Action** : appuyez sur **Entree** sans rien taper (garder l'emplacement par defaut).

```
Enter passphrase (empty for no passphrase):
```
**Action** : deux choix :
- Appuyez sur **Entree** (pas de passphrase) → plus simple, connexion sans rien taper
- Tapez un mot de passe → plus securise, mais demande a chaque connexion

> **Conseil pour debutant** : appuyez sur Entree (pas de passphrase).
> Vous pourrez en ajouter une plus tard.

```
Enter same passphrase again:
```
**Action** : appuyez sur **Entree** a nouveau.

**Resultat attendu** :
```
Your identification has been saved in /Users/votre-nom/.ssh/id_ed25519
Your public key has been saved in /Users/votre-nom/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:AbCdEf123456... votre-email@example.com
```

### Etape 1.4 — Copier votre cle publique

```bash
cat ~/.ssh/id_ed25519.pub
```

**Resultat** (une seule longue ligne) :
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGxPm7oJ3Kq... votre-email@example.com
```

**Action** : selectionnez **TOUTE** la ligne et copiez-la (**Cmd + C**).

> **ATTENTION** :
> - Copiez la cle **publique** (`.pub`) et **jamais** la cle privee (sans `.pub`)
> - La cle publique commence toujours par `ssh-ed25519` ou `ssh-rsa`
> - C'est une seule ligne, meme si elle semble longue

### Etape 1.5 — Notez votre cle quelque part

Collez la cle dans un endroit temporaire (Notes, un fichier texte)
pour pouvoir la copier facilement quand vous serez sur le VPS.

> **Pourquoi ?** Quand vous serez connecte au VPS, vous ne pourrez pas
> facilement copier depuis le terminal de votre Mac vers le terminal du VPS.
> Avoir la cle dans un fichier accessible facilite le copier-coller.

---

## Phase 2 — Premiere connexion au VPS vierge (2 min)

> **Ou** : sur votre Mac, dans le Terminal.
> **Pourquoi** : se connecter au serveur pour y lancer le script.

### Etape 2.1 — Trouver l'IP et le mot de passe root de votre VPS

Ces informations sont fournies par votre hebergeur :

| Hebergeur | Ou trouver |
|-----------|------------|
| **OVH** | Email "Votre VPS est pret" ou OVH Manager → VPS → Informations generales |
| **Hetzner** | Email de creation ou Cloud Console → Servers |
| **DigitalOcean** | Email ou Dashboard → Droplets |

Vous avez besoin de :
- **L'adresse IP** du VPS (ex: `51.178.42.100`)
- **Le mot de passe root** (dans l'email ou defini a la creation)

### Etape 2.2 — Se connecter en root

```bash
ssh root@51.178.42.100
```

> Remplacez `51.178.42.100` par **votre** IP.

**Premiere connexion** — le terminal affiche :
```
The authenticity of host '51.178.42.100' can't be established.
ED25519 key fingerprint is SHA256:xYzAbC123...
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

**Action** : tapez **yes** et appuyez sur **Entree**.

> **Qu'est-ce que ce message signifie ?**
> Votre Mac ne connait pas encore ce serveur. Il vous demande de confirmer
> que c'est bien le bon. C'est normal a la premiere connexion.
> Ce message n'apparaitra plus par la suite.

**Ensuite** :
```
root@51.178.42.100's password:
```

**Action** : tapez le mot de passe root et appuyez sur **Entree**.

> **Note** : le mot de passe ne s'affiche PAS quand vous le tapez
> (pas de `*` ni de points). C'est normal. Tapez-le a l'aveugle et validez.

**Resultat attendu** :
```
Welcome to Ubuntu 24.04.1 LTS
root@vps-abc123:~#
```

Vous etes connecte au VPS en tant que **root** (administrateur).

> **PRECAUTION** : a partir de maintenant, vous etes root sur le serveur.
> Chaque commande s'execute avec les pleins pouvoirs. Une mauvaise commande
> (comme `rm -rf /`) pourrait detruire le serveur. Tapez les commandes
> exactement comme indique.

---

## Phase 3 — Telecharger et lancer le script (5 min)

> **Ou** : sur le VPS (vous etes connecte en root depuis la phase 2).
> **Pourquoi** : preparer et securiser le serveur automatiquement.

### Etape 3.1 — Telecharger le script

```bash
wget https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/Docker/dockploy-deployment/quick-prepare-vps-for-dockploy/quick-prepare-vps.sh
```

> **`wget`** est un outil qui telecharge un fichier depuis internet.
> Si la commande echoue ("wget: command not found"), essayez :
> ```bash
> curl -O https://raw.githubusercontent.com/lwilly3/scripts-radioManager/main/Docker/dockploy-deployment/quick-prepare-vps-for-dockploy/quick-prepare-vps.sh
> ```

**Verifier que le fichier est la** :
```bash
ls -lh quick-prepare-vps.sh
```

Resultat attendu :
```
-rw-r--r-- 1 root root 51K Mar 13 14:30 quick-prepare-vps.sh
```

### Etape 3.2 — Rendre le script executable

```bash
chmod +x quick-prepare-vps.sh
```

> **Qu'est-ce que ca fait ?**
> Par defaut, un fichier telecharge ne peut pas etre "lance" comme un programme.
> `chmod +x` ajoute la permission d'"execution" au fichier.

### Etape 3.3 — Lancer le script avec votre cle SSH

```bash
sudo SSH_PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGxPm7oJ3Kq... votre-email@example.com" bash quick-prepare-vps.sh
```

> **IMPORTANT** : remplacez le contenu entre guillemets par **votre vraie cle publique**
> copiee a l'etape 1.4.
>
> **Qu'est-ce que cette commande fait ?**
> - `sudo` : execute en tant qu'administrateur
> - `SSH_PUBKEY="..."` : passe votre cle publique au script
> - `bash quick-prepare-vps.sh` : lance le script
>
> **Qu'est-ce que `SSH_PUBKEY` change ?**
> Sans : le serveur accepte les connexions par mot de passe (moins securise)
> Avec : le serveur accepte UNIQUEMENT votre cle SSH (beaucoup plus securise)

### Etape 3.4 — Repondre aux questions du script

**Question 1 — Changer le port SSH ?**
```
Voulez-vous changer le port SSH par defaut (22) ? [y/N]
```

**Action** : appuyez sur **N** puis **Entree** (ou juste **Entree**).

> **Explication** : le port 22 est le port standard pour SSH. Le changer
> ajoute une petite couche de securite (les scanners automatiques ne testent
> que le port 22), mais complique la connexion (il faut se souvenir du port).
>
> **Pour un debutant** : gardez le port 22. Fail2ban protege deja
> contre les attaques brute-force.

**Question 2 — Confirmer la configuration**
```
Continuer avec cette configuration ? [y/N]
```

**Action** : tapez **y** puis **Entree**.

> Lisez le resume affiche avant de confirmer. Verifiez que l'utilisateur,
> le port et le fuseau horaire sont corrects.

**Question 3 — Mot de passe pour l'utilisateur `dokploy`**
```
Definition du mot de passe pour 'dokploy' :
   (Utilisez un mot de passe fort : min 16 caracteres, lettres+chiffres+symboles)
New password:
```

**Action** : tapez un mot de passe **fort** et appuyez sur **Entree**.
Puis retapez-le pour confirmer.

> **PRECAUTIONS CRITIQUES sur ce mot de passe :**
>
> 1. **C'est votre porte de secours.** Si vous perdez votre Mac (et donc
>    votre cle SSH), ce mot de passe sera le SEUL moyen de vous reconnecter
>    au serveur via la console KVM de votre hebergeur.
>
> 2. **Il sert aussi pour `sudo`.** Quand vous serez connecte en tant que
>    `dokploy` et que vous voudrez executer une commande admin (installer
>    un paquet, redemarrer un service), le system demandera ce mot de passe.
>
> 3. **Notez-le dans un gestionnaire de mots de passe** (Bitwarden, 1Password,
>    KeePass). Ne le stockez PAS dans un fichier texte ou un post-it.
>
> 4. **Conseils pour un bon mot de passe** :
>    - Minimum 16 caracteres
>    - Melangez majuscules, minuscules, chiffres, symboles
>    - Exemple : `K8z!mP2@vL9$nQ5#xR7`
>    - Ou une phrase de passe : `MonServeurRadio-2026!EstPret`
>
> **Le mot de passe ne s'affiche PAS quand vous le tapez.** C'est normal.

### Etape 3.5 — Attendre la fin du script

Le script deroule 12 etapes automatiquement (3-5 minutes) :

```
========================================
  Etape 1/12 : Mise a jour du systeme
========================================
Systeme mis a jour

========================================
  Etape 2/12 : Installation des outils essentiels
========================================
Outils essentiels installes

... (continue jusqu'a l'etape 12) ...

==========================================
  PREPARATION TERMINEE AVEC SUCCES !
==========================================
```

> **Si le script s'arrete avec une erreur :**
>
> Le message indiquera la ligne et la commande qui a echoue :
> ```
> ERREUR a la ligne 142. Consultez le log : /var/log/vps-prepare-20260313_143000.log
> Commande qui a echoue : apt update -qq
> ```
>
> **Causes courantes** :
> - Pas de connexion internet → verifiez avec `ping -c 2 google.com`
> - Disque plein → verifiez avec `df -h`
> - Paquet en cours d'installation par un autre processus → attendez 2 minutes et relancez

### Etape 3.6 — Lire le resume final

A la fin, le script affiche un resume complet. **Lisez-le attentivement.**

Les informations importantes a noter :
- **Port SSH** : le port pour se connecter (22 par defaut)
- **Log du script** : le chemin du fichier log en cas de probleme
- **Backup SSH** : le chemin du backup de la config SSH originale

> **NE FERMEZ PAS cette session.** Vous en avez besoin comme filet de securite
> jusqu'a ce que la nouvelle connexion SSH soit testee et fonctionnelle.

---

## Phase 4 — Tester et activer SSH (3 min)

> **Ou** : sur votre Mac, dans un **NOUVEAU** terminal.
> **Pourquoi** : verifier que la cle SSH fonctionne avant d'activer les changements.

### Etape 4.1 — Ouvrir un NOUVEAU terminal

Sur votre Mac :
- **Cmd + N** dans Terminal (ou **Cmd + T** pour un nouvel onglet)

> **CRITIQUE** : ne fermez PAS le terminal ou vous etes connecte en root !
> C'est votre filet de securite. Si la nouvelle connexion ne marche pas,
> vous pourrez corriger depuis l'ancien terminal.

### Etape 4.2 — Tester la connexion par cle SSH

```bash
ssh dokploy@51.178.42.100
```

> Remplacez `51.178.42.100` par votre IP.

**Trois resultats possibles :**

```
# RESULTAT A — SUCCES (pas de mot de passe demande) :
Welcome to Ubuntu 24.04.1 LTS
dokploy@vps-abc123:~$

→ Parfait ! La cle SSH fonctionne. Passez a l'etape 4.3.
```

```
# RESULTAT B — Mot de passe demande :
dokploy@51.178.42.100's password:

→ La cle SSH n'a pas ete reconnue. Voir "Depannage" ci-dessous.
```

```
# RESULTAT C — Connexion refusee :
ssh: connect to host 51.178.42.100 port 22: Connection refused

→ SSH ne tourne pas ou le port est mauvais. Voir "Depannage" ci-dessous.
```

**Depannage resultat B** (mot de passe demande) :

```bash
# Retournez dans le terminal root (l'ancien) et verifiez :

# 1. Le fichier authorized_keys existe-t-il ?
cat /home/dokploy/.ssh/authorized_keys
# Il devrait afficher votre cle publique

# 2. Les permissions sont-elles correctes ?
ls -la /home/dokploy/.ssh/
# Attendu :
# drwx------ 2 dokploy dokploy  .ssh/
# -rw------- 1 dokploy dokploy  authorized_keys

# 3. Si les permissions sont mauvaises, corriger :
chmod 700 /home/dokploy/.ssh
chmod 600 /home/dokploy/.ssh/authorized_keys
chown -R dokploy:dokploy /home/dokploy/.ssh

# 4. Retester depuis le nouveau terminal sur votre Mac
```

**Depannage resultat C** (connexion refusee) :

```bash
# Dans le terminal root, verifier que SSH tourne :
sudo systemctl status sshd

# S'il ne tourne pas :
sudo systemctl start sshd
```

### Etape 4.3 — Redemarrer SSH (depuis le VPS)

Une fois la connexion testee et fonctionnelle, **retournez dans le terminal root**
(l'ancien) et redemarrez SSH pour appliquer tous les changements de securite :

```bash
sudo systemctl restart sshd
```

> **Qu'est-ce que cette commande fait ?**
> Elle redemarrer le service SSH. Jusqu'ici, les modifications de securite
> (root desactive, cle obligatoire, etc.) etaient ecrites dans le fichier
> de config mais pas encore appliquees. Apres le redemarrage, elles sont actives.
>
> **CONSEQUENCE IRREVERSIBLE** : apres cette commande, la connexion en root
> via SSH ne fonctionne plus. Seul `dokploy` avec la cle SSH peut se connecter.
> C'est pourquoi on teste AVANT de redemarrer.

### Etape 4.4 — Re-tester apres le redemarrage

Dans le **nouveau** terminal (pas celui en root) :

```bash
ssh dokploy@51.178.42.100
```

Si ca fonctionne → vous pouvez **fermer le terminal root en toute securite**.

### Etape 4.5 — (Recommande) Creer un alias SSH

Pour ne plus taper l'IP a chaque fois, creez un raccourci sur votre Mac :

```bash
nano ~/.ssh/config
```

Ajoutez ces lignes :

```
Host vps
    HostName 51.178.42.100
    User dokploy
    Port 22
    IdentityFile ~/.ssh/id_ed25519
```

Sauvegardez : **Ctrl + O**, **Entree**, **Ctrl + X**.

Desormais, pour vous connecter :

```bash
ssh vps
```

C'est tout. Deux mots, pas d'IP a retenir.

---

## Phase 5 — Installer Dokploy (5 min)

> **Ou** : sur le VPS, connecte en tant que `dokploy`.
> **Pourquoi** : Dokploy gere le deploiement de vos applications (RadioManager).

### Etape 5.1 — Se connecter

```bash
ssh vps
# ou : ssh dokploy@51.178.42.100
```

### Etape 5.2 — Installer Dokploy

```bash
curl -sSL https://dokploy.com/install.sh | sh
```

> **Qu'est-ce que cette commande fait ?**
> - `curl -sSL` : telecharge le script d'installation de Dokploy
> - `| sh` : l'execute immediatement
>
> L'installation prend 3-5 minutes. Elle installe Docker (si absent)
> et deploie Dokploy en tant que container Docker.

Attendez jusqu'a voir un message de succes.

### Etape 5.3 — Acceder a Dokploy

Ouvrez dans votre navigateur :

```
https://51.178.42.100:3000
```

> **Premiere visite** : le navigateur affichera un avertissement de securite
> ("Votre connexion n'est pas privee"). C'est normal — le certificat SSL
> n'est pas encore configure. Cliquez sur "Avance" puis "Continuer".
>
> Ce probleme disparaitra apres la configuration du domaine et de Traefik (phase 6).

Dokploy vous demandera de creer un compte administrateur.
**Notez ces identifiants** dans votre gestionnaire de mots de passe.

---

## Phase 6 — Configurer les DNS

> **Ou** : sur l'interface de votre registrar DNS (OVH, Cloudflare, etc.).
> **Pourquoi** : pour acceder a vos services via un nom de domaine
> au lieu d'une adresse IP.

### Etape 6.1 — Ajouter les enregistrements DNS

Connectez-vous a votre gestionnaire DNS et ajoutez ces enregistrements de type **A** :

```
Type   Nom                     Valeur           TTL
A      dokploy.audace.ovh      51.178.42.100    300
A      app.radio.audace.ovh    51.178.42.100    300
A      api.radio.audace.ovh    51.178.42.100    300
```

> Remplacez `51.178.42.100` par votre IP et `audace.ovh` par votre domaine.
>
> **TTL 300** = 5 minutes. Les modifications DNS prendront jusqu'a 5 minutes
> pour se propager. En attendant, continuez avec l'IP directe.

### Etape 6.2 — Verifier la propagation

```bash
# Sur votre Mac
nslookup dokploy.audace.ovh
```

Resultat attendu :
```
Name:    dokploy.audace.ovh
Address: 51.178.42.100
```

Si l'adresse correspond a votre IP → les DNS sont propages.

> **Si ca ne marche pas** : attendez 5-15 minutes et retestez.
> Les DNS prennent parfois du temps a se propager dans le monde entier.

---

## Phase 7 — Verifications finales

> **Ou** : sur le VPS, connecte en tant que `dokploy`.
> **Pourquoi** : s'assurer que tout est bien en place.

### Checklist de verification

Lancez ces commandes une par une et verifiez les resultats attendus :

```bash
# 1. Pare-feu actif ?
sudo ufw status
# Attendu : Status: active
# Ports : 22, 80, 443, 3000

# 2. Fail2ban actif ?
sudo fail2ban-client status
# Attendu : Number of jail: 2
# Jail list: recidive, sshd

# 3. Swap actif ?
free -h
# Attendu : la ligne "Swap" montre 2.0Gi (ou la taille choisie)

# 4. Docker tourne ?
docker ps
# Attendu : liste des containers Dokploy

# 5. Backups configures ?
cat /etc/cron.d/backup-postgres
# Attendu : le cron job de backup

# 6. Mises a jour auto actives ?
sudo systemctl status unattended-upgrades
# Attendu : active (running)

# 7. Espace disque correct ?
df -h /
# Attendu : il reste au moins 50% libre

# 8. Protection Docker-UFW en place ?
sudo grep "DOCKER-USER" /etc/ufw/after.rules
# Attendu : des lignes contenant DOCKER-USER
```

Si tout est bon → votre VPS est pret pour RadioManager.

---

## Precautions et implications

### Ce que le script change sur votre serveur

Apres le script, votre serveur n'est **plus** un VPS standard.
Voici les changements et leurs implications :

#### Connexion root desactivee

```
AVANT : ssh root@IP → fonctionne
APRES : ssh root@IP → "Permission denied"
```

**Implication** : vous ne pouvez plus JAMAIS vous connecter en root via SSH.
Tout passe par `dokploy` + `sudo`.

**Pourquoi c'est bien** : un attaquant qui devine le mot de passe root aurait
un acces total. Avec `dokploy`, il faudrait trouver le nom d'utilisateur,
la cle SSH, ET le mot de passe sudo.

**Si vous avez besoin de root** :
```bash
# Connecte en tant que dokploy
sudo -i
# Vous etes maintenant root (tapez "exit" pour revenir a dokploy)
```

#### Mot de passe SSH desactive (si SSH_PUBKEY fourni)

```
AVANT : ssh dokploy@IP → demande un mot de passe → connexion
APRES : ssh dokploy@IP → utilise la cle SSH → connexion (aucun mot de passe)
        ssh hacker@IP → "Permission denied (publickey)"
```

**Implication** : seul quelqu'un qui possede la cle privee correspondante
peut se connecter. Le mot de passe ne fonctionne PAS pour SSH.

**Pourquoi c'est bien** : aucun brute-force possible. Un mot de passe
peut etre devine, une cle ED25519 non.

**Risque** : si vous perdez la cle privee ET n'avez pas de backup,
vous etes coupe du serveur (sauf via KVM, voir ci-dessous).

#### Le mot de passe dokploy sert encore a deux choses

Meme si SSH n'accepte plus les mots de passe, celui de `dokploy` sert pour :

1. **`sudo`** — quand vous executez `sudo apt update` sur le serveur,
   il demande le mot de passe de `dokploy`

2. **Console KVM** — si vous perdez votre Mac et sa cle SSH, la console
   KVM de votre hebergeur (un ecran virtuel branche au serveur) utilise
   le login `dokploy` + mot de passe classique (SSH n'est pas implique)

> **C'est pour ca qu'on ne doit JAMAIS oublier ce mot de passe.**

#### Ports bloques par defaut

```
Port 5432 (PostgreSQL)  → BLOQUE depuis internet, accessible entre containers
Port 6379 (Redis)       → BLOQUE depuis internet, accessible entre containers
Port 8080 (autres)      → BLOQUE depuis internet
```

**Implication** : vous ne pouvez PAS vous connecter a PostgreSQL depuis votre Mac
avec un outil comme DBeaver ou pgAdmin directement.

**Si vous avez besoin d'acceder a PostgreSQL depuis votre Mac** :
```bash
# Utilisez un tunnel SSH (votre Mac → SSH → VPS → PostgreSQL)
ssh -L 5432:localhost:5432 vps

# Puis dans un autre terminal, connectez-vous a PostgreSQL via localhost :
psql -h localhost -p 5432 -U postgres
```

Le tunnel SSH encapsule la connexion PostgreSQL dans le tunnel SSH securise.

#### Fail2ban peut vous bloquer

Si vous tapez 3 fois un mauvais mot de passe (ou si votre cle SSH echoue 3 fois),
votre IP est **bannie pendant 24 heures**.

**Comment savoir si vous etes banni** :
```
ssh: connect to host 51.178.42.100 port 22: Connection timed out
```

> Le message est "timed out" et PAS "Connection refused".
> "Connection refused" = SSH ne tourne pas.
> "Connection timed out" = votre IP est probablement bannie.

**Comment vous debannir** :
- Changez d'IP (connexion 4G via telephone)
- Ou utilisez la console KVM de votre hebergeur
- Puis : `sudo fail2ban-client set sshd unbanip VOTRE_IP`

#### Le swap consomme de l'espace disque

Le script cree un fichier de 2 GB sur le disque pour le swap.

**Implication** : 2 GB de votre disque sont reserves pour la memoire de secours.
Sur un VPS avec 20 GB de disque, il restera 18 GB pour vos applications.

**Pourquoi c'est necessaire** : sans swap, quand la RAM est pleine,
Linux tue des processus aleatoirement (souvent PostgreSQL → perte de donnees).

#### Les backups s'accumulent

Chaque nuit a 3h, un backup PostgreSQL est cree (~2-10 MB compresse).
Les backups de plus de 7 jours sont supprimes automatiquement.

**Implication** : environ 70 MB de backups maximum (7 jours x ~10 MB).
C'est negligeable.

#### Les mises a jour de securite s'installent seules

Chaque nuit, le systeme installe automatiquement les patchs de securite.

**Implication** : tres rarement, une mise a jour peut demander un reboot.
Vous verrez ce message a la connexion SSH :
```
*** System restart required ***
```

Le serveur ne redemarrera **jamais** tout seul. Redemarrez quand ca vous arrange :
```bash
sudo reboot
```

---

### Resumee des risques et mitigations

| Risque | Probabilite | Impact | Mitigation |
|--------|-------------|--------|-----------|
| Perte du Mac (cle SSH) | Moyenne | Eleve (perte d'acces) | Sauvegarder la cle dans 1Password + ajouter une 2e cle |
| IP bannie par Fail2ban | Moyenne | Faible (temporaire) | Changer d'IP (4G) ou attendre 24h |
| Mot de passe dokploy oublie | Faible | Moyen (plus de sudo) | Gestionnaire de mots de passe |
| Config SSH cassee | Faible | Eleve (perte d'acces) | Backup automatique + KVM |
| Disque plein | Faible | Eleve (serveur plante) | Rotation logs Docker + nettoyage |
| Mise a jour casse quelque chose | Tres faible | Moyen | Uniquement patchs securite, pas de mises a jour majeures |

---

### Les 3 choses a retenir absolument

```
1. NOTEZ LE MOT DE PASSE DOKPLOY
   → dans un gestionnaire de mots de passe
   → c'est votre porte de secours KVM

2. SAUVEGARDEZ VOTRE CLE SSH PRIVEE
   → dans 1Password / Bitwarden
   → ou sur une cle USB chiffree
   → JAMAIS par email / Slack / Git

3. SACHEZ OU EST LA CONSOLE KVM
   → OVH Manager → VPS → KVM
   → C'est votre acces d'urgence quand SSH ne marche plus
```

---

## Checklist recapitulative

Cochez chaque etape au fur et a mesure :

```
PREPARATION (Mac)
[ ] Cle SSH generee ou existante
[ ] Cle publique copiee

INSTALLATION (VPS)
[ ] Connecte en root au VPS
[ ] Script telecharge
[ ] Script lance avec SSH_PUBKEY
[ ] Mot de passe dokploy defini et note
[ ] Script termine sans erreur

ACTIVATION (Mac + VPS)
[ ] Connexion testee : ssh dokploy@IP (sans mot de passe)
[ ] SSH redemarre sur le VPS
[ ] Connexion re-testee apres redemarrage
[ ] Session root fermee

DOKPLOY
[ ] Dokploy installe
[ ] Interface accessible sur https://IP:3000
[ ] Compte admin cree

DNS
[ ] Enregistrements A crees
[ ] Propagation verifiee (nslookup)

VERIFICATIONS
[ ] Pare-feu actif (ufw status)
[ ] Fail2ban actif
[ ] Swap actif (free -h)
[ ] Backups configures
[ ] Mises a jour auto actives

SECURITE PERSONNELLE
[ ] Mot de passe dokploy sauvegarde (gestionnaire de mots de passe)
[ ] Cle SSH privee sauvegardee (gestionnaire ou cle USB)
[ ] Console KVM testee une fois (savoir ou la trouver)
[ ] (Optionnel) 2e cle SSH ajoutee sur le serveur
[ ] (Optionnel) Alias SSH configure dans ~/.ssh/config
```

---

*Derniere mise a jour : 2026-03-13 — Script quick-prepare-vps.sh v2.0*
*Projet RadioManager*
