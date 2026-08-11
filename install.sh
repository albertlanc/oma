#!/bin/bash
# Universal Debian/Ubuntu Installer

set -euo pipefail

echo -e "\e[32m[INFO]\e[0m Verifying Operating System..."
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        echo -e "\e[31m[ERROR]\e[0m Unsupported OS. Requires Debian or Ubuntu." >&2; exit 1;
    fi
fi

echo -e "\e[32m[INFO]\e[0m Installing base dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get install -y curl wget jq cron iptables fail2ban nginx unzip zip tar certbot sqlite3 nano

echo -e "\e[32m[INFO]\e[0m Creating directory structure..."
mkdir -p /opt/vpn_platform/modules /etc/xray /var/log/vpn_platform
chmod -R 750 /opt/vpn_platform

echo -e "\e[32m[INFO]\e[0m Installing Xray-core..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
chown -R root:root /etc/xray
chmod 600 /etc/xray/config.json

echo -e "\e[32m[SUCCESS]\e[0m Installation complete! Proceed to create the menu."
