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
    echo -e "                 VMESS MANAGER                   "
    echo -e "\e[32m=================================================\e[0m"
    echo -e "  [1] Create VMess Trial Account (24 Hours)"
    echo -e "  [2] Create VMess Permanent Account"
    echo -e "  [3] Renew VMess Account"
    echo -e "  [4] Delete VMess Account"
    echo -e "  [0] Back to Main Menu"
    echo -e "\e[32m=================================================\e[0m"
    read -p "Select option [0-4]: " sub_opt

    server_ip=$(get_server_ip)
    dom="${SERVER_DOMAIN:-$server_ip}"
    uuid=$(cat /proc/sys/kernel/random/uuid)

    case $sub_opt in
        1)
            clear
            username="TRIAL-$(date +%s%N | cut -c11-14)"
            exp_date="24 Hours (Trial)"
            vmess_tls="vmess://$(echo -e '{"v":"2","ps":"'"$username"'","add":"'"$dom"'","port":"443","id":"'"$uuid"'","aid":"0","net":"ws","type":"none","host":"'"$dom"'","path":"/vmess","tls":"tls"}' | base64 -w 0)"
            vmess_upgrade="vmess://$(echo -e '{"v":"2","ps":"'"$username"'","add":"'"$dom"'","port":"443","id":"'"$uuid"'","aid":"0","net":"httpupgrade","type":"none","host":"'"$dom"'","path":"/vmess-upgrade","tls":"tls"}' | base64 -w 0)"
            vmess_ntls="vmess://$(echo -e '{"v":"2","ps":"'"$username"'","add":"'"$dom"'","port":"80","id":"'"$uuid"'","aid":"0","net":"ws","type":"none","host":"'"$dom"'","path":"/vmess","tls":""}' | base64 -w 0)"
            clear
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "             TRIAL ACCOUNT CREATED                "
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e " Remarks     : \e[32m$username\e[0m"
            echo -e " Domain      : \e[33m$dom\e[0m"
            echo -e " User ID     : \e[33m$uuid\e[0m"
            echo -e " Expired On  : \e[31m$exp_date\e[0m"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e " \e[36mLINK TLS :\e[0m\n$vmess_tls"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e " \e[36mLINK HTTP-UPGRADE (CloudFront Bypass) :\e[0m\n$vmess_upgrade"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e " \e[36mLINK NO-TLS :\e[0m\n$vmess_ntls"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            read -n 1 -s -r -p "Press any key to back on menu"
            ;;
        2)
            clear
            read -p "Enter username: " username
            read -p "Enter active duration in days: " days
            exp_date=$(date -d "+$days days" +"%Y-%m-%d")
            vmess_tls="vmess://$(echo -e '{"v":"2","ps":"'"$username"'","add":"'"$dom"'","port":"443","id":"'"$uuid"'","aid":"0","net":"ws","type":"none","host":"'"$dom"'","path":"/vmess","tls":"tls"}' | base64 -w 0)"
            vmess_upgrade="vmess://$(echo -e '{"v":"2","ps":"'"$username"'","add":"'"$dom"'","port":"443","id":"'"$uuid"'","aid":"0","net":"httpupgrade","type":"none","host":"'"$dom"'","path":"/vmess-upgrade","tls":"tls"}' | base64 -w 0)"
            vmess_ntls="vmess://$(echo -e '{"v":"2","ps":"'"$username"'","add":"'"$dom"'","port":"80","id":"'"$uuid"'","aid":"0","net":"ws","type":"none","host":"'"$dom"'","path":"/vmess","tls":""}' | base64 -w 0)"
            clear
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "           PERMANENT ACCOUNT CREATED              "
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e " Remarks     : \e[32m$username\e[0m"
            echo -e " Domain      : \e[33m$dom\e[0m"
            echo -e " User ID     : \e[33m$uuid\e[0m"
            echo -e " Expired On  : \e[31m$exp_date\e[0m"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e " \e[36mLINK TLS :\e[0m\n$vmess_tls"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e " \e[36mLINK HTTP-UPGRADE (CloudFront Bypass) :\e[0m\n$vmess_upgrade"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e " \e[36mLINK NO-TLS :\e[0m\n$vmess_ntls"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            read -n 1 -s -r -p "Press any key to back on menu"
            ;;
        0) break ;;
    esac
done
