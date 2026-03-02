<?php
/**
 * RAP_GitHub_Updater — Mise a jour automatique depuis GitHub Releases.
 *
 * Verifie les releases du repo GitHub et integre le systeme de mise
 * a jour natif de WordPress (tableau de bord > Mises a jour).
 *
 * @package Radio_Audace_Player
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

class RAP_GitHub_Updater {

    /**
     * Fichier principal du plugin (chemin complet).
     *
     * @var string
     */
    private $plugin_file;

    /**
     * Slug du plugin au format WordPress (dossier/fichier.php).
     *
     * @var string
     */
    private $plugin_slug;

    /**
     * Proprietaire/nom du repo GitHub.
     *
     * @var string
     */
    private $github_repo = 'lwilly3/scripts-radioManager';

    /**
     * Cle du transient de cache.
     *
     * @var string
     */
    private $cache_key = 'rap_github_release';

    /**
     * Duree du cache en secondes (12 heures).
     *
     * @var int
     */
    private $cache_ttl = 43200;

    /**
     * @param string $plugin_file Chemin absolu vers le fichier principal du plugin.
     */
    public function __construct( $plugin_file ) {
        $this->plugin_file = $plugin_file;
        $this->plugin_slug = plugin_basename( $plugin_file );

        add_filter( 'pre_set_site_transient_update_plugins', array( $this, 'check_update' ) );
        add_filter( 'plugins_api', array( $this, 'plugin_info' ), 20, 3 );
        add_action( 'upgrader_process_complete', array( $this, 'after_update' ), 10, 2 );
    }

    /**
     * Recupere les informations de la derniere release GitHub.
     * Utilise un cache transient pour limiter les appels API.
     *
     * @return array|null Donnees de la release ou null en cas d'erreur.
     */
    private function get_latest_release() {
        $cached = get_transient( $this->cache_key );
        if ( false !== $cached ) {
            return $cached;
        }

        $url      = 'https://api.github.com/repos/' . $this->github_repo . '/releases/latest';
        $response = wp_remote_get( $url, array(
            'timeout' => 10,
            'headers' => array(
                'Accept'     => 'application/vnd.github.v3+json',
                'User-Agent' => 'WordPress/' . get_bloginfo( 'version' ) . '; ' . home_url(),
            ),
        ) );

        if ( is_wp_error( $response ) || 200 !== wp_remote_retrieve_response_code( $response ) ) {
            return null;
        }

        $body = json_decode( wp_remote_retrieve_body( $response ), true );
        if ( empty( $body['tag_name'] ) ) {
            return null;
        }

        set_transient( $this->cache_key, $body, $this->cache_ttl );

        return $body;
    }

    /**
     * Extrait le numero de version depuis le tag (supprime le prefixe 'v').
     *
     * @param string $tag Ex: 'v3.1.0'.
     * @return string Ex: '3.1.0'.
     */
    private function parse_version( $tag ) {
        return ltrim( $tag, 'vV' );
    }

    /**
     * Trouve l'URL du ZIP a telecharger dans la release.
     * Priorite : asset nomme 'radio-audace-player.zip', sinon zipball_url.
     *
     * @param array $release Donnees de la release GitHub.
     * @return string URL du ZIP.
     */
    private function get_download_url( $release ) {
        if ( ! empty( $release['assets'] ) ) {
            foreach ( $release['assets'] as $asset ) {
                if ( 'radio-audace-player.zip' === $asset['name'] ) {
                    return $asset['browser_download_url'];
                }
            }
        }
        return $release['zipball_url'] ?? '';
    }

    /**
     * Hook WordPress : injecte la mise a jour disponible dans le transient.
     *
     * @param object $transient Transient des mises a jour plugins.
     * @return object Transient modifie.
     */
    public function check_update( $transient ) {
        if ( empty( $transient->checked ) ) {
            return $transient;
        }

        $release = $this->get_latest_release();
        if ( ! $release ) {
            return $transient;
        }

        $remote_version = $this->parse_version( $release['tag_name'] );

        if ( version_compare( $remote_version, RAP_VERSION, '>' ) ) {
            $download_url = $this->get_download_url( $release );
            if ( $download_url ) {
                $transient->response[ $this->plugin_slug ] = (object) array(
                    'slug'        => 'radio-audace-player',
                    'plugin'      => $this->plugin_slug,
                    'new_version' => $remote_version,
                    'url'         => $release['html_url'],
                    'package'     => $download_url,
                    'icons'       => array(),
                    'banners'     => array(),
                    'tested'      => '',
                    'requires'    => '5.0',
                    'requires_php'=> '7.4',
                );
            }
        }

        return $transient;
    }

    /**
     * Hook WordPress : fournit les details du plugin (fenetre modale).
     *
     * @param false|object $result Resultat existant.
     * @param string       $action Action demandee.
     * @param object       $args   Arguments de la requete.
     * @return false|object Infos du plugin ou resultat original.
     */
    public function plugin_info( $result, $action, $args ) {
        if ( 'plugin_information' !== $action ) {
            return $result;
        }
        if ( ! isset( $args->slug ) || 'radio-audace-player' !== $args->slug ) {
            return $result;
        }

        $release = $this->get_latest_release();
        if ( ! $release ) {
            return $result;
        }

        $remote_version = $this->parse_version( $release['tag_name'] );

        $info                = new stdClass();
        $info->name          = 'Radio Audace Player';
        $info->slug          = 'radio-audace-player';
        $info->version       = $remote_version;
        $info->author        = '<a href="https://www.radioaudace.com">Radio Audace</a>';
        $info->homepage      = 'https://www.radioaudace.com';
        $info->requires      = '5.0';
        $info->requires_php  = '7.4';
        $info->tested        = get_bloginfo( 'version' );
        $info->download_link = $this->get_download_url( $release );
        $info->trunk         = $this->get_download_url( $release );
        $info->last_updated  = $release['published_at'] ?? '';

        $info->sections = array(
            'description' => 'Lecteur audio streaming personnalise pour Radio Audace 106.8 FM. Shortcode, widget, lecteur flottant avec skins multiples et lecture persistante entre les pages.',
            'changelog'   => nl2br( esc_html( $release['body'] ?? 'Aucune note de version.' ) ),
        );

        return $info;
    }

    /**
     * Hook WordPress : nettoie le cache apres une mise a jour.
     *
     * @param object $upgrader Instance de l'upgrader.
     * @param array  $options  Options de la mise a jour.
     */
    public function after_update( $upgrader, $options ) {
        if (
            'update' === ( $options['action'] ?? '' ) &&
            'plugin' === ( $options['type'] ?? '' )
        ) {
            $plugins = $options['plugins'] ?? array();
            if ( in_array( $this->plugin_slug, $plugins, true ) ) {
                delete_transient( $this->cache_key );
            }
        }
    }
}

/* Initialiser l'updater */
new RAP_GitHub_Updater( RAP_PLUGIN_DIR . 'radio-audace-player.php' );
