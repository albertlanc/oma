#!/bin/bash
# Domain and SSL Manager

DOMAIN_CONF="/opt/vpn_platform/domain.conf"
mkdir -p /opt/vpn_platform
mkdir -p /etc/xray

install_dependencies() {
    echo -e "\e[33mChecking dependencies (curl, socat, cron)...\e[0m"
    apt-get update -y &>/dev/null
    apt-get install curl socat cron ufw -y &>/dev/null
    
    if [ ! -d "/root/.acme.sh" ]; then
        echo -e "\e[33mInstalling acme.sh for SSL management...\e[0m"
        curl -sL https://get.acme.sh | sh &>/dev/null
    fi
}

point_domain() {
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "             DOMAIN & SSL MANAGER                "
    echo -e "\e[36m=================================================\e[0m"
    echo -e "Make sure your domain is already pointed to:"
    echo -e "\e[32m$(hostname -I | awk '{print $1}')\e[0m"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Enter your Domain/Subdomain : " domain
    read -p "Enter your Name Server (NS) : " nameserver
    
    if [ -z "$domain" ]; then
        echo -e "\e[31mDomain cannot be empty!\e[0m"
        sleep 2
        return
    fi

    # 1. Save Domain and NS Globally
    echo "SERVER_DOMAIN=\"$domain\"" > "$DOMAIN_CONF"
    if [ -n "$nameserver" ]; then
        echo "SERVER_NS=\"$nameserver\"" >> "$DOMAIN_CONF"
    fi
    echo -e "\e[32mData saved globally to $DOMAIN_CONF!\e[0m"
    sleep 1

    # 2. Install Dependencies
    install_dependencies

    # 3. Stop services that might block Port 80
    echo -e "\e[33mStopping web services temporarily to free Port 80...\e[0m"
    systemctl stop nginx &>/dev/null
    systemctl stop xray &>/dev/null

    # 4. Issue SSL Certificate (Only for the main domain)
    echo -e "\e[33mIssuing SSL Certificate for $domain...\e[0m"
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt &>/dev/null
    /root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256

    # 5. Install Certificate
    if [ $? -eq 0 ]; then
        echo -e "\e[33mInstalling Certificate to /etc/xray/ ...\e[0m"
        /root/.acme.sh/acme.sh --installcert -d "$domain" --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
        chmod 644 /etc/xray/xray.crt /etc/xray/xray.key
        
        echo -e "\e[36m=================================================\e[0m"
        echo -e "\e[32m          SSL CERTIFICATE SUCCESSFUL!            \e[0m"
        echo -e "\e[36m=================================================\e[0m"
        echo -e " Domain      : \e[32m$domain\e[0m"
        if [ -n "$nameserver" ]; then
            echo -e " Name Server : \e[32m$nameserver\e[0m"
        fi
        echo -e " Public Key  : \e[33m/etc/xray/xray.crt\e[0m"
        echo -e " Private Key : \e[33m/etc/xray/xray.key\e[0m"
        echo -e "\e[36m=================================================\e[0m"
    else
        echo -e "\e[36m=================================================\e[0m"
        echo -e "\e[31m            SSL CERTIFICATE FAILED               \e[0m"
        echo -e "\e[36m=================================================\e[0m"
        echo -e "Please ensure your domain is strictly pointed to"
        echo -e "this server's IP and Port 80 is open."
    fi

    # Restart services
    systemctl start xray &>/dev/null
    systemctl start nginx &>/dev/null
    
    read -n 1 -s -r -p "Press any key to return to Main Menu..."
}

while true; do
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "             DOMAIN & SSL MANAGER                "
    echo -e "\e[36m=================================================\e[0m"
    
    if [ -f "$DOMAIN_CONF" ]; then
        source "$DOMAIN_CONF"
        echo -e " Current Active Domain      : \e[32m${SERVER_DOMAIN:-None}\e[0m"
        echo -e " Current Active Name Server : \e[32m${SERVER_NS:-None}\e[0m"
    else
        echo -e " Current Active Domain      : \e[31mNone (Using Server IP)\e[0m"
        echo -e " Current Active Name Server : \e[31mNone\e[0m"
    fi
    
    echo -e "\e[36m=================================================\e[0m"
    echo -e "  [1] Input/Change Domain & Install SSL"
    echo -e "  [2] Renew SSL Certificate Manually"
    echo -e "  [0] Back to Main Menu"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select option [0-2]: " ssl_opt

    case $ssl_opt in
        1)
            point_domain
            ;;
        2)
            if [ -f "$DOMAIN_CONF" ]; then
                source "$DOMAIN_CONF"
                clear
                echo -e "\e[33mForcing SSL Renewal for $SERVER_DOMAIN...\e[0m"
                systemctl stop nginx &>/dev/null
                systemctl stop xray &>/dev/null
                /root/.acme.sh/acme.sh --renew -d "$SERVER_DOMAIN" --force --ecc
                systemctl start xray &>/dev/null
                systemctl start nginx &>/dev/null
                echo -e "\e[32mRenewal process completed.\e[0m"
                read -n 1 -s -r -p "Press any key to continue..."
            else
                echo -e "\e[31mNo domain registered yet!\e[0m"
                sleep 2
            fi
            ;;
        0)
            break
            ;;
    esac
done
