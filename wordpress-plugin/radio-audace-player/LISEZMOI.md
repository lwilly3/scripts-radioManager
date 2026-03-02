# Radio Audace Player v2 — Plugin WordPress

Plugin WordPress personnalise pour le streaming audio de **Radio Audace 106.8 FM**.
Compatible Divi / Extra. Lecture persistante entre les pages.

## Nouveautes v2

- **5 skins** configurables (Sombre, Clair, Verre depoli, Couleur Audace, Neon)
- **3 types de lecteur flottant** (Barre minimisable, Bulle expansible, Mini barre retractable)
- **Lecture persistante** : la musique continue quand le visiteur navigue entre les pages (Pjax + fallback sessionStorage)
- **Bulle avec label "Ecouter en direct"** : indicateur visuel clair pour inviter l'internaute a ecouter la radio, avec animation d'attention et passage en "EN DIRECT" pendant la lecture
- Lecteur flottant injecte automatiquement sur toutes les pages
- Interface admin avec selecteurs visuels
- Correction du bug play/pause (le bouton ne restait plus fige apres arret)

## Structure

```
radio-audace-player/
├── radio-audace-player.php         # Fichier principal (shortcode, widget, flottant)
├── admin/
│   └── settings.php                # Page admin avec previews visuels
├── css/
│   └── radio-audace-player.css     # 5 skins + 3 types flottants + responsive
├── js/
│   └── radio-audace-player.js      # Audio, Pjax, comportements flottants
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
| **Barre** (`bar-float`) | Barre complete en bas de page. Bouton minimiser la reduit en pastille compacte (play + nom + badge). |
| **Bulle** (`bubble`) | Bouton circulaire dans le coin avec label "Ecouter en direct". S'expanse en panel au clic. Se ferme au clic exterieur. Le label affiche "EN DIRECT" en rouge pendant la lecture. Animation d'attention au chargement. |
| **Mini barre** (`mini-bar`) | Barre fine en bas. Se retracte en petite languette (play + chevron). |

Tous les types conservent l'etat minimise/retracte via `localStorage` (persiste entre les pages).

### Lecture Persistante

Quand activee, la navigation utilise la technique **Pjax** (fetch + remplacement du contenu) :
- Les liens internes sont interceptes
- Seul le contenu principal est remplace (pas de rechargement complet)
- Le player et l'audio restent intacts
- Le menu Divi est mis a jour, les modules re-initialises
- Boutons back/forward du navigateur geres

**Fallback** : si le Pjax echoue ou si la page est rechargee manuellement, le plugin utilise `sessionStorage` pour reprendre la lecture automatiquement (si l'interruption est < 5 secondes).

**Selecteur CSS configurable** : par defaut, le plugin auto-detecte le conteneur Divi/Extra (`#main-content`, `#et-main-area`, `#content-area`). Possibilite de specifier un selecteur personnalise dans les reglages.

## Utilisation

### Shortcode

```
[radio_audace_player]
[radio_audace_player style="bar" skin="neon"]
[radio_audace_player style="mini" skin="glass"]
```

Parametres :
- `style` : `bar` (horizontal) ou `mini` (vertical pour sidebar)
- `skin` : `dark`, `light`, `glass`, `brand`, `neon`

### Dans Divi / Extra

1. Ajouter un module **Texte** ou **Code**
2. Coller : `[radio_audace_player]`
3. Enregistrer

### Lecteur Flottant

Automatique sur toutes les pages quand active dans les reglages. Pas besoin de shortcode.

### Widget

**Apparence > Widgets** > ajouter **Radio Audace Player**. Choix du style et du skin.

### PHP (dans un template)

```php
<?php echo do_shortcode('[radio_audace_player style="bar" skin="brand"]'); ?>
```

## Notes techniques

### Gestion audio
- Un seul element `<audio>` global partage par tous les players de la page
- Arret propre avec flag `isStopping` pour eviter les evenements parasites du navigateur
- Reconnexion fraiche au stream a chaque lecture (parametre `?t=timestamp` anti-cache)

### MediaSession API
- Controles systeme (notifications, ecran de verrouillage)
- Compatibilite casques bluetooth (play/pause)

### Compatibilite Divi
- Reset CSS isole pour eviter les conflits avec les styles Divi
- `!important` sur les boutons pour contrer les overrides du theme
- Re-initialisation des modules Divi apres navigation Pjax (`et_pb_init_modules`, `et_init_main_modules`)

## Compatibilite

- WordPress 5.0+
- Divi Builder / Theme Extra (Elegant Themes)
- Navigateurs : Chrome, Firefox, Safari, Edge (versions recentes)
- Responsive : Desktop, Tablette, Mobile
- Streaming : Icecast MP3 / OGG
- MediaSession API (controles systeme, casque bluetooth)
