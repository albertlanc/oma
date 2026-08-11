#!/bin/bash
UPTIME=$(uptime -p | sed 's/up //')
RAM_USAGE=$(free -m | awk 'NR==2{printf "%.1f%% (%sMB/%sMB)", $3*100/$2, $3, $2}')
CONFIG_FILE="/usr/local/etc/xray/config.json"
if [ -f "$CONFIG_FILE" ] && command -v jq &> /dev/null; then
    VMESS_COUNT=$(jq '[.inbounds[] | select(.protocol=="vmess") | .settings.clients[]?] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    VLESS_COUNT=$(jq '[.inbounds[] | select(.protocol=="vless") | .settings.clients[]?] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    TROJAN_COUNT=$(jq '[.inbounds[] | select(.protocol=="trojan") | .settings.clients[]?] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
else
    VMESS_COUNT="0"; VLESS_COUNT="0"; TROJAN_COUNT="0"
fi

while true; do
    clear
    echo -e "\e[38;5;51m╔════════════════════════════════════════════════════════╗\e[0m"
    echo -e "\e[38;5;51m║\e[0m \e[1m\e[38;5;214m        VPN SERVER MANAGEMENT PLATFORM V2.5             \e[0m\e[38;5;51m║\e[0m"
    echo -e "\e[38;5;51m╚════════════════════════════════════════════════════════╝\e[0m"
    echo -e " \e[38;5;244m•\e[0m \e[1mHost:\e[0m $(hostname -I | awk '{print $1}')  \e[38;5;244m•\e[0m \e[1mUptime:\e[0m $UPTIME"
    echo -e " \e[38;5;244m•\e[0m \e[1mRAM:\e[0m  $RAM_USAGE"
    echo -e " \e[38;5;51m──────────────────────────────────────────────────────────\e[0m"
    echo -e " \e[38;5;46m📊 Active Accounts\e[0m -> VMess: \e[33m$VMESS_COUNT\e[0m | VLESS: \e[33m$VLESS_COUNT\e[0m | Trojan: \e[33m$TROJAN_COUNT\e[0m"
    echo -e " \e[38;5;51m──────────────────────────────────────────────────────────\e[0m"
    echo -e "  \e[38;5;51m[01]\e[0m \e[36mSSH Manager\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[02]\e[0m \e[36mVMess Manager\e[0m   \e[38;5;240m(TLS / Non-TLS)\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[03]\e[0m \e[36mVLESS Manager\e[0m   \e[38;5;240m(TLS / Non-TLS / XHTTP)\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[04]\e[0m \e[36mTrojan Manager\e[0m  \e[38;5;240m(Secure Proxy)\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[05]\e[0m \e[36mSettings & Optimization\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[06]\e[0m \e[36mBackup/Restore via Telegram\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[07]\e[0m \e[36mDomain & SSL Manager\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[08]\e[0m \e[36mCheck Running Services\e[0m"
    echo -e ""
    echo -e "  \e[38;5;220m[09]\e[0m \e[33mRun Server Speed Test\e[0m"
    echo -e ""
    echo -e "  \e[38;5;220m[10]\e[0m \e[33mQuick Restart Xray & Nginx\e[0m"
    echo -e ""
    echo -e "  \e[38;5;196m[00]\e[0m \e[31mExit Dashboard\e[0m"
    echo -e "\e[38;5;51m════════════════════════════════════════════════════════\e[0m"
    read -p " Select an option [00-10]: " option
    case $option in
        01|1) /root/vpn-management-platform/modules/ssh_manager.sh ;;
        02|2) /root/vpn-management-platform/modules/vmess_manager.sh ;;
        03|3) /root/vpn-management-platform/modules/vless_manager.sh ;;
        04|4) /root/vpn-management-platform/modules/trojan_manager.sh ;;
        05|5) /root/vpn-management-platform/modules/settings.sh ;;
        06|6) /root/vpn-management-platform/modules/backup.sh ;;
        07|7) /root/vpn-management-platform/modules/domain_ssl.sh ;;
        08|8) /root/vpn-management-platform/modules/check_running.sh ;;
        09|9) clear; echo -e "\e[33m[INFO] Running speed test...\e[0m"; speedtest-cli; read -p "Press Enter..." ;;
        10) clear; echo -e "\e[33m[INFO] Restarting services...\e[0m"; systemctl restart xray nginx; sleep 1.5 ;;
        00|0) clear; echo -e "\e[32mExiting...\e[0m"; exit 0 ;;
        *) echo -e "\e[31m[!] Invalid option.\e[0m"; sleep 1.5 ;;
    esac
done
