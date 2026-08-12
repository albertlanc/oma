#!/bin/bash
echo "[INFO] Starting VPN Platform Installation..."

# 1. Make sure the main menu and all module scripts are fully executable
chmod +x menu.sh 2>/dev/null
chmod +x modules/*.sh 2>/dev/null

# 2. Verify domain configuration
if [ ! -f /etc/xray/domain ]; then
    echo "[ERROR] Domain configuration file not found in /etc/xray/domain!"
    exit 1
fi
DOMAIN=$(cat /etc/xray/domain)
echo "[INFO] Configured Domain: $DOMAIN"

# 3. Install base system dependencies (Added dropbear, fail2ban, ufw)
echo "[INFO] Installing required core packages..."
apt-get update -y
apt-get install -y curl wget jq git nginx certbot dropbear fail2ban ufw

# 4. System Optimization & Security
echo "[INFO] Syncing system time (Required for VMess)..."
timedatectl set-ntp true
timedatectl set-timezone UTC

echo "[INFO] Enabling TCP BBR for faster VPN speeds..."
cat <<EOF >> /etc/sysctl.conf
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
sysctl -p > /dev/null 2>&1

echo "[INFO] Configuring basic UFW firewall rules..."
ufw allow ssh > /dev/null 2>&1
ufw allow 80/tcp > /dev/null 2>&1
ufw allow 443/tcp > /dev/null 2>&1
ufw allow 53/udp > /dev/null 2>&1
echo "y" | ufw enable > /dev/null 2>&1

# 5. Install X-ray Core Binary & Systemd Service
echo "[INFO] Installing X-ray Core..."
bash -c "$(curl -L -s https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
systemctl daemon-reload
systemctl enable xray --quiet
systemctl start xray

# 6. Run Xray and Nginx setup module if it exists
if [ -f "modules/setup_xray_nginx.sh" ]; then
    echo "[INFO] Executing Xray & Nginx setup..."
    bash modules/setup_xray_nginx.sh
fi

# 7. Install Modern Go 1.21 (Ensures SlowDNS module compiles correctly)
echo "[INFO] Installing Go 1.21 for SlowDNS compilation..."
wget -q https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
rm go1.21.0.linux-amd64.tar.gz

# 8. Run the updated SlowDNS installation and key generation module
echo "[INFO] Setting up SlowDNS and generating cryptographic keys..."
if [ -f "modules/install_slowdns.sh" ]; then
    bash modules/install_slowdns.sh
else
    echo "[ERROR] modules/install_slowdns.sh is missing from your repository!"
fi

# 9. Issue or verify SSL Certificate using Certbot
echo "[INFO] Securing domain with SSL..."
if [ -f "modules/issue_ssl.sh" ]; then
    bash modules/issue_ssl.sh
else
    systemctl stop nginx
    certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email
    systemctl start nginx
fi

# 10. Install global menu shortcut to both standard paths
if [ -f "menu.sh" ]; then
    cp -f menu.sh /usr/local/bin/menu
    cp -f menu.sh /usr/bin/menu
    chmod +x /usr/local/bin/menu /usr/bin/menu
    echo "[INFO] Global 'menu' shortcut installed successfully."
fi

# 11. Restart all core backend services
echo "[INFO] Restarting all backend services..."
systemctl daemon-reload
systemctl restart xray nginx slowdns dropbear fail2ban 2>/dev/null

echo "--------------------------------------------------"
echo " INSTALL COMPLETE! Type 'menu' to access the panel. "
echo "--------------------------------------------------"
