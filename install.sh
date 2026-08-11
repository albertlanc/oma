#!/bin/bash
# Master Commercial VPN Platform Installer
# Supports all versions of Ubuntu (18.04 - 24.04) and Debian (10 - 12+)

export DEBIAN_FRONTEND=noninteractive

clear
echo -e "\e[36m=================================================\e[0m"
echo -e "       COMMERCIAL VPN PLATFORM INSTALLER         "
echo -e "\e[36m=================================================\e[0m"

# 1. Wait for any active apt/dpkg locks to clear
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo -e "\e[33m[INFO] Waiting for background system updates to finish...\e[0m"
    sleep 3
done

# 2. Update package repositories safely
echo -e "\e[33m[INFO] Updating system package lists...\e[0m"
apt-get update -y || apt-get --fix-missing update -y

# 3. Install core dependencies safely across versions
PACKAGES=(nginx dropbear stunnel4 openvpn fail2ban wget curl ufw socat net-tools iptables dnsutils)
echo -e "\e[33m[INFO] Installing core services...\e[0m"
for pkg in "${PACKAGES[@]}"; do
    if dpkg -l | grep -qw "$pkg"; then
        echo -e "  - [$pkg] : \e[32mAlready Installed\e[0m"
    else
        echo -e "  - Installing [$pkg]..."
        apt-get install -y "$pkg" || {
            dpkg --configure -a
            apt-get install -f -y
            apt-get install -y "$pkg"
        }
    fi
done

# 4. Install Xray Core universally
if ! command -v xray &> /dev/null; then
    echo -e "\e[33m[INFO] Installing Xray Core...\e[0m"
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
fi

# 5. Apply SlowDNS Immunization (Fixes Port 53 / systemd-resolved / Vultr / UpCloud issues)
echo -e "\e[33m[INFO] Immunizing SlowDNS (dnstt) environment...\e[0m"
if systemctl list-unit-files | grep -q "systemd-resolved.service"; then
    systemctl stop systemd-resolved 2>/dev/null || true
    systemctl disable systemd-resolved 2>/dev/null || true
    if [ -f /etc/systemd/resolved.conf ]; then
        sed -i 's/#DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
        sed -i 's/DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
    fi
    rm -f /etc/resolv.conf
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
fi

# Open necessary ports in Firewall
if command -v ufw &> /dev/null; then
    ufw allow 53/udp >/dev/null 2>&1
    ufw allow 53/tcp >/dev/null 2>&1
    ufw allow 443/tcp >/dev/null 2>&1
    ufw allow 444/tcp >/dev/null 2>&1
    ufw allow 22/tcp >/dev/null 2>&1
    ufw reload >/dev/null 2>&1
fi

iptables -I INPUT -p udp --dport 53 -j ACCEPT
iptables -I INPUT -p tcp --dport 53 -j ACCEPT

# 6. Configure Stunnel4 (Port 444) & Dropbear (Port 109)
echo -e "\e[33m[INFO] Configuring Stunnel4 and Dropbear services...\e[0m"
mkdir -p /etc/stunnel /var/run/stunnel4 /var/log/stunnel4

if [ ! -f /etc/stunnel/stunnel.pem ]; then
    openssl req -new -x509 -days 365 -nodes \
        -out /etc/stunnel/stunnel.pem \
        -keyout /etc/stunnel/stunnel.pem \
        -subj "/CN=localhost" 2>/dev/null
    chmod 600 /etc/stunnel/stunnel.pem
fi

cat << 'STUNNEL_EOF' > /etc/stunnel/stunnel.conf
pid = /var/run/stunnel4/stunnel4.pid
output = /var/log/stunnel4/stunnel.log
cert = /etc/stunnel/stunnel.pem

[dropbear-ssl]
accept = 444
connect = 127.0.0.1:109
STUNNEL_EOF

chown -R stunnel4:stunnel4 /var/run/stunnel4 /var/log/stunnel4 2>/dev/null || true

if [ -f /etc/default/dropbear ]; then
    sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
    sed -i 's/DROPBEAR_PORT=.*/DROPBEAR_PORT=109/g' /etc/default/dropbear
fi

# 7. Configure Xray Core & Nginx Reverse Proxy (Port 443)
echo -e "\e[33m[INFO] Deploying Xray and Nginx routing templates...\e[0m"
mkdir -p /etc/xray

if [ ! -f /etc/xray/xray.crt ]; then
    openssl req -new -x509 -days 365 -nodes \
        -out /etc/xray/xray.crt \
        -keyout /etc/xray/xray.key \
        -subj "/CN=localhost" 2>/dev/null
    chmod 600 /etc/xray/xray.key
    chmod 644 /etc/xray/xray.crt
fi

cat << 'XRAY_EOF' > /etc/xray/config.json
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
    }
  ],
  "outbounds": [{ "protocol": "freedom", "settings": {} }, { "protocol": "blackhole", "tag": "blocked" }]
}
XRAY_EOF

cat << 'NGINX_EOF' > /etc/nginx/conf.d/vpn_xray.conf
server {
    listen 443 ssl;
    server_name _;

    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;

    location /vmess {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /vless {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /trojan {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX_EOF

# 8. Enable and Start All Services Cleanly
SERVICES=(nginx xray stunnel4 dropbear openvpn fail2ban ufw)
for srv in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^$srv.service"; then
        systemctl enable "$srv" >/dev/null 2>&1
        systemctl restart "$srv" >/dev/null 2>&1 || true
    fi
done

mkdir -p /opt/vpn_platform

echo -e "\e[36m=================================================\e[0m"
echo -e "\e[32m       INSTALLATION & ROUTING COMPLETE           \e[0m"
echo -e "\e[36m=================================================\e[0m"
