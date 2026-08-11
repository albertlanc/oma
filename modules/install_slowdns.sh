#!/bin/bash

echo "================================================="
echo "       SLOWDNS AUTOMATED INSTALLER"
echo "================================================="
read -p "Enter your SlowDNS Nameserver (e.g., ns.yourdomain.com): " NS_DOMAIN

if [ -z "$NS_DOMAIN" ]; then
    echo "[ERROR] Nameserver domain cannot be empty!"
    exit 1
fi

echo "[INFO] Installing dependencies..."
apt-get update -y && apt-get install -y golang git build-essential

echo "[INFO] Building dnstt-server..."
mkdir -p /tmp/dnstt-build
cd /tmp/dnstt-build
git clone https://www.bamsoftware.com/git/dnstt.git 2>/dev/null || git clone https://github.com/willscott/dnstt.git
cd dnstt/dnstt-server
go build -o /usr/local/bin/dnstt-server
chmod +x /usr/local/bin/dnstt-server

echo "[INFO] Generating cryptographic keys..."
mkdir -p /etc/slowdns
if [ ! -f /etc/slowdns/server.key ]; then
    /usr/local/bin/dnstt-server -gen-key -privkey-file /etc/slowdns/server.key -pubkey-file /etc/slowdns/server.pub
fi

echo "[INFO] Configuring systemd service..."
cat << EOF > /etc/systemd/system/slowdns.service
[Unit]
Description=SlowDNS Server (dnstt)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/slowdns
ExecStart=/usr/local/bin/dnstt-server -udp :53 -privkey-file /etc/slowdns/server.key $NS_DOMAIN 127.0.0.1:109
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
