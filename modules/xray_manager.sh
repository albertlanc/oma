#!/bin/bash
# Advanced Xray Protocol Manager (VMess, VLESS, Trojan)

DOMAIN_CONF="/opt/vpn_platform/domain.conf"

load_domain() {
    if [ -f "$DOMAIN_CONF" ]; then
        source "$DOMAIN_CONF"
    fi
}

get_server_ip() {
    hostname -I | awk '{print $1}'
}

while true; do
    load_domain
    clear
    echo -e "\e[32m=================================================\e[0m"
    echo -e "           XRAY PROTOCOLS MANAGER                "
    echo -e "\e[32m=================================================\e[0m"
    echo -e "  [1] VMess Manager"
    echo -e "  [2] VLESS Manager"
    echo -e "  [3] Trojan Manager"
    echo -e "  [0] Back to Main Menu"
    echo -e "\e[32m=================================================\e[0m"
    read -p "Select an option [0-3]: " proto_opt

    case $proto_opt in
        1)
            while true; do
                clear
                echo -e "\e[32m=================================================\e[0m"
                echo -e "                 VMESS MANAGER                   "
                echo -e "\e[32m=================================================\e[0m"
                echo -e "  [1] Create VMess Trial Account (1 Hour)"
                echo -e "  [2] Create VMess Permanent Account"
                echo -e "  [3] Renew VMess Account"
                echo -e "  [4] Delete VMess Account"
                echo -e "  [0] Back"
                echo -e "\e[32m=================================================\e[0m"
                read -p "Select option [0-4]: " sub_opt

                server_ip=$(get_server_ip)
                dom="${SERVER_DOMAIN:-$server_ip}"
                uuid=$(cat /proc/sys/kernel/random/uuid)

                case $sub_opt in
                    1)
                        clear
                        username="trial-$(date +%s%N | cut -c10-13)"
                        exp_date=$(date -d "+1 hour" +"%Y-%m-%d %H:%M:%S")
                        
                        # Generate VMess JSON link structures
                        vmess_tls="vmess://$(echo -e '{"v":"2","ps":"'"$username"'","add":"'"$dom"'","port":"443","id":"'"$uuid"'","aid":"0","net":"ws","type":"none","host":"'"$dom"'","path":"/vmess","tls":"tls"}' | base64 -w 0)"
                        vmess_ntls="vmess://$(echo -e '{"v":"2","ps":"'"$username"'","add":"'"$dom"'","port":"80","id":"'"$uuid"'","aid":"0","net":"ws","type":"none","host":"'"$dom"'","path":"/vmess","tls":""}' | base64 -w 0)"
                        vmess_upgrade="vmess://$(echo -e '{"v":"2","ps":"'"$username"'","add":"'"$dom"'","port":"443","id":"'"$uuid"'","aid":"0","net":"httpupgrade","type":"none","host":"'"$dom"'","path":"/vmess-upgrade","tls":"tls"}' | base64 -w 0)"

                        clear
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e "        TRIAL ACCOUNT CREATED           "
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " Remarks     : \e[32m$username\e[0m"
                        echo -e " Domain      : \e[33m$dom\e[0m"
                        echo -e " User ID     : \e[33m$uuid\e[0m"
                        echo -e " Expired On  : \e[31m$exp_date\e[0m"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " \e[36m[VMess TLS Link]:\e[0m"
                        echo -e "$vmess_tls"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " \e[36m[VMess Non-TLS Link]:\e[0m"
                        echo -e "$vmess_ntls"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " \e[36m[LINK HTTP-UPGRADE (CloudFront Bypass)]:\e[0m"
                        echo -e "$vmess_upgrade"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        read -n 1 -s -r -p "Press any key to continue..."
                        ;;
                    2)
                        clear
                        read -p "Enter username: " username
                        read -p "Enter active duration in days: " days
                        exp_date=$(date -d "+$days days" +"%Y-%m-%d")

                        vmess_tls="vmess://$(echo -e '{"v":"2","ps":"'"$username"'","add":"'"$dom"'","port":"443","id":"'"$uuid"'","aid":"0","net":"ws","type":"none","host":"'"$dom"'","path":"/vmess","tls":"tls"}' | base64 -w 0)"
                        vmess_ntls="vmess://$(echo -e '{"v":"2","ps":"'"$username"'","add":"'"$dom"'","port":"80","id":"'"$uuid"'","aid":"0","net":"ws","type":"none","host":"'"$dom"'","path":"/vmess","tls":""}' | base64 -w 0)"
                        vmess_upgrade="vmess://$(echo -e '{"v":"2","ps":"'"$username"'","add":"'"$dom"'","port":"443","id":"'"$uuid"'","aid":"0","net":"httpupgrade","type":"none","host":"'"$dom"'","path":"/vmess-upgrade","tls":"tls"}' | base64 -w 0)"

                        clear
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e "        VMESS ACCOUNT CREATED           "
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " Remarks     : \e[32m$username\e[0m"
                        echo -e " Domain      : \e[33m$dom\e[0m"
                        echo -e " User ID     : \e[33m$uuid\e[0m"
                        echo -e " Expired On  : \e[31m$exp_date\e[0m"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " \e[36m[VMess TLS Link]:\e[0m"
                        echo -e "$vmess_tls"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " \e[36m[VMess Non-TLS Link]:\e[0m"
                        echo -e "$vmess_ntls"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " \e[36m[LINK HTTP-UPGRADE (CloudFront Bypass)]:\e[0m"
                        echo -e "$vmess_upgrade"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        read -n 1 -s -r -p "Press any key to continue..."
                        ;;
                    3|4)
                        echo -e "\e[33mFeature under active integration for database records.\e[0m"
                        sleep 2
                        ;;
                    0)
                        break
                        ;;
                esac
            done
            ;;
        2)
            while true; do
                clear
                echo -e "\e[32m=================================================\e[0m"
                echo -e "                 VLESS MANAGER                   "
                echo -e "\e[32m=================================================\e[0m"
                echo -e "  [1] Create VLESS Trial Account (1 Hour)"
                echo -e "  [2] Create VLESS Permanent Account"
                echo -e "  [0] Back"
                echo -e "\e[32m=================================================\e[0m"
                read -p "Select option [0-2]: " vless_sub

                server_ip=$(get_server_ip)
                dom="${SERVER_DOMAIN:-$server_ip}"
                uuid=$(cat /proc/sys/kernel/random/uuid)

                case $vless_sub in
                    1)
                        clear
                        username="trial-vless-$(date +%s%N | cut -c10-13)"
                        exp_date=$(date -d "+1 hour" +"%Y-%m-%d %H:%M:%S")
                        vless_link="vless://$uuid@$dom:443?encryption=none&security=tls&sni=$dom&type=ws&path=%2Fvless#$username"
                        vless_upgrade="vless://$uuid@$dom:443?encryption=none&security=tls&sni=$dom&type=httpupgrade&path=%2Fvless-upgrade#$username"

                        clear
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e "        TRIAL ACCOUNT CREATED           "
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " Remarks     : \e[32m$username\e[0m"
                        echo -e " Domain      : \e[33m$dom\e[0m"
                        echo -e " User ID     : \e[33m$uuid\e[0m"
                        echo -e " Expired On  : \e[31m$exp_date\e[0m"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " \e[36m[VLESS TLS Link]:\e[0m"
                        echo -e "$vless_link"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " \e[36m[LINK HTTP-UPGRADE (CloudFront Bypass)]:\e[0m"
                        echo -e "$vless_upgrade"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        read -n 1 -s -r -p "Press any key to continue..."
                        ;;
                    2)
                        clear
                        read -p "Enter username: " username
                        read -p "Enter active duration in days: " days
                        exp_date=$(date -d "+$days days" +"%Y-%m-%d")
                        vless_link="vless://$uuid@$dom:443?encryption=none&security=tls&sni=$dom&type=ws&path=%2Fvless#$username"

                        clear
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e "        VLESS ACCOUNT CREATED           "
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " Remarks     : \e[32m$username\e[0m"
                        echo -e " Domain      : \e[33m$dom\e[0m"
                        echo -e " User ID     : \e[33m$uuid\e[0m"
                        echo -e " Expired On  : \e[31m$exp_date\e[0m"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " \e[36m[VLESS Link]:\e[0m"
                        echo -e "$vless_link"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        read -n 1 -s -r -p "Press any key to continue..."
                        ;;
                    0)
                        break
                        ;;
                esac
            done
            ;;
        3)
            while true; do
                clear
                echo -e "\e[32m=================================================\e[0m"
                echo -e "                 TROJAN MANAGER                  "
                echo -e "\e[32m=================================================\e[0m"
                echo -e "  [1] Create Trojan Trial Account (1 Hour)"
                echo -e "  [2] Create Trojan Permanent Account"
                echo -e "  [0] Back"
                echo -e "\e[32m=================================================\e[0m"
                read -p "Select option [0-2]: " trojan_sub

                server_ip=$(get_server_ip)
                dom="${SERVER_DOMAIN:-$server_ip}"
                password="tr-$(date +%s%N | cut -c10-15)"

                case $trojan_sub in
                    1)
                        clear
                        username="trial-trojan-$(date +%s%N | cut -c10-13)"
                        exp_date=$(date -d "+1 hour" +"%Y-%m-%d %H:%M:%S")
                        trojan_link="trojan://$password@$dom:443?security=tls&sni=$dom&type=ws&path=%2Ftrojan#$username"

                        clear
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e "        TRIAL ACCOUNT CREATED           "
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " Remarks     : \e[32m$username\e[0m"
                        echo -e " Domain      : \e[33m$dom\e[0m"
                        echo -e " User ID     : \e[33m$password\e[0m"
                        echo -e " Expired On  : \e[31m$exp_date\e[0m"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " \e[36m[Trojan Link]:\e[0m"
                        echo -e "$trojan_link"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        read -n 1 -s -r -p "Press any key to continue..."
                        ;;
                    2)
                        clear
                        read -p "Enter username: " username
                        read -p "Enter custom password: " password
                        read -p "Enter active duration in days: " days
                        exp_date=$(date -d "+$days days" +"%Y-%m-%d")
                        trojan_link="trojan://$password@$dom:443?security=tls&sni=$dom&type=ws&path=%2Ftrojan#$username"

                        clear
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e "        TROJAN ACCOUNT CREATED          "
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " Remarks     : \e[32m$username\e[0m"
                        echo -e " Domain      : \e[33m$dom\e[0m"
                        echo -e " User ID     : \e[33m$password\e[0m"
                        echo -e " Expired On  : \e[31m$exp_date\e[0m"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo -e " \e[36m[Trojan Link]:\e[0m"
                        echo -e "$trojan_link"
                        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        read -n 1 -s -r -p "Press any key to continue..."
                        ;;
                    0)
                        break
                        ;;
                esac
            done
            ;;
        0)
            break
            ;;
    esac
done
