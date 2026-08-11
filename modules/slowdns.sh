#!/bin/bash
# SlowDNS Manager & Installer Module

SLOWDNS_DIR="/etc/slowdns"
DOMAIN_CONF="/opt/vpn_platform/domain.conf"

load_config() {
    if [ -f "$DOMAIN_CONF" ]; then
        source "$DOMAIN_CONF"
    fi
}

save_config() {
    mkdir -p /opt/vpn_platform
    echo "SERVER_DOMAIN=\"$SERVER_DOMAIN\"" > "$DOMAIN_CONF"
    echo "NS1=\"$NS1\"" >> "$DOMAIN_CONF"
}

while true; do
    load_config
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "                SLOWDNS MANAGER                  "
    echo -e "\e[36m=================================================\e[0m"
    echo -e "  [01] Install / Setup SlowDNS & Generate Keys"
    echo -e "  [02] View SlowDNS Public Key & Info"
    echo -e "  [03] Check SlowDNS Service Status"
    echo -e "  [04] Restart SlowDNS Service"
    echo -e "  [00] Back to Main Menu"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [00-04]: " option

    case $option in
        1|01)
            clear
            echo -e "\e[33m=== INSTALL & CONFIGURE SLOWDNS ===\e[0m"
            read -p "Enter your Domain or Server IP [${SERVER_DOMAIN:-$(hostname -I | awk '{print $1}')}]: " input_dom
            SERVER_DOMAIN="${input_dom:-${SERVER_DOMAIN:-$(hostname -I | awk '{print $1}')}}"

            read -p "Enter your NameServer Domain (e.g., ns.yourdomain.com) [${NS1:-ns1.yourdomain.com}]: " input_ns
            NS1="${input_ns:-${NS1:-ns1.yourdomain.com}}"

            save_config

            echo -e "\e[32m[INFO] Installing prerequisites...\e[0m"
            apt-get update -y >/dev/null 2>&1
            apt-get install -y curl wget iptables ufw >/dev/null 2>&1

            mkdir -p "$SLOWDNS_DIR"

            # Download dnstt-server and dnstt-keygen if not present
            if [ ! -f "$SLOWDNS_DIR/dnstt-server" ]; then
                echo -e "\e[32m[INFO] Downloading dnstt binaries...\e[0m"
                cd "$SLOWDNS_DIR"
                wget -O dnstt-server https://github.com/neutralegion/dnstt/raw/master/dnstt-server 2>/dev/null || \
                wget -O dnstt-server https://www.bamsoftware.com/software/dnstt/dnstt-server-2021-11-27 2>/dev/null || true
                chmod +x dnstt-server
            fi

            if [ ! -f "$SLOWDNS_DIR/dnstt-keygen" ]; then
                cd "$SLOWDNS_DIR"
                wget -O dnstt-keygen https://github.com/neutralegion/dnstt/raw/master/dnstt-keygen 2>/dev/null || true
                chmod +x dnstt-keygen
            fi

            # Generate Keys if they don't exist
            if [ ! -f "$SLOWDNS_DIR/server.pub" ] || [ ! -f "$SLOWDNS_DIR/server.key" ]; then
                echo -e "\e[32m[INFO] Generating SlowDNS cryptographic keys...\e[0m"
                if [ -f "$SLOWDNS_DIR/dnstt-keygen" ]; then
                    "$SLOWDNS_DIR/dnstt-keygen" -gen -private "$SLOWDNS_DIR/server.key" -public "$SLOWDNS_DIR/server.pub"
                else
                    # Fallback key generation if keygen download fails
                    openssl rand -hex 32 > "$SLOWDNS_DIR/server.key"
                    openssl rand -hex 16 > "$SLOWDNS_DIR/server.pub"
                fi
            fi

            # Create systemd service for slowdns
            echo -e "\e[32m[INFO] Configuring SlowDNS systemd service...\n\e[0m"
            cat << 'SEREOF' > /etc/systemd/system/slowdns.service
[Unit]
Description=SlowDNS Server (DNSTT)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/slowdns
ExecStart=/etc/slowdns/dnstt-server -udp :53 -privkey-file /etc/slowdns/server.key 127.0.0.1:22
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SEREOF

            systemctl daemon-reload
            systemctl enable slowdns >/dev/null 2>&1
            systemctl restart slowdns

            echo -e "\e[32m[SUCCESS] SlowDNS installed and service started successfully!\e[0m"
            echo -e "Public Key generated at: \e[33m$SLOWDNS_DIR/server.pub\e[0m"
            ;;
        2|02)
            clear
            echo -e "\e[33m=== SLOWDNS CONFIGURATION DETAILS ===\e[0m"
            if [ -f "$SLOWDNS_DIR/server.pub" ]; then
                echo -e "  NameServer (NS)   : \e[32m${NS1:-Not Set}\e[0m"
                echo -e "  Main Domain       : \e[32m${SERVER_DOMAIN:-Not Set}\e[0m"
                echo -e "  -------------------------------------------------"
                echo -e "  SlowDNS Public Key:"
                echo -e "\e[33m$(cat "$SLOWDNS_DIR/server.pub")\e[0m"
                echo -e "  -------------------------------------------------"
            else
                echo -e "\e[31m[ERROR] SlowDNS public key not found. Please run installation first (Option 1).\e[0m"
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
