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

echo "[INFO] Updating domain variable dynamically across module files..."
find /root/vpn-management-platform/modules/ -type f -exec sed -i "s/vps.gregsmarty.co.uk/$DOMAIN/g" {} +

echo "[INFO] Installing advanced V2.5 global 'menu' shortcut..."
cp /root/vpn-management-platform/menu.sh /usr/local/bin/menu
#!/bin/bash
UPTIME=\$(uptime -p | sed 's/up //')
RAM_USAGE=\$(free -m | awk 'NR==2{printf "%.1f%% (%sMB/%sMB)", \$3*100/\$2, \$3, \$2}')
CONFIG_FILE="/usr/local/etc/xray/config.json"
if [ -f "\$CONFIG_FILE" ] && command -v jq &> /dev/null; then
    VMESS_COUNT=\$(jq '[.inbounds[] | select(.protocol=="vmess") | .settings.clients[]?] | length' "\$CONFIG_FILE" 2>/dev/null || echo "0")
    VLESS_COUNT=\$(jq '[.inbounds[] | select(.protocol=="vless") | .settings.clients[]?] | length' "\$CONFIG_FILE" 2>/dev/null || echo "0")
    TROJAN_COUNT=\$(jq '[.inbounds[] | select(.protocol=="trojan") | .settings.clients[]?] | length' "\$CONFIG_FILE" 2>/dev/null || echo "0")
else
    VMESS_COUNT="0"; VLESS_COUNT="0"; TROJAN_COUNT="0"
fi

while true; do
    clear
    echo -e "\e[38;5;51m╔════════════════════════════════════════════════════════╗\e[0m"
    echo -e "\e[38;5;51m║\e[0m \e[1m\e[38;5;214m        VPN SERVER MANAGEMENT PLATFORM V2.5             \e[0m\e[38;5;51m║\e[0m"
    echo -e "\e[38;5;51m╚════════════════════════════════════════════════════════╝\e[0m"
    echo -e " \e[38;5;244m•\e[0m \e[1mHost:\e[0m \$(hostname -I | awk '{print \$1}')  \e[38;5;244m•\e[0m \e[1mUptime:\e[0m \$UPTIME"
    echo -e " \e[38;5;244m•\e[0m \e[1mRAM:\e[0m  \$RAM_USAGE"
    echo -e " \e[38;5;51m──────────────────────────────────────────────────────────\e[0m"
    echo -e " \e[38;5;46m📊 Active Accounts\e[0m -> VMess: \e[33m\$VMESS_COUNT\e[0m | VLESS: \e[33m\$VLESS_COUNT\e[0m | Trojan: \e[33m\$TROJAN_COUNT\e[0m"
    echo -e " \e[38;5;51m──────────────────────────────────────────────────────────\e[0m"
    echo -e "  \e[38;5;51m[01]\e[0m \e[36mSSH Manager\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[02]\e[0m \e[36mVMess Manager\e[0m   \e[38;5;240m(TLS / Non-TLS)\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[03]\e[0m \e[36mVLESS Manager\e[0m   \e[38;5;240m(TLS / Non-TLS / XHTTP)\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[04]\e[0m \e[36mProjan Manager\e[0m  \e[38;5;240m(Secure Proxy)\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[05]\e[0m \e[36mSettings & Optimization\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[06]\e[0m \e[36mBackup/Restore via Telegram\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[07]\e[0m \e[36mDomain & SSL Manager\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[08]\e[0m \e[36mCheck Running Services\e[0m"
    echo -e ""
    echo -e "  \e[38;5;220m[09]\e[0m \e[33mRun Server Speed Test\e[0m"
    echo -e ""
    echo -e "  \e[38;5;220m[10]\e[0m \e[33mQuick Restart Xray & Nginx\e[0m"
    echo -e ""
    echo -e "  \e[38;5;196m[00]\e[0m \e[31mExit Dashboard\e[0m"
    echo -e "\e[38;5;51m════════════════════════════════════════════════════════\e[0m"
    read -p " Select an option [00-10]: " option
    case \$option in
        01|1) /root/vpn-management-platform/modules/ssh_manager.sh ;;
        02|2) /root/vpn-management-platform/modules/vmess_manager.sh ;;
        03|3) /root/vpn-management-platform/modules/vless_manager.sh ;;
        04|4) /root/vpn-management-platform/modules/trojan_manager.sh ;;
        05|5) /root/vpn-management-platform/modules/settings.sh ;;
        06|6) /root/vpn-management-platform/modules/backup.sh ;;
        07|7) /root/vpn-management-platform/modules/domain_ssl.sh ;;
        08|8) /root/vpn-management-platform/modules/check_running.sh ;;
        09|9) clear; echo -e "\e[33m[INFO] Running speed test...\e[0m"; speedtest-cli; read -p "Press Enter..." ;;
        10) clear; echo -e "\e[33m[INFO] Restarting services...\e[0m"; systemctl restart xray nginx; sleep 1.5 ;;
        00|0) clear; echo -e "\e[32mExiting...\e[0m"; exit 0 ;;
        *) echo -e "\e[31m[!] Invalid option.\e[0m"; sleep 1.5 ;;
    esac
done
MENUEXEC

chmod +x /usr/local/bin/menu

echo "[INFO] Restarting services..."
systemctl daemon-reload
systemctl enable xray nginx
systemctl restart xray nginx
echo "INSTALL COMPLETE!"
