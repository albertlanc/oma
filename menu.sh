#!/bin/bash

while true; do
    clear
    echo "=================================================="
    echo "       VPN SERVER MANAGEMENT PLATFORM V2.5        "
    echo "=================================================="
    echo "  [1]  SSH & OpenVPN Manager"
    echo "  [2]  VMess Manager"
    echo "  [3]  VLESS Manager"
    echo "  [4]  Trojan Manager"
    echo "  [5]  Shadowsocks Manager"
    echo "  [6]  SlowDNS Manager"
    echo "  [7]  System Status & Monitoring"
    echo "  [8]  Bandwidth & User Usage"
    echo "  [9]  Domain & SSL Management"
    echo "  [10] Telegram Bot & Backup Settings"
    echo "  [11] Server Security & Anti-Abuse"
    echo "  [12] Purge Expired Accounts"
    echo "  [0]  Exit"
    echo "=================================================="
    read -p "Select an option [0-12]: " choice

    case $choice in
        1|01)  /root/vpn-management-platform/modules/ssh_manager.sh ;;
        2|02)  /root/vpn-management-platform/modules/vmess_manager.sh ;;
        3|03)  /root/vpn-management-platform/modules/vless_manager.sh ;;
        4|04)  /root/vpn-management-platform/modules/trojan_manager.sh ;;
        5|05)  /root/vpn-management-platform/modules/shadowsocks_manager.sh ;;
        6|06)  /root/vpn-management-platform/modules/slowdns_manager.sh ;;
        7|07)  /root/vpn-management-platform/modules/status.sh ;;
        8|08)  /root/vpn-management-platform/modules/usage.sh ;;
        9|09)  /root/vpn-management-platform/modules/domain_ssl.sh ;;
        10)    /root/vpn-management-platform/modules/backup.sh ;;
        11)    /root/vpn-management-platform/modules/security.sh ;;
        12)
            clear
            echo "=========================================="
            echo "       PURGING EXPIRED ACCOUNTS           "
            echo "=========================================="
            /root/vpn-management-platform/modules/auto_cleanup.sh
            echo ""
            echo -e "\e[32m[✓] Cleanup process complete!\e[0m"
            echo -e "Check full logs at: \e[33m/var/log/vpn_cleanup.log\e[0m"
            read -p "Press Enter to return..."
            ;;
        0|00)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo -e "\e[31mInvalid option!\e[0m"
            sleep 1
            ;;
    esac
done
