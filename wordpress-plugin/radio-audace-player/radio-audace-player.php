<?php
/**
 * Plugin Name: Radio Audace Player
 * Plugin URI:  https://www.radioaudace.com
 * Description: Lecteur audio streaming personnalise pour Radio Audace 106.8 FM. Shortcode, widget, lecteur flottant avec skins multiples et lecture persistante entre les pages. Compatible Divi/Extra.
 * Version:     3.3.0
 * Author:      Radio Audace
 * Author URI:  https://www.radioaudace.com
 * License:     GPL-2.0+
 * Text Domain: radio-audace-player
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

define( 'RAP_VERSION', '3.3.0' );
define( 'RAP_PLUGIN_DIR', plugin_dir_path( __FILE__ ) );
define( 'RAP_PLUGIN_URL', plugin_dir_url( __FILE__ ) );

/* ═══════════════════════════════════════════════════════════════════
   OPTIONS
   ═══════════════════════════════════════════════════════════════════ */

function rap_get_defaults() {
    return array(
        'stream_url'          => 'https://radio.audace.ovh/stream.mp3',
        'station_name'        => 'Radio Audace 106.8 FM',
        'tagline'             => 'Bien Plus que l\'info',
        'primary_color'       => '#2ea3f2',
        'logo_url'            => '',

        // Skins : dark | light | glass | brand | neon
        'skin'                => 'dark',

        // Style pour shortcode inline : bar | mini | card
        'player_style'        => 'bar',

        // Lecteur flottant
        'floating_enabled'    => true,
        'floating_type'       => 'bar-float',  // bar-float | bubble | mini-bar
        'live_badge_text'     => 'EN DIRECT',
        'bubble_label_text'   => 'Ecouter en direct',

        // Navigation persistante (Pjax)
        'persistent_playback' => true,
        'content_selector'    => '',  // vide = auto-detection Divi/Extra

        'show_volume'         => true,
        'auto_play'           => false,
        'default_volume'      => 80,             // 0-100

        // Integration API RadioManager (v3)
        'api_url'                => 'https://api.cloud.audace.ovh',
        'api_polling_interval'   => 60,
        'show_now_playing'       => true,
        'show_alert_banner'      => true,
        'analytics_enabled'      => true,
        'wp_sync_secret'         => '',

        // Gestion piste RadioDJ
        'show_track_info'        => true,       // afficher la piste RadioDJ (artiste + titre)
        'unknown_artist_mode'    => 'hide',     // hide | replace | show
        'unknown_artist_text'    => '',          // texte de remplacement (si mode=replace)
    );
}

function rap_get_options() {
    $defaults = rap_get_defaults();
    $options  = get_option( 'rap_options', array() );
    return wp_parse_args( $options, $defaults );
}

function rap_valid_skins() {
    return array( 'dark', 'light', 'glass', 'brand', 'neon' );
}

function rap_valid_floating_types() {
    return array( 'bar-float', 'bubble', 'mini-bar' );
}

/* ═══════════════════════════════════════════════════════════════════
   ASSETS
   ═══════════════════════════════════════════════════════════════════ */

function rap_enqueue_assets() {
    $options = rap_get_options();

    wp_enqueue_style(
        'rap-style',
        RAP_PLUGIN_URL . 'css/radio-audace-player.css',
        array(),
        RAP_VERSION
    );

    wp_enqueue_script(
        'rap-script',
        RAP_PLUGIN_URL . 'js/radio-audace-player.js',
        array(),
        RAP_VERSION,
        true
    );

    wp_localize_script( 'rap-script', 'rapConfig', array(
        'streamUrl'          => esc_url( $options['stream_url'] ),
        'stationName'        => esc_html( $options['station_name'] ),
        'tagline'            => esc_html( $options['tagline'] ),
        'primaryColor'       => sanitize_hex_color( $options['primary_color'] ),
        'skin'               => $options['skin'],
        'floatingEnabled'    => (bool) $options['floating_enabled'],
        'floatingType'       => $options['floating_type'],
        'persistentPlayback' => (bool) $options['persistent_playback'],
        'contentSelector'    => $options['content_selector'],
        'showVolume'         => (bool) $options['show_volume'],
        'autoPlay'           => (bool) $options['auto_play'],
        'defaultVolume'      => intval( $options['default_volume'] ),
        'siteUrl'            => home_url(),
        // Integration API v3
        'ajaxUrl'            => admin_url( 'admin-ajax.php' ),
        'pollingInterval'    => intval( $options['api_polling_interval'] ) * 1000,
        'showNowPlaying'     => (bool) $options['show_now_playing'],
        'showAlertBanner'    => (bool) $options['show_alert_banner'],
        'analyticsEnabled'   => (bool) $options['analytics_enabled'],
        'nonce'              => wp_create_nonce( 'rap_nonce' ),
        // Lecteur flottant
        'liveBadgeText'      => esc_html( $options['live_badge_text'] ),
        'bubbleLabelText'    => esc_html( $options['bubble_label_text'] ),
        // Gestion piste RadioDJ
        'showTrackInfo'      => (bool) $options['show_track_info'],
        'unknownArtistMode'  => $options['unknown_artist_mode'],
        'unknownArtistText'  => esc_html( $options['unknown_artist_text'] ),
    ) );

    $color = sanitize_hex_color( $options['primary_color'] );
    if ( $color ) {
        $css = "
            :root {
                --rap-primary: {$color};
                --rap-primary-dark: {$color}dd;
                --rap-primary-light: {$color}33;
                --rap-primary-glow: {$color}66;
            }
        ";
        wp_add_inline_style( 'rap-style', $css );
    }
}
add_action( 'wp_enqueue_scripts', 'rap_enqueue_assets' );

/* ═══════════════════════════════════════════════════════════════════
   AJAX HANDLERS — Proxy vers l'API RadioManager (v3)
   ═══════════════════════════════════════════════════════════════════ */

function rap_api_request( $endpoint ) {
    $options = rap_get_options();
    $api_url = rtrim( $options['api_url'], '/' );
    $cache_key = 'rap_' . md5( $endpoint );
    $cached = get_transient( $cache_key );
    if ( false !== $cached ) {
        return $cached;
    }
    $response = wp_remote_get( $api_url . $endpoint, array( 'timeout' => 10 ) );
    if ( is_wp_error( $response ) ) {
        return null;
    }
    $body = json_decode( wp_remote_retrieve_body( $response ), true );
    set_transient( $cache_key, $body, 30 );
    return $body;
}

function rap_ajax_now_playing() {
    check_ajax_referer( 'rap_nonce', 'nonce' );
    $data = rap_api_request( '/public/now-playing' );
    if ( null === $data ) {
        wp_send_json_error( 'API injoignable' );
    }
    wp_send_json_success( $data );
}
add_action( 'wp_ajax_rap_now_playing', 'rap_ajax_now_playing' );
add_action( 'wp_ajax_nopriv_rap_now_playing', 'rap_ajax_now_playing' );

function rap_ajax_schedule() {
    check_ajax_referer( 'rap_nonce', 'nonce' );
    $week = isset( $_GET['week'] ) ? sanitize_text_field( $_GET['week'] ) : 'current';
    $data = rap_api_request( '/public/schedule?week=' . urlencode( $week ) );
    if ( null === $data ) {
        wp_send_json_error( 'API injoignable' );
    }
    wp_send_json_success( $data );
}
add_action( 'wp_ajax_rap_schedule', 'rap_ajax_schedule' );
add_action( 'wp_ajax_nopriv_rap_schedule', 'rap_ajax_schedule' );

function rap_ajax_alert() {
    check_ajax_referer( 'rap_nonce', 'nonce' );
    $data = rap_api_request( '/public/alert' );
    if ( null === $data ) {
        wp_send_json_error( 'API injoignable' );
    }
    wp_send_json_success( $data );
}
add_action( 'wp_ajax_rap_alert', 'rap_ajax_alert' );
add_action( 'wp_ajax_nopriv_rap_alert', 'rap_ajax_alert' );

function rap_ajax_presenters() {
    check_ajax_referer( 'rap_nonce', 'nonce' );
    $data = rap_api_request( '/public/presenters' );
    if ( null === $data ) {
        wp_send_json_error( 'API injoignable' );
    }
    wp_send_json_success( $data );
}
add_action( 'wp_ajax_rap_presenters', 'rap_ajax_presenters' );
add_action( 'wp_ajax_nopriv_rap_presenters', 'rap_ajax_presenters' );

function rap_ajax_analytics() {
    check_ajax_referer( 'rap_nonce', 'nonce' );
    $options = rap_get_options();
    if ( ! $options['analytics_enabled'] ) {
        wp_send_json_error( 'Analytics desactive' );
    }
    $api_url = rtrim( $options['api_url'], '/' );
    $body = json_encode( array(
        'session_id' => sanitize_text_field( $_POST['session_id'] ?? '' ),
        'event_type' => sanitize_text_field( $_POST['event_type'] ?? '' ),
        'duration'   => intval( $_POST['duration'] ?? 0 ),
        'page_url'   => esc_url_raw( $_POST['page_url'] ?? '' ),
    ) );
    $response = wp_remote_post( $api_url . '/public/analytics/listen-event', array(
        'timeout' => 5,
        'headers' => array( 'Content-Type' => 'application/json' ),
        'body'    => $body,
    ) );
    if ( is_wp_error( $response ) ) {
        wp_send_json_error( 'Echec envoi' );
    }
    wp_send_json_success( json_decode( wp_remote_retrieve_body( $response ), true ) );
}
add_action( 'wp_ajax_rap_analytics', 'rap_ajax_analytics' );
add_action( 'wp_ajax_nopriv_rap_analytics', 'rap_ajax_analytics' );

/* ═══════════════════════════════════════════════════════════════════
   NOUVEAUX SHORTCODES v3
   ═══════════════════════════════════════════════════════════════════ */

/**
 * [radio_audace_programme] — Affiche l'emission en cours et la prochaine.
 */
function rap_programme_shortcode( $atts ) {
    $options = rap_get_options();
    $skin = ! empty( $atts['skin'] ) ? $atts['skin'] : $options['skin'];
    ob_start();
    ?>
    <div id="rap-now-playing" class="rap-now-playing rap-skin--<?php echo esc_attr( $skin ); ?>"
         data-rap-now-playing>
        <div class="rap-now-playing__loading"><?php esc_html_e( 'Chargement du programme...', 'radio-audace-player' ); ?></div>
    </div>
    <?php
    return ob_get_clean();
}
add_shortcode( 'radio_audace_programme', 'rap_programme_shortcode' );

/**
 * [radio_audace_grille] — Grille des programmes de la semaine.
 */
function rap_grille_shortcode( $atts ) {
    $options = rap_get_options();
    $skin = ! empty( $atts['skin'] ) ? $atts['skin'] : $options['skin'];
    ob_start();
    ?>
    <div id="rap-schedule" class="rap-schedule rap-skin--<?php echo esc_attr( $skin ); ?>"
         data-rap-schedule>
        <div class="rap-schedule__loading"><?php esc_html_e( 'Chargement de la grille...', 'radio-audace-player' ); ?></div>
    </div>
    <?php
    return ob_get_clean();
}
add_shortcode( 'radio_audace_grille', 'rap_grille_shortcode' );

/**
 * [radio_audace_equipe] — Fiches des animateurs.
 */
function rap_equipe_shortcode( $atts ) {
    $options = rap_get_options();
    $skin = ! empty( $atts['skin'] ) ? $atts['skin'] : $options['skin'];
    ob_start();
    ?>
    <div id="rap-team" class="rap-team rap-skin--<?php echo esc_attr( $skin ); ?>"
         data-rap-team>
        <div class="rap-team__loading"><?php esc_html_e( 'Chargement de l\'equipe...', 'radio-audace-player' ); ?></div>
    </div>
    <?php
    return ob_get_clean();
}
add_shortcode( 'radio_audace_equipe', 'rap_equipe_shortcode' );

/* ═══════════════════════════════════════════════════════════════════
   BANDEAU D'ALERTE — injecte via wp_footer avant le lecteur flottant
   ═══════════════════════════════════════════════════════════════════ */

function rap_render_alert_banner() {
    if ( is_admin() ) {
        return;
    }
    $options = rap_get_options();
    if ( ! $options['show_alert_banner'] ) {
        return;
    }
    ?>
    <div id="rap-alert-banner" class="rap-alert-banner" style="display:none;"
         role="alert" data-rap-alert></div>
    <?php
}
add_action( 'wp_footer', 'rap_render_alert_banner', 98 );

/* ═══════════════════════════════════════════════════════════════════
   REST API — Endpoint de synchronisation cross-posting (P5)
   ═══════════════════════════════════════════════════════════════════ */

function rap_register_rest_routes() {
    register_rest_route( 'rap/v1', '/sync-show', array(
        'methods'             => 'POST',
        'callback'            => 'rap_sync_show_callback',
        'permission_callback' => 'rap_verify_sync_secret',
    ) );
}
add_action( 'rest_api_init', 'rap_register_rest_routes' );

function rap_verify_sync_secret( $request ) {
    $options = rap_get_options();
    $secret  = $request->get_header( 'X-RAP-Sync-Secret' );
    return ! empty( $options['wp_sync_secret'] ) && hash_equals( $options['wp_sync_secret'], (string) $secret );
}

function rap_sync_show_callback( $request ) {
    $data = $request->get_json_params();
    if ( empty( $data['title'] ) ) {
        return new WP_Error( 'missing_title', 'Le titre est requis', array( 'status' => 400 ) );
    }

    $show_id = intval( $data['id'] ?? 0 );
    $existing = null;
    if ( $show_id ) {
        $existing_posts = get_posts( array(
            'post_type'  => 'post',
            'meta_key'   => '_rap_show_id',
            'meta_value' => $show_id,
            'numberposts' => 1,
        ) );
        if ( ! empty( $existing_posts ) ) {
            $existing = $existing_posts[0];
        }
    }

    $content  = wp_kses_post( $data['description'] ?? '' );
    $content .= "\n\n[radio_audace_player]";
    if ( ! empty( $data['presenter_name'] ) ) {
        $content .= "\n\n<p><strong>Animateur :</strong> " . esc_html( $data['presenter_name'] ) . "</p>";
    }

    $post_data = array(
        'post_title'   => sanitize_text_field( $data['title'] ),
        'post_content' => $content,
        'post_status'  => 'publish',
        'post_type'    => 'post',
        'meta_input'   => array(
            '_rap_show_id'        => $show_id,
            '_rap_broadcast_date' => sanitize_text_field( $data['broadcast_date'] ?? '' ),
            '_rap_duration'       => intval( $data['duration'] ?? 0 ),
        ),
    );

    if ( $existing ) {
        $post_data['ID'] = $existing->ID;
        wp_update_post( $post_data );
        $post_id = $existing->ID;
    } else {
        $post_id = wp_insert_post( $post_data );
    }

    return rest_ensure_response( array( 'post_id' => $post_id, 'updated' => ! is_null( $existing ) ) );
}

/**
 * Icones SVG partagees.
 */
function rap_svg_play() {
    return '<svg class="rap-icon rap-icon--play" viewBox="0 0 24 24" width="28" height="28" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>';
}
function rap_svg_pause() {
    return '<svg class="rap-icon rap-icon--pause" viewBox="0 0 24 24" width="28" height="28" fill="currentColor" style="display:none"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>';
}
function rap_svg_loading() {
    return '<svg class="rap-icon rap-icon--loading" viewBox="0 0 24 24" width="28" height="28" fill="none" stroke="currentColor" stroke-width="2" style="display:none"><circle cx="12" cy="12" r="10" stroke-dasharray="31.4 31.4" stroke-linecap="round"/></svg>';
}
function rap_svg_vol_on() {
    return '<svg class="rap-icon rap-icon--vol-on" viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/></svg>';
}
function rap_svg_vol_off() {
    return '<svg class="rap-icon rap-icon--vol-off" viewBox="0 0 24 24" width="20" height="20" fill="currentColor" style="display:none"><path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z"/></svg>';
}
function rap_svg_minimize() {
    return '<svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor"><path d="M19 13H5v-2h14v2z"/></svg>';
}
function rap_svg_close() {
    return '<svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor"><path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/></svg>';
}

/**
 * Bloc volume HTML.
 */
function rap_volume_html() {
    $options = rap_get_options();
    if ( ! $options['show_volume'] ) {
        return '';
    }
    ob_start();
    ?>
    <div class="rap-player__volume">
        <button class="rap-player__btn rap-player__btn--mute" type="button" aria-label="<?php esc_attr_e( 'Couper / Activer le son', 'radio-audace-player' ); ?>">
            <?php echo rap_svg_vol_on() . rap_svg_vol_off(); ?>
        </button>
        <input class="rap-player__volume-slider" type="range" min="0" max="100" value="80" aria-label="<?php esc_attr_e( 'Volume', 'radio-audace-player' ); ?>">
    </div>
    <?php
    return ob_get_clean();
}

/* ═══════════════════════════════════════════════════════════════════
   SHORTCODE  [radio_audace_player]
   Pour les players inline (bar, mini, card) — places dans le contenu.
   ═══════════════════════════════════════════════════════════════════ */

function rap_shortcode( $atts ) {
    $atts = shortcode_atts( array(
        'style'           => '',      // bar | mini | card
        'skin'            => '',      // dark | light | glass | brand | neon
        'title'           => '',      // titre optionnel au-dessus
        'custom_name'     => '',      // surcharge nom station
        'custom_tagline'  => '',      // surcharge slogan
        'hide_volume'     => '',      // '1' = masquer volume
        'hide_live_badge' => '',      // '1' = masquer badge
        'show_track'      => '',      // '1' = afficher piste en cours
    ), $atts, 'radio_audace_player' );

    $options      = rap_get_options();
    $style        = ! empty( $atts['style'] ) ? $atts['style'] : $options['player_style'];
    $skin         = ! empty( $atts['skin'] ) ? $atts['skin'] : $options['skin'];
    $logo         = ! empty( $options['logo_url'] ) ? $options['logo_url'] : RAP_PLUGIN_URL . 'assets/default-logo.svg';
    $station_name = ! empty( $atts['custom_name'] ) ? $atts['custom_name'] : $options['station_name'];
    $tagline      = ! empty( $atts['custom_tagline'] ) ? $atts['custom_tagline'] : $options['tagline'];
    $show_volume  = ( $atts['hide_volume'] === '1' ) ? false : (bool) $options['show_volume'];
    $show_badge   = ( $atts['hide_live_badge'] === '1' ) ? false : true;
    $show_track   = ( $atts['show_track'] === '1' );
    $widget_title = ! empty( $atts['title'] ) ? $atts['title'] : '';

    ob_start();

    if ( 'card' === $style ) :
    ?>
    <div class="rap-player rap-player--card rap-skin--<?php echo esc_attr( $skin ); ?>"
         data-rap-player data-rap-show-track="<?php echo $show_track ? '1' : '0'; ?>"
         role="region" aria-label="<?php esc_attr_e( 'Lecteur Radio', 'radio-audace-player' ); ?>">

        <?php if ( $widget_title ) : ?>
        <div class="rap-player__widget-title"><?php echo esc_html( $widget_title ); ?></div>
        <?php endif; ?>

        <div class="rap-player__info">
            <img class="rap-player__logo" src="<?php echo esc_url( $logo ); ?>"
                 alt="<?php echo esc_attr( $station_name ); ?>" width="72" height="72">
            <div class="rap-player__text">
                <span class="rap-player__name"><?php echo esc_html( $station_name ); ?></span>
                <span class="rap-player__tagline"><?php echo esc_html( $tagline ); ?></span>
            </div>
        </div>

        <div class="rap-player__controls">
            <div class="rap-player__equalizer">
                <span class="rap-player__eq-bar"></span>
                <span class="rap-player__eq-bar"></span>
                <span class="rap-player__eq-bar"></span>
                <span class="rap-player__eq-bar"></span>
            </div>

            <button class="rap-player__btn rap-player__btn--play" type="button"
                    aria-label="<?php esc_attr_e( 'Lecture / Pause', 'radio-audace-player' ); ?>">
                <?php echo rap_svg_play() . rap_svg_pause() . rap_svg_loading(); ?>
            </button>

            <?php if ( $show_badge ) : ?>
            <div class="rap-player__live-badge">
                <span class="rap-player__live-dot"></span>
                <span><?php echo esc_html( $options['live_badge_text'] ); ?></span>
            </div>
            <?php endif; ?>
        </div>

        <?php if ( $show_track ) : ?>
        <div class="rap-player__widget-track" data-rap-widget-track></div>
        <?php endif; ?>

        <?php if ( $show_volume ) : ?>
        <?php echo rap_volume_html(); ?>
        <?php endif; ?>
    </div>
    <?php
    else :
    // ── Styles bar / mini (HTML existant) ──
    ?>
    <div class="rap-player rap-player--<?php echo esc_attr( $style ); ?> rap-skin--<?php echo esc_attr( $skin ); ?>"
         data-rap-player data-rap-show-track="<?php echo $show_track ? '1' : '0'; ?>"
         role="region" aria-label="<?php esc_attr_e( 'Lecteur Radio', 'radio-audace-player' ); ?>">

        <?php if ( $widget_title ) : ?>
        <div class="rap-player__widget-title"><?php echo esc_html( $widget_title ); ?></div>
        <?php endif; ?>

        <div class="rap-player__info">
            <img class="rap-player__logo" src="<?php echo esc_url( $logo ); ?>"
                 alt="<?php echo esc_attr( $station_name ); ?>" width="48" height="48">
            <div class="rap-player__text">
                <span class="rap-player__name"><?php echo esc_html( $station_name ); ?></span>
                <span class="rap-player__tagline"><?php echo esc_html( $tagline ); ?></span>
            </div>
        </div>

        <div class="rap-player__controls">
            <button class="rap-player__btn rap-player__btn--play" type="button"
                    aria-label="<?php esc_attr_e( 'Lecture / Pause', 'radio-audace-player' ); ?>">
                <?php echo rap_svg_play() . rap_svg_pause() . rap_svg_loading(); ?>
            </button>

            <?php if ( $show_badge ) : ?>
            <div class="rap-player__live-badge">
                <span class="rap-player__live-dot"></span>
                <span><?php echo esc_html( $options['live_badge_text'] ); ?></span>
            </div>
            <?php endif; ?>

            <?php if ( $show_volume ) : ?>
            <?php echo rap_volume_html(); ?>
            <?php endif; ?>
        </div>

        <?php if ( $show_track ) : ?>
        <div class="rap-player__widget-track" data-rap-widget-track></div>
        <?php endif; ?>
    </div>
    <?php
    endif;

    return ob_get_clean();
}
add_shortcode( 'radio_audace_player', 'rap_shortcode' );

/* ═══════════════════════════════════════════════════════════════════
   LECTEUR FLOTTANT — injecte automatiquement via wp_footer
   ═══════════════════════════════════════════════════════════════════ */

function rap_render_floating_player() {
    if ( is_admin() ) {
        return;
    }

    $options = rap_get_options();
    if ( ! $options['floating_enabled'] ) {
        return;
    }

    $skin    = esc_attr( $options['skin'] );
    $type    = esc_attr( $options['floating_type'] );
    $logo    = ! empty( $options['logo_url'] ) ? $options['logo_url'] : RAP_PLUGIN_URL . 'assets/default-logo.svg';
    $name    = esc_html( $options['station_name'] );
    $tagline = esc_html( $options['tagline'] );

    ?>
    <!-- Radio Audace — Lecteur Flottant -->
    <div id="rap-floating-root" class="rap-floating rap-floating--<?php echo $type; ?> rap-skin--<?php echo $skin; ?>"
         data-rap-player data-rap-floating
         role="region" aria-label="<?php esc_attr_e( 'Lecteur Radio Flottant', 'radio-audace-player' ); ?>">

        <?php if ( 'bar-float' === $options['floating_type'] ) : ?>
        <!-- ══ TYPE: BARRE FLOTTANTE (minimisable) ══ -->
        <div class="rap-floating__bar">
            <div class="rap-player__info">
                <img class="rap-player__logo" src="<?php echo esc_url( $logo ); ?>" alt="<?php echo esc_attr( $name ); ?>" width="40" height="40">
                <div class="rap-player__text">
                    <span class="rap-player__name"><?php echo $name; ?></span>
                    <span class="rap-player__tagline"><?php echo $tagline; ?></span>
                </div>
            </div>
            <div class="rap-player__controls">
                <button class="rap-player__btn rap-player__btn--play" type="button" aria-label="<?php esc_attr_e( 'Lecture / Pause', 'radio-audace-player' ); ?>">
                    <?php echo rap_svg_play() . rap_svg_pause() . rap_svg_loading(); ?>
                </button>
                <div class="rap-player__live-badge">
                    <span class="rap-player__live-dot"></span>
                    <span><?php echo esc_html( $options['live_badge_text'] ); ?></span>
                </div>
                <?php echo rap_volume_html(); ?>
            </div>
            <button class="rap-floating__toggle" type="button" data-rap-minimize aria-label="<?php esc_attr_e( 'Minimiser', 'radio-audace-player' ); ?>">
                <?php echo rap_svg_minimize(); ?>
            </button>
        </div>

        <!-- Etat minimise : pastille compacte -->
        <div class="rap-floating__collapsed" data-rap-expand>
            <button class="rap-player__btn rap-player__btn--play rap-floating__collapsed-play" type="button" aria-label="<?php esc_attr_e( 'Lecture / Pause', 'radio-audace-player' ); ?>">
                <?php echo rap_svg_play() . rap_svg_pause() . rap_svg_loading(); ?>
            </button>
            <span class="rap-floating__collapsed-name"><?php echo $name; ?></span>
            <div class="rap-player__live-badge">
                <span class="rap-player__live-dot"></span>
                <span><?php echo esc_html( $options['live_badge_text'] ); ?></span>
            </div>
        </div>

        <?php elseif ( 'bubble' === $options['floating_type'] ) : ?>
        <!-- ══ TYPE: BULLE (bouton circulaire expansible) ══ -->
        <div class="rap-bubble__wrapper">
            <div class="rap-bubble__label" data-rap-bubble-toggle>
                <svg viewBox="0 0 24 24" width="14" height="14" fill="currentColor" style="flex-shrink:0"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02z"/></svg>
                <span><?php echo esc_html( $options['bubble_label_text'] ); ?></span>
            </div>
            <button class="rap-bubble__trigger" type="button" data-rap-bubble-toggle
                    aria-label="<?php esc_attr_e( 'Ouvrir le lecteur radio', 'radio-audace-player' ); ?>">
                <img class="rap-bubble__logo" src="<?php echo esc_url( $logo ); ?>" alt="" width="36" height="36">
                <div class="rap-bubble__rings"></div>
            </button>
        </div>

        <div class="rap-bubble__panel">
            <div class="rap-bubble__header">
                <img class="rap-player__logo" src="<?php echo esc_url( $logo ); ?>" alt="" width="44" height="44">
                <div class="rap-player__text">
                    <span class="rap-player__name"><?php echo $name; ?></span>
                    <span class="rap-player__tagline"><?php echo $tagline; ?></span>
                </div>
                <button class="rap-bubble__close" type="button" data-rap-bubble-toggle aria-label="<?php esc_attr_e( 'Fermer', 'radio-audace-player' ); ?>">
                    <?php echo rap_svg_close(); ?>
                </button>
            </div>
            <div class="rap-bubble__controls">
                <button class="rap-player__btn rap-player__btn--play" type="button" aria-label="<?php esc_attr_e( 'Lecture / Pause', 'radio-audace-player' ); ?>">
                    <?php echo rap_svg_play() . rap_svg_pause() . rap_svg_loading(); ?>
                </button>
                <div class="rap-player__live-badge">
                    <span class="rap-player__live-dot"></span>
                    <span><?php echo esc_html( $options['live_badge_text'] ); ?></span>
                </div>
            </div>
            <?php echo rap_volume_html(); ?>
        </div>

        <?php elseif ( 'mini-bar' === $options['floating_type'] ) : ?>
        <!-- ══ TYPE: MINI BARRE (fine, retractable) ══ -->
        <div class="rap-minibar__content">
            <button class="rap-player__btn rap-player__btn--play" type="button" aria-label="<?php esc_attr_e( 'Lecture / Pause', 'radio-audace-player' ); ?>">
                <?php echo rap_svg_play() . rap_svg_pause() . rap_svg_loading(); ?>
            </button>
            <span class="rap-player__name"><?php echo $name; ?></span>
            <div class="rap-player__live-badge">
                <span class="rap-player__live-dot"></span>
                <span><?php echo esc_html( $options['live_badge_text'] ); ?></span>
            </div>
            <?php echo rap_volume_html(); ?>
            <button class="rap-minibar__close" type="button" data-rap-minimize aria-label="<?php esc_attr_e( 'Fermer', 'radio-audace-player' ); ?>">
                <?php echo rap_svg_close(); ?>
            </button>
        </div>

        <!-- Etat retracte : petite languette -->
        <div class="rap-minibar__tab" data-rap-expand>
            <button class="rap-player__btn rap-player__btn--play rap-minibar__tab-play" type="button" aria-label="<?php esc_attr_e( 'Lecture / Pause', 'radio-audace-player' ); ?>">
                <?php echo rap_svg_play() . rap_svg_pause() . rap_svg_loading(); ?>
            </button>
            <svg class="rap-minibar__tab-expand" viewBox="0 0 24 24" width="16" height="16" fill="currentColor"><path d="M12 8l-6 6 1.41 1.41L12 10.83l4.59 4.58L18 14z"/></svg>
        </div>

        <?php endif; ?>
    </div>
    <?php
}
add_action( 'wp_footer', 'rap_render_floating_player', 99 );

/* ═══════════════════════════════════════════════════════════════════
   WIDGET
   ═══════════════════════════════════════════════════════════════════ */

class RAP_Widget extends WP_Widget {

    public function __construct() {
        parent::__construct(
            'rap_widget',
            __( 'Radio Audace Player', 'radio-audace-player' ),
            array( 'description' => __( 'Lecteur streaming Radio Audace — style carte premium avec piste en cours', 'radio-audace-player' ) )
        );
    }

    public function widget( $args, $instance ) {
        $options = rap_get_options();

        $style           = ! empty( $instance['style'] ) ? $instance['style'] : 'card';
        $skin            = ! empty( $instance['skin'] ) ? $instance['skin'] : '';
        $title           = ! empty( $instance['title'] ) ? $instance['title'] : '';
        $custom_name     = ! empty( $instance['custom_name'] ) ? $instance['custom_name'] : '';
        $custom_tagline  = ! empty( $instance['custom_tagline'] ) ? $instance['custom_tagline'] : '';
        $hide_volume     = ! empty( $instance['hide_volume'] ) ? '1' : '';
        $hide_live_badge = ! empty( $instance['hide_live_badge'] ) ? '1' : '';
        $show_track      = ! empty( $instance['show_track'] ) ? '1' : '';

        // Construire le shortcode dynamiquement
        $sc = '[radio_audace_player style="' . esc_attr( $style ) . '"';
        if ( $skin ) {
            $sc .= ' skin="' . esc_attr( $skin ) . '"';
        }
        if ( $title ) {
            $sc .= ' title="' . esc_attr( $title ) . '"';
        }
        if ( $custom_name ) {
            $sc .= ' custom_name="' . esc_attr( $custom_name ) . '"';
        }
        if ( $custom_tagline ) {
            $sc .= ' custom_tagline="' . esc_attr( $custom_tagline ) . '"';
        }
        if ( $hide_volume ) {
            $sc .= ' hide_volume="1"';
        }
        if ( $hide_live_badge ) {
            $sc .= ' hide_live_badge="1"';
        }
        if ( $show_track ) {
            $sc .= ' show_track="1"';
        }
        $sc .= ']';

        echo $args['before_widget'];
        echo do_shortcode( $sc );
        echo $args['after_widget'];
    }

    public function form( $instance ) {
        $options = rap_get_options();

        $title           = ! empty( $instance['title'] ) ? $instance['title'] : '';
        $style           = ! empty( $instance['style'] ) ? $instance['style'] : 'card';
        $skin            = ! empty( $instance['skin'] ) ? $instance['skin'] : '';
        $custom_name     = ! empty( $instance['custom_name'] ) ? $instance['custom_name'] : '';
        $custom_tagline  = ! empty( $instance['custom_tagline'] ) ? $instance['custom_tagline'] : '';
        $hide_volume     = ! empty( $instance['hide_volume'] );
        $hide_live_badge = ! empty( $instance['hide_live_badge'] );
        $show_track      = ! empty( $instance['show_track'] );

        // CSS pour le selecteur visuel de skin (une seule fois)
        static $styles_rendered = false;
        if ( ! $styles_rendered ) :
            $styles_rendered = true;
        ?>
        <style>
            .rap-widget-skin-cards { display: flex; flex-wrap: wrap; gap: 6px; margin: 6px 0 12px; }
            .rap-widget-skin-card {
                position: relative; display: flex; flex-direction: column; align-items: center;
                border: 2px solid #ddd; border-radius: 8px; padding: 8px 10px;
                cursor: pointer; transition: all 0.2s; background: #fafafa; min-width: 54px;
            }
            .rap-widget-skin-card:hover { border-color: #2ea3f2; }
            .rap-widget-skin-card.is-active { border-color: #2ea3f2; background: #e8f4fd; box-shadow: 0 0 0 1px #2ea3f2; }
            .rap-widget-skin-card input[type="radio"] { position: absolute; opacity: 0; pointer-events: none; }
            .rap-widget-skin-card__preview { width: 32px; height: 18px; border-radius: 4px; margin-bottom: 4px; border: 1px solid rgba(0,0,0,0.08); }
            .rap-widget-skin-card__label { font-size: 10px; font-weight: 600; color: #1d2327; text-align: center; }
            .rap-widget-skin-card .rap-preview-dark   { background: linear-gradient(135deg, #1a1a2e, #16213e); }
            .rap-widget-skin-card .rap-preview-light  { background: #fff; box-shadow: inset 0 0 0 1px #e5e7eb; }
            .rap-widget-skin-card .rap-preview-glass  { background: linear-gradient(135deg, rgba(26,26,46,0.6), rgba(22,33,62,0.6)); }
            .rap-widget-skin-card .rap-preview-brand  { background: linear-gradient(135deg, #2ea3f2, #1a6fc7); }
            .rap-widget-skin-card .rap-preview-neon   { background: #0a0a1a; box-shadow: inset 0 0 4px #2ea3f266, 0 0 0 1px #2ea3f2; }
            .rap-widget-separator { border: 0; border-top: 1px solid #eee; margin: 12px 0; }
        </style>
        <?php endif; ?>

        <!-- Titre -->
        <p>
            <label for="<?php echo esc_attr( $this->get_field_id( 'title' ) ); ?>"><?php esc_html_e( 'Titre du widget :', 'radio-audace-player' ); ?></label>
            <input class="widefat" id="<?php echo esc_attr( $this->get_field_id( 'title' ) ); ?>" name="<?php echo esc_attr( $this->get_field_name( 'title' ) ); ?>" type="text" value="<?php echo esc_attr( $title ); ?>" placeholder="<?php esc_attr_e( 'ex: Ecouter Radio Audace', 'radio-audace-player' ); ?>">
        </p>

        <!-- Style -->
        <p>
            <label for="<?php echo esc_attr( $this->get_field_id( 'style' ) ); ?>"><?php esc_html_e( 'Style :', 'radio-audace-player' ); ?></label>
            <select class="widefat" id="<?php echo esc_attr( $this->get_field_id( 'style' ) ); ?>" name="<?php echo esc_attr( $this->get_field_name( 'style' ) ); ?>">
                <option value="card" <?php selected( $style, 'card' ); ?>><?php esc_html_e( 'Carte Premium (recommande)', 'radio-audace-player' ); ?></option>
                <option value="bar" <?php selected( $style, 'bar' ); ?>><?php esc_html_e( 'Barre', 'radio-audace-player' ); ?></option>
                <option value="mini" <?php selected( $style, 'mini' ); ?>><?php esc_html_e( 'Mini', 'radio-audace-player' ); ?></option>
            </select>
        </p>

        <!-- Skin — selecteur visuel -->
        <p style="margin-bottom:2px;"><strong><?php esc_html_e( 'Skin :', 'radio-audace-player' ); ?></strong></p>
        <div class="rap-widget-skin-cards" data-rap-widget-skin-cards>
            <?php
            $skin_options = array(
                ''      => array( 'Defaut',  'rap-preview-dark' ),
                'dark'  => array( 'Sombre',  'rap-preview-dark' ),
                'light' => array( 'Clair',   'rap-preview-light' ),
                'glass' => array( 'Verre',   'rap-preview-glass' ),
                'brand' => array( 'Audace',  'rap-preview-brand' ),
                'neon'  => array( 'Neon',    'rap-preview-neon' ),
            );
            foreach ( $skin_options as $key => $info ) :
            ?>
            <label class="rap-widget-skin-card <?php echo $skin === $key ? 'is-active' : ''; ?>">
                <input type="radio" name="<?php echo esc_attr( $this->get_field_name( 'skin' ) ); ?>" value="<?php echo esc_attr( $key ); ?>" <?php checked( $skin, $key ); ?>>
                <div class="rap-widget-skin-card__preview <?php echo esc_attr( $info[1] ); ?>"></div>
                <span class="rap-widget-skin-card__label"><?php echo esc_html( $info[0] ); ?></span>
            </label>
            <?php endforeach; ?>
        </div>

        <hr class="rap-widget-separator">

        <!-- Nom personnalise -->
        <p>
            <label for="<?php echo esc_attr( $this->get_field_id( 'custom_name' ) ); ?>"><?php esc_html_e( 'Nom personnalise :', 'radio-audace-player' ); ?></label>
            <input class="widefat" id="<?php echo esc_attr( $this->get_field_id( 'custom_name' ) ); ?>" name="<?php echo esc_attr( $this->get_field_name( 'custom_name' ) ); ?>" type="text" value="<?php echo esc_attr( $custom_name ); ?>" placeholder="<?php echo esc_attr( $options['station_name'] ); ?>">
            <small class="description"><?php esc_html_e( 'Laissez vide pour utiliser le nom global.', 'radio-audace-player' ); ?></small>
        </p>

        <!-- Slogan personnalise -->
        <p>
            <label for="<?php echo esc_attr( $this->get_field_id( 'custom_tagline' ) ); ?>"><?php esc_html_e( 'Slogan personnalise :', 'radio-audace-player' ); ?></label>
            <input class="widefat" id="<?php echo esc_attr( $this->get_field_id( 'custom_tagline' ) ); ?>" name="<?php echo esc_attr( $this->get_field_name( 'custom_tagline' ) ); ?>" type="text" value="<?php echo esc_attr( $custom_tagline ); ?>" placeholder="<?php echo esc_attr( $options['tagline'] ); ?>">
            <small class="description"><?php esc_html_e( 'Laissez vide pour utiliser le slogan global.', 'radio-audace-player' ); ?></small>
        </p>

        <hr class="rap-widget-separator">

        <!-- Options d'affichage -->
        <p><strong><?php esc_html_e( 'Options d\'affichage', 'radio-audace-player' ); ?></strong></p>
        <p>
            <label>
                <input type="checkbox" name="<?php echo esc_attr( $this->get_field_name( 'hide_volume' ) ); ?>" value="1" <?php checked( $hide_volume ); ?>>
                <?php esc_html_e( 'Masquer le volume', 'radio-audace-player' ); ?>
            </label>
        </p>
        <p>
            <label>
                <input type="checkbox" name="<?php echo esc_attr( $this->get_field_name( 'hide_live_badge' ) ); ?>" value="1" <?php checked( $hide_live_badge ); ?>>
                <?php esc_html_e( 'Masquer le badge EN DIRECT', 'radio-audace-player' ); ?>
            </label>
        </p>
        <p>
            <label>
                <input type="checkbox" name="<?php echo esc_attr( $this->get_field_name( 'show_track' ) ); ?>" value="1" <?php checked( $show_track ); ?>>
                <?php esc_html_e( 'Afficher la piste en cours (RadioDJ)', 'radio-audace-player' ); ?>
            </label>
        </p>

        <script>
        jQuery(document).on('change', '[data-rap-widget-skin-cards] input[type="radio"]', function() {
            jQuery(this).closest('.rap-widget-skin-cards').find('.rap-widget-skin-card').removeClass('is-active');
            jQuery(this).closest('.rap-widget-skin-card').addClass('is-active');
        });
        </script>
        <?php
    }

    public function update( $new_instance, $old_instance ) {
        $instance                    = array();
        $instance['title']           = sanitize_text_field( $new_instance['title'] ?? '' );
        $instance['style']           = sanitize_text_field( $new_instance['style'] ?? 'card' );
        $instance['skin']            = sanitize_text_field( $new_instance['skin'] ?? '' );
        $instance['custom_name']     = sanitize_text_field( $new_instance['custom_name'] ?? '' );
        $instance['custom_tagline']  = sanitize_text_field( $new_instance['custom_tagline'] ?? '' );
        $instance['hide_volume']     = ! empty( $new_instance['hide_volume'] );
        $instance['hide_live_badge'] = ! empty( $new_instance['hide_live_badge'] );
        $instance['show_track']      = ! empty( $new_instance['show_track'] );
        return $instance;
    }
}

function rap_register_widget() {
    register_widget( 'RAP_Widget' );
}
add_action( 'widgets_init', 'rap_register_widget' );

/* ═══════════════════════════════════════════════════════════════════
   ADMIN
   ═══════════════════════════════════════════════════════════════════ */

require_once RAP_PLUGIN_DIR . 'admin/settings.php';
require_once RAP_PLUGIN_DIR . 'admin/updater.php';
