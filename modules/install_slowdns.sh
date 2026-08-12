#!/bin/bash

echo "[INFO] Installing modern Go..."
# Remove the old apt version
apt-get remove -y golang-go golang-src golang-doc
# Download and install modern Go 1.21
wget -q -O /tmp/go.tar.gz https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tar.gz
export PATH=$PATH:/usr/local/go/bin

echo "[INFO] Building dnstt-server..."
# Remove old repo if it exists, then clone fresh
rm -rf /root/dnstt
git clone https://www.bamsoftware.com/git/dnstt.git /root/dnstt
cd /root/dnstt/dnstt-server
/usr/local/go/bin/go build
cp dnstt-server /usr/local/bin/
chmod +x /usr/local/bin/dnstt-server

echo "[INFO] Generating cryptographic keys..."
mkdir -p /etc/slowdns
cd /etc/slowdns
/usr/local/bin/dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub

echo "[INFO] Configuring systemd service..."
# Fetch the NS Domain saved during initial setup
NS_DOMAIN=$(cat /etc/xray/nsdomain)

# Ensure EOF is properly closed
cat << EOF > /etc/systemd/system/slowdns.service
[Unit]
Description=SlowDNS Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/dnstt-server -udp :5300 -privkey-file /etc/slowdns/server.key 127.0.0.1:22 $NS_DOMAIN
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable slowdns
systemctl start slowdns

echo "[INFO] SlowDNS Installation Complete!"
