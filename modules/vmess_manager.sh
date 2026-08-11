#!/bin/bash
# Advanced VMess Manager Module (WS/HTTPUpgrade, Quotas, QR Codes)

while true; do
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "             ADVANCED VMESS MANAGER              "
    echo -e "\e[36m=================================================\e[0m"
    echo -e "  [01] Create VMess Account (Custom Quota)"
    echo -e "  [02] Generate 24-Hour Trial VMess"
    echo -e "  [03] Bulk Create VMess Accounts"
    echo -e "  [04] Renew VMess Account"
    echo -e "  [05] Delete VMess Account"
    echo -e "  [06] List All VMess Accounts"
    echo -e "  [00] Back to Main Menu"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [00-06]: " option

    case $option in
        01|1)
            read -p "Enter username: " user
            read -p "Enter active days (e.g., 30): " days
            read -p "Enter traffic quota in GB (e.g., 50, or 0 for unlimited): " quota
            uuid=$(cat /proc/sys/kernel/random/uuid)
            exp_date=$(date -d "+$days days" +"%Y-%m-%d")
            
            mkdir -p /opt/vpn_platform
            echo "$user:$uuid:$exp_date:vmess:$quota" >> /opt/vpn_platform/xray_users.db
            
            # Generate config link template
            vmess_json="{\"v\":\"2\",\"ps\":\"${user}-VMess\",\"add\":\"$(hostname -I | awk '{print $1}')\",\"port\":\"443\",\"id\":\"${uuid}\;\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"\",\"path\":\"/vmess\",\"tls\":\"tls\"}"
            vmess_link="vmess://$(echo -n "$vmess_json" | base64 -w 0)"
            
            echo -e "\e[32m[SUCCESS] VMess Account Created!\e[0m"
            echo "Username : $user"
            echo "UUID     : $uuid"
            echo "Expires  : $exp_date"
            echo "Quota    : ${quota}GB"
            echo -e "\nLink:\n$vmess_link"
            if command -v qrencode &> /dev/null; then
                echo -e "\nQR Code:"
                qrencode -t ansiutf8 "$vmess_link"
            fi
            ;;
        02|2)
            user="trial_vmess_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 4)"
            uuid=$(cat /proc/sys/kernel/random/uuid)
            exp_date=$(date -d "+1 days" +"%Y-%m-%d")
            echo "$user:$uuid:$exp_date:vmess:5" >> /opt/vpn_platform/xray_users.db
            echo -e "\e[32m[SUCCESS] 24-Hour Trial Created: $user (UUID: $uuid)\e[0m"
            ;;
        03|3)
            read -p "Enter base username: " base
            read -p "How many accounts? " count
            read -p "Active days: " days
            exp_date=$(date -d "+$days days" +"%Y-%m-%d")
            for i in $(seq 1 "$count"); do
                user="${base}${i}"
                uuid=$(cat /proc/sys/kernel/random/uuid)
                echo "$user:$uuid:$exp_date:vmess:0" >> /opt/vpn_platform/xray_users.db
                echo "Created: $user ($uuid)"
            done
            echo -e "\e[32m[SUCCESS] Bulk creation complete.\e[0m"
            ;;
        04|4)
            read -p "Enter username to renew: " user
            read -p "Add how many days? " days
            new_exp=$(date -d "+$days days" +"%Y-%m-%d")
            sed -i "/^$user:.*:vmess/ s/:[0-9-]\{10\}:/:$new_exp:/" /opt/vpn_platform/xray_users.db
            echo -e "\e[32m[SUCCESS] Account $user renewed until $new_exp.\e[0m"
            ;;
        05|5)
            read -p "Enter username to delete: " user
            sed -i "/^$user:.*:vmess/d" /opt/vpn_platform/xray_users.db
            echo -e "\e[32m[SUCCESS] Account $user removed.\e[0m"
            ;;
        06|6)
            echo -e "\e[33mActive VMess Accounts:\e[0m"
            grep ":vmess:" /opt/vpn_platform/xray_users.db 2>/dev/null | awk -F':' '{print "User: " $1 " | Expires: " $3 " | Quota: " $5 "GB"}'
            ;;
        00|0) break ;;
    esac
    read -n 1 -s -r -p "Press any key to continue..."
done
