#!/bin/bash
# Advanced Trojan Manager Module (gRPC/WS, Auto-Cleanup Sweeper)

while true; do
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "             ADVANCED TROJAN MANAGER             "
    echo -e "\e[36m=================================================\e[0m"
    echo -e "  [01] Create Trojan Account"
    echo -e "  [02] Generate 24-Hour Trial Trojan"
    echo -e "  [03] Bulk Create Trojan Accounts"
    echo -e "  [04] Renew Trojan Account"
    echo -e "  [05] Delete Trojan Account"
    echo -e "  [06] Automatic Expiry Sweeper (Purge Expired)"
    echo -e "  [07] List All Trojan Accounts"
    echo -e "  [00] Back to Main Menu"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [00-07]: " option

    case $option in
        01|1)
            read -p "Enter username: " user
            read -p "Enter password/token: " pass
            read -p "Enter active days: " days
            exp_date=$(date -d "+$days days" +"%Y-%m-%d")
            
            mkdir -p /opt/vpn_platform
            echo "$user:$pass:$exp_date:trojan" >> /opt/vpn_platform/xray_users.db
            
            trojan_link="trojan://${pass}@$(hostname -I | awk '{print $1}'):443?security=tls&type=tcp#${user}-Trojan"
            
            echo -e "\e[32m[SUCCESS] Trojan Account Created!\e[0m"
            echo "Username : $user"
            echo "Password : $pass"
            echo "Expires  : $exp_date"
            echo -e "\nLink:\n$trojan_link"
            if command -v qrencode &> /dev/null; then
                echo -e "\nQR Code:"
                qrencode -t ansiutf8 "$trojan_link"
            fi
            ;;
        02|2)
            user="trial_trojan_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 4)"
            pass="pass_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 6)"
            exp_date=$(date -d "+1 days" +"%Y-%m-%d")
            echo "$user:$pass:$exp_date:trojan" >> /opt/vpn_platform/xray_users.db
            echo -e "\e[32m[SUCCESS] Trial Trojan Created: $user / $pass\e[0m"
            ;;
        03|3)
            read -p "Enter base username: " base
            read -p "How many accounts? " count
            read -p "Active days: " days
            exp_date=$(date -d "+$days days" +"%Y-%m-%d")
            for i in $(seq 1 "$count"); do
                user="${base}${i}"
                pass="pass${i}_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 4)"
                echo "$user:$pass:$exp_date:trojan" >> /opt/vpn_platform/xray_users.db
                echo "Created: $user / $pass"
            done
            echo -e "\e[32m[SUCCESS] Bulk creation complete.\e[0m"
            ;;
        04|4)
            read -p "Enter username to renew: " user
            read -p "Add how many days? " days
            new_exp=$(date -d "+$days days" +"%Y-%m-%d")
            sed -i "/^$user:.*:trojan/ s/:[0-9-]\{10\}:/:$new_exp:/" /opt/vpn_platform/xray_users.db
            echo -e "\e[32m[SUCCESS] Account $user renewed until $new_exp.\e[0m"
            ;;
        05|5)
            read -p "Enter username to delete: " user
            sed -i "/^$user:.*:trojan/d" /opt/vpn_platform/xray_users.db
            echo -e "\e[32m[SUCCESS] Account $user removed.\e[0m"
            ;;
        06|6)
            echo -e "\e[33mRunning expiry sweeper...\e[0m"
            today=$(date +"%Y-%m-%d")
            # Removes lines where expiration date is earlier than today
            while IFS=Read -r line; do
                if [ -n "$line" ]; then
                    u_date=$(echo "$line" | awk -F':' '{print $3}')
                    if [[ "$u_date" < "$today" ]]; then
                        u_name=$(echo "$line" | awk -F':' '{print $1}')
                        echo "Purging expired account: $u_name (Expired on $u_date)"
                        sed -i "\|^$u_name:.*:trojan|d" /opt/vpn_platform/xray_users.db
                    fi
                fi
            done < /opt/vpn_platform/xray_users.db
            echo -e "\e[32m[SUCCESS] Sweeper complete.\e[0m"
            ;;
        07|7)
            echo -e "\e[33mActive Trojan Accounts:\e[0m"
            grep ":trojan:" /opt/vpn_platform/xray_users.db 2>/dev/null | awk -F':' '{print "User: " $1 " | Pass: " $2 " | Expires: " $3}'
            ;;
        00|0) break ;;
    esac
    read -n 1 -s -r -p "Press any key to continue..."
done
