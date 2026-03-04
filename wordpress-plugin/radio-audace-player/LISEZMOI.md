# Radio Audace Player v3 — Plugin WordPress

Plugin WordPress personnalise pour le streaming audio de **Radio Audace 106.8 FM**.
Compatible Divi / Extra. Lecture persistante entre les pages.
**v3 : Integration API RadioManager** — Programme en direct, grille, alertes, equipe, analytics, piste RadioDJ.

## Nouveautes v3

- **Programme en direct** : affiche l'emission en cours + prochaine emission, synchronise depuis le SaaS RadioManager via l'API
- **Piste RadioDJ (Now Playing)** : affiche en temps reel le titre et l'artiste du morceau diffuse par RadioDJ, avec gestion des artistes inconnus et defilement du texte long
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

### Piste RadioDJ

| Option | Description | Defaut |
|--------|-------------|--------|
| Artiste inconnu | Comportement quand l'artiste est "Unknown Artist" ou vide | `hide` (masquer) |
| Texte de remplacement | Texte affiche a la place de l'artiste inconnu (si mode = remplacer) | (vide) |

**Modes disponibles :**
- **Masquer** (`hide`) : seul le titre est affiche, l'artiste n'apparait pas
- **Remplacer** (`replace`) : l'artiste est remplace par le texte personnalise (ex: "Radio Audace")
- **Afficher tel quel** (`show`) : "Unknown Artist" est affiche sans modification

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
RADIODJ (Windows)
PC de diffusion
┌──────────────────────┐
│ Plugin "Now Playing   │
│ Info Exporter" v2.1   │
│                       │
│ POST form-urlencoded  │
│ a chaque changement   │
│ de piste              │
└──────────┬────────────┘
           │ password + artist + title + album + duration
           ▼
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
                                   │ /public/radiodj/track   │ POST + API key
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
│ ├── Piste RadioDJ            │  Affichee dans carte NP + flottant + lockscreen
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

### Piste RadioDJ — Now Playing (guide developpeur)

#### Flux de donnees complet

```
RadioDJ (Windows)
  │ Plugin "Now Playing Info Exporter" v2.1.2.0 (.NET)
  │ POST form-urlencoded a chaque changement de piste
  │ Champs : password, artist, title, album, duration
  ▼
FastAPI Backend (PostgreSQL)
  │ POST /public/radiodj/track  (auth par champ "password")
  │ Stocke dans table "now_playing_tracks" (append-only, historique)
  │ Parsing HH:MM:SS → secondes pour la duree
  ▼
GET /public/now-playing  (polling toutes les 60s par WordPress)
  │ Retourne { current_show, next_show, current_track }
  │ current_track = dernier morceau non-exclu, non-perime (< 10 min)
  ▼
WordPress Plugin (AJAX proxy + cache transient 30s)
  │ JS renderNowPlaying(data) traite data.current_track
  │ Applique resolveArtist() pour gerer les artistes inconnus
  ▼
Affichage : carte NP + tagline flottant + MediaSession lockscreen
```

#### Structure de `data.current_track` (JSON)

```json
{
  "artist": "CLAUDY",
  "title": "ON VOUS EMBARQUE",
  "album": "emissions",
  "duration": 5889.0,
  "track_type": "$songtype$",
  "started_at": "2025-03-04T15:42:12"
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `artist` | `string \| null` | Nom de l'artiste (peut etre "Unknown Artist" ou `null`) |
| `title` | `string` | Titre du morceau (toujours present) |
| `album` | `string \| null` | Nom de l'album |
| `duration` | `float \| null` | Duree en secondes. RadioDJ envoie au format HH:MM:SS, le backend convertit |
| `track_type` | `string \| null` | Type de piste RadioDJ. Le backend exclut : jingle, sweeper, spot, voicetrack, id |
| `started_at` | `string` | Horodatage ISO du debut de diffusion |

**Peremption** : si `started_at` est > 10 minutes sans mise a jour, le backend retourne `current_track: null`.

#### Fonction `resolveArtist(artist)` — logique JS

Cette fonction centralise la gestion des artistes inconnus. Elle est appelee a 3 endroits :
1. **Carte Now Playing** (`#rap-now-playing`) — `.rap-np__track-artist`
2. **Tagline lecteur flottant** (`.rap-player__tagline`) — texte "artiste — titre"
3. **MediaSession API** — metadata lockscreen (mobile, bluetooth)

```
resolveArtist(artist)
  │
  ├── artiste valide (ex: "CLAUDY") → retourne tel quel
  │
  └── artiste inconnu (vide, "Unknown Artist", "Unknown", "Artiste Inconnu")
      │
      ├── mode "hide"    → retourne null (pas d'artiste affiche)
      ├── mode "replace" → retourne config.unknownArtistText (ex: "Radio Audace")
      └── mode "show"    → retourne la valeur brute
```

**Valeurs detectees comme "artiste inconnu"** (comparaison insensible a la casse) :
- `"Unknown Artist"` — valeur par defaut de RadioDJ quand le tag ID3 est absent
- `"Unknown"` — variante courte
- `"Artiste Inconnu"` — equivalent francais
- `""` (vide) — aucun artiste renseigne

**Pour ajouter d'autres valeurs** : modifier le tableau `unknowns` dans la fonction `resolveArtist()` du fichier `js/radio-audace-player.js`.

#### Marquee (defilement du tagline)

Quand le texte "artiste — titre" depasse la largeur du conteneur `.rap-player__tagline` dans le lecteur flottant :
1. La classe `is-marquee` est ajoutee au conteneur
2. Le texte est duplique dans un `<span class="rap-marquee__inner">` avec un separateur `•`
3. L'animation CSS `@keyframes rap-marquee` fait defiler le texte de 0 a -50% (boucle infinie)
4. Le hover met l'animation en pause (`animation-play-state: paused`)

**Duree** : 15 secondes par cycle complet (modifiable dans `radio-audace-player.css`).

Si le texte ne deborde pas (artiste/titre courts), l'affichage reste classique avec `text-overflow: ellipsis`.

**Responsive** : sur mobile (< 768px), le `.rap-player__text` est masque (`display: none`) dans la barre flottante, donc le marquee n'est pas visible (le texte apparait toujours dans la carte Now Playing du shortcode).

#### Options WordPress (cles internes)

| Cle `rap_options[]` | Valeurs | Transmis au JS via | Defaut |
|---------------------|---------|-------------------|--------|
| `unknown_artist_mode` | `hide`, `replace`, `show` | `rapConfig.unknownArtistMode` | `hide` |
| `unknown_artist_text` | texte libre | `rapConfig.unknownArtistText` | `""` |

#### Classes CSS associees

| Classe | Element | Description |
|--------|---------|-------------|
| `.rap-np__track` | `div` | Conteneur flex de la piste dans la carte Now Playing |
| `.rap-np__track-icon` | `div` | Cercle 32px avec icone note de musique |
| `.rap-np__track-artist` | `span` | Nom de l'artiste (couleur `--rap-primary`, 12px, bold) |
| `.rap-np__track-title` | `span` | Titre du morceau (blanc 95%, 14px, bold) |
| `.rap-player__tagline.is-marquee` | `div` | Tagline flottant en mode defilement |
| `.rap-marquee__inner` | `span` | Contenu duplique qui defile horizontalement |

#### Variables plugin RadioDJ supportees

Le plugin .NET "Now Playing Info Exporter" v2.1.2.0 supporte ces variables dans le champ Custom Data.
Elles sont remplacees par les valeurs du morceau en cours au moment de l'export.

**Variables de metadata du morceau :**

| Variable | Description | Exemple |
|----------|-------------|---------|
| `$artist$` | Artiste du morceau (tag ID3) | `CLAUDY` |
| `$title$` | Titre du morceau (tag ID3) | `ON VOUS EMBARQUE` |
| `$album$` | Album (tag ID3) | `emissions` |
| `$duration$` | Duree au format `HH:MM:SS` | `01:38:09` |
| `$year$` | Annee du morceau (tag ID3) | `2024` |
| `$composer$` | Compositeur (tag ID3) | |
| `$copyright$` | Copyright (tag ID3) | |
| `$original_artist$` | Artiste original (tag ID3) | |
| `$publisher$` | Editeur (tag ID3) | |

**Variables de la station :**

| Variable | Description | Source |
|----------|-------------|--------|
| `$station_name$` | Nom de la station | Config RadioDJ > General |
| `$station_slogan$` | Slogan de la station | Config RadioDJ > General |

**Variables de date/heure (moment de l'export) :**

| Variable | Description | Exemple |
|----------|-------------|---------|
| `$now-date$` | Date courante (format systeme) | `04/03/2026` |
| `$now-time$` | Heure courante (format systeme) | `16:42:35` |
| `$now-day$` | Jour du mois | `04` |
| `$now-month$` | Mois | `03` |
| `$now-year$` | Annee | `2026` |
| `$now-hour$` | Heure (24h) | `16` |
| `$now-minute$` | Minute | `42` |
| `$now-second$` | Seconde | `35` |

**Variables NON supportees (envoyees en texte brut) :**

| Variable | Statut | Alternative |
|----------|--------|-------------|
| `$songtype$` | N'existe pas dans le plugin | Aucun equivalent — le type de piste n'est pas accessible via ce plugin |
| `$genre$` | N'existe pas | Utiliser les tags ID3 directement dans RadioDJ |
| `$bpm$` | N'existe pas | Idem |

> **Regle** : toute variable non reconnue par le plugin est envoyee telle quelle en texte brut
> (ex: `$songtype$` arrive comme la chaine de caracteres `$songtype$` et non comme le type de piste).

#### Modes d'export du plugin RadioDJ

Le plugin "Now Playing Info Exporter" supporte 4 modes d'export (configurables dans RadioDJ > Options > Now Playing) :

| Mode | Description | Utilise par notre integration |
|------|-------------|------------------------------|
| **Export fichier texte** | Ecrit dans un fichier local (ex: `NowPlaying.txt`) | Non |
| **Export Web (HTTP POST)** | Envoie un POST form-urlencoded a une URL | **Oui** — c'est le mode utilise |
| **Export Serial** | Envoie sur un port serie (COM) | Non |
| **Export Stream Server** | Met a jour les metadata du serveur de streaming | Non |

**Configuration XML** : les parametres du plugin sont stockes dans des fichiers XML dans le dossier RadioDJ :
- `Plugin_MetadataExport.xml` — parametres generaux (chemins, encodage, types a exporter)
- `Plugin_MetadataExport_web_items.xml` — items d'export web (URL, methode, custom data, mot de passe)
- `Plugin_MetadataExport_serial_items.xml` — items serial
- `Plugin_MetadataExport_network_items.xml` — items reseau
- `Plugin_MetadataExport_streamserver_items.xml` — items stream server

**Types a exporter** (`TypesToExport` dans la config XML) : controle quels types de pistes declenchent l'export. Les valeurs correspondent aux types internes de RadioDJ (0=Music, 1=Jingle, 5=Sweeper, etc.). Par defaut, la plupart des types sont actives.

**Configuration actuelle du Custom Data dans RadioDJ** :
```
password=VOTRE_CLE_API&artist=$artist$&title=$title$&album=$album$&duration=$duration$
```

> **Note** : le `&songtype=$songtype$` initialement present a ete retire car la variable n'est pas supportee.

#### Backend — Endpoints concernes

| Endpoint | Methode | Auth | Description |
|----------|---------|------|-------------|
| `/public/radiodj/track` | POST | Champ `password` = `RADIODJ_API_KEY` | Recoit les metadata de RadioDJ |
| `/public/now-playing` | GET | Aucune | Retourne emission en cours + `current_track` |

**Fichiers backend** (repo `/Users/happi/App/API/FASTAPI/`) :
- `routeur/public_route.py` — Endpoint POST + ajout de `current_track` dans GET
- `app/db/crud/crud_public.py` — `store_now_playing_track()` + `get_current_track()`
- `app/models/model_now_playing_track.py` — Modele SQLAlchemy `NowPlayingTrack`
- `app/config/config.py` — Setting `RADIODJ_API_KEY`

#### Pour etendre cette fonctionnalite

**Ajouter un nouveau champ de metadata** (ex: genre, BPM) :
1. Ajouter la colonne dans le modele SQLAlchemy `NowPlayingTrack`
2. Generer une migration Alembic (`alembic revision --autogenerate`)
3. Extraire le champ dans `public_route.py` (section `radiodj_track_route`)
4. Retourner le champ dans `get_current_track()` (`crud_public.py`)
5. L'utiliser dans `renderNowPlaying()` cote JS (le champ arrive automatiquement dans `data.current_track`)

**Ajouter des pochettes d'album** :
- Le champ `cover_url` existe deja dans le modele backend (colonne reservee)
- Ajouter un service de recherche de pochettes (MusicBrainz, Deezer API, etc.)
- Stocker l'URL dans `cover_url` a chaque POST
- Cote JS : ajouter un `<img>` dans `.rap-np__track-icon` si `data.current_track.cover_url` existe

**Modifier la sensibilite au staleness** :
- Variable `TRACK_STALENESS_SECONDS` dans `crud_public.py` (defaut: 600 = 10 minutes)
- Si RadioDJ est arrete, `current_track` sera `null` apres ce delai

**Modifier les types de pistes exclus** :
- Set `EXCLUDED_TRACK_TYPES` dans `crud_public.py`
- Par defaut : `{'jingle', 'sweeper', 'spot', 'voicetrack', 'id'}`
- Les pistes dont le `track_type` (insensible a la casse) est dans ce set ne sont pas affichees

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
