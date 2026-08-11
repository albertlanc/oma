#!/bin/bash

# Ensure script is run as root
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
apt-get install -y curl wget jq nginx certbot

echo "[INFO] Installing official Xray core..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

echo "[INFO] Obtaining SSL Certificate via Certbot..."
systemctl stop nginx
certbot certonly --standalone --agree-tos --register-unsafely-without-email -d "$DOMAIN" --non-interactive || {
  echo "[ERROR] Certbot failed to obtain an SSL certificate. Make sure your domain's DNS A record points to this server's IP address!"
  exit 1
}

echo "[INFO] Deploying base Xray configuration..."
mkdir -p /usr/local/etc/xray
cat << XRAYCONF > /usr/local/etc/xray/config.json
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
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10004;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /vless-ntls {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10005;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /xhttp {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10006;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location /vmess {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /vless {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /trojan {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
NGINXCONF

echo "[INFO] Updating domain variable dynamically across module files..."
find /root/vpn-management-platform/modules/ -type f -exec sed -i "s/vps.gregsmarty.co.uk/$DOMAIN/g" {} +

echo "[INFO] Installing global 'menu' shortcut..."
cat << 'MENUEXEC' > /usr/local/bin/menu
#!/bin/bash
# Main VPN Dashboard Menu
while true; do
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "          VPN SERVER MANAGEMENT PLATFORM         "
    echo -e "\e[36m=================================================\e[0m"
    echo -e "  [01] SSH Manager"
    echo -e "  [02] VMess Manager"
    echo -e "  [03] VLESS Manager"
    echo -e "  [04] Trojan Manager"
    echo -e "  [05] Settings & Optimization"
    echo -e "  [06] Backup/Restore via Telegram"
    echo -e "  [07] Domain & SSL Manager"
    echo -e "  [08] Check Running Services"
    echo -e "  [00] Exit"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [00-08]: " option
    case $option in
        01|1) /root/vpn-management-platform/modules/ssh_manager.sh ;;
        02|2) /root/vpn-management-platform/modules/vmess_manager.sh ;;
        03|3) /root/vpn-management-platform/modules/vless_manager.sh ;;
        04|4) /root/vpn-management-platform/modules/trojan_manager.sh ;;
        05|5) /root/vpn-management-platform/modules/settings.sh ;;
        06|6) /root/vpn-management-platform/modules/backup.sh ;;
        07|7) /root/vpn-management-platform/modules/domain_ssl.sh ;;
        08|8) /root/vpn-management-platform/modules/check_running.sh ;;
        00|0) clear; echo "Exiting Dashboard..."; exit 0 ;;
        *) echo "Invalid option. Please try again."; sleep 2 ;;
    esac
done
MENUEXEC

chmod +x /usr/local/bin/menu
chmod -R +x /root/vpn-management-platform/modules/

echo "[INFO] Restarting and enabling services..."
systemctl daemon-reload
systemctl enable xray nginx
systemctl restart xray nginx

echo ""
echo "=========================================="
echo "      INSTALLATION COMPLETED SUCCESSFULLY! "
echo "=========================================="
echo " Type 'menu' anywhere in your terminal"
echo " to open your VPN management platform."
echo "=========================================="
