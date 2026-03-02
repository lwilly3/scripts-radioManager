<?php
/**
 * Plugin Name: Radio Audace Player
 * Plugin URI:  https://www.radioaudace.com
 * Description: Lecteur audio streaming personnalise pour Radio Audace 106.8 FM. Shortcode, widget, lecteur flottant avec skins multiples et lecture persistante entre les pages. Compatible Divi/Extra.
 * Version:     3.1.0
 * Author:      Radio Audace
 * Author URI:  https://www.radioaudace.com
 * License:     GPL-2.0+
 * Text Domain: radio-audace-player
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

define( 'RAP_VERSION', '3.1.0' );
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

        // Style pour shortcode inline : bar | mini
        'player_style'        => 'bar',

        // Lecteur flottant
        'floating_enabled'    => true,
        'floating_type'       => 'bar-float',  // bar-float | bubble | mini-bar
        'floating_position'   => 'bottom-center', // bottom-center | bottom-left | bottom-right

        // Navigation persistante (Pjax)
        'persistent_playback' => true,
        'content_selector'    => '',  // vide = auto-detection Divi/Extra

        'show_volume'         => true,
        'auto_play'           => false,

        // Integration API RadioManager (v3)
        'api_url'                => 'https://api.radio.audace.ovh',
        'api_polling_interval'   => 60,
        'show_now_playing'       => true,
        'show_alert_banner'      => true,
        'analytics_enabled'      => true,
        'wp_sync_secret'         => '',
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
        'siteUrl'            => home_url(),
        // Integration API v3
        'ajaxUrl'            => admin_url( 'admin-ajax.php' ),
        'pollingInterval'    => intval( $options['api_polling_interval'] ) * 1000,
        'showNowPlaying'     => (bool) $options['show_now_playing'],
        'showAlertBanner'    => (bool) $options['show_alert_banner'],
        'analyticsEnabled'   => (bool) $options['analytics_enabled'],
        'nonce'              => wp_create_nonce( 'rap_nonce' ),
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
    wp_send_json( $data );
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
    wp_send_json( $data );
}
add_action( 'wp_ajax_rap_schedule', 'rap_ajax_schedule' );
add_action( 'wp_ajax_nopriv_rap_schedule', 'rap_ajax_schedule' );

function rap_ajax_alert() {
    check_ajax_referer( 'rap_nonce', 'nonce' );
    $data = rap_api_request( '/public/alert' );
    if ( null === $data ) {
        wp_send_json_error( 'API injoignable' );
    }
    wp_send_json( $data );
}
add_action( 'wp_ajax_rap_alert', 'rap_ajax_alert' );
add_action( 'wp_ajax_nopriv_rap_alert', 'rap_ajax_alert' );

function rap_ajax_presenters() {
    check_ajax_referer( 'rap_nonce', 'nonce' );
    $data = rap_api_request( '/public/presenters' );
    if ( null === $data ) {
        wp_send_json_error( 'API injoignable' );
    }
    wp_send_json( $data );
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
    wp_send_json( json_decode( wp_remote_retrieve_body( $response ), true ) );
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
   Pour les players inline (bar, mini) — places dans le contenu.
   ═══════════════════════════════════════════════════════════════════ */

function rap_shortcode( $atts ) {
    $atts = shortcode_atts( array(
        'style' => '',      // bar | mini
        'skin'  => '',      // dark | light | glass | brand | neon
    ), $atts, 'radio_audace_player' );

    $options = rap_get_options();
    $style   = ! empty( $atts['style'] ) ? $atts['style'] : $options['player_style'];
    $skin    = ! empty( $atts['skin'] ) ? $atts['skin'] : $options['skin'];
    $logo    = ! empty( $options['logo_url'] ) ? $options['logo_url'] : RAP_PLUGIN_URL . 'assets/default-logo.svg';

    ob_start();
    ?>
    <div class="rap-player rap-player--<?php echo esc_attr( $style ); ?> rap-skin--<?php echo esc_attr( $skin ); ?>"
         data-rap-player role="region"
         aria-label="<?php esc_attr_e( 'Lecteur Radio', 'radio-audace-player' ); ?>">

        <div class="rap-player__info">
            <img class="rap-player__logo" src="<?php echo esc_url( $logo ); ?>"
                 alt="<?php echo esc_attr( $options['station_name'] ); ?>" width="48" height="48">
            <div class="rap-player__text">
                <span class="rap-player__name"><?php echo esc_html( $options['station_name'] ); ?></span>
                <span class="rap-player__tagline"><?php echo esc_html( $options['tagline'] ); ?></span>
            </div>
        </div>

        <div class="rap-player__controls">
            <button class="rap-player__btn rap-player__btn--play" type="button"
                    aria-label="<?php esc_attr_e( 'Lecture / Pause', 'radio-audace-player' ); ?>">
                <?php echo rap_svg_play() . rap_svg_pause() . rap_svg_loading(); ?>
            </button>

            <div class="rap-player__live-badge">
                <span class="rap-player__live-dot"></span>
                <span>EN DIRECT</span>
            </div>

            <?php echo rap_volume_html(); ?>
        </div>
    </div>
    <?php
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
                    <span>EN DIRECT</span>
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
                <span>EN DIRECT</span>
            </div>
        </div>

        <?php elseif ( 'bubble' === $options['floating_type'] ) : ?>
        <!-- ══ TYPE: BULLE (bouton circulaire expansible) ══ -->
        <div class="rap-bubble__wrapper">
            <div class="rap-bubble__label" data-rap-bubble-toggle>
                <svg viewBox="0 0 24 24" width="14" height="14" fill="currentColor" style="flex-shrink:0"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02z"/></svg>
                <span><?php esc_html_e( 'Ecouter en direct', 'radio-audace-player' ); ?></span>
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
                    <span>EN DIRECT</span>
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
                <span>EN DIRECT</span>
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
            array( 'description' => __( 'Lecteur streaming Radio Audace', 'radio-audace-player' ) )
        );
    }

    public function widget( $args, $instance ) {
        $style = ! empty( $instance['style'] ) ? $instance['style'] : 'mini';
        $skin  = ! empty( $instance['skin'] ) ? $instance['skin'] : '';
        $sc    = '[radio_audace_player style="' . esc_attr( $style ) . '"';
        if ( $skin ) {
            $sc .= ' skin="' . esc_attr( $skin ) . '"';
        }
        $sc .= ']';
        echo $args['before_widget'];
        echo do_shortcode( $sc );
        echo $args['after_widget'];
    }

    public function form( $instance ) {
        $style = ! empty( $instance['style'] ) ? $instance['style'] : 'mini';
        $skin  = ! empty( $instance['skin'] ) ? $instance['skin'] : '';
        ?>
        <p>
            <label for="<?php echo esc_attr( $this->get_field_id( 'style' ) ); ?>"><?php esc_html_e( 'Style :', 'radio-audace-player' ); ?></label>
            <select class="widefat" id="<?php echo esc_attr( $this->get_field_id( 'style' ) ); ?>" name="<?php echo esc_attr( $this->get_field_name( 'style' ) ); ?>">
                <option value="bar" <?php selected( $style, 'bar' ); ?>>Barre</option>
                <option value="mini" <?php selected( $style, 'mini' ); ?>>Mini</option>
            </select>
        </p>
        <p>
            <label for="<?php echo esc_attr( $this->get_field_id( 'skin' ) ); ?>"><?php esc_html_e( 'Skin :', 'radio-audace-player' ); ?></label>
            <select class="widefat" id="<?php echo esc_attr( $this->get_field_id( 'skin' ) ); ?>" name="<?php echo esc_attr( $this->get_field_name( 'skin' ) ); ?>">
                <option value="" <?php selected( $skin, '' ); ?>>Par defaut (reglages)</option>
                <option value="dark" <?php selected( $skin, 'dark' ); ?>>Sombre</option>
                <option value="light" <?php selected( $skin, 'light' ); ?>>Clair</option>
                <option value="glass" <?php selected( $skin, 'glass' ); ?>>Verre depoli</option>
                <option value="brand" <?php selected( $skin, 'brand' ); ?>>Couleur Audace</option>
                <option value="neon" <?php selected( $skin, 'neon' ); ?>>Neon</option>
            </select>
        </p>
        <?php
    }

    public function update( $new_instance, $old_instance ) {
        $instance          = array();
        $instance['style'] = sanitize_text_field( $new_instance['style'] );
        $instance['skin']  = sanitize_text_field( $new_instance['skin'] );
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
