#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] Please run this script as root (sudo -i)."
  exit 1
fi

clear
echo "=========================================="
echo "    VPN MANAGEMENT PLATFORM INSTALLER     "
echo "=========================================="
read -p "Enter your Domain Name (e.g., vps.yourdomain.com): " DOMAIN
read -p "Enter your Email Address (for SSL registration): " EMAIL

if [ -z "$DOMAIN" ]; then
  echo "[ERROR] Domain name cannot be empty!"
  exit 1
fi

echo "[INFO] Updating package lists and installing dependencies..."
apt-get update -y
apt-get install -y curl wget jq nginx certbot speedtest-cli

echo "[INFO] Installing official Xray core..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

echo "[INFO] Obtaining SSL Certificate via Certbot..."
systemctl stop nginx
certbot certonly --standalone --agree-tos --register-unsafely-without-email -d "$DOMAIN" --non-interactive || {
  echo "[ERROR] Certbot failed to obtain an SSL certificate."
  exit 1
}

echo "[INFO] Deploying base Xray configuration..."
mkdir -p /usr/local/etc/xray
cat << 'XRAYCONF' > /usr/local/etc/xray/config.json
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 10001, "listen": "127.0.0.1", "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } }
    },
    {
      "port": 10002, "listen": "127.0.0.1", "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vless" } }
    },
    {
      "port": 10003, "listen": "127.0.0.1", "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/trojan" } }
    },
    {
      "port": 10004, "listen": "127.0.0.1", "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess-ntls" } }
    },
    {
      "port": 10005, "listen": "127.0.0.1", "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vless-ntls" } }
    },
    {
      "port": 10006, "listen": "127.0.0.1", "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": { "network": "xhttp", "xhttpSettings": { "path": "/xhttp" } }
    }
  ],
  "outbounds": [{ "protocol": "freedom", "settings": {} }]
}
XRAYCONF

echo "[INFO] Deploying Nginx reverse proxy configuration..."
cat << NGINXCONF > /etc/nginx/conf.d/vpn_xray.conf
server {
    listen 80;
    server_name $DOMAIN;
    location /vmess-ntls {
        proxy_redirect off; proxy_pass http://127.0.0.1:10004; proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    location /vless-ntls {
        proxy_redirect off; proxy_pass http://127.0.0.1:10005; proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    location /xhttp {
        proxy_redirect off; proxy_pass http://127.0.0.1:10006; proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    location /vmess {
        proxy_redirect off; proxy_pass http://127.0.0.1:10001; proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    location /vless {
        proxy_redirect off; proxy_pass http://127.0.0.1:10002; proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    location /trojan {
        proxy_redirect off; proxy_pass http://127.0.0.1:10003; proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
NGINXCONF

echo "[INFO] Updating domain variable across module files..."
if [ -d "/root/vpn-management-platform/modules" ]; then
  find /root/vpn-management-platform/modules/ -type f -exec sed -i "s/vps.gregsmarty.co.uk/$DOMAIN/g" {} +
fi

echo "[INFO] Installing global 'menu' shortcut from repository..."
if [ -f "/root/vpn-management-platform/menu.sh" ]; then
  cp /root/vpn-management-platform/menu.sh /usr/local/bin/menu
else
  echo "[ERROR] menu.sh not found in repository!"
  exit 1
fi

chmod +x /usr/local/bin/menu

echo "[INFO] Restarting services..."
systemctl daemon-reload
systemctl enable xray nginx
systemctl restart xray nginx
echo "INSTALL COMPLETE!"
