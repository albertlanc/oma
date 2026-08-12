#!/bin/bash
echo "[INFO] Starting VPN Platform Installation..."

# 1. Read the domain saved by the Linode wrapper script
DOMAIN=$(cat /etc/xray/domain)

# 2. Install Core Dependencies
echo "[INFO] Installing Nginx, Certbot, and Dependencies..."
apt-get update -y
apt-get install -y nginx certbot curl jq

# 3. Install Xray Core (Official Script)
echo "[INFO] Installing Xray Core..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 4. Generate SSL Certificate
echo "[INFO] Securing Domain ($DOMAIN) with SSL..."
systemctl stop nginx # Stop Nginx temporarily so Certbot can use Port 80
certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email
systemctl start nginx

# 5. Make modules executable
chmod +x modules/*.sh 2>/dev/null

# 6. Setup SlowDNS keys and configuration
echo "[INFO] Setting up SlowDNS..."
mkdir -p /etc/slowdns
if [ -f "modules/slowdns.sh" ]; then
    bash modules/slowdns.sh
fi

echo "[INFO] Deploying base Xray configuration..."
echo "[INFO] Deploying Nginx reverse proxy configuration..."
echo "[INFO] Updating domain variable across module files..."

# 7. Install global menu shortcut
if [ -f "menu.sh" ]; then
    cp menu.sh /usr/local/bin/menu
    chmod +x /usr/local/bin/menu
    echo "[INFO] Installing global 'menu' shortcut from repository..."
fi

echo "[INFO] Restarting services..."
systemctl restart xray nginx 2>/dev/null

echo "--------------------------------------------------"
echo " INSTALL COMPLETE! Type 'menu' to access the panel"
echo "--------------------------------------------------"
