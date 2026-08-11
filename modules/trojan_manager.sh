#!/bin/bash
DOMAIN_CONF="/opt/vpn_platform/domain.conf"

load_domain() {
    if [ -f "$DOMAIN_CONF" ]; then source "$DOMAIN_CONF"; fi
}
get_server_ip() { hostname -I | awk '{print $1}'; }

while true; do
    load_domain
    clear
    echo -e "\e[32m=================================================\e[0m"
    echo -e "                 TROJAN MANAGER                  "
    echo -e "\e[32m=================================================\e[0m"
    echo -e "  [1] Create Trojan Trial Account (24 Hours)"
    echo -e "  [2] Create Trojan Permanent Account"
    echo -e "  [3] Renew Trojan Account"
    echo -e "  [4] Delete Trojan Account"
    echo -e "  [0] Back to Main Menu"
    echo -e "\e[32m=================================================\e[0m"
    read -p "Select option [0-4]: " trojan_sub

    server_ip=$(get_server_ip)
    dom="${SERVER_DOMAIN:-$server_ip}"
    password="tr-$(date +%s%N | cut -c10-15)"

    case $trojan_sub in
        1)
            clear
            username="TRIAL-$(date +%s%N | cut -c11-14)"
            exp_date="24 Hours (Trial)"
            trojan_tls="trojan://$password@$dom:443?security=tls&sni=$dom&type=ws&path=%2Ftrojan#$username"
            trojan_upgrade="trojan://$password@$dom:443?security=tls&sni=$dom&type=httpupgrade&path=%2Ftrojan-upgrade#$username"
            clear
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "             TRIAL ACCOUNT CREATED                "
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e " Remarks     : \e[32m$username\e[0m"
            echo -e " Domain      : \e[33m$dom\e[0m"
            echo -e " User ID     : \e[33m$password\e[0m"
            echo -e " Expired On  : \e[31m$exp_date\e[0m"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e " \e[36mLINK TLS :\e[0m\n$trojan_tls"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e " \e[36mLINK HTTP-UPGRADE (CloudFront Bypass) :\e[0m\n$trojan_upgrade"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            read -n 1 -s -r -p "Press any key to back on menu"
            ;;
        2)
            clear
            read -p "Enter username: " username
            read -p "Enter custom password: " password
            read -p "Enter active duration in days: " days
            exp_date=$(date -d "+$days days" +"%Y-%m-%d")
            trojan_tls="trojan://$password@$dom:443?security=tls&sni=$dom&type=ws&path=%2Ftrojan#$username"
            trojan_upgrade="trojan://$password@$dom:443?security=tls&sni=$dom&type=httpupgrade&path=%2Ftrojan-upgrade#$username"
            clear
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "           PERMANENT ACCOUNT CREATED              "
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e " Remarks     : \e[32m$username\e[0m"
            echo -e " Domain      : \e[33m$dom\e[0m"
            echo -e " User ID     : \e[33m$password\e[0m"
            echo -e " Expired On  : \e[31m$exp_date\e[0m"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e " \e[36mLINK TLS :\e[0m\n$trojan_tls"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e " \e[36mLINK HTTP-UPGRADE (CloudFront Bypass) :\e[0m\n$trojan_upgrade"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            read -n 1 -s -r -p "Press any key to back on menu"
            ;;
        0) break ;;
    esac
done
