/**
 * Radio Audace Player v2 — JavaScript
 *
 * - Audio HTML5 avec un seul element audio global
 * - 3 types de lecteur flottant (bar-float, bubble, mini-bar)
 * - Navigation Pjax pour lecture persistante entre les pages
 * - Fallback sessionStorage pour reprise auto
 * - MediaSession API (controles systeme / bluetooth)
 */
(function () {
    'use strict';

    var config = window.rapConfig || {};
    var audio = null;
    var isPlaying = false;
    var isStopping = false;  // flag pour ignorer les events pendant l'arret
    var currentVolume = 0.8;
    var pjaxEnabled = config.persistentPlayback !== false;

    /* ═══════════════════════════════════════════════════════════════
       INIT
       ═══════════════════════════════════════════════════════════════ */

    function init() {
        audio = new Audio();
        audio.preload = 'none';
        audio.volume = currentVolume;

        // Restaurer l'etat depuis sessionStorage
        restoreState();

        // Attacher les evenements audio
        audio.addEventListener('playing', function () {
            isPlaying = true;
            updateAllPlayers();
            saveState();
        });
        audio.addEventListener('pause', function () {
            if (isStopping) return; // ignore pendant arret volontaire
            isPlaying = false;
            updateAllPlayers();
            saveState();
        });
        audio.addEventListener('waiting', function () {
            if (isStopping) return;
            setAllPlayersState('loading');
        });
        audio.addEventListener('error', function () {
            if (isStopping) return; // ignore l'erreur causee par le retrait du src
            isPlaying = false;
            updateAllPlayers();
        });

        // Lier tous les players existants
        bindAllPlayers();

        // Comportements flottants
        initFloatingBehaviors();

        // Navigation Pjax
        if (pjaxEnabled) {
            initPjax();
        }

        // MediaSession
        setupMediaSession();
    }

    /* ═══════════════════════════════════════════════════════════════
       PLAYERS — liaison evenements
       ═══════════════════════════════════════════════════════════════ */

    function bindAllPlayers() {
        var players = document.querySelectorAll('[data-rap-player]');
        players.forEach(function (player) {
            if (player.dataset.rapBound) return;
            player.dataset.rapBound = '1';
            bindPlayer(player);
        });

        // Mettre a jour l'etat si deja en lecture
        if (isPlaying) {
            updateAllPlayers();
        }
    }

    function bindPlayer(player) {
        // Boutons play (il peut y en avoir plusieurs dans un floating)
        var playBtns = player.querySelectorAll('.rap-player__btn--play');
        playBtns.forEach(function (btn) {
            btn.addEventListener('click', function (e) {
                e.stopPropagation();
                togglePlay();
            });
        });

        // Boutons mute
        var muteBtns = player.querySelectorAll('.rap-player__btn--mute');
        muteBtns.forEach(function (btn) {
            btn.addEventListener('click', function () {
                toggleMute();
                updateVolumeUI();
            });
        });

        // Sliders volume
        var sliders = player.querySelectorAll('.rap-player__volume-slider');
        sliders.forEach(function (slider) {
            slider.addEventListener('input', function () {
                setVolume(parseInt(this.value, 10) / 100);
                updateVolumeUI();
            });
        });
    }

    /* ═══════════════════════════════════════════════════════════════
       AUDIO — lecture / pause / volume
       ═══════════════════════════════════════════════════════════════ */

    function togglePlay() {
        if (isPlaying) {
            // Arret : on gere manuellement l'etat pour eviter les events parasites
            isStopping = true;
            audio.pause();
            audio.src = '';
            isPlaying = false;
            updateAllPlayers();
            saveState();
            // Laisser le temps aux events parasites (pause/error) de passer
            setTimeout(function () { isStopping = false; }, 200);
        } else {
            audio.src = config.streamUrl + '?t=' + Date.now();
            audio.load();
            var p = audio.play();
            if (p !== undefined) {
                p.catch(function () {
                    isPlaying = false;
                    updateAllPlayers();
                });
            }
            setAllPlayersState('loading');
        }
    }

    function setVolume(val) {
        currentVolume = Math.max(0, Math.min(1, val));
        audio.volume = currentVolume;
        if (audio.muted && currentVolume > 0) {
            audio.muted = false;
        }
        saveState();
    }

    function toggleMute() {
        audio.muted = !audio.muted;
        saveState();
    }

    /* ═══════════════════════════════════════════════════════════════
       UI — mise a jour de tous les players
       ═══════════════════════════════════════════════════════════════ */

    function updateAllPlayers() {
        var state = isPlaying ? 'playing' : 'stopped';
        var players = document.querySelectorAll('[data-rap-player]');
        players.forEach(function (p) {
            setPlayerState(p, state);
        });
        updateVolumeUI();
    }

    function setAllPlayersState(state) {
        var players = document.querySelectorAll('[data-rap-player]');
        players.forEach(function (p) {
            setPlayerState(p, state);
        });
    }

    function setPlayerState(player, state) {
        // Mettre a jour tous les groupes d'icones play/pause/loading dans ce player
        var groups = player.querySelectorAll('.rap-player__btn--play');
        groups.forEach(function (btn) {
            var iconPlay = btn.querySelector('.rap-icon--play');
            var iconPause = btn.querySelector('.rap-icon--pause');
            var iconLoading = btn.querySelector('.rap-icon--loading');
            if (!iconPlay || !iconPause || !iconLoading) return;

            iconPlay.style.display = 'none';
            iconPause.style.display = 'none';
            iconLoading.style.display = 'none';

            switch (state) {
                case 'playing':  iconPause.style.display = '';  break;
                case 'loading':  iconLoading.style.display = ''; break;
                default:         iconPlay.style.display = '';
            }
        });

        if (state === 'playing') {
            player.classList.add('is-playing');
        } else {
            player.classList.remove('is-playing');
        }

        // Mettre a jour le label de la bulle si present
        var bubbleLabel = player.querySelector('.rap-bubble__label span');
        if (bubbleLabel) {
            bubbleLabel.textContent = state === 'playing' ? 'EN DIRECT' : 'Ecouter en direct';
        }
    }

    function updateVolumeUI() {
        var vol = audio.muted ? 0 : Math.round(currentVolume * 100);
        var sliders = document.querySelectorAll('.rap-player__volume-slider');
        sliders.forEach(function (s) { s.value = vol; });

        var iconsOn = document.querySelectorAll('.rap-icon--vol-on');
        var iconsOff = document.querySelectorAll('.rap-icon--vol-off');
        iconsOn.forEach(function (el) { el.style.display = audio.muted ? 'none' : ''; });
        iconsOff.forEach(function (el) { el.style.display = audio.muted ? '' : 'none'; });
    }

    /* ═══════════════════════════════════════════════════════════════
       LECTEUR FLOTTANT — comportements
       ═══════════════════════════════════════════════════════════════ */

    function initFloatingBehaviors() {
        var root = document.getElementById('rap-floating-root');
        if (!root) return;

        // Restaurer l'etat minimise
        if (localStorage.getItem('rap_minimized') === '1') {
            root.classList.add('is-minimized');
        }

        // Boutons minimiser
        var minimizeBtns = root.querySelectorAll('[data-rap-minimize]');
        minimizeBtns.forEach(function (btn) {
            btn.addEventListener('click', function (e) {
                e.stopPropagation();
                root.classList.add('is-minimized');
                localStorage.setItem('rap_minimized', '1');
            });
        });

        // Boutons expanser (depuis etat minimise)
        var expandBtns = root.querySelectorAll('[data-rap-expand]');
        expandBtns.forEach(function (btn) {
            btn.addEventListener('click', function (e) {
                // Ne pas intercepter les clics sur les boutons play a l'interieur
                if (e.target.closest('.rap-player__btn--play')) return;
                root.classList.remove('is-minimized');
                localStorage.setItem('rap_minimized', '0');
            });
        });

        // Bulle : toggle panel
        var bubbleToggles = root.querySelectorAll('[data-rap-bubble-toggle]');
        bubbleToggles.forEach(function (btn) {
            btn.addEventListener('click', function (e) {
                e.stopPropagation();
                root.classList.toggle('is-expanded');
            });
        });

        // Bulle : fermer au clic outside
        if (root.classList.contains('rap-floating--bubble')) {
            document.addEventListener('click', function (e) {
                if (!root.contains(e.target)) {
                    root.classList.remove('is-expanded');
                }
            });
        }
    }

    /* ═══════════════════════════════════════════════════════════════
       PERSISTANCE — sessionStorage
       ═══════════════════════════════════════════════════════════════ */

    function saveState() {
        try {
            sessionStorage.setItem('rap_state', JSON.stringify({
                playing: isPlaying,
                volume: currentVolume,
                muted: audio.muted,
                ts: Date.now()
            }));
        } catch (e) { /* quota */ }
    }

    function restoreState() {
        try {
            var raw = sessionStorage.getItem('rap_state');
            if (!raw) return;
            var state = JSON.parse(raw);

            // Restaurer volume
            if (typeof state.volume === 'number') {
                currentVolume = state.volume;
                audio.volume = currentVolume;
            }
            if (state.muted) {
                audio.muted = true;
            }

            // Si etait en lecture et page chargee il y a moins de 5s : reprendre
            if (state.playing && (Date.now() - state.ts) < 5000) {
                audio.src = config.streamUrl + '?t=' + Date.now();
                audio.load();
                var p = audio.play();
                if (p !== undefined) {
                    p.catch(function () {
                        isPlaying = false;
                        updateAllPlayers();
                    });
                }
                setAllPlayersState('loading');
            }
        } catch (e) { /* parse error */ }
    }

    /* ═══════════════════════════════════════════════════════════════
       PJAX — Navigation sans rechargement
       Remplace le contenu principal, garde le player + audio vivants
       ═══════════════════════════════════════════════════════════════ */

    function initPjax() {
        // Intercepter les clics sur les liens internes
        document.addEventListener('click', function (e) {
            var link = e.target.closest('a');
            if (!link) return;
            if (!shouldIntercept(link, e)) return;

            e.preventDefault();
            navigateTo(link.href);
        });

        // Gerer back/forward du navigateur
        window.addEventListener('popstate', function (e) {
            if (e.state && e.state.rapPjax) {
                navigateTo(location.href, true);
            }
        });

        // Marquer l'etat initial
        history.replaceState({ rapPjax: true }, '', location.href);
    }

    function shouldIntercept(link, e) {
        // Modifier keys = nouvel onglet
        if (e.ctrlKey || e.metaKey || e.shiftKey || e.altKey) return false;
        // Pas meme origine
        if (link.origin !== location.origin) return false;
        // target blank
        if (link.target && link.target !== '_self') return false;
        // Lien de telechargement
        if (link.hasAttribute('download')) return false;
        // Hash seul sur la meme page
        if (link.pathname === location.pathname && link.hash) return false;
        // Admin WordPress
        if (link.pathname.indexOf('/wp-admin') === 0) return false;
        if (link.pathname.indexOf('/wp-login') === 0) return false;
        // Fichiers
        var ext = link.pathname.split('.').pop().toLowerCase();
        if (['pdf','zip','doc','docx','xls','xlsx','mp3','mp4','rar','gz'].indexOf(ext) !== -1) return false;
        // Liens dans le player lui-meme (pas de navigation)
        if (link.closest('[data-rap-player]')) return false;

        return true;
    }

    function navigateTo(url, isPopState) {
        document.body.classList.add('rap-navigating');

        fetch(url, { credentials: 'same-origin' })
            .then(function (r) {
                if (!r.ok) throw new Error(r.status);
                return r.text();
            })
            .then(function (html) {
                var parser = new DOMParser();
                var doc = parser.parseFromString(html, 'text/html');

                // Trouver et remplacer le contenu principal
                var replaced = replaceContent(doc);
                if (!replaced) {
                    // Fallback : rechargement classique
                    window.location.href = url;
                    return;
                }

                // MAJ titre
                document.title = doc.title;

                // MAJ classes body (Divi les utilise beaucoup)
                var newBodyClass = doc.body.className;
                // Garder les classes rap-*
                var rapClasses = [];
                document.body.classList.forEach(function (c) {
                    if (c.indexOf('rap-') === 0) rapClasses.push(c);
                });
                document.body.className = newBodyClass;
                rapClasses.forEach(function (c) { document.body.classList.add(c); });

                // MAJ menu actif
                updateActiveMenu(url, doc);

                // MAJ head (meta, styles specifiques a la page)
                updateHead(doc);

                // History
                if (!isPopState) {
                    history.pushState({ rapPjax: true }, '', url);
                }

                // Scroll haut
                window.scrollTo({ top: 0, behavior: 'instant' });

                // Re-init
                document.body.classList.remove('rap-navigating');
                bindAllPlayers();
                reinitDivi();

                // Evenement pour d'autres scripts
                document.dispatchEvent(new CustomEvent('rap:pjax:complete', { detail: { url: url } }));
            })
            .catch(function () {
                // En cas d'erreur, navigation classique
                window.location.href = url;
            });
    }

    /**
     * Remplace le contenu principal en essayant plusieurs selecteurs.
     */
    function replaceContent(doc) {
        // Selecteur configure en priorite
        var selectors = [];
        if (config.contentSelector) {
            selectors.push(config.contentSelector);
        }
        // Selecteurs Divi / Extra classiques
        selectors.push('#main-content', '#et-main-area', '#content-area', '#page-container .container');

        for (var i = 0; i < selectors.length; i++) {
            var sel = selectors[i];
            var newEl = doc.querySelector(sel);
            var oldEl = document.querySelector(sel);
            if (newEl && oldEl) {
                oldEl.innerHTML = newEl.innerHTML;
                return true;
            }
        }
        return false;
    }

    /**
     * Met a jour les elements actifs du menu Divi.
     */
    function updateActiveMenu(url, doc) {
        // Copier les classes current-menu-item depuis le nouveau document
        var newNav = doc.querySelector('#main-header nav, #top-header nav, .et-menu');
        var oldNav = document.querySelector('#main-header nav, #top-header nav, .et-menu');
        if (newNav && oldNav) {
            oldNav.innerHTML = newNav.innerHTML;
        }
    }

    /**
     * Met a jour certains elements du <head> (meta description, etc.)
     */
    function updateHead(doc) {
        // Meta description
        var oldMeta = document.querySelector('meta[name="description"]');
        var newMeta = doc.querySelector('meta[name="description"]');
        if (oldMeta && newMeta) {
            oldMeta.setAttribute('content', newMeta.getAttribute('content'));
        }
        // Canonical
        var oldCanonical = document.querySelector('link[rel="canonical"]');
        var newCanonical = doc.querySelector('link[rel="canonical"]');
        if (oldCanonical && newCanonical) {
            oldCanonical.setAttribute('href', newCanonical.getAttribute('href'));
        }
    }

    /**
     * Re-initialise les modules Divi apres remplacement du contenu.
     */
    function reinitDivi() {
        // Divi Builder
        if (typeof window.et_pb_init_modules === 'function') {
            try { window.et_pb_init_modules(); } catch (e) {}
        }
        // Extra theme
        if (typeof window.et_init_main_modules === 'function') {
            try { window.et_init_main_modules(); } catch (e) {}
        }
        // Trigger resize pour les modules qui en dependent
        try { window.dispatchEvent(new Event('resize')); } catch (e) {}
        // Trigger Divi custom event
        try { jQuery(document).trigger('et_pb_after_init_modules'); } catch (e) {}
    }

    /* ═══════════════════════════════════════════════════════════════
       MEDIASESSION
       ═══════════════════════════════════════════════════════════════ */

    function setupMediaSession() {
        if (!('mediaSession' in navigator)) return;

        navigator.mediaSession.metadata = new MediaMetadata({
            title: config.stationName || 'Radio Audace',
            artist: config.tagline || 'En direct',
            album: '106.8 FM'
        });

        navigator.mediaSession.setActionHandler('play', function () {
            if (!isPlaying) togglePlay();
        });
        navigator.mediaSession.setActionHandler('pause', function () {
            if (isPlaying) togglePlay();
        });
    }

    /* ═══════════════════════════════════════════════════════════════
       DEMARRAGE
       ═══════════════════════════════════════════════════════════════ */

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

})();
