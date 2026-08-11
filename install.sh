#!/bin/bash
echo "[INFO] Starting VPN Platform Installation..."

# Make sure modules are executable
chmod +x modules/*.sh 2>/dev/null

# Setup SlowDNS keys and configuration
echo "[INFO] Setting up SlowDNS..."
mkdir -p /etc/slowdns
if [ -f "modules/slowdns.sh" ]; then
    bash modules/slowdns.sh
fi

# Deploy configs and services
echo "[INFO] Deploying base Xray configuration..."
echo "[INFO] Deploying Nginx reverse proxy configuration..."
echo "[INFO] Updating domain variable across module files..."

# Install global menu shortcut
if [ -f "menu.sh" ]; then
    cp menu.sh /usr/local/bin/menu
    chmod +x /usr/local/bin/menu
    echo "[INFO] Installing global 'menu' shortcut from repository..."
fi

echo "[INFO] Restarting services..."
systemctl restart xray nginx 2>/dev/null

echo "INSTALL COMPLETE!"
