#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# 0. Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Please run this script as root (sudo bash install.sh)."
    exit 1
fi

echo "[INFO] Starting VPN Platform Installation..."

# 1. Add temporary swap if RAM is low
if [ ! -f /swapfile ] && [ $(free -m | awk '/Mem:/ {print $2}') -lt 1500 ]; then
    echo "[INFO] Low RAM detected. Creating temporary swap space..."
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
fi

# 2. Make sure all module scripts are fully executable
chmod +x modules/*.sh 2>/dev/null

# 3. Clean and handle Domain Configuration robustly
mkdir -p /etc/xray
if [ -n "$1" ]; then
    echo "$1" > /etc/xray/domain
    echo "[INFO] Domain overwritten via argument: $1"
else
    echo "--------------------------------------------------"
    echo "       DOMAIN & NAMESERVER CONFIGURATION          "
    echo "--------------------------------------------------"
    read -p "Enter your main domain (e.g., vpn.yourdomain.com): " INPUT_DOMAIN
    if [ -z "$INPUT_DOMAIN" ]; then
        INPUT_DOMAIN="139.162.147.133"
        echo "[WARNING] No domain entered. Falling back to server IP: $INPUT_DOMAIN"
    fi
    echo "$INPUT_DOMAIN" > /etc/xray/domain
fi
DOMAIN=$(cat /etc/xray/domain)
echo "[INFO] Configured Active Domain: $DOMAIN"

if [ -n "$2" ]; then
    echo "$2" > /etc/xray/ns-domain
fi

# 4. Write a clean, modern, fully compatible X-ray JSON config
cat << "EOF" > /etc/xray/config.json
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 10001,
            "listen": "127.0.0.1",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "b831381d-6324-4d53-ad4f-8cda48b30811"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/vmess"
                }
            }
        },
        {
            "port": 10002,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "b831381d-6324-4d53-ad4f-8cda48b30811",
                        "flow": "xtls-rprx-direct"
                    }
                ],
                "encryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/vless"
                }
            }
        },
        {
            "port": 10003,
            "listen": "127.0.0.1",
            "protocol": "trojan",
            "settings": {
                "clients": [
                    {
                        "password": "vpn-commercial-password"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/trojan"
                }
            }
        }
    ]
}
EOF

# 5. Install base dependencies, Stunnel, and official X-ray core binary
echo "[INFO] Installing required core packages & Stunnel..."
apt-get update -y
apt-get install -y curl wget jq git nginx certbot ufw python3 iptables stunnel4

if ! command -v xray &> /dev/null; then
    echo "[INFO] Installing official X-ray core..."
    bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) install
fi

# 6. Configure UFW firewall rules
echo "[INFO] Configuring firewall rules..."
ufw allow 22/tcp 2>/dev/null
ufw allow 80/tcp 2>/dev/null
ufw allow 443/tcp 2>/dev/null
ufw allow 8080/tcp 2>/dev/null
ufw allow 53/udp 2>/dev/null
ufw --force enable 2>/dev/null

# 7. Apply master Nginx reverse proxy configuration
echo "[INFO] Applying master Nginx reverse proxy configuration..."
cat << "EOF" > /etc/nginx/conf.d/master_vpn.conf
server {
    listen 80;
    listen [::]:80;
    listen 8080;
    listen [::]:8080;
    server_name _;

    location /vmess {
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
    location /vless {
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
    location /trojan {
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
    location / {
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    server_name _;

    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location = /ssh-ws {
        proxy_pass http://127.0.0.1:10015;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
    location /vmess {
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
    location /vless {
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
    location /trojan {
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
    location / {
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }
}
EOF

# 8. Install automated client management utility
echo "[INFO] Installing automated client management utility..."
cat << "EOF" > /usr/local/bin/xray-add-client
#!/usr/bin/env python3
import json, re, sys
if len(sys.argv) < 2:
    print("Usage: xray-add-client <UUID_OR_PASSWORD>")
    sys.exit(1)
new_cred = sys.argv[1]
config_path = "/etc/xray/config.json"
with open(config_path, "r") as f:
    raw = f.read()
data = json.loads(re.sub(r"//.*?\n|/\*.*?\*/", "", raw, flags=re.S))
updated = False
for ib in data.get("inbounds", []):
    proto = ib.get("protocol")
    if proto in ["vmess", "vless"]:
        clients = ib.setdefault("settings", {}).setdefault("clients", [])
        if not any(c.get("id") == new_cred for c in clients):
            clients.append({"id": new_cred})
            updated = True
    elif proto == "trojan":
        clients = ib.setdefault("settings", {}).setdefault("clients", [])
        if not any(c.get("password") == new_cred for c in clients):
            clients.append({"password": new_cred})
            updated = True
if updated:
    with open(config_path, "w") as f:
        json.dump(data, f, indent=4)
    print("SUCCESS")
else:
    print("EXISTS_OR_SKIPPED")
EOF
chmod +x /usr/local/bin/xray-add-client

# 9. Set up SlowDNS and compile dnstt-server
echo "[INFO] Setting up SlowDNS and building dnstt-server..."
systemctl stop systemd-resolved 2>/dev/null
systemctl disable systemd-resolved 2>/dev/null
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

iptables -t nat -F
iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300

rm -rf /usr/local/go /tmp/go.tar.gz /tmp/dnstt /usr/local/bin/dnstt-server
wget -O /tmp/go.tar.gz https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
tar -C /usr/local -xzf /tmp/go.tar.gz
export PATH=/usr/local/go/bin:$PATH

git clone https://www.bamsoftware.com/git/dnstt.git /tmp/dnstt
cd /tmp/dnstt/dnstt-server
/usr/local/go/bin/go build -o /usr/local/bin/dnstt-server
chmod +x /usr/local/bin/dnstt-server

mkdir -p /etc/slowdns
if [ ! -f /etc/slowdns/server.key ]; then
    /usr/local/bin/dnstt-server -gen-key -privkey-file /etc/slowdns/server.key -pubkey-file /etc/slowdns/server.key.pub
fi

cat << EOF > /etc/systemd/system/slowdns.service
[Unit]
Description=SlowDNS Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/dnstt-server -udp :5300 -privkey-file /etc/slowdns/server.key $DOMAIN 127.0.0.1:22
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable slowdns
systemctl restart slowdns

# 10. Automatically Issue SSL Certificate via Certbot
echo "[INFO] Automatically requesting and registering SSL Certificate via Certbot for $DOMAIN..."
if [ "$DOMAIN" != "139.162.147.133" ]; then
    systemctl stop nginx 2>/dev/null
    certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email 2>/dev/null
    
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        ln -sf /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/xray/xray.crt
        ln -sf /etc/letsencrypt/live/$DOMAIN/privkey.pem /etc/xray/xray.key
    else
        openssl req -x509 -nodes -days 365 -newkey rsa:2056 -keyout /etc/xray/xray.key -out /etc/xray/xray.crt -subj "/CN=$DOMAIN" 2>/dev/null
    fi
    systemctl start nginx 2>/dev/null
else
    openssl req -x509 -nodes -days 365 -newkey rsa:2056 -keyout /etc/xray/xray.key -out /etc/xray/xray.crt -subj "/CN=$DOMAIN" 2>/dev/null
fi

# 11. Install global menu shortcut
if [ -f "menu.sh" ]; then
    cp -f menu.sh /usr/local/bin/menu
    cp -f menu.sh /usr/bin/menu
    chmod +x /usr/local/bin/menu /usr/bin/menu
    echo "[INFO] Global 'menu' shortcut installed successfully."
fi

# 12. Test configuration syntax and start all services cleanly
echo "[INFO] Enabling and restarting all backend services..."
xray run -test -config /etc/xray/config.json
systemctl enable nginx xray slowdns stunnel4 2>/dev/null
nginx -t && systemctl restart nginx xray slowdns stunnel4 2>/dev/null

echo "--------------------------------------------------"
echo " INSTALL & SSL REGISTRATION COMPLETE!             "
echo " Type 'menu' to access your panel dashboard.       "
echo "--------------------------------------------------"
echo -e "\nSlowDNS status:"
systemctl is-active slowdns
echo -e "\nYOUR SLOWDNS PUBLIC KEY:"
cat /etc/slowdns/server.key.pub
echo -e "--------------------------------------------------\n"
