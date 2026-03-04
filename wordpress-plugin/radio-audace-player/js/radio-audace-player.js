/**
 * Radio Audace Player v3 — JavaScript
 *
 * - Audio HTML5 avec un seul element audio global
 * - 3 types de lecteur flottant (bar-float, bubble, mini-bar)
 * - Navigation Pjax pour lecture persistante entre les pages
 * - Fallback sessionStorage pour reprise auto
 * - MediaSession API (controles systeme / bluetooth)
 * - v3: Now Playing, Alert Banner, Analytics, Schedule, Team
 */
(function () {
    'use strict';

    var config = window.rapConfig || {};
    var audio = null;
    var isPlaying = false;
    var isStopping = false;  // flag pour ignorer les events pendant l'arret
    var currentVolume = (config.defaultVolume !== undefined) ? config.defaultVolume / 100 : 0.8;
    var pjaxEnabled = config.persistentPlayback !== false;
    var analyticsSessionId = null;
    var heartbeatTimer = null;
    var listenStartTime = null;

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

        // v3: Modules API RadioManager
        if (config.showNowPlaying) { initNowPlaying(); }
        if (config.showAlertBanner) { initAlertBanner(); }
        if (config.analyticsEnabled) { initAnalytics(); }
        initSchedule();
        initTeam();
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
            bubbleLabel.textContent = state === 'playing'
                ? (config.liveBadgeText || 'EN DIRECT')
                : (config.bubbleLabelText || 'Ecouter en direct');
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

                // v3: Re-init shortcodes apres Pjax
                initSchedule();
                initTeam();
                if (config.showNowPlaying) { initNowPlaying(); }

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
       v3: NOW PLAYING — Emission en cours
       ═══════════════════════════════════════════════════════════════ */

    var nowPlayingTimer = null;

    function initNowPlaying() {
        fetchNowPlaying();
        if (nowPlayingTimer) clearInterval(nowPlayingTimer);
        var interval = config.pollingInterval || 60000;
        nowPlayingTimer = setInterval(fetchNowPlaying, interval);
    }

    function fetchNowPlaying() {
        if (!config.ajaxUrl) return;
        fetch(config.ajaxUrl + '?action=rap_now_playing&nonce=' + (config.nonce || ''))
            .then(function (r) { return r.json(); })
            .then(function (resp) {
                if (resp.success) {
                    renderNowPlaying(resp.data);
                }
            })
            .catch(function () {});
    }

    function resolveArtist(artist) {
        var unknowns = ['unknown artist', 'unknown', 'artiste inconnu', ''];
        var raw = (artist || '').trim();
        if (unknowns.indexOf(raw.toLowerCase()) === -1) return raw; // artiste valide
        var mode = config.unknownArtistMode || 'hide';
        if (mode === 'show') return raw || null;
        if (mode === 'replace' && config.unknownArtistText) return config.unknownArtistText;
        return null; // hide
    }

    function renderNowPlaying(data) {
        // Mettre a jour les shortcodes [radio_audace_programme]
        var containers = document.querySelectorAll('#rap-now-playing');
        containers.forEach(function (el) {
            if (!data || !data.current_show) {
                el.innerHTML = '<div class="rap-np__empty">Aucune emission en cours</div>';
                return;
            }
            var show = data.current_show;
            var presenterName = (show.presenters && show.presenters.length > 0)
                ? show.presenters[0].name : '';
            var segmentText = show.current_segment
                ? '<div class="rap-np__segment"><span class="rap-np__segment-label">En cours :</span> ' + escapeHtml(show.current_segment.title) + '</div>'
                : '';

            // Piste RadioDJ en cours
            var trackHtml = '';
            if (config.showTrackInfo !== false && data.current_track && data.current_track.title) {
                var trackArtist = resolveArtist(data.current_track.artist);
                var trackTitle = escapeHtml(data.current_track.title);
                trackHtml =
                    '<div class="rap-np__track">' +
                        '<div class="rap-np__track-icon">' +
                            '<svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>' +
                        '</div>' +
                        '<div class="rap-np__track-info">' +
                            (trackArtist ? '<span class="rap-np__track-artist">' + escapeHtml(trackArtist) + '</span>' : '') +
                            '<span class="rap-np__track-title">' + trackTitle + '</span>' +
                        '</div>' +
                    '</div>';
            }

            var nextHtml = '';
            if (data.next_show) {
                nextHtml = '<div class="rap-np__next">Prochaine : <strong>' + escapeHtml(data.next_show.title) + '</strong></div>';
            }
            el.innerHTML =
                '<div class="rap-np__card">' +
                    '<div class="rap-np__header">' +
                        '<div class="rap-np__live-dot"></div>' +
                        '<span class="rap-np__live-text">EN DIRECT</span>' +
                    '</div>' +
                    '<h3 class="rap-np__title">' + escapeHtml(show.title) + '</h3>' +
                    (presenterName ? '<p class="rap-np__presenter">' + escapeHtml(presenterName) + '</p>' : '') +
                    segmentText +
                    trackHtml +
                    nextHtml +
                '</div>';
        });

        // Mettre a jour le label du lecteur flottant
        var floatingName = document.querySelector('.rap-floating .rap-player__name');
        if (floatingName && data && data.current_show) {
            floatingName.textContent = data.current_show.title;
        }

        // Mettre a jour le tagline du lecteur flottant avec la piste
        var floatingTagline = document.querySelector('.rap-floating .rap-player__tagline');
        if (floatingTagline) {
            if (config.showTrackInfo !== false && data && data.current_track && data.current_track.title) {
                var tagArtist = resolveArtist(data.current_track.artist);
                var tagText = data.current_track.title;
                if (tagArtist) {
                    tagText = tagArtist + ' \u2014 ' + tagText;
                }
                floatingTagline.textContent = tagText;

                // Marquee si le texte deborde
                requestAnimationFrame(function() {
                    if (floatingTagline.scrollWidth > floatingTagline.clientWidth) {
                        floatingTagline.classList.add('is-marquee');
                        floatingTagline.innerHTML =
                            '<span class="rap-marquee__inner">' +
                            escapeHtml(tagText) + '\u00A0\u00A0\u00A0\u2022\u00A0\u00A0\u00A0' +
                            escapeHtml(tagText) + '\u00A0\u00A0\u00A0\u2022\u00A0\u00A0\u00A0' +
                            '</span>';
                    } else {
                        floatingTagline.classList.remove('is-marquee');
                    }
                });
            } else {
                // Pas de piste : revenir au slogan
                floatingTagline.classList.remove('is-marquee');
                floatingTagline.textContent = config.tagline || '';
            }
        }

        // Mettre a jour MediaSession
        if ('mediaSession' in navigator && data && data.current_show) {
            var msArtist = (data.current_show.presenters && data.current_show.presenters.length > 0)
                ? data.current_show.presenters[0].name
                : (config.stationName || 'Radio Audace');
            var msTitle = data.current_show.title;

            // Si piste RadioDJ disponible, l'utiliser pour MediaSession (lockscreen mobile)
            if (config.showTrackInfo !== false && data.current_track && data.current_track.title) {
                msTitle = data.current_track.title;
                var msTrackArtist = resolveArtist(data.current_track.artist);
                if (msTrackArtist) {
                    msArtist = msTrackArtist;
                }
            }

            navigator.mediaSession.metadata = new MediaMetadata({
                title: msTitle,
                artist: msArtist,
                album: config.stationName || 'Radio Audace 106.8 FM'
            });
        }

        // Mettre a jour les widget track containers
        var widgetTrackEls = document.querySelectorAll('[data-rap-widget-track]');
        widgetTrackEls.forEach(function (el) {
            var playerEl = el.closest('[data-rap-player]');
            if (!playerEl || playerEl.getAttribute('data-rap-show-track') !== '1') return;
            if (!data || !data.current_track || !data.current_track.title ||
                config.showTrackInfo === false) {
                el.innerHTML = '';
                el.style.display = 'none';
                return;
            }
            var wTrackArtist = resolveArtist(data.current_track.artist);
            var wTrackTitle = escapeHtml(data.current_track.title);
            el.style.display = '';
            el.innerHTML =
                '<div class="rap-widget-track__icon">' +
                    '<svg viewBox="0 0 24 24" width="14" height="14" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>' +
                '</div>' +
                '<div class="rap-widget-track__info">' +
                    (wTrackArtist ? '<span class="rap-widget-track__artist">' + escapeHtml(wTrackArtist) + '</span>' : '') +
                    '<span class="rap-widget-track__title">' + wTrackTitle + '</span>' +
                '</div>';
        });
    }

    /* ═══════════════════════════════════════════════════════════════
       v3: ALERT BANNER — Bandeau d'alerte
       ═══════════════════════════════════════════════════════════════ */

    var alertTimer = null;

    function initAlertBanner() {
        fetchAlertBanner();
        if (alertTimer) clearInterval(alertTimer);
        alertTimer = setInterval(fetchAlertBanner, 30000);
    }

    function fetchAlertBanner() {
        if (!config.ajaxUrl) return;
        fetch(config.ajaxUrl + '?action=rap_alert&nonce=' + (config.nonce || ''))
            .then(function (r) { return r.json(); })
            .then(function (resp) {
                if (resp.success) {
                    renderAlertBanner(resp.data);
                }
            })
            .catch(function () {});
    }

    function renderAlertBanner(data) {
        var banner = document.getElementById('rap-alert-banner');
        if (!banner) return;

        if (!data || !data.active) {
            banner.classList.remove('is-visible');
            return;
        }

        var typeClass = 'rap-alert-banner--' + (data.alert_type || 'info');
        banner.className = 'rap-alert-banner ' + typeClass + ' is-visible';

        var urlHtml = data.url
            ? ' <a href="' + escapeHtml(data.url) + '" target="_blank" rel="noopener" class="rap-alert-banner__link">En savoir plus</a>'
            : '';

        banner.innerHTML =
            '<div class="rap-alert-banner__content">' +
                '<strong class="rap-alert-banner__title">' + escapeHtml(data.title) + '</strong>' +
                '<span class="rap-alert-banner__message">' + escapeHtml(data.message) + urlHtml + '</span>' +
            '</div>' +
            '<button class="rap-alert-banner__close" aria-label="Fermer">&times;</button>';

        banner.querySelector('.rap-alert-banner__close').addEventListener('click', function () {
            banner.classList.remove('is-visible');
        });
    }

    /* ═══════════════════════════════════════════════════════════════
       v3: ANALYTICS — Statistiques d'ecoute
       ═══════════════════════════════════════════════════════════════ */

    function initAnalytics() {
        // Generer un session_id unique
        analyticsSessionId = sessionStorage.getItem('rap_analytics_sid');
        if (!analyticsSessionId) {
            analyticsSessionId = 'rap_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            sessionStorage.setItem('rap_analytics_sid', analyticsSessionId);
        }

        // Ecouter les changements d'etat audio
        audio.addEventListener('playing', function () {
            sendAnalyticsEvent('play');
            startHeartbeat();
        });
        audio.addEventListener('pause', function () {
            if (isStopping) return;
            sendAnalyticsEvent('pause');
            stopHeartbeat();
        });
    }

    function sendAnalyticsEvent(eventType) {
        if (!config.ajaxUrl || !analyticsSessionId) return;
        var duration = 0;
        if (listenStartTime && (eventType === 'pause' || eventType === 'heartbeat')) {
            duration = Math.round((Date.now() - listenStartTime) / 1000);
        }
        if (eventType === 'play') {
            listenStartTime = Date.now();
        }

        var formData = new FormData();
        formData.append('action', 'rap_analytics');
        formData.append('nonce', config.nonce || '');
        formData.append('session_id', analyticsSessionId);
        formData.append('event_type', eventType);
        formData.append('duration', String(duration));
        formData.append('page_url', window.location.href);

        fetch(config.ajaxUrl, { method: 'POST', body: formData })
            .catch(function () {});
    }

    function startHeartbeat() {
        stopHeartbeat();
        heartbeatTimer = setInterval(function () {
            sendAnalyticsEvent('heartbeat');
        }, 30000);
    }

    function stopHeartbeat() {
        if (heartbeatTimer) {
            clearInterval(heartbeatTimer);
            heartbeatTimer = null;
        }
    }

    /* ═══════════════════════════════════════════════════════════════
       v3: SCHEDULE — Grille des programmes
       ═══════════════════════════════════════════════════════════════ */

    function initSchedule() {
        var containers = document.querySelectorAll('#rap-schedule');
        if (containers.length === 0) return;
        if (!config.ajaxUrl) return;

        fetch(config.ajaxUrl + '?action=rap_schedule&nonce=' + (config.nonce || ''))
            .then(function (r) { return r.json(); })
            .then(function (resp) {
                if (resp.success && resp.data) {
                    containers.forEach(function (el) {
                        renderSchedule(el, resp.data);
                    });
                }
            })
            .catch(function () {});
    }

    function renderSchedule(container, data) {
        var days = data.days || data;
        if (!days || typeof days !== 'object') {
            container.innerHTML = '<p class="rap-schedule__empty">Aucun programme disponible.</p>';
            return;
        }

        var dayNames = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
        var html = '<div class="rap-schedule__grid">';

        dayNames.forEach(function (day) {
            var shows = days[day] || [];
            html += '<div class="rap-schedule__day">';
            html += '<h4 class="rap-schedule__day-name">' + day.charAt(0).toUpperCase() + day.slice(1) + '</h4>';
            if (shows.length === 0) {
                html += '<p class="rap-schedule__no-show">-</p>';
            } else {
                shows.forEach(function (show) {
                    var isLive = show.status === 'en-cours';
                    html += '<div class="rap-schedule__show' + (isLive ? ' is-live' : '') + '">';
                    html += '<span class="rap-schedule__time">' + escapeHtml(show.time || '') + '</span>';
                    html += '<span class="rap-schedule__title">' + escapeHtml(show.title || show.emission || '') + '</span>';
                    if (show.presenter) {
                        html += '<span class="rap-schedule__presenter">' + escapeHtml(show.presenter) + '</span>';
                    }
                    html += '</div>';
                });
            }
            html += '</div>';
        });

        html += '</div>';
        container.innerHTML = html;
    }

    /* ═══════════════════════════════════════════════════════════════
       v3: TEAM — Fiches animateurs
       ═══════════════════════════════════════════════════════════════ */

    function initTeam() {
        var containers = document.querySelectorAll('#rap-team');
        if (containers.length === 0) return;
        if (!config.ajaxUrl) return;

        fetch(config.ajaxUrl + '?action=rap_presenters&nonce=' + (config.nonce || ''))
            .then(function (r) { return r.json(); })
            .then(function (resp) {
                if (resp.success && resp.data) {
                    containers.forEach(function (el) {
                        renderTeam(el, resp.data);
                    });
                }
            })
            .catch(function () {});
    }

    function renderTeam(container, presenters) {
        if (!presenters || presenters.length === 0) {
            container.innerHTML = '<p class="rap-team__empty">Aucun animateur disponible.</p>';
            return;
        }

        var html = '<div class="rap-team__grid">';
        presenters.forEach(function (p) {
            var photoHtml = p.photo_url
                ? '<img src="' + escapeHtml(p.photo_url) + '" alt="' + escapeHtml(p.name) + '" class="rap-team__photo">'
                : '<div class="rap-team__photo rap-team__photo--placeholder">' + escapeHtml(p.name.charAt(0)) + '</div>';
            html += '<div class="rap-team__card">';
            html += photoHtml;
            html += '<h4 class="rap-team__name">' + escapeHtml(p.name) + '</h4>';
            if (p.biography) {
                html += '<p class="rap-team__bio">' + escapeHtml(p.biography) + '</p>';
            }
            html += '</div>';
        });
        html += '</div>';
        container.innerHTML = html;
    }

    /* ═══════════════════════════════════════════════════════════════
       UTILITAIRE
       ═══════════════════════════════════════════════════════════════ */

    function escapeHtml(str) {
        if (!str) return '';
        var div = document.createElement('div');
        div.appendChild(document.createTextNode(str));
        return div.innerHTML;
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
