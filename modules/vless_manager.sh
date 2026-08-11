#!/bin/bash
while true; do
    clear
    echo "=========================================="
    echo "            VLESS MANAGER                 "
    echo "=========================================="
    echo "  [1] Create VLESS Account (TLS)"
    echo "  [2] Create VLESS Account (Non-TLS)"
    echo "  [3] Create VLESS Account (XHTTP)"
    echo "  [4] Create VLESS Trial (TLS)"
    echo "  [5] Delete VLESS Account"
    echo "  [0] Return to Main Menu"
    echo "=========================================="
    read -p "Select an option [0-5]: " subopt

    case $subopt in
        1|01)
            clear
            echo "=== CREATE VLESS (TLS) ==="
            read -p "Enter Client Username: " USERNAME
            DOMAIN="vps.gregsmarty.co.uk"
            NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
            CONFIG_FILE="/usr/local/etc/xray/config.json"

            jq --arg id "$NEW_UUID" '(.inbounds[] | select(.protocol == "vless" and .port == 10002)).settings.clients += [{"id": $id}]' "$CONFIG_FILE" > /tmp/x.json && mv /tmp/x.json "$CONFIG_FILE"
            systemctl restart xray
            LINK="vless://$NEW_UUID@$DOMAIN:443?type=ws&security=tls&path=%2Fvless&host=$DOMAIN#$USERNAME"
            echo -e "\nSUCCESS!\nLink: $LINK"
            read -p "Press Enter..."
            ;;
        2|02)
            clear
            echo "=== CREATE VLESS (NON-TLS) ==="
            read -p "Enter Client Username: " USERNAME
            DOMAIN="vps.gregsmarty.co.uk"
            NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
            CONFIG_FILE="/usr/local/etc/xray/config.json"

            jq --arg id "$NEW_UUID" '(.inbounds[] | select(.protocol == "vless" and .port == 10005)).settings.clients += [{"id": $id}]' "$CONFIG_FILE" > /tmp/x.json && mv /tmp/x.json "$CONFIG_FILE"
            systemctl restart xray
            LINK="vless://$NEW_UUID@$DOMAIN:80?type=ws&security=none&path=%2Fvless-ntls&host=$DOMAIN#$USERNAME"
            echo -e "\nSUCCESS!\nLink: $LINK"
            read -p "Press Enter..."
            ;;
        3|03)
            clear
            echo "=== CREATE VLESS (XHTTP) ==="
            read -p "Enter Client Username: " USERNAME
            DOMAIN="vps.gregsmarty.co.uk"
            NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
            CONFIG_FILE="/usr/local/etc/xray/config.json"

            jq --arg id "$NEW_UUID" '(.inbounds[] | select(.protocol == "vless" and .port == 10006)).settings.clients += [{"id": $id}]' "$CONFIG_FILE" > /tmp/x.json && mv /tmp/x.json "$CONFIG_FILE"
            systemctl restart xray
            LINK="vless://$NEW_UUID@$DOMAIN:80?type=xhttp&security=none&path=%2Fxhttp&host=$DOMAIN#$USERNAME"
            echo -e "\nSUCCESS!\nLink: $LINK"
            read -p "Press Enter..."
            ;;
        4|04)
            clear
            USERNAME="TRIAL-$(tr -dc A-Z0-9 </dev/urandom | head -c 4)"
            DOMAIN="vps.gregsmarty.co.uk"
            NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
            CONFIG_FILE="/usr/local/etc/xray/config.json"

            jq --arg id "$NEW_UUID" '(.inbounds[] | select(.protocol == "vless" and .port == 10002)).settings.clients += [{"id": $id}]' "$CONFIG_FILE" > /tmp/x.json && mv /tmp/x.json "$CONFIG_FILE"
            systemctl restart xray
            LINK="vless://$NEW_UUID@$DOMAIN:443?type=ws&security=tls&path=%2Fvless&host=$DOMAIN#$USERNAME"
            echo -e "\nTRIAL CREATED (TLS)!\nUsername: $USERNAME\nLink: $LINK"
            read -p "Press Enter..."
            ;;
        5|05)
            clear
            read -p "Enter UUID to delete: " DEL_UUID
            jq --arg id "$DEL_UUID" '(.inbounds[] | select(.protocol == "vless")).settings.clients |= map(select(.id != $id))' /usr/local/etc/xray/config.json > /tmp/x.json && mv /tmp/x.json /usr/local/etc/xray/config.json
            systemctl restart xray
            echo "Deleted if found."
            read -p "Press Enter..."
            ;;
        0|00) break ;;
    esac
done
