<?php
/**
 * Radio Audace Player v2 — Page d'administration
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/* ─── Menu admin ───────────────────────────────────────────────── */

function rap_admin_menu() {
    add_options_page(
        __( 'Radio Audace Player', 'radio-audace-player' ),
        __( 'Radio Audace Player', 'radio-audace-player' ),
        'manage_options',
        'radio-audace-player',
        'rap_settings_page'
    );
}
add_action( 'admin_menu', 'rap_admin_menu' );

/* ─── Enregistrement des settings ──────────────────────────────── */

function rap_register_settings() {
    register_setting( 'rap_options_group', 'rap_options', 'rap_sanitize_options' );
}
add_action( 'admin_init', 'rap_register_settings' );

function rap_sanitize_options( $input ) {
    $defaults  = rap_get_defaults();
    $sanitized = array();

    $sanitized['stream_url']    = ! empty( $input['stream_url'] ) ? esc_url_raw( $input['stream_url'] ) : $defaults['stream_url'];
    $sanitized['station_name']  = ! empty( $input['station_name'] ) ? sanitize_text_field( $input['station_name'] ) : $defaults['station_name'];
    $sanitized['tagline']       = ! empty( $input['tagline'] ) ? sanitize_text_field( $input['tagline'] ) : $defaults['tagline'];
    $sanitized['primary_color'] = ! empty( $input['primary_color'] ) ? sanitize_hex_color( $input['primary_color'] ) : $defaults['primary_color'];
    $sanitized['logo_url']      = ! empty( $input['logo_url'] ) ? esc_url_raw( $input['logo_url'] ) : '';

    $sanitized['skin'] = in_array( $input['skin'], rap_valid_skins(), true ) ? $input['skin'] : 'dark';

    $valid_styles              = array( 'bar', 'mini', 'card' );
    $sanitized['player_style'] = in_array( $input['player_style'], $valid_styles, true ) ? $input['player_style'] : 'bar';

    $sanitized['floating_enabled']    = ! empty( $input['floating_enabled'] );
    $sanitized['floating_type']       = in_array( $input['floating_type'], rap_valid_floating_types(), true ) ? $input['floating_type'] : 'bar-float';
    $sanitized['live_badge_text']     = ! empty( $input['live_badge_text'] ) ? sanitize_text_field( $input['live_badge_text'] ) : 'EN DIRECT';
    $sanitized['bubble_label_text']   = ! empty( $input['bubble_label_text'] ) ? sanitize_text_field( $input['bubble_label_text'] ) : 'Ecouter en direct';
    $sanitized['persistent_playback'] = ! empty( $input['persistent_playback'] );
    $sanitized['content_selector']    = sanitize_text_field( $input['content_selector'] ?? '' );

    $sanitized['show_volume'] = ! empty( $input['show_volume'] );
    $sanitized['auto_play']   = ! empty( $input['auto_play'] );
    $sanitized['default_volume'] = max( 0, min( 100, intval( $input['default_volume'] ?? 80 ) ) );

    $sanitized['api_url']              = ! empty( $input['api_url'] ) ? esc_url_raw( $input['api_url'] ) : $defaults['api_url'];
    $sanitized['api_polling_interval'] = ! empty( $input['api_polling_interval'] ) ? intval( $input['api_polling_interval'] ) : $defaults['api_polling_interval'];
    $sanitized['api_polling_interval'] = max( 15, min( 300, $sanitized['api_polling_interval'] ) );
    $sanitized['show_now_playing']     = ! empty( $input['show_now_playing'] );
    $sanitized['show_alert_banner']    = ! empty( $input['show_alert_banner'] );
    $sanitized['analytics_enabled']    = ! empty( $input['analytics_enabled'] );
    $sanitized['wp_sync_secret']       = ! empty( $input['wp_sync_secret'] ) ? sanitize_text_field( $input['wp_sync_secret'] ) : '';

    $sanitized['show_track_info']     = ! empty( $input['show_track_info'] );
    $valid_ua_modes = array( 'hide', 'replace', 'show' );
    $sanitized['unknown_artist_mode'] = in_array( $input['unknown_artist_mode'] ?? '', $valid_ua_modes, true )
        ? $input['unknown_artist_mode'] : 'hide';
    $sanitized['unknown_artist_text'] = sanitize_text_field( $input['unknown_artist_text'] ?? '' );

    return $sanitized;
}

/* ─── Page de reglages ─────────────────────────────────────────── */

function rap_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        return;
    }
    $options = rap_get_options();
    ?>
    <style>
        .rap-admin-cards { display: flex; flex-wrap: wrap; gap: 12px; margin: 8px 0 4px; }
        .rap-admin-card {
            position: relative; display: flex; flex-direction: column; align-items: center;
            border: 2px solid #ddd; border-radius: 10px; padding: 14px 18px;
            cursor: pointer; transition: all 0.2s; background: #fafafa; min-width: 120px;
        }
        .rap-admin-card:hover { border-color: #2ea3f2; background: #f0f9ff; }
        .rap-admin-card.is-active { border-color: #2ea3f2; background: #e8f4fd; box-shadow: 0 0 0 1px #2ea3f2; }
        .rap-admin-card input[type="radio"] { position: absolute; opacity: 0; pointer-events: none; }
        .rap-admin-card__preview { width: 80px; height: 40px; border-radius: 6px; margin-bottom: 8px; border: 1px solid rgba(0,0,0,0.1); }
        .rap-admin-card__label { font-size: 13px; font-weight: 600; color: #1d2327; }
        .rap-admin-card__desc { font-size: 11px; color: #646970; margin-top: 2px; text-align: center; }

        /* Skin previews */
        .rap-preview-dark   { background: linear-gradient(135deg, #1a1a2e, #16213e); }
        .rap-preview-light  { background: #ffffff; box-shadow: inset 0 0 0 1px #e5e7eb; }
        .rap-preview-glass  { background: linear-gradient(135deg, rgba(26,26,46,0.6), rgba(22,33,62,0.6)); backdrop-filter: blur(4px); }
        .rap-preview-brand  { background: linear-gradient(135deg, #2ea3f2, #1a6fc7); }
        .rap-preview-neon   { background: #0a0a1a; box-shadow: inset 0 0 8px #2ea3f266, 0 0 0 1px #2ea3f2; }

        /* Floating type previews */
        .rap-preview-bar-float { background: linear-gradient(135deg, #1a1a2e, #16213e); position: relative; }
        .rap-preview-bar-float::after { content: ''; position: absolute; bottom: 4px; left: 8px; right: 8px; height: 6px; background: #2ea3f2; border-radius: 3px; }
        .rap-preview-bubble { background: #f5f5f5; position: relative; }
        .rap-preview-bubble::after { content: ''; position: absolute; bottom: 6px; right: 8px; width: 16px; height: 16px; background: #2ea3f2; border-radius: 50%; }
        .rap-preview-mini-bar { background: linear-gradient(135deg, #1a1a2e, #16213e); position: relative; }
        .rap-preview-mini-bar::after { content: ''; position: absolute; bottom: 4px; left: 16px; right: 16px; height: 3px; background: #2ea3f2; border-radius: 2px; }

        .rap-section { background: #fff; border: 1px solid #c3c4c7; border-radius: 8px; padding: 20px 24px; margin: 16px 0; }
        .rap-section h2 { margin-top: 0; padding: 0; font-size: 16px; border-bottom: 1px solid #eee; padding-bottom: 12px; margin-bottom: 16px; }
    </style>

    <div class="wrap">
        <h1><?php esc_html_e( 'Radio Audace Player — Reglages', 'radio-audace-player' ); ?></h1>

        <form method="post" action="options.php">
            <?php settings_fields( 'rap_options_group' ); ?>

            <!-- ═══ SECTION : STATION ═══ -->
            <div class="rap-section">
                <h2><?php esc_html_e( 'Station', 'radio-audace-player' ); ?></h2>
                <table class="form-table" role="presentation">
                    <tr>
                        <th scope="row"><label for="rap_stream_url"><?php esc_html_e( 'URL du Stream', 'radio-audace-player' ); ?></label></th>
                        <td>
                            <input type="url" id="rap_stream_url" name="rap_options[stream_url]" value="<?php echo esc_attr( $options['stream_url'] ); ?>" class="regular-text" placeholder="https://radio.audace.ovh/stream.mp3">
                            <p class="description"><?php esc_html_e( 'URL du flux Icecast (MP3 ou OGG).', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="rap_station_name"><?php esc_html_e( 'Nom de la station', 'radio-audace-player' ); ?></label></th>
                        <td><input type="text" id="rap_station_name" name="rap_options[station_name]" value="<?php echo esc_attr( $options['station_name'] ); ?>" class="regular-text"></td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="rap_tagline"><?php esc_html_e( 'Slogan', 'radio-audace-player' ); ?></label></th>
                        <td><input type="text" id="rap_tagline" name="rap_options[tagline]" value="<?php echo esc_attr( $options['tagline'] ); ?>" class="regular-text"></td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="rap_primary_color"><?php esc_html_e( 'Couleur primaire', 'radio-audace-player' ); ?></label></th>
                        <td>
                            <input type="text" id="rap_primary_color" name="rap_options[primary_color]" value="<?php echo esc_attr( $options['primary_color'] ); ?>" class="regular-text" placeholder="#2ea3f2">
                            <p class="description"><?php esc_html_e( 'Code hexadecimal (ex: #2ea3f2).', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="rap_logo_url"><?php esc_html_e( 'Logo', 'radio-audace-player' ); ?></label></th>
                        <td>
                            <input type="url" id="rap_logo_url" name="rap_options[logo_url]" value="<?php echo esc_attr( $options['logo_url'] ); ?>" class="regular-text">
                            <button type="button" class="button" id="rap_upload_logo"><?php esc_html_e( 'Choisir une image', 'radio-audace-player' ); ?></button>
                            <p class="description"><?php esc_html_e( 'Laissez vide pour le logo par defaut.', 'radio-audace-player' ); ?></p>
                            <?php if ( ! empty( $options['logo_url'] ) ) : ?>
                                <p><img src="<?php echo esc_url( $options['logo_url'] ); ?>" style="max-width:64px;max-height:64px;margin-top:8px;border-radius:50%;"></p>
                            <?php endif; ?>
                        </td>
                    </tr>
                </table>
            </div>

            <!-- ═══ SECTION : SKIN ═══ -->
            <div class="rap-section">
                <h2><?php esc_html_e( 'Skin (apparence visuelle)', 'radio-audace-player' ); ?></h2>
                <p class="description" style="margin-bottom:12px;"><?php esc_html_e( 'Choisissez le theme visuel du player. S\'applique au shortcode et au lecteur flottant.', 'radio-audace-player' ); ?></p>
                <div class="rap-admin-cards" id="rap-skin-cards">
                    <?php
                    $skins = array(
                        'dark'  => array( 'Sombre',         'Fond sombre elegant' ),
                        'light' => array( 'Clair',          'Fond blanc epure' ),
                        'glass' => array( 'Verre depoli',   'Effet de transparence' ),
                        'brand' => array( 'Couleur Audace', 'Degrade bleu signature' ),
                        'neon'  => array( 'Neon',           'Effet lumineux' ),
                    );
                    foreach ( $skins as $key => $info ) :
                    ?>
                    <label class="rap-admin-card <?php echo $options['skin'] === $key ? 'is-active' : ''; ?>">
                        <input type="radio" name="rap_options[skin]" value="<?php echo esc_attr( $key ); ?>" <?php checked( $options['skin'], $key ); ?>>
                        <div class="rap-admin-card__preview rap-preview-<?php echo esc_attr( $key ); ?>"></div>
                        <span class="rap-admin-card__label"><?php echo esc_html( $info[0] ); ?></span>
                        <span class="rap-admin-card__desc"><?php echo esc_html( $info[1] ); ?></span>
                    </label>
                    <?php endforeach; ?>
                </div>
            </div>

            <!-- ═══ SECTION : LECTEUR FLOTTANT ═══ -->
            <div class="rap-section">
                <h2><?php esc_html_e( 'Lecteur Flottant', 'radio-audace-player' ); ?></h2>
                <table class="form-table" role="presentation">
                    <tr>
                        <th scope="row"><?php esc_html_e( 'Activer', 'radio-audace-player' ); ?></th>
                        <td>
                            <label>
                                <input type="checkbox" name="rap_options[floating_enabled]" value="1" <?php checked( $options['floating_enabled'] ); ?>>
                                <?php esc_html_e( 'Afficher le lecteur flottant sur toutes les pages', 'radio-audace-player' ); ?>
                            </label>
                        </td>
                    </tr>
                </table>

                <p style="font-weight:600;margin: 16px 0 8px;"><?php esc_html_e( 'Type de lecteur flottant', 'radio-audace-player' ); ?></p>
                <div class="rap-admin-cards" id="rap-floating-cards">
                    <?php
                    $types = array(
                        'bar-float' => array( 'Barre',         'Barre en bas, minimisable en pastille compacte' ),
                        'bubble'    => array( 'Bulle',         'Bouton rond discret, s\'expanse au clic' ),
                        'mini-bar'  => array( 'Mini barre',    'Barre fine, retractable en languette' ),
                    );
                    foreach ( $types as $key => $info ) :
                    ?>
                    <label class="rap-admin-card <?php echo $options['floating_type'] === $key ? 'is-active' : ''; ?>">
                        <input type="radio" name="rap_options[floating_type]" value="<?php echo esc_attr( $key ); ?>" <?php checked( $options['floating_type'], $key ); ?>>
                        <div class="rap-admin-card__preview rap-preview-<?php echo esc_attr( $key ); ?>"></div>
                        <span class="rap-admin-card__label"><?php echo esc_html( $info[0] ); ?></span>
                        <span class="rap-admin-card__desc"><?php echo esc_html( $info[1] ); ?></span>
                    </label>
                    <?php endforeach; ?>
                </div>

                <table class="form-table" role="presentation" style="margin-top:12px;">
                    <tr>
                        <th scope="row"><label for="rap_live_badge_text"><?php esc_html_e( 'Texte du badge en direct', 'radio-audace-player' ); ?></label></th>
                        <td>
                            <input type="text" id="rap_live_badge_text" name="rap_options[live_badge_text]" value="<?php echo esc_attr( $options['live_badge_text'] ); ?>" class="regular-text" placeholder="EN DIRECT">
                            <p class="description"><?php esc_html_e( 'Texte affiche dans le badge rouge du lecteur (ex: EN DIRECT, LIVE, A L\'ANTENNE).', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                    <tr id="rap_bubble_label_text_row" style="<?php echo $options['floating_type'] === 'bubble' ? '' : 'display:none;'; ?>">
                        <th scope="row"><label for="rap_bubble_label_text"><?php esc_html_e( 'Texte du label bulle', 'radio-audace-player' ); ?></label></th>
                        <td>
                            <input type="text" id="rap_bubble_label_text" name="rap_options[bubble_label_text]" value="<?php echo esc_attr( $options['bubble_label_text'] ); ?>" class="regular-text" placeholder="Ecouter en direct">
                            <p class="description"><?php esc_html_e( 'Texte affiche a cote du bouton bulle avant ouverture.', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                </table>
            </div>

            <!-- ═══ SECTION : LECTURE PERSISTANTE ═══ -->
            <div class="rap-section">
                <h2><?php esc_html_e( 'Lecture Persistante', 'radio-audace-player' ); ?></h2>
                <table class="form-table" role="presentation">
                    <tr>
                        <th scope="row"><?php esc_html_e( 'Navigation Pjax', 'radio-audace-player' ); ?></th>
                        <td>
                            <label>
                                <input type="checkbox" name="rap_options[persistent_playback]" value="1" <?php checked( $options['persistent_playback'] ); ?>>
                                <?php esc_html_e( 'La musique continue quand le visiteur navigue entre les pages', 'radio-audace-player' ); ?>
                            </label>
                            <p class="description"><?php esc_html_e( 'Utilise une technique AJAX pour charger les pages sans rechargement complet. Compatible Divi/Extra.', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="rap_content_selector"><?php esc_html_e( 'Selecteur CSS du contenu', 'radio-audace-player' ); ?></label></th>
                        <td>
                            <input type="text" id="rap_content_selector" name="rap_options[content_selector]" value="<?php echo esc_attr( $options['content_selector'] ); ?>" class="regular-text" placeholder="auto-detection">
                            <p class="description"><?php esc_html_e( 'Laissez vide pour auto-detection (Divi/Extra). Exemples : #main-content, #et-main-area', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                </table>
            </div>

            <!-- ═══ SECTION : OPTIONS ═══ -->
            <div class="rap-section">
                <h2><?php esc_html_e( 'Options', 'radio-audace-player' ); ?></h2>
                <table class="form-table" role="presentation">
                    <tr>
                        <th scope="row"><label for="rap_player_style"><?php esc_html_e( 'Style shortcode', 'radio-audace-player' ); ?></label></th>
                        <td>
                            <select id="rap_player_style" name="rap_options[player_style]">
                                <option value="bar" <?php selected( $options['player_style'], 'bar' ); ?>><?php esc_html_e( 'Barre (horizontal)', 'radio-audace-player' ); ?></option>
                                <option value="mini" <?php selected( $options['player_style'], 'mini' ); ?>><?php esc_html_e( 'Mini (sidebar/widget)', 'radio-audace-player' ); ?></option>
                                <option value="card" <?php selected( $options['player_style'], 'card' ); ?>><?php esc_html_e( 'Carte (sidebar premium)', 'radio-audace-player' ); ?></option>
                            </select>
                            <p class="description"><?php esc_html_e( 'Style par defaut du shortcode [radio_audace_player].', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><?php esc_html_e( 'Volume', 'radio-audace-player' ); ?></th>
                        <td>
                            <label>
                                <input type="checkbox" name="rap_options[show_volume]" value="1" <?php checked( $options['show_volume'] ); ?>>
                                <?php esc_html_e( 'Afficher le controle de volume', 'radio-audace-player' ); ?>
                            </label>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><?php esc_html_e( 'Lecture automatique', 'radio-audace-player' ); ?></th>
                        <td>
                            <label>
                                <input type="checkbox" name="rap_options[auto_play]" value="1" <?php checked( $options['auto_play'] ); ?>>
                                <?php esc_html_e( 'Lancer la lecture automatiquement', 'radio-audace-player' ); ?>
                            </label>
                            <p class="description"><?php esc_html_e( 'Note : la plupart des navigateurs bloquent la lecture automatique.', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="rap_default_volume"><?php esc_html_e( 'Volume par defaut', 'radio-audace-player' ); ?></label></th>
                        <td>
                            <input type="number" id="rap_default_volume" name="rap_options[default_volume]" value="<?php echo esc_attr( $options['default_volume'] ); ?>" class="small-text" min="0" max="100"> %
                            <p class="description"><?php esc_html_e( 'Volume initial du lecteur au premier chargement (0 a 100).', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                </table>
            </div>

            <!-- ═══ SECTION : PISTE RADIODJ ═══ -->
            <div class="rap-section">
                <h2><?php esc_html_e( 'Piste RadioDJ', 'radio-audace-player' ); ?></h2>
                <p class="description" style="margin-bottom:16px;">
                    <?php esc_html_e( 'Configurez le comportement lorsque RadioDJ envoie un artiste inconnu (ex: "Unknown Artist").', 'radio-audace-player' ); ?>
                </p>
                <table class="form-table" role="presentation">
                    <tr>
                        <th scope="row"><?php esc_html_e( 'Piste en cours', 'radio-audace-player' ); ?></th>
                        <td>
                            <label>
                                <input type="checkbox" name="rap_options[show_track_info]" value="1" <?php checked( $options['show_track_info'] ); ?>>
                                <?php esc_html_e( 'Afficher les informations de la piste RadioDJ en cours', 'radio-audace-player' ); ?>
                            </label>
                            <p class="description"><?php esc_html_e( 'Si active, le titre et l\'artiste du morceau diffuse par RadioDJ s\'affichent dans la carte Now Playing et dans le lecteur flottant.', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="rap_unknown_artist_mode"><?php esc_html_e( 'Artiste inconnu', 'radio-audace-player' ); ?></label></th>
                        <td>
                            <select id="rap_unknown_artist_mode" name="rap_options[unknown_artist_mode]">
                                <option value="hide" <?php selected( $options['unknown_artist_mode'], 'hide' ); ?>><?php esc_html_e( 'Masquer (afficher uniquement le titre)', 'radio-audace-player' ); ?></option>
                                <option value="replace" <?php selected( $options['unknown_artist_mode'], 'replace' ); ?>><?php esc_html_e( 'Remplacer par un texte personnalise', 'radio-audace-player' ); ?></option>
                                <option value="show" <?php selected( $options['unknown_artist_mode'], 'show' ); ?>><?php esc_html_e( 'Afficher tel quel', 'radio-audace-player' ); ?></option>
                            </select>
                            <p class="description"><?php esc_html_e( 'Comportement quand l\'artiste est "Unknown Artist", "Unknown" ou vide.', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                    <tr id="rap_unknown_artist_text_row" style="<?php echo $options['unknown_artist_mode'] === 'replace' ? '' : 'display:none;'; ?>">
                        <th scope="row"><label for="rap_unknown_artist_text"><?php esc_html_e( 'Texte de remplacement', 'radio-audace-player' ); ?></label></th>
                        <td>
                            <input type="text" id="rap_unknown_artist_text" name="rap_options[unknown_artist_text]" value="<?php echo esc_attr( $options['unknown_artist_text'] ); ?>" class="regular-text" placeholder="<?php esc_attr_e( 'ex: Radio Audace', 'radio-audace-player' ); ?>">
                            <p class="description"><?php esc_html_e( 'Ce texte remplacera "Unknown Artist" dans l\'affichage.', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                </table>
            </div>

            <!-- ═══ SECTION : INTEGRATION API RADIOMANAGER ═══ -->
            <div class="rap-section">
                <h2><?php esc_html_e( 'Integration API RadioManager', 'radio-audace-player' ); ?></h2>
                <p class="description" style="margin-bottom:16px;">
                    <?php esc_html_e( 'Connectez ce plugin a votre plateforme RadioManager pour synchroniser automatiquement les emissions, alertes et statistiques d\'ecoute. Toutes les donnees transitent via un proxy securise (admin-ajax.php) — l\'URL de l\'API n\'est jamais exposee aux visiteurs.', 'radio-audace-player' ); ?>
                </p>
                <table class="form-table" role="presentation">
                    <tr>
                        <th scope="row"><label for="rap_api_url"><?php esc_html_e( 'URL de l\'API', 'radio-audace-player' ); ?></label></th>
                        <td>
                            <input type="url" id="rap_api_url" name="rap_options[api_url]" value="<?php echo esc_attr( $options['api_url'] ); ?>" class="regular-text" placeholder="https://api.cloud.audace.ovh">
                            <p class="description"><?php esc_html_e( 'Adresse complete du backend RadioManager (ex: https://api.cloud.audace.ovh). Cette URL est utilisee cote serveur WordPress uniquement — jamais exposee dans le navigateur des visiteurs.', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="rap_api_polling_interval"><?php esc_html_e( 'Intervalle de mise a jour (secondes)', 'radio-audace-player' ); ?></label></th>
                        <td>
                            <input type="number" id="rap_api_polling_interval" name="rap_options[api_polling_interval]" value="<?php echo esc_attr( $options['api_polling_interval'] ); ?>" class="small-text" min="15" max="300"> <?php esc_html_e( 'secondes', 'radio-audace-player' ); ?>
                            <p class="description"><?php esc_html_e( 'Toutes les X secondes, le player interroge l\'API pour rafraichir l\'emission en cours et les alertes. Valeur recommandee : 60. Minimum : 15, maximum : 300.', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><?php esc_html_e( 'Emission en cours', 'radio-audace-player' ); ?></th>
                        <td>
                            <label>
                                <input type="checkbox" name="rap_options[show_now_playing]" value="1" <?php checked( $options['show_now_playing'] ); ?>>
                                <?php esc_html_e( 'Afficher l\'emission en cours dans le lecteur flottant', 'radio-audace-player' ); ?>
                            </label>
                            <p class="description"><?php esc_html_e( 'Quand une emission est "en cours" dans RadioManager, son titre, son animateur et le segment actuel s\'affichent dans le player. Endpoint utilise : /public/now-playing.', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><?php esc_html_e( 'Alertes', 'radio-audace-player' ); ?></th>
                        <td>
                            <label>
                                <input type="checkbox" name="rap_options[show_alert_banner]" value="1" <?php checked( $options['show_alert_banner'] ); ?>>
                                <?php esc_html_e( 'Afficher les bandeaux d\'alerte envoyes depuis RadioManager', 'radio-audace-player' ); ?>
                            </label>
                            <p class="description"><?php esc_html_e( 'Les alertes creees dans RadioManager (page "Alertes WordPress") s\'affichent en bandeau anime en haut du site. 3 niveaux : Information (bleu), Avertissement (orange), Urgent (rouge).', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><?php esc_html_e( 'Statistiques d\'ecoute', 'radio-audace-player' ); ?></th>
                        <td>
                            <label>
                                <input type="checkbox" name="rap_options[analytics_enabled]" value="1" <?php checked( $options['analytics_enabled'] ); ?>>
                                <?php esc_html_e( 'Envoyer les statistiques d\'ecoute a RadioManager', 'radio-audace-player' ); ?>
                            </label>
                            <p class="description"><?php esc_html_e( 'Enregistre anonymement les evenements play/pause et un signal toutes les 30 secondes (heartbeat). Ces donnees alimentent la page "Auditeurs" du SaaS : ecoutes du jour, sessions uniques, duree moyenne, heure de pointe. Aucune donnee personnelle n\'est collectee.', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="rap_wp_sync_secret"><?php esc_html_e( 'Cle secrete de synchronisation', 'radio-audace-player' ); ?></label></th>
                        <td>
                            <input type="password" id="rap_wp_sync_secret" name="rap_options[wp_sync_secret]" value="<?php echo esc_attr( $options['wp_sync_secret'] ); ?>" class="regular-text" autocomplete="off" placeholder="<?php esc_attr_e( 'ex: mon-secret-de-sync-2024', 'radio-audace-player' ); ?>">
                            <p class="description"><?php esc_html_e( 'Cle partagee entre ce plugin et le backend. Quand une emission passe "en cours", le backend peut creer automatiquement un article WordPress (cross-posting). Cette cle doit etre identique a la variable WORDPRESS_SYNC_SECRET du backend. Laissez vide pour desactiver le cross-posting.', 'radio-audace-player' ); ?></p>
                        </td>
                    </tr>
                </table>
            </div>

            <?php submit_button( __( 'Enregistrer les reglages', 'radio-audace-player' ) ); ?>
        </form>

        <hr>

        <!-- ═══ AIDE ═══ -->
        <div class="rap-section">
            <h2><?php esc_html_e( 'Utilisation', 'radio-audace-player' ); ?></h2>
            <table class="widefat" style="max-width:750px;">
                <thead>
                    <tr>
                        <th><?php esc_html_e( 'Methode', 'radio-audace-player' ); ?></th>
                        <th><?php esc_html_e( 'Code / Instructions', 'radio-audace-player' ); ?></th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Shortcode</strong></td>
                        <td><code>[radio_audace_player]</code></td>
                    </tr>
                    <tr>
                        <td><strong>Avec style + skin</strong></td>
                        <td>
                            <code>[radio_audace_player style="bar" skin="neon"]</code><br>
                            <code>[radio_audace_player style="mini" skin="glass"]</code><br>
                            <code>[radio_audace_player style="card" skin="dark" show_track="1"]</code>
                        </td>
                    </tr>
                    <tr>
                        <td><strong>Carte avec options</strong></td>
                        <td>
                            <code>[radio_audace_player style="card" title="Ecouter" hide_volume="1" show_track="1"]</code><br>
                            <code>[radio_audace_player style="card" custom_name="Ma Radio" custom_tagline="Le meilleur son"]</code>
                        </td>
                    </tr>
                    <tr>
                        <td><strong>Lecteur flottant</strong></td>
                        <td><?php esc_html_e( 'Automatique sur toutes les pages si active ci-dessus.', 'radio-audace-player' ); ?></td>
                    </tr>
                    <tr>
                        <td><strong>Widget</strong></td>
                        <td><?php esc_html_e( 'Apparence > Widgets > "Radio Audace Player"', 'radio-audace-player' ); ?></td>
                    </tr>
                    <tr>
                        <td><strong>Divi / Extra</strong></td>
                        <td><?php esc_html_e( 'Module "Texte" ou "Code" > coller le shortcode.', 'radio-audace-player' ); ?></td>
                    </tr>
                    <tr>
                        <td><strong>Programme</strong></td>
                        <td>
                            <code>[radio_audace_programme]</code><br>
                            <?php esc_html_e( 'Affiche l\'emission en cours et la prochaine', 'radio-audace-player' ); ?>
                        </td>
                    </tr>
                    <tr>
                        <td><strong>Grille</strong></td>
                        <td>
                            <code>[radio_audace_grille]</code><br>
                            <?php esc_html_e( 'Grille des programmes de la semaine', 'radio-audace-player' ); ?>
                        </td>
                    </tr>
                    <tr>
                        <td><strong>Equipe</strong></td>
                        <td>
                            <code>[radio_audace_equipe]</code><br>
                            <?php esc_html_e( 'Affiche les fiches animateurs', 'radio-audace-player' ); ?>
                        </td>
                    </tr>
                    <tr>
                        <td><strong>PHP</strong></td>
                        <td><code>&lt;?php echo do_shortcode('[radio_audace_player]'); ?&gt;</code></td>
                    </tr>
                </tbody>
            </table>
        </div>

    </div>

    <script>
    jQuery(document).ready(function($) {
        // Selection visuelle des cards (skin + floating type)
        $('.rap-admin-cards').on('change', 'input[type="radio"]', function() {
            $(this).closest('.rap-admin-cards').find('.rap-admin-card').removeClass('is-active');
            $(this).closest('.rap-admin-card').addClass('is-active');
        });

        // Toggle champ texte artiste inconnu
        $('#rap_unknown_artist_mode').on('change', function() {
            $('#rap_unknown_artist_text_row').toggle($(this).val() === 'replace');
        });

        // Toggle champ texte label bulle (visible seulement si type=bubble)
        $('#rap-floating-cards').on('change', 'input[type="radio"]', function() {
            $('#rap_bubble_label_text_row').toggle($(this).val() === 'bubble');
        });

        // Media uploader pour le logo
        $('#rap_upload_logo').on('click', function(e) {
            e.preventDefault();
            var frame = wp.media({
                title: '<?php echo esc_js( __( 'Choisir un logo', 'radio-audace-player' ) ); ?>',
                button: { text: '<?php echo esc_js( __( 'Utiliser ce logo', 'radio-audace-player' ) ); ?>' },
                multiple: false,
                library: { type: 'image' }
            });
            frame.on('select', function() {
                var attachment = frame.state().get('selection').first().toJSON();
                $('#rap_logo_url').val(attachment.url);
            });
            frame.open();
        });
    });
    </script>
    <?php
}

/* Charger le media uploader */
function rap_admin_enqueue( $hook ) {
    if ( 'settings_page_radio-audace-player' !== $hook ) {
        return;
    }
    wp_enqueue_media();
}
add_action( 'admin_enqueue_scripts', 'rap_admin_enqueue' );
