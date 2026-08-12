#!/bin/bash
# Advanced Service Health Monitor Module

while true; do
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "          ADVANCED SERVICE HEALTH MONITOR        "
    echo -e "\e[36m=================================================\e[0m"
    echo -e "  Service Name      | Status      | PID   | Memory"
    echo -e "\e[36m-------------------------------------------------\e[0m"

    check_service() {
        local service=$1
        local display_name=$2
        if systemctl is-active --quiet "$service"; then
            local pid=$(systemctl show -p MainPID --value "$service" 2>/dev/null)
            local mem=$(ps -o %mem= -p "$pid" 2>/dev/null | tr -d ' ')
            [ -z "$mem" ] && mem="0.0"
            echo -e "  $display_name \t: \e[32m[ RUNNING ]\e[0m | PID: $pid | Mem: ${mem}%"
        else
            echo -e "  $display_name \t: \e[31m[ STOPPED ]\e[0m | N/A   | N/A"
        fi
    }

    check_service "nginx" "Nginx Proxy    "
    check_service "xray" "Xray Core      "
    check_service "stunnel4" "Stunnel4       "
    check_service "dropbear" "Dropbear SSH   "
    check_service "openvpn" "OpenVPN        "
    check_service "fail2ban" "Fail2ban       "
    check_service "ufw" "UFW Firewall   "

    echo -e "\e[36m=================================================\e[0m"
    echo -e "  [1] Restart a Specific Service"
    echo -e "  [2] View Detailed Service Logs"
    echo -e "  [0] Back to Main Menu"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [0-2]: " choice

    case $choice in
        1)
            read -p "Enter service name to restart (e.g., xray, nginx, dropbear): " srv
            if systemctl list-unit-files | grep -q "^$srv"; then
                echo -e "\e[33mRestarting $srv...\e[0m"
                systemctl restart "$srv"
                echo -e "\e[32m[SUCCESS] $srv restarted.\e[0m"
            else
                echo -e "\e[31m[ERROR] Service not found or invalid.\e[0m"
            fi
            ;;
        2)
            read -p "Enter service name for logs (e.g., xray, nginx): " srv
            if systemctl list-unit-files | grep -q "^$srv"; then
                echo -e "\e[33mShowing recent logs for $srv:\e[0m"
                journalctl -u "$srv" -n 30 --no-pager
            else
                echo -e "\e[31m[ERROR] Service not found.\e[0m"
            fi
            ;;
        0) break ;;
        *) echo "Invalid choice."; sleep 1 ;;
    esac
    read -n 1 -s -r -p "Press any key to continue..."
done
