#!/bin/bash
# SlowDNS Manager & Installer Module

SLOWDNS_DIR="/etc/slowdns"
DOMAIN_CONF="/root/oma/domain"
NS_CONF="/root/oma/nsdomain"

load_config() {
    if [ -f "$DOMAIN_CONF" ]; then
        SERVER_DOMAIN=$(cat "$DOMAIN_CONF")
    fi
    if [ -f "$NS_CONF" ]; then
        NS1=$(cat "$NS_CONF")
    fi
}

while true; do
    load_config
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "                SLOWDNS MANAGER                  "
    echo -e "\e[36m=================================================\e[0m"
    echo -e "  [01] Re-check / Setup SlowDNS & IPTables Redirection"
    echo -e "  [02] View SlowDNS Public Key & Info"
    echo -e "  [03] Check SlowDNS Service Status"
    echo -e "  [04] Restart SlowDNS Service"
    echo -e "  [00] Back to Main Menu"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [00-04]: " option

    case $option in
        1|01)
            clear
            echo -e "\e[33m=== FIX & RE-APPLY SLOWDNS ===\e[0m"
            
            # Ensure iptables redirection is active
            modprobe ip_tables 2>/dev/null
            modprobe iptable_nat 2>/dev/null
            iptables -t nat -F
            iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300

            # Re-create correct systemd service with the mandatory NS1 domain argument
            cat << SEREOF > /etc/systemd/system/slowdns.service
[Unit]
Description=SlowDNS Server (DNSTT)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/slowdns
ExecStart=/usr/local/bin/dnstt-server -udp :5300 -privkey-file /etc/slowdns/server.key $NS1 127.0.0.1:22
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SEREOF

            systemctl daemon-reload
            systemctl enable slowdns >/dev/null 2>&1
            systemctl restart slowdns

            echo -e "\e[32m[SUCCESS] SlowDNS service and IPTables redirection re-applied successfully!\e[0m"
            ;;
        2|02)
            clear
            echo -e "\e[33m=== SLOWDNS CONFIGURATION DETAILS ===\e[0m"
            if [ -f "$SLOWDNS_DIR/server.key.pub" ]; then
                echo -e "  NameServer (NS)   : \e[32m${NS1:-Not Set}\e[0m"
                echo -e "  Main Domain       : \e[32m${SERVER_DOMAIN:-Not Set}\e[0m"
                echo -e "  -------------------------------------------------"
                echo -e "  SlowDNS Public Key:"
                echo -e "\e[33m$(cat "$SLOWDNS_DIR/server.key.pub")\e[0m"
                echo -e "  -------------------------------------------------"
            else
                echo -e "\e[31m[ERROR] SlowDNS public key not found.\e[0m"
            fi
            ;;
        3|03)
            clear
            echo -e "\e[33m=== SLOWDNS SERVICE STATUS ===\e[0m"
            systemctl status slowdns --no-pager
            ;;
        4|04)
            clear
            echo -e "\e[33m=== RESTARTING SLOWDNS ===\e[0m"
            systemctl restart slowdns
            echo -e "\e[32m[SUCCESS] SlowDNS service restarted.\e[0m"
            ;;
        0|00)
            break
            ;;
        *)
            echo "Invalid option."
            sleep 1
            ;;
    esac
    read -n 1 -s -r -p "Press any key to return to SlowDNS menu..."
done
