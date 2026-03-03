# 🔄 Processus de mise à jour du plugin Radio Audace Player

> **Guide de référence pour les développeurs et agents IA (Claude, etc.)**
> Ce document décrit le processus complet pour publier une nouvelle version du plugin WordPress.

## 📋 Vue d'ensemble

Le plugin **Radio Audace Player** utilise un système de mise à jour automatique basé sur les **GitHub Releases**.
Le fichier `admin/updater.php` (`RAP_GitHub_Updater`) interroge l'API GitHub toutes les 12h pour détecter
une nouvelle release. Si le tag de la release est supérieur à `RAP_VERSION`, WordPress propose la mise à jour
dans le tableau de bord.

### Architecture du système de mise à jour

```
Repository GitHub (lwilly3/scripts-radioManager)
    │
    ├── Tag Git : v3.2.0
    └── GitHub Release : v3.2.0
         └── Asset : radio-audace-player.zip   ◄── OBLIGATOIRE (nom exact)
                │
                ▼
WordPress (site client)
    │
    ├── RAP_GitHub_Updater::check_update()
    │       → GET https://api.github.com/repos/lwilly3/scripts-radioManager/releases/latest
    │       → Compare tag_name (ex: v3.2.0) avec RAP_VERSION (ex: 3.1.0)
    │       → Si supérieur → injecte dans le transient update_plugins
    │
    ├── Tableau de bord > Extensions
    │       → Affiche "Mise à jour disponible"
    │       → Télécharge radio-audace-player.zip
    │       → Décompresse et remplace le dossier plugin
    │
    └── RAP_GitHub_Updater::after_update()
            → Purge le cache transient rap_github_release
```

## 🎯 Checklist rapide (Copier-coller)

```
□ 1. Incrémenter la version dans radio-audace-player.php (en-tête + RAP_VERSION)
□ 2. Mettre à jour CHANGELOG.md
□ 3. Commit avec message conventionnel
□ 4. Créer le tag Git (vX.Y.Z)
□ 5. Push commits + tag
□ 6. Créer la GitHub Release avec notes
□ 7. Générer le ZIP et l'attacher comme asset (nom exact : radio-audace-player.zip)
□ 8. Vérifier la release sur GitHub
```

---

## 🚀 Processus détaillé étape par étape

### Étape 1 — Incrémenter la version

**Fichier** : `wordpress-plugin/radio-audace-player/radio-audace-player.php`

Deux endroits à modifier **obligatoirement** (doivent être identiques) :

```php
// Ligne ~6 : En-tête WordPress
 * Version:     X.Y.Z

// Ligne ~17 : Constante PHP
define( 'RAP_VERSION', 'X.Y.Z' );
```

**Convention Semantic Versioning :**

| Type de changement | Exemple | Version |
|---|---|---|
| Correction de bug | Fix CSS, fix JS | `3.2.0` → `3.2.1` |
| Nouvelle fonctionnalité | Intégration RadioDJ, nouveau shortcode | `3.2.0` → `3.3.0` |
| Changement cassant / refonte | Refonte complète, API incompatible | `3.2.0` → `4.0.0` |

### Étape 2 — Mettre à jour le CHANGELOG

**Fichier** : `CHANGELOG.md` (racine du repo)

Ajouter une section en **haut** du fichier (après le header), format Keep a Changelog :

```markdown
## [X.Y.Z] - AAAA-MM-JJ

### Ajouté
- 🎵 Description de la fonctionnalité

### Modifié
- ⬆️ Description de la modification

### Corrigé
- 🐛 Description du fix
```

### Étape 3 — Commit

Message de commit conventionnel :

```bash
# Nouvelle fonctionnalité
git add -A
git commit -m "feat(plugin): description courte (vX.Y.Z)"

# Fix
git commit -m "fix(plugin): description courte (vX.Y.Z)"

# Plusieurs changements
git commit -m "feat(plugin): description principale (vX.Y.Z)

- Détail 1
- Détail 2
- Détail 3"
```

### Étape 4 — Créer le tag Git

```bash
git tag -a vX.Y.Z -m "vX.Y.Z — Description courte de la release"
```

**Important** : Le tag DOIT commencer par `v` (ex: `v3.2.0`). L'updater PHP fait `ltrim($tag, 'vV')` pour extraire la version.

### Étape 5 — Push vers GitHub

```bash
git push origin main --tags
```

Ceci pousse les commits ET le tag en une seule commande.

### Étape 6 — Créer la GitHub Release

La release GitHub est **indispensable** — c'est elle que l'updater WordPress interroge via l'endpoint `/releases/latest`.

#### Option A : Via GitHub CLI (`gh`)

```bash
gh release create vX.Y.Z \
  --title "vX.Y.Z — Description" \
  --notes "## Radio Audace Player vX.Y.Z

### Nouveautés
- Description des changements

### Mise à jour
Téléchargez radio-audace-player.zip ci-dessous ou laissez la mise à jour automatique."
```

#### Option B : Via l'API GitHub (curl)

```bash
# Récupérer le token depuis le keychain macOS
GITHUB_TOKEN=$(printf "protocol=https\nhost=github.com\n" \
  | git credential-osxkeychain get 2>/dev/null \
  | grep "^password=" | cut -d= -f2)

# Créer la release
curl -s -X POST "https://api.github.com/repos/lwilly3/scripts-radioManager/releases" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -d '{
    "tag_name": "vX.Y.Z",
    "name": "vX.Y.Z — Description courte",
    "body": "## Radio Audace Player vX.Y.Z\n\n### Nouveautés\n- Description...\n\n### Mise à jour\nTéléchargez `radio-audace-player.zip` ci-dessous.",
    "draft": false,
    "prerelease": false
  }'
```

La réponse JSON contient le `id` de la release (nécessaire pour l'étape 7).

#### Option C : Via l'interface web GitHub

1. Aller sur https://github.com/lwilly3/scripts-radioManager/releases/new
2. Choisir le tag `vX.Y.Z`
3. Titre : `vX.Y.Z — Description`
4. Écrire les notes de release en Markdown
5. **Ne pas publier encore** — d'abord attacher le ZIP (étape 7)

### Étape 7 — Générer et attacher le ZIP

#### Générer le ZIP

```bash
cd wordpress-plugin
zip -r ../radio-audace-player.zip radio-audace-player/ -x "radio-audace-player/.DS_Store"
```

**Structure requise du ZIP** (la racine DOIT être le dossier `radio-audace-player/`) :

```
radio-audace-player.zip
└── radio-audace-player/
    ├── radio-audace-player.php
    ├── admin/
    │   ├── settings.php
    │   └── updater.php
    ├── css/
    │   └── radio-audace-player.css
    ├── js/
    │   └── radio-audace-player.js
    ├── assets/
    │   └── default-logo.svg
    └── LISEZMOI.md
```

#### Attacher le ZIP à la release

##### Via GitHub CLI

```bash
gh release upload vX.Y.Z radio-audace-player.zip
```

##### Via l'API (curl)

```bash
RELEASE_ID=<id_retourné_à_l'étape_6>

curl -s -X POST \
  "https://uploads.github.com/repos/lwilly3/scripts-radioManager/releases/${RELEASE_ID}/assets?name=radio-audace-player.zip" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/zip" \
  --data-binary @radio-audace-player.zip
```

##### Via l'interface web

Glisser-déposer le fichier `radio-audace-player.zip` dans la zone "Attach binaries" de la page de release.

> ⚠️ **CRITIQUE** : L'asset DOIT s'appeler exactement `radio-audace-player.zip`.
> L'updater PHP cherche ce nom exact dans `get_download_url()`. Si le nom est différent,
> WordPress utilisera le `zipball_url` GitHub (qui contient tout le repo, pas juste le plugin).

#### Nettoyer le ZIP local

```bash
rm radio-audace-player.zip
```

Le `.gitignore` exclut déjà les `*.zip`.

### Étape 8 — Vérification

```bash
# Vérifier que la release est visible
curl -s "https://api.github.com/repos/lwilly3/scripts-radioManager/releases/latest" \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('Tag:', d['tag_name'])
print('Assets:', [a['name'] for a in d.get('assets', [])])
print('URL ZIP:', next((a['browser_download_url'] for a in d.get('assets', []) if a['name'] == 'radio-audace-player.zip'), 'MANQUANT !'))
"
```

Résultat attendu :

```
Tag: vX.Y.Z
Assets: ['radio-audace-player.zip']
URL ZIP: https://github.com/lwilly3/scripts-radioManager/releases/download/vX.Y.Z/radio-audace-player.zip
```

---

## ⚙️ Fonctionnement interne de l'updater (`admin/updater.php`)

### Fichiers impliqués

| Fichier | Rôle |
|---|---|
| `radio-audace-player.php` | Définit `RAP_VERSION` (version locale) |
| `admin/updater.php` | Classe `RAP_GitHub_Updater` — gère toute la logique |

### Hooks WordPress utilisés

| Hook | Méthode | Rôle |
|---|---|---|
| `pre_set_site_transient_update_plugins` | `check_update()` | Injecte la mise à jour si dispo |
| `plugins_api` | `plugin_info()` | Fournit les détails (modale "Voir les détails") |
| `upgrader_process_complete` | `after_update()` | Purge le cache après MAJ |

### Cache et performance

- **Clé transient** : `rap_github_release`
- **Durée** : 43200 secondes (12 heures)
- **Endpoint API** : `GET https://api.github.com/repos/lwilly3/scripts-radioManager/releases/latest`
- Le cache évite de dépasser les rate limits GitHub (60 requêtes/heure sans auth)

### Forcer la vérification (debug)

Pour forcer WordPress à re-vérifier immédiatement (utile après une release) :

```php
// Dans la console WP-CLI ou un mu-plugin temporaire
delete_transient('rap_github_release');
delete_site_transient('update_plugins');
```

Ou via WP-CLI :

```bash
wp transient delete rap_github_release
wp transient delete update_plugins --network  # Multisite
```

---

## 🤖 Instructions pour agents IA (Claude, Copilot, etc.)

### Quand on te demande de "pousser une mise à jour du plugin" :

1. **Modifier le code** du plugin selon la demande
2. **Incrémenter la version** dans `radio-audace-player.php` :
   - En-tête `* Version: X.Y.Z`
   - Constante `define('RAP_VERSION', 'X.Y.Z')`
   - Les deux valeurs DOIVENT être identiques
3. **Mettre à jour `CHANGELOG.md`** avec la date du jour et les changements
4. **Commit** avec message conventionnel (`feat(plugin):`, `fix(plugin):`, etc.)
5. **Tag Git** : `git tag -a vX.Y.Z -m "description"`
6. **Push** : `git push origin main --tags`
7. **Créer la GitHub Release** via l'API curl (le token est dans le keychain macOS) :
   ```bash
   GITHUB_TOKEN=$(printf "protocol=https\nhost=github.com\n" \
     | git credential-osxkeychain get 2>/dev/null \
     | grep "^password=" | cut -d= -f2)
   ```
8. **Générer le ZIP** :
   ```bash
   cd wordpress-plugin
   zip -r ../radio-audace-player.zip radio-audace-player/ -x "radio-audace-player/.DS_Store"
   cd ..
   ```
9. **Uploader le ZIP** comme asset de la release (nom exact : `radio-audace-player.zip`)
10. **Nettoyer** : `rm radio-audace-player.zip`

### Erreurs courantes à éviter

| Erreur | Conséquence | Solution |
|---|---|---|
| Oublier de modifier `RAP_VERSION` | L'updater ne détecte pas la MAJ | Toujours modifier les 2 endroits |
| Version en-tête ≠ constante | Comportement imprévisible | Garder les 2 valeurs synchronisées |
| Tag sans préfixe `v` | L'updater parse `ltrim($tag, 'vV')` — fonctionne, mais convention non respectée | Toujours préfixer avec `v` |
| Asset ZIP mal nommé | WordPress télécharge le zipball complet du repo | Nommer exactement `radio-audace-player.zip` |
| ZIP sans dossier racine | WordPress ne trouve pas le plugin après extraction | Le ZIP doit contenir `radio-audace-player/` comme racine |
| Oublier de créer la Release | Pas de MAJ côté WordPress (seul le tag ne suffit pas) | Toujours créer la Release GitHub en plus du tag |
| Release en `draft: true` | L'API `/releases/latest` ne retourne pas les drafts | Publier la release (pas de brouillon) |

### Commande tout-en-un (référence)

Script complet pour une release, à adapter :

```bash
# Variables
VERSION="X.Y.Z"
DESCRIPTION="Description courte"
REPO="lwilly3/scripts-radioManager"

# 1. Commit, tag, push
cd /Users/happi/App/scripts/scripts-radioManager
git add -A
git commit -m "feat(plugin): ${DESCRIPTION} (v${VERSION})"
git tag -a "v${VERSION}" -m "v${VERSION} — ${DESCRIPTION}"
git push origin main --tags

# 2. Token GitHub
GITHUB_TOKEN=$(printf "protocol=https\nhost=github.com\n" \
  | git credential-osxkeychain get 2>/dev/null \
  | grep "^password=" | cut -d= -f2)

# 3. Créer la release
RELEASE_ID=$(curl -s -X POST "https://api.github.com/repos/${REPO}/releases" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -d "{
    \"tag_name\": \"v${VERSION}\",
    \"name\": \"v${VERSION} — ${DESCRIPTION}\",
    \"body\": \"## Radio Audace Player v${VERSION}\n\n### Changements\n- ${DESCRIPTION}\",
    \"draft\": false,
    \"prerelease\": false
  }" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")

echo "Release ID: $RELEASE_ID"

# 4. Générer le ZIP
cd wordpress-plugin
zip -r ../radio-audace-player.zip radio-audace-player/ -x "radio-audace-player/.DS_Store"
cd ..

# 5. Uploader le ZIP
curl -s -X POST \
  "https://uploads.github.com/repos/${REPO}/releases/${RELEASE_ID}/assets?name=radio-audace-player.zip" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/zip" \
  --data-binary @radio-audace-player.zip \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK:', d['name'], d['state'])"

# 6. Nettoyage
rm radio-audace-player.zip
echo "✅ Release v${VERSION} publiée !"
```

---

## ⚠️ Dépannage

### La mise à jour n'apparaît pas dans WordPress

1. **Vérifier la release GitHub** : `https://api.github.com/repos/lwilly3/scripts-radioManager/releases/latest`
2. **Vérifier le tag** : le `tag_name` doit être supérieur à la version installée
3. **Vérifier l'asset** : doit être nommé `radio-audace-player.zip`
4. **Purger le cache** : `delete_transient('rap_github_release')` côté WordPress
5. **Forcer la vérification** : aller dans Tableau de bord > Mises à jour et cliquer "Vérifier à nouveau"

### L'installation échoue après téléchargement

- **Vérifier la structure du ZIP** : la racine doit être `radio-audace-player/`
- **Tester manuellement** : `unzip -l radio-audace-player.zip` pour voir le contenu
- **Permissions** : le serveur WordPress doit pouvoir écrire dans `wp-content/plugins/`

### Rate limit GitHub

- L'API GitHub autorise 60 requêtes/heure sans authentification
- Le cache transient de 12h protège contre ça
- Si problème, vérifier que le transient fonctionne (`get_transient('rap_github_release')`)

---

## 📚 Références

- **Repository** : https://github.com/lwilly3/scripts-radioManager
- **Plugin source** : `wordpress-plugin/radio-audace-player/`
- **Updater** : `wordpress-plugin/radio-audace-player/admin/updater.php`
- **API GitHub Releases** : https://docs.github.com/en/rest/releases
- **WordPress Plugin Update API** : https://developer.wordpress.org/plugins/wordpress-org/how-your-readme-txt-works/

---

**Version de ce guide** : 1.0
**Dernière mise à jour** : 3 mars 2026
