#!/bin/bash

# =============================================================================
#
#  ACCES TEMPORAIRE PGADMIN — PostgreSQL via pgAdmin 4
#
#  Ce script ouvre/ferme l'acces distant a PostgreSQL (port 5432)
#  pour une adresse IP specifique. Il agit sur UFW + DOCKER-USER (iptables).
#
#  Usage :
#    sudo bash pgadmin-access.sh enable         # Ouvre l'acces pour ton IP SSH
#    sudo bash pgadmin-access.sh enable 1.2.3.4 # Ouvre pour une IP specifique
#    sudo bash pgadmin-access.sh disable         # Ferme tous les acces pgAdmin
#    sudo bash pgadmin-access.sh status          # Affiche l'etat actuel
#
#  Connexion pgAdmin 4 :
#    Host     : IP publique du VPS
#    Port     : 5432
#    Database : audace_db
#    Username : audace_user
#    Password : (celui configure dans docker-compose)
#
# =============================================================================

set -e

PORT=5432
COMMENT="pgAdmin-temp"

# --- Couleurs ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Verification root ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Ce script doit etre execute avec sudo${NC}"
    echo "  sudo bash $0 $*"
    exit 1
fi

# --- Detection automatique de l'IP ---
detect_ip() {
    # Methode 1 : variable SSH_CLIENT (contient l'IP du client SSH connecte)
    if [ -n "$SSH_CLIENT" ]; then
        echo "$SSH_CLIENT" | awk '{print $1}'
        return
    fi

    # Methode 2 : variable SSH_CONNECTION
    if [ -n "$SSH_CONNECTION" ]; then
        echo "$SSH_CONNECTION" | awk '{print $1}'
        return
    fi

    # Methode 3 : commande who (derniere connexion SSH)
    local ip
    ip=$(who -m 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)
    if [ -n "$ip" ]; then
        echo "$ip"
        return
    fi

    # Methode 4 : derniere connexion SSH dans les logs
    ip=$(last -i -1 2>/dev/null | head -1 | awk '{print $3}' | grep -oP '\d+\.\d+\.\d+\.\d+')
    if [ -n "$ip" ]; then
        echo "$ip"
        return
    fi

    echo ""
}

# --- Fonctions ---

enable_access() {
    local ip="$1"

    if [ -z "$ip" ]; then
        ip=$(detect_ip)
    fi

    if [ -z "$ip" ]; then
        echo -e "${RED}Impossible de detecter ton IP automatiquement.${NC}"
        echo ""
        echo "Utilise une de ces methodes pour trouver ton IP :"
        echo "  - Depuis ton PC : ouvre https://ifconfig.me dans un navigateur"
        echo "  - Ou execute    : curl -s ifconfig.me"
        echo ""
        echo "Puis relance avec :"
        echo "  sudo bash $0 enable TON_IP"
        exit 1
    fi

    echo -e "${YELLOW}=== Ouverture acces PostgreSQL ===${NC}"
    echo -e "IP autorisee : ${GREEN}$ip${NC}"
    echo ""

    # 1. UFW
    ufw allow from "$ip" to any port $PORT proto tcp comment "$COMMENT" 2>/dev/null
    echo -e "${GREEN}[OK]${NC} UFW : port $PORT ouvert pour $ip"

    # 2. DOCKER-USER (iptables)
    # Verifier si la regle existe deja
    if iptables -C DOCKER-USER -p tcp --dport $PORT -s "$ip" -j RETURN 2>/dev/null; then
        echo -e "${GREEN}[OK]${NC} DOCKER-USER : regle deja presente"
    else
        iptables -I DOCKER-USER 1 -p tcp --dport $PORT -s "$ip" -j RETURN
        echo -e "${GREEN}[OK]${NC} DOCKER-USER : regle ajoutee"
    fi

    echo ""
    echo -e "${GREEN}Acces pgAdmin active !${NC}"
    echo ""
    echo "Connexion pgAdmin 4 :"
    echo "  Host     : $(hostname -I | awk '{print $1}') (ou IP publique du VPS)"
    echo "  Port     : $PORT"
    echo "  Database : audace_db"
    echo "  Username : audace_user"
    echo ""
    echo -e "${YELLOW}N'oublie pas de fermer apres la maintenance :${NC}"
    echo "  sudo bash $0 disable"
}

disable_access() {
    echo -e "${YELLOW}=== Fermeture acces PostgreSQL ===${NC}"
    echo ""

    # 1. UFW — supprimer toutes les regles pgAdmin-temp
    local count=0
    while ufw status numbered | grep -q "$COMMENT"; do
        local rule_num
        rule_num=$(ufw status numbered | grep "$COMMENT" | head -1 | grep -oP '^\[\s*\K\d+')
        if [ -n "$rule_num" ]; then
            echo "y" | ufw delete "$rule_num" > /dev/null 2>&1
            count=$((count + 1))
        else
            break
        fi
    done
    echo -e "${GREEN}[OK]${NC} UFW : $count regle(s) pgAdmin supprimee(s)"

    # 2. DOCKER-USER — supprimer les regles port 5432
    local iptables_count=0
    while iptables -L DOCKER-USER -n --line-numbers 2>/dev/null | grep -q "dpt:$PORT"; do
        local line_num
        line_num=$(iptables -L DOCKER-USER -n --line-numbers | grep "dpt:$PORT" | head -1 | awk '{print $1}')
        if [ -n "$line_num" ]; then
            iptables -D DOCKER-USER "$line_num"
            iptables_count=$((iptables_count + 1))
        else
            break
        fi
    done
    echo -e "${GREEN}[OK]${NC} DOCKER-USER : $iptables_count regle(s) supprimee(s)"

    echo ""
    echo -e "${GREEN}Acces pgAdmin desactive. Port $PORT ferme.${NC}"
}

show_status() {
    echo -e "${YELLOW}=== Statut acces PostgreSQL (port $PORT) ===${NC}"
    echo ""

    # UFW
    echo "--- UFW ---"
    local ufw_rules
    ufw_rules=$(ufw status | grep "$PORT" || true)
    if [ -n "$ufw_rules" ]; then
        echo -e "${RED}OUVERT${NC} — Regles trouvees :"
        echo "$ufw_rules" | sed 's/^/  /'
    else
        echo -e "${GREEN}FERME${NC} — Aucune regle UFW sur le port $PORT"
    fi

    echo ""

    # DOCKER-USER
    echo "--- DOCKER-USER (iptables) ---"
    local docker_rules
    docker_rules=$(iptables -L DOCKER-USER -n 2>/dev/null | grep "dpt:$PORT" || true)
    if [ -n "$docker_rules" ]; then
        echo -e "${RED}OUVERT${NC} — Regles trouvees :"
        echo "$docker_rules" | sed 's/^/  /'
    else
        echo -e "${GREEN}FERME${NC} — Aucune regle DOCKER-USER sur le port $PORT"
    fi

    echo ""

    # Resume
    if [ -n "$ufw_rules" ] || [ -n "$docker_rules" ]; then
        echo -e "Resultat : ${RED}PostgreSQL est accessible depuis l'exterieur${NC}"
        echo ""
        echo "Pour fermer : sudo bash $0 disable"
    else
        echo -e "Resultat : ${GREEN}PostgreSQL est protege (acces interne uniquement)${NC}"
    fi
}

# --- Point d'entree ---

case "${1:-}" in
    enable)
        enable_access "${2:-}"
        ;;
    disable)
        disable_access
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage : sudo bash $0 {enable|disable|status} [IP]"
        echo ""
        echo "  enable          Ouvre le port 5432 pour ton IP (detectee automatiquement)"
        echo "  enable 1.2.3.4  Ouvre le port 5432 pour l'IP specifiee"
        echo "  disable         Ferme tous les acces pgAdmin"
        echo "  status          Affiche l'etat actuel"
        exit 1
        ;;
esac
