#!/bin/bash
# VLESS Manager Module (XTLS & HTTPUpgrade)

clear
echo -e "\e[36m=================================================\e[0m"
echo -e "                 VLESS MANAGER                   "
echo -e "\e[36m=================================================\e[0m"
echo -e "  [1] Create VLESS User"
echo -e "  [2] Generate Trial User"
echo -e "  [3] Delete VLESS User"
echo -e "  [0] Back to Main Menu"
echo -e "\e[36m=================================================\e[0m"
read -p "Select choice: " choice

case $choice in
    1|2)
        if [ "$choice" -eq 2 ]; then
            user="trial_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 4)"
            exp_days=1
            echo -e "\e[33mGenerating 24-Hour Trial User: $user\e[0m"
        else
            read -p "Enter Username: " user
            read -p "Enter Active Days: " exp_days
        fi
        
        uuid=$(cat /proc/sys/kernel/random/uuid)
        exp_date=$(date -d "+$exp_days days" +"%Y-%m-%d")
        
        echo "$user:$uuid:$exp_date:vless" >> /opt/vpn_platform/xray_users.db
        echo -e "\e[32m[SUCCESS] VLESS User Created!\e[0m"
        echo "Username : $user"
        echo "UUID     : $uuid"
        echo "Expires  : $exp_date"
        ;;
    3)
        read -p "Enter Username to Delete: " del_user
        sed -i "/^$del_user:.*:vless/d" /opt/vpn_platform/xray_users.db
        echo -e "\e[32m[SUCCESS] User $del_user removed.\e[0m"
        ;;
    *) exit 0 ;;
esac
read -n 1 -s -r -p "Press any key to return..."
