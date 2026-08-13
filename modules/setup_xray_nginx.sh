#!/bin/bash
# Master Xray & Nginx Routing Deployer

DOMAIN_CONF="/opt/vpn_platform/domain.conf"
if [ -f "$DOMAIN_CONF" ]; then
    source "$DOMAIN_CONF"
else
    SERVER_DOMAIN=$(hostname -I | awk '{print $1}')
fi

echo -e "\e[33m[INFO] Configuring Xray Core for domain: ${SERVER_DOMAIN}...\e[0m"

# Ensure Xray config directory exists
mkdir -p /usr/local/etc/xray

# 1. Generate Master Xray Config (/usr/local/etc/xray/config.json)
# Using standard ports: VMess (10001), VLESS (10002), Trojan (10003)
cat << 'CONFIGEOF' > /usr/local/etc/xray/config.json
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
        "clients": []
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
        "clients": [],
        "decryption": "none"
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
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/trojan"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ]
}
CONFIGEOF

# 2. Configure Nginx Reverse Proxy for Port 443 Routing
echo -e "\e[33m[INFO] Configuring Nginx reverse proxy routes...\e[0m"
cat << NGINXEOF > /etc/nginx/conf.d/vpn_xray.conf
server {
    listen 443 ssl;
    server_name ${SERVER_DOMAIN};

    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;

    # VMess WebSocket Route
    location /vmess {
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # VLESS WebSocket Route
    location /vless {
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Trojan WebSocket Route
    location /trojan {
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
NGINXEOF

echo -e "\e[32m[INFO] Restarting Nginx and Xray services...\e[0m"
systemctl restart nginx
systemctl restart xray
echo -e "\e[32m[INFO] Setup complete successfully!\e[0m"
