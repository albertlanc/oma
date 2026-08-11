#!/bin/bash
while true; do
    clear
    echo "=========================================="
    echo "            VMESS MANAGER                 "
    echo "=========================================="
    echo "  [1] Create VMess Account (TLS)"
    echo "  [2] Create VMess Account (Non-TLS)"
    echo "  [3] Create VMess Trial (TLS)"
    echo "  [4] Delete VMess Account"
    echo "  [0] Return to Main Menu"
    echo "=========================================="
    read -p "Select an option [0-4]: " subopt

    case $subopt in
        1|01)
            clear
            echo "=== CREATE VMESS (TLS) ==="
            read -p "Enter Client Username: " USERNAME
            DOMAIN="vps.gregsmarty.co.uk"
            NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
            CONFIG_FILE="/usr/local/etc/xray/config.json"

            jq --arg id "$NEW_UUID" '(.inbounds[] | select(.protocol == "vmess" and .port == 10001)).settings.clients += [{"id": $id, "alterId": 0}]' "$CONFIG_FILE" > /tmp/x.json && mv /tmp/x.json "$CONFIG_FILE"
            systemctl restart xray
            
            VMESS_JSON=$(cat <<EOFjson
{"v":"2","ps":"$USERNAME","add":"$DOMAIN","port":"443","id":"$NEW_UUID","aid":"0","net":"ws","type":"none","host":"$DOMAIN","path":"/vmess","tls":"tls"}
EOFjson
)
            LINK="vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"
            echo -e "\nSUCCESS!\nLink: $LINK"
            read -p "Press Enter..."
            ;;
        2|02)
            clear
            echo "=== CREATE VMESS (NON-TLS) ==="
            read -p "Enter Client Username: " USERNAME
            DOMAIN="vps.gregsmarty.co.uk"
            NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
            CONFIG_FILE="/usr/local/etc/xray/config.json"

            jq --arg id "$NEW_UUID" '(.inbounds[] | select(.protocol == "vmess" and .port == 10004)).settings.clients += [{"id": $id, "alterId": 0}]' "$CONFIG_FILE" > /tmp/x.json && mv /tmp/x.json "$CONFIG_FILE"
            systemctl restart xray

            VMESS_JSON=$(cat <<EOFjson
{"v":"2","ps":"$USERNAME","add":"$DOMAIN","port":"80","id":"$NEW_UUID","aid":"0","net":"ws","type":"none","host":"$DOMAIN","path":"/vmess-ntls","tls":""}
EOFjson
)
            LINK="vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"
            echo -e "\nSUCCESS!\nLink: $LINK"
            read -p "Press Enter..."
            ;;
        3|03)
            clear
            USERNAME="TRIAL-$(tr -dc A-Z0-9 </dev/urandom | head -c 4)"
            DOMAIN="vps.gregsmarty.co.uk"
            NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
            CONFIG_FILE="/usr/local/etc/xray/config.json"

            jq --arg id "$NEW_UUID" '(.inbounds[] | select(.protocol == "vmess" and .port == 10001)).settings.clients += [{"id": $id, "alterId": 0}]' "$CONFIG_FILE" > /tmp/x.json && mv /tmp/x.json "$CONFIG_FILE"
            systemctl restart xray

            VMESS_JSON=$(cat <<EOFjson
{"v":"2","ps":"$USERNAME","add":"$DOMAIN","port":"443","id":"$NEW_UUID","aid":"0","net":"ws","type":"none","host":"$DOMAIN","path":"/vmess","tls":"tls"}
EOFjson
)
            LINK="vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"
            echo -e "\nTRIAL CREATED (TLS)!\nUsername: $USERNAME\nLink: $LINK"
            read -p "Press Enter..."
            ;;
        4|04)
            clear
            read -p "Enter UUID to delete: " DEL_UUID
            jq --arg id "$DEL_UUID" '(.inbounds[] | select(.protocol == "vmess")).settings.clients |= map(select(.id != $id))' /usr/local/etc/xray/config.json > /tmp/x.json && mv /tmp/x.json /usr/local/etc/xray/config.json
            systemctl restart xray
            echo "Deleted if found."
            read -p "Press Enter..."
            ;;
        0|00) break ;;
    esac
done
