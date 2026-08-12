#!/bin/bash
while true; do
    clear
    echo "=========================================="
    echo "            VLESS MANAGER                 "
    echo "=========================================="
    echo "  [1] Create VLESS Account (TLS)"
    echo "  [2] Create VLESS Account (Non-TLS)"
    echo "  [3] Create VLESS Trial (TLS)"
    echo "  [4] Delete VLESS Account"
    echo "  [0] Return to Main Menu"
    echo "=========================================="
    read -p "Select an option [0-4]: " subopt
    case $subopt in
        1|01)
            clear
            echo "=== CREATE VLESS (TLS) ==="
            read -p "Enter Client Username: " USERNAME
            read -p "Enter Duration (Days) [default: 30]: " EXP
            [[ -z "$EXP" || ! "$EXP" =~ ^[0-9]+$ ]] && EXP=30
            EXP_DATE=$(date -d "+$EXP days" +"%Y-%m-%d")
            
            DOMAIN=$(cat /etc/xray/domain)
            NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
            CONFIG_FILE="/usr/local/etc/xray/config.json"
            
            jq --arg id "$NEW_UUID" --arg email "$USERNAME" '(.inbounds[] | select(.protocol == "vless" and .port == 10002)).settings.clients += [{"id": $id, "email": $email}]' "$CONFIG_FILE" > /tmp/x.json && mv /tmp/x.json "$CONFIG_FILE"
            systemctl restart xray
            
            echo "$USERNAME | $NEW_UUID | $EXP_DATE | vless" >> /etc/xray/clients.db
            LINK="vless://${NEW_UUID}@${DOMAIN}:443?path=%2Fvless&security=tls&encryption=none&type=ws&sni=${DOMAIN}#${USERNAME}"
            
            echo -e "\n\e[32mSUCCESS! VLESS (TLS) CREATED\e[0m"
            echo -e " \e[33m• Username :\e[0m $USERNAME"
            echo -e " \e[33m• UUID     :\e[0m $NEW_UUID"
            echo -e " \e[33m• Expiry   :\e[0m $EXP_DATE ($EXP Days)"
            echo -e "\e[36m--------------------------------------------------\e[0m"
            echo -e " \e[32mLink:\e[0m\n$LINK"
            echo -e "\e[36m--------------------------------------------------\e[0m"
            read -p "Press Enter..."
            ;;
        2|02)
            clear
            echo "=== CREATE VLESS (NON-TLS) ==="
            read -p "Enter Client Username: " USERNAME
            read -p "Enter Duration (Days) [default: 30]: " EXP
            [[ -z "$EXP" || ! "$EXP" =~ ^[0-9]+$ ]] && EXP=30
            EXP_DATE=$(date -d "+$EXP days" +"%Y-%m-%d")
            
            DOMAIN=$(cat /etc/xray/domain)
            NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
            CONFIG_FILE="/usr/local/etc/xray/config.json"
            
            jq --arg id "$NEW_UUID" --arg email "$USERNAME" '(.inbounds[] | select(.protocol == "vless" and .port == 10005)).settings.clients += [{"id": $id, "email": $email}]' "$CONFIG_FILE" > /tmp/x.json && mv /tmp/x.json "$CONFIG_FILE"
            systemctl restart xray
            
            echo "$USERNAME | $NEW_UUID | $EXP_DATE | vless-ntls" >> /etc/xray/clients.db
            LINK="vless://${NEW_UUID}@${DOMAIN}:80?path=%2Fvless-ntls&security=none&encryption=none&type=ws#${USERNAME}"
            
            echo -e "\n\e[32mSUCCESS! VLESS (NON-TLS) CREATED\e[0m"
            echo -e " \e[33m• Username :\e[0m $USERNAME"
            echo -e " \e[33m• Expiry   :\e[0m $EXP_DATE ($EXP Days)"
            echo -e "\e[36m--------------------------------------------------\e[0m"
            echo -e " \e[32mLink:\e[0m\n$LINK"
            echo -e "\e[36m--------------------------------------------------\e[0m"
            read -p "Press Enter..."
            ;;
        3|03)
            clear
            echo "=== CREATE VLESS TRIAL (TLS) ==="
            USERNAME="TRIAL-$(tr -dc A-Z0-9 </dev/urandom | head -c 4)"
            EXP=1
            EXP_DATE=$(date -d "+$EXP days" +"%Y-%m-%d")
            
            DOMAIN=$(cat /etc/xray/domain)
            NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
            CONFIG_FILE="/usr/local/etc/xray/config.json"
            
            jq --arg id "$NEW_UUID" --arg email "$USERNAME" '(.inbounds[] | select(.protocol == "vless" and .port == 10002)).settings.clients += [{"id": $id, "email": $email}]' "$CONFIG_FILE" > /tmp/x.json && mv /tmp/x.json "$CONFIG_FILE"
            systemctl restart xray
            
            echo "$USERNAME | $NEW_UUID | $EXP_DATE | vless-trial" >> /etc/xray/clients.db
            LINK="vless://${NEW_UUID}@${DOMAIN}:443?path=%2Fvless&security=tls&encryption=none&type=ws&sni=${DOMAIN}#${USERNAME}"
            
            echo -e "\n\e[32mSUCCESS! VLESS TRIAL CREATED\e[0m"
            echo -e " \e[33m• Username :\e[0m $USERNAME"
            echo -e " \e[33m• Expiry   :\e[0m $EXP_DATE (24 Hours)"
            echo -e "\e[36m--------------------------------------------------\e[0m"
            echo -e " \e[32mLink:\e[0m\n$LINK"
            echo -e "\e[36m--------------------------------------------------\e[0m"
            read -p "Press Enter..."
            ;;
        4|04)
            clear
            read -p "Enter UUID to delete: " DEL_UUID
            jq --arg id "$DEL_UUID" '(.inbounds[] | select(.protocol == "vless")).settings.clients |= map(select(.id != $id))' /usr/local/etc/xray/config.json > /tmp/x.json && mv /tmp/x.json /usr/local/etc/xray/config.json
            sed -i "/$DEL_UUID/d" /etc/xray/clients.db
            systemctl restart xray
            echo "Deleted if found."
            read -p "Press Enter..."
            ;;
        0|00) break ;;
    esac
done
