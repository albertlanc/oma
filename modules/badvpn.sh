#!/bin/bash
# BadVPN UDPGW Manager & Installer Module

while true; do
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "              BADVPN UDPGW MANAGER               "
    echo -e "\e[36m=================================================\e[0m"
    echo -e "  [01] Install & Setup BadVPN UDPGW (Port 7300)"
    echo -e "  [02] Check BadVPN Service Status"
    echo -e "  [03] Restart BadVPN Service"
    echo -e "  [04] Uninstall BadVPN"
    echo -e "  [00] Back to Main Menu"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [00-04]: " option

    case $option in
        1|01)
            clear
            echo -e "\e[33m=== INSTALLING BADVPN UDPGW ===\e[0m"
            echo -e "\e[32m[INFO] Installing compilation dependencies...\e[0m"
            apt-get update -y >/dev/null 2>&1
            apt-get install -y cmake make gcc g++ git wget unzip >/dev/null 2>&1

            echo -e "\e[32m[INFO] Downloading BadVPN source code...\e[0m"
            cd /tmp
            rm -rf badvpn-master badvpn-1.999.130*
            wget -O badvpn.tar.gz https://github.com/ambrop72/badvpn/archive/refs/tags/1.999.130.tar.gz 2>/dev/null || \
            wget -O badvpn.tar.gz https://www.bamsoftware.com/software/badvpn/badvpn-1.999.130.tar.gz 2>/dev/null || true

            if [ -f "badvpn.tar.gz" ]; then
                tar -zxf badvpn.tar.gz
                cd badvpn-1.999.130
            else
                git clone https://github.com/ambrop72/badvpn.git badvpn-master
                cd badvpn-master
            fi

            mkdir -p build
            cd build
            cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 >/dev/null 2>&1
            make install >/dev/null 2>&1
            
            # Clean up temporary build files
            cd /tmp
            rm -rf badvpn*

            echo -e "\e[32m[INFO] Creating systemd service for badvpn-udpgw...\e[0m"
            cat << 'SEREOF' > /etc/systemd/system/badvpn.service
[Unit]
Description=BadVPN UDP Gateway (UDPGW)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500 --max-connections 0
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SEREOF

            systemctl daemon-reload
            systemctl enable badvpn >/dev/null 2>&1
            systemctl restart badvpn

            if systemctl is-active --quiet badvpn; then
                echo -e "\e[32m[SUCCESS] BadVPN UDPGW successfully installed and running on port 7300!\e[0m"
            else
                echo -e "\e[31m[ERROR] BadVPN service failed to start. Check 'systemctl status badvpn'.\e[0m"
            fi
            ;;
        2|02)
            clear
            echo -e "\e[33m=== BADVPN SERVICE STATUS ===\e[0m"
            systemctl status badvpn --no-pager
            ;;
        3|03)
            clear
            echo -e "\e[33m=== RESTARTING BADVPN ===\e[0m"
            systemctl restart badvpn
            echo -e "\e[32m[SUCCESS] BadVPN service restarted.\e[0m"
            ;;
        4|04)
            clear
            echo -e "\e[33m=== UNINSTALLING BADVPN ===\e[0m"
            systemctl stop badvpn 2>/dev/null
            systemctl disable badvpn 2>/dev/null
            rm -f /etc/systemd/system/badvpn.service
            rm -f /usr/local/bin/badvpn-udpgw
            systemctl daemon-reload
            echo -e "\e[32m[SUCCESS] BadVPN has been completely removed from the system.\e[0m"
            ;;
        0|00)
            break
            ;;
        *)
            echo "Invalid option."
            sleep 1
            ;;
    esac
    read -n 1 -s -r -p "Press any key to return to BadVPN menu..."
done
