# Radio Audace Player v3 — Plugin WordPress

Plugin WordPress personnalise pour le streaming audio de **Radio Audace 106.8 FM**.
Compatible Divi / Extra. Lecture persistante entre les pages.
**v3 : Integration API RadioManager** — Programme en direct, grille, alertes, equipe, analytics.

## Nouveautes v3

- **Programme en direct** : affiche l'emission en cours + prochaine emission, synchronise depuis le SaaS RadioManager via l'API
- **Grille des programmes** : shortcode `[radio_audace_grille]` pour afficher la grille hebdomadaire des emissions
- **Bandeau d'alerte** : alertes info/warning/urgent poussees depuis le SaaS, affichees en bandeau anime en haut du site
- **Fiches animateurs** : shortcode `[radio_audace_equipe]` pour la page "Notre equipe"
- **Statistiques d'ecoute** : evenements play/pause/heartbeat envoyes au backend pour le dashboard SaaS
- **Cross-posting** : creation automatique d'articles WordPress quand une emission passe en direct
- **Proxy AJAX securise** : les appels API passent par WordPress (admin-ajax.php) avec nonce + cache transient
- **Page d'administration etendue** : section "Integration API RadioManager" avec URL API, intervalle polling, toggles, cle secrete

### Conserve de v2

- **5 skins** configurables (Sombre, Clair, Verre depoli, Couleur Audace, Neon)
- **3 types de lecteur flottant** (Barre minimisable, Bulle expansible, Mini barre retractable)
- **Lecture persistante** : Pjax + fallback sessionStorage
- **Bulle avec label "Ecouter en direct"**
- Interface admin avec selecteurs visuels
- Correction du bug play/pause

## Structure

```
radio-audace-player/
├── radio-audace-player.php         # Fichier principal (shortcode, widget, flottant, AJAX, REST)
├── admin/
│   └── settings.php                # Page admin avec previews visuels + section API
├── css/
│   └── radio-audace-player.css     # 5 skins + 3 flottants + alerte + now-playing + grille + equipe
├── js/
│   └── radio-audace-player.js      # Audio, Pjax, now-playing, alerte, analytics, grille, equipe
├── assets/
│   └── default-logo.svg            # Logo par defaut
└── LISEZMOI.md                     # Cette documentation
```

## Installation

1. Compresser le dossier `radio-audace-player/` en fichier ZIP
2. WordPress > **Extensions > Ajouter > Telecharger une extension** > choisir le ZIP
3. **Activer** le plugin
4. Configurer dans **Reglages > Radio Audace Player**

Ou par FTP : copier le dossier `radio-audace-player/` dans `/wp-content/plugins/`.

## Configuration (Reglages > Radio Audace Player)

### Station

| Option | Description | Defaut |
|--------|-------------|--------|
| URL du Stream | Flux Icecast | `https://radio.audace.ovh/stream.mp3` |
| Nom | Affiche dans le player | Radio Audace 106.8 FM |
| Slogan | Sous-titre | Bien Plus que l'info |
| Couleur | Bouton play, accents | `#2ea3f2` |
| Logo | Image ronde | Logo SVG par defaut |

### Integration API RadioManager

| Option | Description | Defaut |
|--------|-------------|--------|
| URL de l'API | Adresse du backend RadioManager | `https://api.radio.audace.ovh` |
| Intervalle de mise a jour | Frequence de polling en secondes (15-300) | `60` |
| Emission en cours | Afficher l'emission en cours dans le lecteur flottant | Active |
| Alertes | Afficher les alertes depuis RadioManager | Active |
| Statistiques | Envoyer les stats d'ecoute au backend | Active |
| Cle secrete | Cle pour le cross-posting securise | (vide) |

### 5 Skins

| Skin | Description |
|------|-------------|
| **Sombre** (`dark`) | Fond sombre elegant, ideal pour sites fonces |
| **Clair** (`light`) | Fond blanc avec ombres legeres |
| **Verre depoli** (`glass`) | Effet de transparence + flou (backdrop-filter) |
| **Couleur Audace** (`brand`) | Degrade bleu signature de Radio Audace |
| **Neon** (`neon`) | Fond noir avec bordures et lueurs neon |

### 3 Types de Lecteur Flottant

| Type | Comportement |
|------|-------------|
| **Barre** (`bar-float`) | Barre complete en bas de page. Bouton minimiser la reduit en pastille compacte. |
| **Bulle** (`bubble`) | Bouton circulaire avec label "Ecouter en direct". S'expanse en panel au clic. |
| **Mini barre** (`mini-bar`) | Barre fine en bas. Se retracte en petite languette. |

### Lecture Persistante

Quand activee, la navigation utilise la technique **Pjax** (fetch + remplacement du contenu) :
- Les liens internes sont interceptes
- Seul le contenu principal est remplace (pas de rechargement complet)
- Le player et l'audio restent intacts
- Les shortcodes v3 sont re-initialises apres chaque navigation Pjax
- Boutons back/forward du navigateur geres

**Fallback** : `sessionStorage` pour reprendre la lecture automatiquement (si l'interruption est < 5 secondes).

## Utilisation

### Shortcodes

```
[radio_audace_player]                          # Player streaming
[radio_audace_player style="bar" skin="neon"]  # Player avec options
[radio_audace_programme]                       # Emission en cours + prochaine
[radio_audace_grille]                          # Grille des programmes de la semaine
[radio_audace_equipe]                          # Fiches animateurs
```

### Parametres du player

- `style` : `bar` (horizontal) ou `mini` (vertical pour sidebar)
- `skin` : `dark`, `light`, `glass`, `brand`, `neon`

### Dans Divi / Extra

1. Ajouter un module **Texte** ou **Code**
2. Coller le shortcode souhaite
3. Enregistrer

### Lecteur Flottant

Automatique sur toutes les pages quand active dans les reglages. Pas besoin de shortcode.

### Widget

**Apparence > Widgets** > ajouter **Radio Audace Player**. Choix du style et du skin.

### PHP (dans un template)

```php
<?php echo do_shortcode('[radio_audace_player style="bar" skin="brand"]'); ?>
<?php echo do_shortcode('[radio_audace_programme]'); ?>
<?php echo do_shortcode('[radio_audace_grille]'); ?>
<?php echo do_shortcode('[radio_audace_equipe]'); ?>
```

## Architecture v3

```
SAAS FRONTEND (React)              BACKEND FASTAPI
app.cloud.audace.ovh               api.radio.audace.ovh
┌──────────────────┐               ┌─────────────────────────┐
│ Module Radio     │ ──── JWT ───> │ /public/now-playing     │ sans auth
│ ├── Alertes WP   │               │ /public/schedule        │ sans auth
│ └── Auditeurs    │               │ /public/alert           │ sans auth
└──────────────────┘               │ /public/presenters      │ sans auth
                                   │ /public/analytics/*     │ POST sans auth
                                   │ /public/alerts (CRUD)   │ avec JWT
                                   │ /public/analytics/stats │ avec JWT
                                   └──────┬──────────────────┘
                                          │
        ┌─────────────────────────────────┘
        ▼
WORDPRESS (www.radioaudace.com)
┌──────────────────────────────┐
│ Plugin Radio Audace Player v3│
│ ├── AJAX proxy → API backend │  (admin-ajax.php + nonce + cache 30s)
│ ├── Shortcodes               │  [programme] [grille] [equipe]
│ ├── Bandeau alerte           │  Auto-injecte via wp_footer
│ ├── Analytics                │  play/pause/heartbeat → backend
│ └── REST /sync-show          │  Cross-posting (cle secrete)
└──────────────────────────────┘
```

## Notes techniques

### Gestion audio
- Un seul element `<audio>` global partage par tous les players
- Arret propre avec flag `isStopping` pour eviter les evenements parasites
- Reconnexion fraiche au stream a chaque lecture (parametre `?t=timestamp`)

### Proxy AJAX
- Les appels au backend passent par `admin-ajax.php` (pas d'appel direct depuis le navigateur)
- L'URL du backend reste cote serveur WordPress (pas exposee au client)
- Cache transient de 30 secondes pour limiter les appels
- Nonce WordPress pour securisation CSRF

### Cross-posting (P5)
- Endpoint REST `POST /wp-json/rap/v1/sync-show`
- Authentification par header `X-RAP-Sync-Secret`
- Creation automatique d'articles WordPress quand une emission passe "en-cours"

### Analytics (P6)
- Session ID unique genere cote client (`sessionStorage`)
- Evenements : `play`, `pause`, `heartbeat` (toutes les 30s)
- Calcul de la duree d'ecoute reelle
- Visible dans le dashboard SaaS (page "Auditeurs")

### Compatibilite Divi
- Reset CSS isole pour eviter les conflits
- `!important` sur les boutons pour contrer les overrides du theme
- Re-initialisation des modules Divi apres navigation Pjax
- Re-initialisation des shortcodes v3 apres chaque navigation Pjax

## Compatibilite

- WordPress 5.0+
- Divi Builder / Theme Extra (Elegant Themes)
- Navigateurs : Chrome, Firefox, Safari, Edge (versions recentes)
- Responsive : Desktop, Tablette, Mobile
- Streaming : Icecast MP3 / OGG
- MediaSession API (controles systeme, casque bluetooth)
- Backend : FastAPI (RadioManager)
