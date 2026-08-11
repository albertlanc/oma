#!/bin/bash
# Advanced VLESS Manager Module (Reality/Vision Support & QR Codes)

while true; do
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "             ADVANCED VLESS MANAGER              "
    echo -e "\e[36m=================================================\e[0m"
    echo -e "  [01] Create VLESS Account (Reality/Vision)"
    echo -e "  [02] Generate 24-Hour Trial VLESS"
    echo -e "  [03] Bulk Create VLESS Accounts"
    echo -e "  [04] Renew VLESS Account"
    echo -e "  [05] Delete VLESS Account"
    echo -e "  [06] List All VLESS Accounts"
    echo -e "  [00] Back to Main Menu"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [00-06]: " option

    case $option in
        01|1)
            read -p "Enter username: " user
            read -p "Enter active days: " days
            uuid=$(cat /proc/sys/kernel/random/uuid)
            exp_date=$(date -d "+$days days" +"%Y-%m-%d")
            
            mkdir -p /opt/vpn_platform
            echo "$user:$uuid:$exp_date:vless" >> /opt/vpn_platform/xray_users.db
            
            vless_link="vless://${uuid}@$(hostname -I | awk '{print $1}'):443?encryption=none&security=reality&sni=yahoo.com&fp=chrome&type=tcp&flow=xtls-rprx-vision#${user}-VLESS"
            
            echo -e "\e[32m[SUCCESS] VLESS Account Created!\e[0m"
            echo "Username : $user"
            echo "UUID     : $uuid"
            echo "Expires  : $exp_date"
            echo -e "\nLink:\n$vless_link"
            if command -v qrencode &> /dev/null; then
                echo -e "\nQR Code:"
                qrencode -t ansiutf8 "$vless_link"
            fi
            ;;
        02|2)
            user="trial_vless_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 4)"
            uuid=$(cat /proc/sys/kernel/random/uuid)
            exp_date=$(date -d "+1 days" +"%Y-%m-%d")
            echo "$user:$uuid:$exp_date:vless" >> /opt/vpn_platform/xray_users.db
            echo -e "\e[32m[SUCCESS] Trial VLESS Created: $user\e[0m"
            ;;
        03|3)
            read -p "Enter base username: " base
            read -p "How many accounts? " count
            read -p "Active days: " days
            exp_date=$(date -d "+$days days" +"%Y-%m-%d")
            for i in $(seq 1 "$count"); do
                user="${base}${i}"
                uuid=$(cat /proc/sys/kernel/random/uuid)
                echo "$user:$uuid:$exp_date:vless" >> /opt/vpn_platform/xray_users.db
                echo "Created: $user"
            done
            echo -e "\e[32m[SUCCESS] Bulk creation complete.\e[0m"
            ;;
        04|4)
            read -p "Enter username to renew: " user
            read -p "Add how many days? " days
            new_exp=$(date -d "+$days days" +"%Y-%m-%d")
            sed -i "/^$user:.*:vless/ s/:[0-9-]\{10\}:/:$new_exp:/" /opt/vpn_platform/xray_users.db
            echo -e "\e[32m[SUCCESS] Account $user renewed until $new_exp.\e[0m"
            ;;
        05|5)
            read -p "Enter username to delete: " user
            sed -i "/^$user:.*:vless/d" /opt/vpn_platform/xray_users.db
            echo -e "\e[32m[SUCCESS] Account $user removed.\e[0m"
            ;;
        06|6)
            echo -e "\e[33mActive VLESS Accounts:\e[0m"
            grep ":vless:" /opt/vpn_platform/xray_users.db 2>/dev/null | awk -F':' '{print "User: " $1 " | Expires: " $3}'
            ;;
        00|0) break ;;
    esac
    read -n 1 -s -r -p "Press any key to continue..."
done
