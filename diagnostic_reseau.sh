#! /bin/bash

# Script de diagnostic réseau complet avec menu interactif
# compatible linux et WSL 
# Auteur : AMMOUR Nadjib 


#--------------couleurs----------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # Pas de couleur 

#---------------Affichage du menu----------------#
print_section(){
echo
echo -e "${BLUE}==========================================${NC}"
echo -e "${BOLD}$1${NC}"
echo -e "${BLUE}==========================================${NC}"
}

#Messages d'information, succès, erreur et avertissement
print_success(){
    echo -e "${GREEN} $1${NC}"
}
print_error(){
    echo -e "${RED} $1${NC}"
}
print_warning(){
    echo -e "${YELLOW} $1${NC}"
}

#-------detection de WSL----------------#
is_wsl(){
  grep -qi Microsoft /proc/version 2>/dev/null 
}

#----informations système----------------#
show_system_info(){
    print_section "INFORMATIONS SYSTEME"

    #Nom de l'hôte
    echo "Nom de l'hôte : $(hostname)"

    #Date et heure
    echo "Date et heure : $(date)"

    #Informations détaillées sur le systeme
    echo "Version système : $(uname -a)"

    if is_wsl ; then
        print_success "On est bien sur WSL"
    else
        print_error "On n'est pas sur WSL"
    fi
}

#----configuration réseau----------------#
show_ip_config(){
    print_section "CONFIGURATION RESEAU"

    #Récupération de l'adresse IP locale
    IP=$(hostname -I | awk '{print $1}')

    #Récupération de la passerelle par défaut
    GW=$(ip route | grep default | awk '{print $3}')

    #Récupération du serveur DNS
    DNS=$(grep "nameserver" /etc/resolv.conf | awk '{print $2}')

    #Vérification si adresse IP trouvée 
    [ -n "$IP" ] && print_success "Adresse IP locale : $IP" || print_error "IP non trouvée"

    #Vérification si passerelle trouvée 
    [ -n "$GW" ] && print_success "Passerelle par défaut : $GW" || print_error "Passerelle non trouvée"

    #Affichage du DNS 
    echo "Serveurs DNS configurés : $DNS"
    
}

#-------test de connectivité----------------#

test_ping(){
    
    cible=$1
    description=$2

    if ping -c 2 -W 2 $cible > /dev/null 2>&1; then
        print_success "$description OK ($cible)"
    else
        print_error "$description échoué ($cible)"
    fi

}

#------Tous les tests de connectivité----------------#
test_connectivity(){
    print_section "TEST DE CONNECTIVITE"

    #récuperation de la passerelle par défaut
    GW=$(ip route | grep default | awk '{print $3}')

    #Test localhost
    test_ping 127.0.0.1 "Ping localhost"

    if [ -n "$GW" ]; then
        test_ping "$GW" "Ping passerelle par défaut"
    else
        print_error "Passerelle inconnue"
    fi

    #Test acces à internet
    test_ping 8.8.8.8 "Ping serveur DNS de Google"

    #Test résolution de DNS
    test_ping google.com "Ping google.com (résolution DNS)"
}

resolve_dns(){
    local domaine=$1

    echo
    echo -e "${CYAN}Résolution de $domaine...${NC}"

    if command -v dig > /dev/null 2>&1; then
        dig +short "$domaine"
    elif command -v nslookup > /dev/null 2>&1; then
        nslookup "$domaine" | awk '/^Address: / { print $2 }'
    else
        print_error "dig ou nslookup non trouvé"
    fi
}

dns_tests()
{
    print_section "TESTS DE RESOLUTION DNS"

    #Test de résolution de google.com
    resolve_dns google.com

    #Test de résolution de github.com
    resolve_dns github.com
}   

#-------------Menu principal----------------#
menu(){

    while true; do
        print_section "MENU PRINCIPAL"
        echo "1) Afficher les informations système"
        echo "2) Afficher la configuration réseau"
        echo "3) Effectuer des tests de connectivité"
        echo "4) Effectuer des tests de résolution DNS"
        echo "5) Diagnostic complet"
        echo "6) Quitter"
        echo 

        read -p "Choix : " choix

        case $choix in
            1) show_system_info ;;
            2) show_ip_config ;;
            3) test_connectivity ;;
            4) dns_tests ;;
            5) 
                show_system_info
                show_ip_config
                test_connectivity
                dns_tests
                ;;
            6) print_success "Au revoir!" 
                exit 0 ;;
            *) print_warning "Choix invalide" 
            ;;
        esac

        
    done
}

menu

