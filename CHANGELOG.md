# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

## [3.2.0] - 2026-03-03

### Ajouté
- 🎵 **Intégration RadioDJ** : affichage de la piste en cours (artiste + titre) dans le widget Now Playing
- 🎧 Piste RadioDJ affichée dans le lecteur flottant (tagline dynamique)
- 📱 MediaSession API : la piste RadioDJ s'affiche sur l'écran de verrouillage mobile et les contrôles Bluetooth
- 🎨 Styles CSS dédiés pour le bloc piste (`.rap-np__track`, icône note de musique, animation fade-in)

### Modifié
- ⬆️ Version du plugin passée de 3.1.0 à 3.2.0

## [3.1.0] - 2025-12-20

### Ajouté
- 🔄 Système de mise à jour automatique depuis GitHub Releases (updater.php)
- 🔗 Intégration API RadioManager v3 (now-playing, grille, alertes, équipe, analytics)
- 📡 Proxy AJAX sécurisé (admin-ajax.php + nonce + cache transient)
- 📺 Shortcodes v3 : `[radio_audace_programme]`, `[radio_audace_grille]`, `[radio_audace_equipe]`
- 🚨 Bandeau d'alerte automatique depuis le SaaS
- 📊 Analytics d'écoute (play/pause/heartbeat)
- 🔁 Cross-posting REST endpoint `/wp-json/rap/v1/sync-show`
- 🎛️ Page d'administration étendue (section API RadioManager)

## [3.0.0] - 2025-10-15

### Ajouté
- 🎨 5 skins configurables (Sombre, Clair, Verre dépoli, Couleur Audace, Néon)
- 🎛️ 3 types de lecteur flottant (Barre, Bulle, Mini barre)
- 🔄 Lecture persistante (Pjax + fallback sessionStorage)
- 📱 Interface admin avec sélecteurs visuels

## [2.0.0] - 2024-12-15

### Ajouté
- 🐳 Support complet Docker (Compose + Dockploy)
- 📚 Documentation exhaustive des variables d'environnement
- 🎯 Guide de démarrage rapide (Quick Start)
- 📊 Tableau comparatif des solutions
- 🎭 Cas d'usage détaillés et recommandations
- 🔒 Checklist de sécurité complète
- 🔄 Calendrier de maintenance recommandé
- 📈 Roadmap publique du projet
- 🎨 Templates pour RadioManager-SaaS et API Audace
- 🧪 Scripts de validation des variables d'environnement

### Modifié
- 📖 README restructuré avec table des matières détaillée
- 🔧 Scripts bash optimisés avec meilleure gestion d'erreurs
- 🐞 Corrections de bugs mineurs dans les scripts de déploiement

### Supprimé
- Rien pour cette version

## [1.5.0] - 2024-11-20

### Ajouté
- 🔐 Support VPN WireGuard (serveur + clients)
- 🤖 Scripts N8N pour Amazon Linux
- 📝 Documentation AGENT.md pour contributeurs

### Modifié
- Amélioration des scripts d'installation API Audace
- Mise à jour des dépendances système

## [1.0.0] - 2024-10-15

### Ajouté
- 🎵 Scripts d'installation API Audace + Icecast
- 🌐 Scripts d'installation RadioManager Frontend
- 📋 Documentation de base
- 🔧 Configuration Nginx avec SSL

---

## Légende des émojis

- 🎉 Nouvelle fonctionnalité majeure
- ✨ Nouvelle fonctionnalité mineure
- 🐳 Docker / Conteneurs
- 🔒 Sécurité
- 🐛 Correction de bug
- 📚 Documentation
- 🔧 Configuration / Maintenance
- ⚡ Performance
- 🎨 UI/UX
- 🔄 Refactoring
- ❌ Suppression
