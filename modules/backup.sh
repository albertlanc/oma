#!/bin/bash
# Backup & Restore Module

BOT_TOKEN="YOUR_SECURE_BOT_TOKEN_HERE"
CHAT_ID="YOUR_ADMIN_CHAT_ID_HERE"
BACKUP_DIR="/var/backups/vpn_platform"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="vpn_backup_${TIMESTAMP}.tar.gz.enc"
ENCRYPTION_PASS="YourStrongPassword123"

mkdir -p "$BACKUP_DIR"

echo "Starting encrypted backup..."
tar -czf - /etc/xray /opt/vpn_platform 2>/dev/null | \
openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$ENCRYPTION_PASS" -out "$BACKUP_DIR/$ARCHIVE_NAME"

curl -s -F document=@"$BACKUP_DIR/$ARCHIVE_NAME" \
     -F caption="System Backup: $TIMESTAMP" \
     "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument?chat_id=${CHAT_ID}" > /dev/null

echo -e "\e[32m[SUCCESS]\e[0m Backup sent to Telegram!"
read -n 1 -s -r -p "Press any key to return to menu..."
