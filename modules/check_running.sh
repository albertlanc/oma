#!/bin/bash

# Color codes
CYAN='\e[36m'
GREEN='\e[32m'
RED='\e[31m'
YELLOW='\e[33m'
NC='\e[0m'

clear
echo -e "${CYAN}==========================================${NC}"
echo -e "       SYSTEM & SERVICE STATUS CHECK       "
echo -e "${CYAN}==========================================${NC}"
echo ""

check_service() {
    local svc=$1
    if systemctl is-active --quiet "$svc"; then
        echo -e "[$2] $3 : ${GREEN}ONLINE (Running)${NC}"
    else
        echo -e "[$2] $3 : ${RED}OFFLINE (Stopped)${NC}"
    fi
}

check_service "xray" "01" "Xray Core (VMess/VLESS/Trojan)"
check_service "nginx" "02" "Nginx Reverse Proxy"
check_service "ssh" "03" "OpenSSH Daemon"

if systemctl list-unit-files | grep -q dropbear; then
    check_service "dropbear" "04" "Dropbear SSH/SSL Proxy"
else
    echo -e "[04] Dropbear SSH/SSL Proxy : ${YELLOW}NOT INSTALLED${NC}"
fi

check_service "slowdns" "05" "SlowDNS (dnstt)"

if systemctl list-unit-files | grep -q fail2ban; then
    check_service "fail2ban" "06" "Fail2ban Security Shield"
else
    echo -e "[06] Fail2ban Security Shield : ${YELLOW}NOT INSTALLED${NC}"
fi

echo ""
echo -e "${CYAN}==========================================${NC}"
read -p "Press Enter to return to the main menu..."
