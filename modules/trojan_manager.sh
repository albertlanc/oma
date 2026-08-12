#!/bin/bash
while true; do
    clear
    echo "=========================================="
    echo "            TROJAN MANAGER                "
    echo "=========================================="
    echo "  [1] Create Trojan Account (TLS)"
    echo "  [2] Create Trojan Trial (TLS)"
    echo "  [3] Delete Trojan Account"
    echo "  [0] Return to Main Menu"
    echo "=========================================="
    read -p "Select an option [0-3]: " subopt
    case $subopt in
        1|01)
            clear
            echo "=== CREATE TROJAN (TLS) ==="
            read -p "Enter Client Username: " USERNAME
            read -p "Enter Duration (Days) [default: 30]: " EXP
            [[ -z "$EXP" || ! "$EXP" =~ ^[0-9]+$ ]] && EXP=30
            EXP_DATE=$(date -d "+$EXP days" +"%Y-%m-%d")
            
            DOMAIN="vps.gregsmarty.co.uk"
            NEW_UUID=$(cat /proc/sys/kernel/random/uuid | cut -d'-' -f1-3)
            CONFIG_FILE="/usr/local/etc/xray/config.json"
            
            jq --arg pass "$NEW_UUID" --arg email "$USERNAME" '(.inbounds[] | select(.protocol == "trojan" and .port == 10003)).settings.clients += [{"password": $pass, "email": $email}]' "$CONFIG_FILE" > /tmp/x.json && mv /tmp/x.json "$CONFIG_FILE"
            systemctl restart xray
            
            echo "$USERNAME | $NEW_UUID | $EXP_DATE | trojan" >> /etc/xray/clients.db
            LINK="trojan://${NEW_UUID}@${DOMAIN}:443?path=%2Ftrojan&security=tls&type=ws&sni=${DOMAIN}#${USERNAME}"
            
            echo -e "\n\e[32mSUCCESS! TROJAN CREATED\e[0m"
            echo -e " \e[33m• Username :\e[0m $USERNAME"
            echo -e " \e[33m• Password :\e[0m $NEW_UUID"
            echo -e " \e[33m• Expiry   :\e[0m $EXP_DATE ($EXP Days)"
            echo -e "\e[36m--------------------------------------------------\e[0m"
            echo -e " \e[32mLink:\e[0m\n$LINK"
            echo -e "\e[36m--------------------------------------------------\e[0m"
            read -p "Press Enter..."
            ;;
        2|02)
            clear
            echo "=== CREATE TROJAN TRIAL (TLS) ==="
            USERNAME="TRIAL-$(tr -dc A-Z0-9 </dev/urandom | head -c 4)"
            EXP=1
            EXP_DATE=$(date -d "+$EXP days" +"%Y-%m-%d")
            
            DOMAIN="vps.gregsmarty.co.uk"
            NEW_UUID=$(cat /proc/sys/kernel/random/uuid | cut -d'-' -f1-3)
            CONFIG_FILE="/usr/local/etc/xray/config.json"
            
            jq --arg pass "$NEW_UUID" --arg email "$USERNAME" '(.inbounds[] | select(.protocol == "trojan" and .port == 10003)).settings.clients += [{"password": $pass, "email": $email}]' "$CONFIG_FILE" > /tmp/x.json && mv /tmp/x.json "$CONFIG_FILE"
            systemctl restart xray
            
            echo "$USERNAME | $NEW_UUID | $EXP_DATE | trojan-trial" >> /etc/xray/clients.db
            LINK="trojan://${NEW_UUID}@${DOMAIN}:443?path=%2Ftrojan&security=tls&type=ws&sni=${DOMAIN}#${USERNAME}"
            
            echo -e "\n\e[32mSUCCESS! TROJAN TRIAL CREATED\e[0m"
            echo -e " \e[33m• Username :\e[0m $USERNAME"
            echo -e " \e[33m• Expiry   :\e[0m $EXP_DATE (24 Hours)"
            echo -e "\e[36m--------------------------------------------------\e[0m"
            echo -e " \e[32mLink:\e[0m\n$LINK"
            echo -e "\e[36m--------------------------------------------------\e[0m"
            read -p "Press Enter..."
            ;;
        3|03)
            clear
            read -p "Enter Password/UUID to delete: " DEL_UUID
            jq --arg pass "$DEL_UUID" '(.inbounds[] | select(.protocol == "trojan")).settings.clients |= map(select(.password != $pass))' /usr/local/etc/xray/config.json > /tmp/x.json && mv /tmp/x.json /usr/local/etc/xray/config.json
            sed -i "/$DEL_UUID/d" /etc/xray/clients.db
            systemctl restart xray
            echo "Deleted if found."
            read -p "Press Enter..."
            ;;
        0|00) break ;;
    esac
done
