#!/bin/bash
while true; do
    clear
    echo "=========================================="
    echo "            TROJAN MANAGER                "
    echo "=========================================="
    echo "  [1] Create Trojan Account (Standard)"
    echo "  [2] Create Trojan Trial Account"
    echo "  [3] Delete Trojan Account"
    echo "  [0] Return to Main Menu"
    echo "=========================================="
    read -p "Select an option [0-3]: " subopt

    case $subopt in
        1|01)
            clear
            echo "=== CREATE TROJAN ACCOUNT ==="
            read -p "Enter Client Username: " USERNAME
            DOMAIN="vps.gregsmarty.co.uk"
            PASSWORD="trj-$(openssl rand -hex 4)"
            CONFIG_FILE="/usr/local/etc/xray/config.json"

            jq --arg pass "$PASSWORD" \
               '(.inbounds[] | select(.protocol == "trojan")).settings.clients += [{"password": $pass}]' \
               "$CONFIG_FILE" > /tmp/xray_temp.json

            if xray run -test -config /tmp/xray_temp.json >/dev/null 2>&1; then
                mv /tmp/xray_temp.json "$CONFIG_FILE"
                systemctl restart xray
                LINK="trojan://$PASSWORD@$DOMAIN:443?type=ws&security=tls&path=%2Ftrojan&host=$DOMAIN#$USERNAME"
                echo ""
                echo "SUCCESSFULLY CREATED!"
                echo "Password: $PASSWORD"
                echo "Link: $LINK"
            else
                echo "[ERROR] Failed to update config."
                rm -f /tmp/xray_temp.json
            fi
            read -p "Press Enter to continue..."
            ;;
        2|02)
            clear
            echo "=== CREATE TROJAN TRIAL ACCOUNT ==="
            USERNAME="TRIAL-$(tr -dc A-Z0-9 </dev/urandom | head -c 4)"
            DOMAIN="vps.gregsmarty.co.uk"
            PASSWORD="trj-$(openssl rand -hex 4)"
            CONFIG_FILE="/usr/local/etc/xray/config.json"

            jq --arg pass "$PASSWORD" \
               '(.inbounds[] | select(.protocol == "trojan")).settings.clients += [{"password": $pass}]' \
               "$CONFIG_FILE" > /tmp/xray_temp.json

            if xray run -test -config /tmp/xray_temp.json >/dev/null 2>&1; then
                mv /tmp/xray_temp.json "$CONFIG_FILE"
                systemctl restart xray
                LINK="trojan://$PASSWORD@$DOMAIN:443?type=ws&security=tls&path=%2Ftrojan&host=$DOMAIN#$USERNAME"
                echo ""
                echo "TRIAL CREATED SUCCESSFULLY!"
                echo "Username: $USERNAME"
                echo "Password: $PASSWORD"
                echo "Link: $LINK"
            else
                echo "[ERROR] Failed to update config."
                rm -f /tmp/xray_temp.json
            fi
            read -p "Press Enter to continue..."
            ;;
        3|03)
            clear
            echo "=== DELETE TROJAN ACCOUNT ==="
            read -p "Enter the exact Password to delete: " DEL_PASS
            CONFIG_FILE="/usr/local/etc/xray/config.json"
            
            jq --arg pass "$DEL_PASS" \
               '(.inbounds[] | select(.protocol == "trojan")).settings.clients |= map(select(.password != $pass))' \
               "$CONFIG_FILE" > /tmp/xray_temp.json && mv /tmp/xray_temp.json "$CONFIG_FILE"
            systemctl restart xray
            echo "Account deleted if it existed."
            read -p "Press Enter to continue..."
            ;;
        0|00)
            break
            ;;
        *)
            echo "Invalid option."
            sleep 1
            ;;
    esac
done
