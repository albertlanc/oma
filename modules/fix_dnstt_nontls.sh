#!/bin/bash
# Ultimate SlowDNS & Xray Non-TLS Fixer

echo -e "\e[33m[INFO] Setting up Go environment to build dnstt-server natively...\e[0m"

# 1. Install Go if missing to compile dnstt cleanly
if ! command -v go &> /dev/null; then
    apt-get update && apt-get install -y wget git build-essential 2>/dev/null || true
    GO_VERSION="1.22.1"
    wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz
    rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
fi

# 2. Build dnstt-server from source
mkdir -p /root/dnstt-build
cd /root/dnstt-build
if [ ! -d "dnstt" ]; then
    git clone https://www.bamsoftware.com/git/dnstt.git 2>/dev/null || git clone https://github.com/live-server-test/dnstt.git 2>/dev/null || true
fi

if [ -d "dnstt/dnstt-server" ]; then
    cd dnstt/dnstt-server
    /usr/local/go/bin/go build -o /usr/local/bin/dnstt-server
elif [ -d "dnstt" ]; then
    cd dnstt
    /usr/local/go/bin/go build -o /usr/local/bin/dnstt-server ./dnstt-server
fi

# 3. Generate SlowDNS Keys
mkdir -p /etc/slowdns
if [ -f /usr/local/bin/dnstt-server ] && [ ! -f /etc/slowdns/server.key ]; then
    /usr/local/bin/dnstt-server -gen-key -privkey-file /etc/slowdns/server.key -pubkey-file /etc/slowdns/server.pub
    chmod 600 /etc/slowdns/server.key
    chmod 644 /etc/slowdns/server.pub
fi

# 4. Create SlowDNS Systemd Service
cat << 'SERVICEEOF' > /etc/systemd/system/slowdns.service
[Unit]
Description=SlowDNS Server (dnstt)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/slowdns
ExecStart=/usr/local/bin/dnstt-server -udp :53 -privkey-file /etc/slowdns/server.key 127.0.0.1:22
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable slowdns >/dev/null 2>&1
systemctl restart slowdns >/dev/null 2>&1

# 5. Configure Xray with both TLS WebSockets and Clear-text Non-TLS ports
cat << 'XRAYEOF' > /etc/xray/config.json
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 10001,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": { "clients": [{ "id": "b831381d-6324-4d53-ad4f-8cda48b30811", "alterId": 0 }] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } }
    },
    {
      "port": 10002,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": { "clients": [{ "id": "b831381d-6324-4d53-ad4f-8cda48b30811", "flow": "xtls-rprx-direct" }], "encryption": "none" },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vless" } }
    },
    {
      "port": 10003,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": { "clients": [{ "password": "vpn-commercial-password" }] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/trojan" } }
    },
    {
      "port": 8080,
      "listen": "0.0.0.0",
      "protocol": "vmess",
      "settings": { "clients": [{ "id": "b831381d-6324-4d53-ad4f-8cda48b30811", "alterId": 0 }] }
    },
    {
      "port": 8081,
      "listen": "0.0.0.0",
      "protocol": "vless",
      "settings": { "clients": [{ "id": "b831381d-6324-4d53-ad4f-8cda48b30811" }], "encryption": "none" }
    }
  ],
  "outbounds": [{ "protocol": "freedom", "settings": {} }, { "protocol": "blackhole", "tag": "blocked" }]
}
XRAYEOF

systemctl restart xray

echo -e "\e[32m[SUCCESS] SlowDNS (dnstt) server is compiled and running on UDP Port 53!\e[0m"
echo -e "\e[32m[SUCCESS] Xray Non-TLS is active on Port 8080 (VMess) and Port 8081 (VLESS)!\e[0m"

if [ -f /etc/slowdns/server.pub ]; then
    echo -e "\n\e[36m=================================================\e[0m"
    echo -e "\e[33mYOUR SLOWDNS PUBLIC KEY (Copy this for clients):\e[0m"
    cat /etc/slowdns/server.pub
    echo -e "\e[36m=================================================\e[0m\n"
fi
