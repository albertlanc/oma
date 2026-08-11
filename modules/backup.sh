#!/bin/bash
# Advanced Telegram Backup & Restore Module

CONFIG_FILE="/opt/vpn_platform/telegram.conf"

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

save_config() {
    mkdir -p /opt/vpn_platform
    echo "BOT_TOKEN=\"$BOT_TOKEN\"" > "$CONFIG_FILE"
    echo "CHAT_ID=\"$CHAT_ID\"" >> "$CONFIG_FILE"
    echo "ENC_PASS=\"$ENC_PASS\"" >> "$CONFIG_FILE"
}

run_backup() {
    load_config
    if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
        echo -e "\e[31m[ERROR] Telegram credentials not configured.\e[0m"
        return 1
    fi

    echo -e "\e[33mGenerating encrypted system backup archive...\e[0m"
    backup_dir="/tmp/vpn_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Bundle core configurations and databases
    cp -r /etc/xray "$backup_dir/" 2>/dev/null || true
    cp -r /etc/nginx "$backup_dir/" 2>/dev/null || true
    mkdir -p "$backup_dir/opt_platform"
    cp -r /opt/vpn_platform/* "$backup_dir/opt_platform/" 2>/dev/null || true
    cp /etc/passwd /etc/shadow /etc/group "$backup_dir/" 2>/dev/null || true

    tar_file="/tmp/vpn_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$tar_file" -C /tmp "$(basename "$backup_dir")"

    # Encrypt file securely using AES-256 if password is provided
    if [ -n "$ENC_PASS" ]; then
        enc_file="${tar_file}.enc"
        openssl enc -aes-256-cbc -salt -in "$tar_file" -out "$enc_file" -k "$ENC_PASS"
        upload_file="$enc_file"
    else
        upload_file="$tar_file"
    fi

    echo -e "\e[33mTransmitting backup package to Telegram...\e[0m"
    response=$(curl -s -F chat_id="$CHAT_ID" -F document=@"$upload_file" "https://api.telegram.org/bot$BOT_TOKEN/sendDocument")
    
    if echo "$response" | grep -q '"ok":true'; then
        echo -e "\e[32m[SUCCESS] Backup successfully delivered to Telegram!\e[0m"
    else
        echo -e "\e[31m[ERROR] Failed to send backup. Verify Bot Token and Chat ID.\e[0m"
    fi

    # Cleanup temp build files
    rm -rf "$backup_dir" "$tar_file" "${tar_file}.enc" 2>/dev/null || true
}

# Handle silent background execution via cron
if [ "$1" == "--auto-backup" ]; then
    run_backup
    exit 0
fi

while true; do
    load_config
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "             TELEGRAM BACKUP & RESTORE           "
    echo -e "\e[36m=================================================\e[0m"
    echo -e "  [01] Configure Telegram Credentials & Passkey"
    echo -e "  [02] Create & Send Encrypted Backup Now"
    echo -e "  [03] Setup Automated Daily Cron Backup (3:00 AM)"
    echo -e "  [04] Restore Platform from Archive File"
    echo -e "  [00] Back to Main Menu"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [00-04]: " option

    case $option in
        01|1)
            read -p "Enter Telegram Bot Token: " BOT_TOKEN
            read -p "Enter Telegram Chat ID: " CHAT_ID
            read -p "Enter AES Encryption Password: " ENC_PASS
            save_config
            echo -e "\e[32m[SUCCESS] Credentials securely saved.\e[0m"
            ;;
        02|2)
            run_backup
            ;;
        03|3)
            load_config
            if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
                echo -e "\e[31m[ERROR] Configure Telegram credentials first.\e[0m"
            else
                cron_cmd="0 3 * * * /root/vpn-management-platform/modules/backup.sh --auto-backup >/dev/null 2>&1"
                (crontab -l 2>/dev/null | grep -v "modules/backup.sh"; echo "$cron_cmd") | crontab -
                echo -e "\e[32m[SUCCESS] Automated daily cron backup activated!\e[0m"
            fi
            ;;
        04|4)
            read -p "Enter full path to local backup archive (.tar.gz or .enc): " bk_path
            if [ ! -f "$bk_path" ]; then
                echo -e "\e[31m[ERROR] File not found.\e[0m"
            else
                if [[ "$bk_path" == *.enc ]]; then
                    read -p "Enter Decryption Password: " dec_pass
                    dec_file="/tmp/decrypted_backup.tar.gz"
                    openssl enc -d -aes-256-cbc -in "$bk_path" -out "$dec_file" -k "$dec_pass"
                    bk_path="$dec_file"
                fi
                echo -e "\e[33mExtracting backup contents...\e[0m"
                tar -xzf "$bk_path" -C /tmp/
                echo -e "\e[32m[SUCCESS] Archive extracted to /tmp/. System configurations ready for sync.\e[0m"
            fi
            ;;
        00|0) break ;;
    esac
    read -n 1 -s -r -p "Press any key to continue..."
done
