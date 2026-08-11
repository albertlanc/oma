#!/bin/bash
# Advanced Domain & SSL Manager Module

DOMAIN_CONF="/opt/vpn_platform/domain.conf"

load_domain() {
    if [ -f "$DOMAIN_CONF" ]; then
        source "$DOMAIN_CONF"
    fi
}

save_domain() {
    mkdir -p /opt/vpn_platform
    echo "SERVER_DOMAIN=\"$SERVER_DOMAIN\"" > "$DOMAIN_CONF"
    echo "NS1=\"$NS1\"" >> "$DOMAIN_CONF"
    echo "NS2=\"$NS2\"" >> "$DOMAIN_CONF"
}

while true; do
    load_domain
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "             DOMAIN & SSL MANAGER                "
    echo -e "\e[36m=================================================\e[0m"
    echo -e "  Current Domain : ${SERVER_DOMAIN:-[ Not Set ]}"
    echo -e "  Custom NS      : ${NS1:-N/A} / ${NS2:-N/A}"
    echo -e "\e[36m-------------------------------------------------\e[0m"
    echo -e "  [01] Add / Change Custom Domain"
    echo -e "  [02] Add / Configure Custom Name Servers (NS)"
    echo -e "  [03] Issue Standard Let's Encrypt SSL (HTTP-01)"
    echo -e "  [04] Issue Wildcard SSL via Cloudflare DNS API"
    echo -e "  [05] Configure Nginx Reverse Proxy & Map Domain"
    echo -e "  [06] Audit SSL Expiry & Domain Health"
    echo -e "  [07] Generate Self-Signed Emergency Fallback Cert"
    echo -e "  [00] Back to Main Menu"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [00-07]: " option

    case $option in
        01|1)
            read -p "Enter your custom domain (e.g., vpn.yourdomain.com): " SERVER_DOMAIN
            save_domain
            echo -e "\e[32m[SUCCESS] Domain saved as $SERVER_DOMAIN\e[0m"
            ;;
        02|2)
            echo -e "\e[33mConfigure custom Name Servers (e.g., ns1.yourdomain.com pointing to server IP)\e[0m"
            read -p "Enter Primary Name Server (NS1): " NS1
            read -p "Enter Secondary Name Server (NS2): " NS2
            save_domain
            server_ip=$(hostname -I | awk '{print $1}')
            echo -e "\e[32m[SUCCESS] Name servers recorded: $NS1, $NS2\e[0m"
            echo -e "\e[33m[NOTE] Ensure you create glue records at your domain registrar pointing $NS1 and $NS2 to server IP: $server_ip\e[0m"
            ;;
        03|3)
            if [ -z "$SERVER_DOMAIN" ]; then
                echo -e "\e[31m[ERROR] Please add a custom domain first (Option 01).\e[0m"
            else
                read -p "Enter your email for Certbot registration: " email
                systemctl stop nginx 2>/dev/null || true
                certbot certonly --standalone --agree-tos --no-eff-email -d "$SERVER_DOMAIN" -m "$email"
                systemctl start nginx 2>/dev/null || true
                echo -e "\e[32m[SUCCESS] Certificate issuance attempt completed.\e[0m"
            fi
            ;;
        04|4)
            if [ -z "$SERVER_DOMAIN" ]; then
                echo -e "\e[31m[ERROR] Please add a custom domain first (Option 01).\e[0m"
            else
                read -p "Enter Cloudflare Email: " cf_email
                read -p "Enter Cloudflare Global API Key: " cf_key
                mkdir -p ~/.secret
                echo "dns_cloudflare_email = $cf_email" > ~/.secret/cloudflare.ini
                echo "dns_cloudflare_api_key = $cf_key" >> ~/.secret/cloudflare.ini
                chmod 600 ~/.secret/cloudflare.ini
                
                if ! dpkg -l | grep -q python3-certbot-dns-cloudflare; then
                    apt-get update && apt-get install -y python3-certbot-dns-cloudflare &>/dev/null
                fi
                
                certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~/.secret/cloudflare.ini -d "$SERVER_DOMAIN" -d "*.$SERVER_DOMAIN" --agree-tos --no-eff-email -m "$cf_email"
                echo -e "\e[32m[SUCCESS] Wildcard certificate requested via Cloudflare DNS API.\e[0m"
            fi
            ;;
        05|5)
            if [ -z "$SERVER_DOMAIN" ]; then
                echo -e "\e[31m[ERROR] Please configure your domain first.\e[0m"
            else
                echo -e "\e[33mConfiguring Nginx reverse proxy server block for $SERVER_DOMAIN...\e[0m"
                cat << NGINX_CONF > /etc/nginx/sites-available/vpn_proxy.conf
server {
    listen 80;
    server_name $SERVER_DOMAIN;
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name $SERVER_DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$SERVER_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$SERVER_DOMAIN/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

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
}
NGINX_CONF
                ln -sf /etc/nginx/sites-available/vpn_proxy.conf /etc/nginx/sites-enabled/
                rm -f /etc/nginx/sites-enabled/default
                nginx -t && systemctl reload nginx
                echo -e "\e[32m[SUCCESS] Nginx configured and reloaded with modern TLS 1.3 settings.\e[0m"
            fi
            ;;
        06|6)
            if command -v certbot &> /dev/null; then
                certbot certificates
            else
                echo -e "\e[31m[INFO] Certbot not installed.\e[0m"
            fi
            ;;
        07|7)
            if [ -z "$SERVER_DOMAIN" ]; then
                domain_name="server.local"
            else
                domain_name="$SERVER_DOMAIN"
            fi
            mkdir -p /etc/xray/ssl
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/xray/ssl/private.key -out /etc/xray/ssl/cert.crt -subj "/CN=$domain_name"
            echo -e "\e[32m[SUCCESS] Self-signed fallback certificate generated at /etc/xray/ssl/\e[0m"
            ;;
        00|0) break ;;
    esac
    read -n 1 -s -r -p "Press any key to return..."
done
