#!/bin/bash
# Advanced Settings & System Optimization Manager

while true; do
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "             SYSTEM SETTINGS & TOOLS             "
    echo -e "\e[36m=================================================\e[0m"
    echo -e "  [01] Enable/Check TCP BBR Congestion Control"
    echo -e "  [02] OTA Git Updater (Pull Latest Platform Update)"
    echo -e "  [03] Run System Speedtest"
    echo -e "  [04] Clean RAM & Kernel Cache (Free Memory)"
    echo -e "  [05] Force NTP Time Synchronization"
    echo -e "  [06] Audit SSL/TLS Certificate Expiry"
    echo -e "  [07] Configure Secure DNS Resolvers (Cloudflare/Google)"
    echo -e "  [08] UFW Firewall Status & Port Security Audit"
    echo -e "  [09] Check/Manage Fail2ban Brute-Force Protection"
    echo -e "  [10] Create/Manage Swap Memory"
    echo -e "  [11] System Hardware & Health Dashboard"
    echo -e "  [00] Back to Main Menu"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [00-11]: " option

    case $option in
        01|1)
            echo -e "\e[33mChecking TCP BBR Status...\e[0m"
            bbr_check=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
            if [ "$bbr_check" == "bbr" ]; then
                echo -e "\e[32m[INFO] TCP BBR is already active on this system!\e[0m"
            else
                echo -e "\e[33mEnabling TCP BBR...\e[0m"
                echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
                echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
                sysctl -p &>/dev/null
                echo -e "\e[32m[SUCCESS] TCP BBR successfully enabled.\e[0m"
            fi
            ;;
        02|2)
            echo -e "\e[33mPulling latest updates from GitHub (albertlanc/oma)...\e[0m"
            cd /root/vpn-management-platform || exit
            git pull origin main
            chmod +x bin/* modules/* install.sh
            echo -e "\e[32m[SUCCESS] Platform updated successfully!\e[0m"
            ;;
        03|3)
            echo -e "\e[33mRunning network speed test...\e[0m"
            if ! command -v speedtest &> /dev/null && ! command -v speedtest-cli &> /dev/null; then
                echo -e "\e[33mInstalling speedtest-cli tool...\e[0m"
                apt-get update && apt-get install -y speedtest-cli &>/dev/null
            fi
            if command -v speedtest &> /dev/null; then
                speedtest
            else
                speedtest-cli
            fi
            ;;
        04|4)
            echo -e "\e[33mFlushing RAM cache and dentries...\e[0m"
            sync && echo 3 > /proc/sys/vm/drop_caches
            echo -e "\e[32m[SUCCESS] System cache cleared. Memory freed up.\e[0m"
            ;;
        05|5)
            echo -e "\e[33mSynchronizing system time via NTP...\e[0m"
            timedatectl set-ntp on
            systemctl restart systemd-timesyncd 2>/dev/null || true
            echo -e "\e[32m[SUCCESS] Time synchronized. Current server time: $(date)\e[0m"
            ;;
        06|6)
            echo -e "\e[33mAuditing SSL Certificates...\e[0m"
            if command -v certbot &> /dev/null; then
                certbot certificates
            else
                echo -e "\e[31m[INFO] Certbot is not installed or no certificates found via Certbot.\e[0m"
            fi
            ;;
        07|7)
            echo -e "\e[33mConfiguring secure upstream DNS (Cloudflare 1.1.1.1 & Google 8.8.8.8)...\e[0m"
            echo -e "nameserver 1.1.1.1\nnameserver 8.8.8.8" > /etc/resolv.conf
            echo -e "\e[32m[SUCCESS] DNS resolvers updated.\e[0m"
            ;;
        08|8)
            echo -e "\e[33mInspecting UFW Firewall Status...\e[0m"
            if command -v ufw &> /dev/null; then
                ufw status verbose
            else
                echo -e "\e[31m[INFO] UFW is not installed.\e[0m"
            fi
            ;;
        09|9)
            echo -e "\e[33mChecking Fail2ban status...\e[0m"
            if systemctl is-active --quiet fail2ban; then
                echo -e "\e[32m[RUNNING] Fail2ban is active and protecting services.\e[0m"
                fail2ban-client status
            else
                echo -e "\e[33mFail2ban is not active. Installing/starting...\e[0m"
                apt-get update && apt-get install -y fail2ban &>/dev/null
                systemctl enable --now fail2ban
                echo -e "\e[32m[SUCCESS] Fail2ban installed and enabled.\e[0m"
            fi
            ;;
        10|10)
            echo -e "\e[33mCurrent Swap Status:\e[0m"
            free -h | grep Swap
            read -p "Do you want to create/expand a 1GB swap file? [y/N]: " create_swap
            if [[ "$create_swap" =~ ^[Yy]$ ]]; then
                fallocate -l 1G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=1024
                chmod 600 /swapfile
                mkswap /swapfile
                swapon /swapfile
                echo '/swapfile none swap sw 0 0' >> /etc/fstab
                echo -e "\e[32m[SUCCESS] 1GB Swap space created and activated.\e[0m"
            fi
            ;;
        11|11)
            clear
            echo -e "\e[36m=================================================\e[0m"
            echo -e "           SYSTEM HARDWARE & METRICS             "
            echo -e "\e[36m=================================================\e[0m"
            echo -e "\e[33mCPU Information:\e[0m"
            lscpu | grep -E "Model name|Architecture|CPU\(s\):"
            echo -e "\n\e[33mMemory Usage:\e[0m"
            free -h
            echo -e "\n\e[33mDisk Usage:\e[0m"
            df -h /
            echo -e "\n\e[33mSystem Uptime:\e[0m"
            uptime
            echo -e "\e[36m=================================================\e[0m"
            ;;
        00|0) break ;;
    esac
    read -n 1 -s -r -p "Press any key to return to settings menu..."
done
