#!/bin/bash
# Automated Let's Encrypt SSL Issuer for Commercial VPN Platform

clear
echo -e "\e[36m=================================================\e[0m"
echo -e "       AUTOMATED TRUSTED SSL ISSUER              "
echo -e "\e[36m=================================================\e[0m"

read -p "Enter your VPN Domain or Subdomain (e.g., vpn.mybusiness.com): " USER_DOMAIN

if [ -z "$USER_DOMAIN" ]; then
    echo -e "\e[31m[ERROR] Domain cannot be empty!\e[0m"
    exit 1
fi

echo -e "\e[33m[INFO] Installing Certbot for trusted SSL generation...\e[0m"
apt-get install -y certbot python3-certbot-nginx 2>/dev/null || true

# Stop nginx temporarily to free port 80 for standalone verification
systemctl stop nginx 2>/dev/null || true

echo -e "\e[33m[INFO] Requesting trusted SSL certificate from Let's Encrypt for ${USER_DOMAIN}...\e[0m"
certbot certonly --standalone --agree-tos --register-unsafely-without-email -d "${USER_DOMAIN}" --force-renewal

if [ -f "/etc/letsencrypt/live/${USER_DOMAIN}/fullchain.pem" ]; then
    echo -e "\e[32m[SUCCESS] Trusted SSL certificate issued successfully!\e[0m"
    
    # Save domain config for future reference
    mkdir -p /opt/vpn_platform
    echo "SERVER_DOMAIN=${USER_DOMAIN}" > /opt/vpn_platform/domain.conf
    
    # Link Let's Encrypt paths to Xray/Nginx configuration locations
    ln -sf /etc/letsencrypt/live/${USER_DOMAIN}/fullchain.pem /etc/xray/xray.crt
    ln -sf /etc/letsencrypt/live/${USER_DOMAIN}/privkey.pem /etc/xray/xray.key
    
    # Update Nginx config to use the domain name
    sed -i "s/server_name _;/server_name ${USER_DOMAIN};/g" /etc/nginx/conf.d/vpn_xray.conf
    
    # Restart services
    systemctl restart nginx
    systemctl restart xray
    
    echo -e "\e[32m[SUCCESS] Nginx and Xray are now secured with a 100% trusted Let's Encrypt certificate!\e[0m"
    echo -e "\e[36mYour clients can now connect instantly without enabling 'Allow Insecure'.\e[0m"
else
    echo -e "\e[31m[ERROR] Failed to issue SSL certificate. Make sure your domain's A Record points to this server's public IP address!\e[0m"
    systemctl start nginx
fi
