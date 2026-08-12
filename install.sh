#!/bin/bash
echo "[INFO] Starting VPN Platform Installation..."

# 1. Make sure all module scripts are fully executable
chmod +x modules/*.sh 2>/dev/null

# 2. Verify domain configuration
if [ ! -f /etc/xray/domain ]; then
    echo "[ERROR] Domain configuration file not found in /etc/xray/domain!"
    exit 1
fi
DOMAIN=$(cat /etc/xray/domain)
echo "[INFO] Configured Domain: $DOMAIN"

# 3. Install base system dependencies
echo "[INFO] Installing required core packages..."
apt-get update -y
apt-get install -y curl wget jq git nginx certbot

# 4. Run Xray and Nginx setup module if it exists
if [ -f "modules/setup_xray_nginx.sh" ]; then
    echo "[INFO] Executing Xray & Nginx setup..."
    bash modules/setup_xray_nginx.sh
fi

# 5. Run the updated SlowDNS installation and key generation module
echo "[INFO] Setting up SlowDNS and generating cryptographic keys..."
if [ -f "modules/install_slowdns.sh" ]; then
    bash modules/install_slowdns.sh
else
    echo "[ERROR] modules/install_slowdns.sh is missing from your repository!"
fi

# 6. Issue or verify SSL Certificate using Certbot
echo "[INFO] Securing domain with SSL..."
if [ -f "modules/issue_ssl.sh" ]; then
    bash modules/issue_ssl.sh
else
    systemctl stop nginx
    certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email
    systemctl start nginx
fi

# 7. Install global menu shortcut to both standard paths
if [ -f "menu.sh" ]; then
    cp -f menu.sh /usr/local/bin/menu
    cp -f menu.sh /usr/bin/menu
    chmod +x /usr/local/bin/menu /usr/bin/menu
    echo "[INFO] Global 'menu' shortcut installed successfully."
fi

# 8. Restart core backend services
echo "[INFO] Restarting all backend services..."
systemctl restart xray nginx slowdns 2>/dev/null

echo "--------------------------------------------------"
echo " INSTALL COMPLETE! Type 'menu' to access the panel. "
echo "--------------------------------------------------"
