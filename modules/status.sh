#!/bin/bash
# status.sh - Service Status Monitor

# Color Variables
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
NC='\e[0m'

echo -e "${YELLOW}==================================================${NC}"
echo -e "           SYSTEM SERVICES STATUS                 "
echo -e "${YELLOW}==================================================${NC}"

check_service() {
    if systemctl is-active --quiet "$1"; then
        echo -e " $2: ${GREEN}Active (Running)${NC}"
    else
        echo -e " $2: ${RED}Inactive (Stopped/Failed)${NC}"
    fi
}

# Check all backend services configured by install.sh
check_service "sshd"       "SSH Server       "
check_service "nginx"      "Nginx Web Server "
check_service "xray"       "Xray Core        "
check_service "slowdns"    "SlowDNS (DNSTT)  "
check_service "ws-proxy"   "SSH-WS Proxy     "
check_service "stunnel4"   "Stunnel4 TLS     "

echo -e "${YELLOW}==================================================${NC}"
echo ""
read -p "Press Enter to return to menu..."
