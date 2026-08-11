#!/bin/bash
# Check Running Services Module

clear
echo -e "\e[36m=================================================\e[0m"
echo -e "             SERVICE HEALTH MONITOR              "
echo -e "\e[36m=================================================\e[0m"

check_status() {
    local service=$1
    local name=$2
    if systemctl is-active --quiet "$service"; then
        echo -e "  $name \t: \e[32m[ RUNNING ]\e[0m"
    else
        echo -e "  $name \t: \e[31m[ OFF / STOPPED ]\e[0m"
    fi
}

check_status "nginx" "Nginx Multiplexer "
check_status "xray" "Xray Core         "
check_status "stunnel4" "Stunnel4          "
check_status "dropbear" "Dropbear SSH      "
check_status "openvpn" "OpenVPN           "

echo -e "\e[36m=================================================\e[0m"
read -n 1 -s -r -p "Press any key to return to menu..."
