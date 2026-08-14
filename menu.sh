#!/bin/bash

# Color codes
CYAN='\e[36m'
GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
GRAY='\e[90m'
BLUE='\e[34m'
NC='\e[0m'

while true; do
    clear
    
    # Dynamic System Stats
    HOST_IP=$(hostname -I | awk '{print $1}')
    UPTIME=$(uptime -p | sed 's/up //')
    RAM_TOTAL=$(free -m | awk 'NR==2{print $2}')
    RAM_USED=$(free -m | awk 'NR==2{print $3}')
    RAM_PCT=$((RAM_USED * 100 / RAM_TOTAL))
    
    # Retrieve Active Domain with Fallback Multi-Path Check
    ACTIVE_DOMAIN="None (Using Server IP)"
    if [ -f /etc/xray/domain ] && [ -s /etc/xray/domain ]; then
        ACTIVE_DOMAIN=$(cat /etc/xray/domain)
    elif [ -f /usr/local/etc/xray/domain ] && [ -s /usr/local/etc/xray/domain ]; then
        ACTIVE_DOMAIN=$(cat /usr/local/etc/xray/domain)
    elif [ -f /root/domain ] && [ -s /root/domain ]; then
        ACTIVE_DOMAIN=$(cat /root/domain)
    elif [ -f /var/lib/premium-script/ipvps.conf ]; then
        source /var/lib/premium-script/ipvps.conf
        [ -n "$IP" ] && ACTIVE_DOMAIN="$IP"
    fi
    
    # Generate graphical RAM progress bar (8 blocks max)
    FILLED=$((RAM_PCT * 8 / 100))
    EMPTY=$((8 - FILLED))
    BAR=""
    for ((i=0; i<FILLED; i++)); do BAR="${BAR}█"; done
    for ((i=0; i<EMPTY; i++)); do BAR="${BAR}░"; done

    # Service Health Checks
    systemctl is-active --quiet xray && XRAY_STATUS="${GREEN}OK${NC}" || XRAY_STATUS="${RED}DOWN${NC}"
    systemctl is-active --quiet nginx && NGINX_STATUS="${GREEN}OK${NC}" || NGINX_STATUS="${RED}DOWN${NC}"
    systemctl is-active --quiet ssh && SSH_STATUS="${GREEN}OK${NC}" || SSH_STATUS="${RED}DOWN${NC}"

    # Active Account Stats (Xray + System SSH Users)
    CONFIG_FILE="/usr/local/etc/xray/config.json"
    [ ! -f "$CONFIG_FILE" ] && CONFIG_FILE="/etc/xray/config.json"
    
    VMESS_COUNT=$(jq '[.inbounds[] | select(.protocol=="vmess").settings.clients[]?] | length' "$CONFIG_FILE" 2>/dev/null || echo 0)
    VLESS_COUNT=$(jq '[.inbounds[] | select(.protocol=="vless").settings.clients[]?] | length' "$CONFIG_FILE" 2>/dev/null || echo 0)
    TROJAN_COUNT=$(jq '[.inbounds[] | select(.protocol=="trojan").settings.clients[]?] | length' "$CONFIG_FILE" 2>/dev/null || echo 0)
    
    # Count regular human login users (UID 1000+) as active SSH accounts
    SSH_COUNT=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)

    # --- MODULAR BOXED LAYOUT WITH DOMAIN & SSH STATS ---
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│          ${YELLOW}VPN SERVER MANAGEMENT PLATFORM V2.5${CYAN}            │${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Host   : ${GREEN}$HOST_IP${NC}"
    echo -e "${CYAN}│${NC} Domain : ${GREEN}$ACTIVE_DOMAIN${NC}"
    echo -e "${CYAN}│${NC} Up     : ${GREEN}$UPTIME${NC}"
    echo -e "${CYAN}│${NC} RAM    : [${GREEN}${BAR}${NC}] ${YELLOW}${RAM_PCT}%${NC} (${RAM_USED}MB/${RAM_TOTAL}MB)"
    echo -e "${CYAN}│${NC} SVC    : Xray:[$XRAY_STATUS] Nginx:[$NGINX_STATUS] SSH:[$SSH_STATUS]"
    echo -e "${CYAN}│${NC} 📊 Active -> SSH:${YELLOW}$SSH_COUNT${NC} VMess:${YELLOW}$VMESS_COUNT${NC} VLESS:${YELLOW}$VLESS_COUNT${NC} Trojan:${YELLOW}$TROJAN_COUNT${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Segment 1: Protocol Management Box
    echo -e "${BLUE}┌─ PROTOCOL MANAGEMENT ───────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}  [01] ${CYAN}SSH Manager${NC}"
    echo -e "${BLUE}│${NC}  [02] ${CYAN}VMess Manager${NC}     ${GRAY}(TLS / Non-TLS)${NC}"
    echo -e "${BLUE}│${NC}  [03] ${CYAN}VLESS Manager${NC}     ${GRAY}(TLS / Non-TLS / XHTTP)${NC}"
    echo -e "${BLUE}│${NC}  [04] ${CYAN}Trojan Manager${NC}    ${GRAY}(Secure Proxy)${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""

    # Segment 2: Server & Automation Box
    echo -e "${BLUE}┌─ SERVER & AUTOMATION ───────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}  [05] ${CYAN}Settings & Optimization${NC}"
    echo -e "${BLUE}│${NC}  [06] ${CYAN}Backup/Restore via Telegram${NC}"
    echo -e "${BLUE}│${NC}  [07] ${CYAN}Domain & SSL Manager${NC}"
    echo -e "${BLUE}│${NC}  [08] ${GREEN}Purge Expired Accounts${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""

    # Segment 3: Diagnostics & Tools Box
    echo -e "${BLUE}┌─ DIAGNOSTICS & TOOLS ───────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}  [09] ${YELLOW}Check Running Services${NC}"
    echo -e "${BLUE}│${NC}  [10] ${YELLOW}Run Server Speed Test${NC}"
    echo -e "${BLUE}│${NC}  [11] ${YELLOW}Quick Restart Xray & Nginx${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""

    # Exit Box
    echo -e "${RED}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${RED}│${NC}  [00] ${RED}Exit Dashboard${NC}"
    echo -e "${RED}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    read -p "Select an option [00-11]: " choice

    case $choice in
        1|01)  /root/oma/modules/ssh_manager.sh ;;
        2|02)  /root/oma/modules/vmess_manager.sh ;;
        3|03)  /root/oma/modules/vless_manager.sh ;;
        4|04)  /root/oma/modules/trojan_manager.sh ;;
        5|05)  /root/oma/modules/settings.sh ;;
        6|06)  /root/oma/modules/backup.sh ;;
        7|07)  
            if [ -f /root/oma/modules/domain_ssl.sh ]; then
                /root/oma/modules/domain_ssl.sh
            else
                echo -e "${RED}[ERROR] domain_ssl.sh module not found!${NC}"
                sleep 2
            fi
            ;;
        8|08)
            clear
            echo -e "${CYAN}==========================================${NC}"
            echo -e "       PURGING EXPIRED ACCOUNTS           "
            echo -e "${CYAN}==========================================${NC}"
            if [ -f /root/oma/modules/auto_cleanup.sh ]; then
                /root/oma/modules/auto_cleanup.sh
            fi
            echo ""
            echo -e "${GREEN}[✓] Cleanup process complete!${NC}"
            echo -e "Check full logs at: ${YELLOW}/var/log/vpn_cleanup.log${NC}"
            read -p "Press Enter to return..."
            ;;
        9|09)  
            if [ -f /root/oma/modules/status.sh ]; then
                /root/oma/modules/status.sh
            else
                echo -e "${RED}[ERROR] status.sh module not found at /root/oma/modules/${NC}"
                sleep 2
            fi
            ;;
        10)    
            if [ -f /root/oma/modules/speedtest.sh ]; then
                /root/oma/modules/speedtest.sh
            else
                echo -e "${RED}[ERROR] speedtest.sh module not found!${NC}"
                sleep 2
            fi
            ;;
        11)
            systemctl restart xray nginx
            echo -e "${GREEN}[✓] Xray & Nginx Restarted Successfully!${NC}"
            sleep 1.5
            ;;
        0|00)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option!${NC}"
            sleep 1
            ;;
    esac
done
