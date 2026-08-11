#!/bin/bash
# Trojan Manager Module (WS & Expired Cleanup)

clear
echo -e "\e[36m=================================================\e[0m"
echo -e "                 TROJAN MANAGER                  "
echo -e "\e[36m=================================================\e[0m"
echo -e "  [1] Create Trojan User"
echo -e "  [2] Manual Expired Users Cleanup"
echo -e "  [0] Back to Main Menu"
echo -e "\e[36m=================================================\e[0m"
read -p "Select choice: " choice

case $choice in
    1)
        read -p "Enter Username: " user
        read -p "Enter Password: " pass
        read -p "Enter Active Days: " exp_days
        exp_date=$(date -d "+$exp_days days" +"%Y-%m-%d")
        
        echo "$user:$pass:$exp_date:trojan" >> /opt/vpn_platform/xray_users.db
        echo -e "\e[32m[SUCCESS] Trojan User Created!\e[0m"
        echo "Username : $user"
        echo "Password : $pass"
        echo "Expires  : $exp_date"
        ;;
    2)
        echo "Purging expired accounts from system..."
        today=$(date +"%Y-%m-%d")
        awk -F':' -v today="$today" '$3 < today {print $1}' /opt/vpn_platform/xray_users.db > /tmp/expired.txt
        sed -i "/$today/d" /opt/vpn_platform/xray_users.db 2>/dev/null || true
        echo -e "\e[32m[SUCCESS] Cleanup complete.\e[0m"
        ;;
    *) exit 0 ;;
esac
read -n 1 -s -r -p "Press any key to return..."
