#!/bin/bash
# VPN Auto Cleanup Script - Runs Daily at Midnight

LOG_FILE="/var/log/vpn_cleanup.log"
echo "=== Cleanup Started: $(date) ===" >> $LOG_FILE

# Get current date in epoch (seconds) for accurate math
TODAY_EPOCH=$(date -d "$(date +"%Y-%m-%d")" +"%s")
XRAY_MODIFIED=false
CONFIG_FILE="/usr/local/etc/xray/config.json"
[ ! -f "$CONFIG_FILE" ] && CONFIG_FILE="/etc/xray/config.json"

# ==========================================
# 1. SAFELY CLEANUP EXPIRED XRAY USERS
# ==========================================
if [ -f "/etc/xray/clients.db" ]; then
    while IFS="|" read -r user uuid exp protocol; do
        # Clean whitespace from variables
        user=$(echo "$user" | xargs)
        uuid=$(echo "$uuid" | xargs)
        exp=$(echo "$exp" | xargs)
        protocol=$(echo "$protocol" | xargs)
        
        # Skip empty lines
        [ -z "$user" ] && continue
        
        # Convert user expiry date to epoch
        EXP_EPOCH=$(date -d "$exp" +"%s" 2>/dev/null)
        
        # If expiry epoch is less than or equal to today, they are expired
        if [ -n "$EXP_EPOCH" ] && [ "$TODAY_EPOCH" -ge "$EXP_EPOCH" ]; then
            echo "[Xray] Deleting expired user: $user ($protocol)" >> $LOG_FILE
            
            # Surgically remove ONLY this user's UUID/Password from the JSON
            if [[ "$protocol" == *"vmess"* ]]; then
                jq --arg id "$uuid" '(.inbounds[] | select(.protocol == "vmess")).settings.clients |= map(select(.id != $id))' "$CONFIG_FILE" > /tmp/x.json && mv /tmp/x.json "$CONFIG_FILE"
            elif [[ "$protocol" == *"vless"* ]]; then
                jq --arg id "$uuid" '(.inbounds[] | select(.protocol == "vless")).settings.clients |= map(select(.id != $id))' "$CONFIG_FILE" > /tmp/x.json && mv /tmp/x.json "$CONFIG_FILE"
            elif [[ "$protocol" == *"trojan"* ]]; then
                jq --arg pass "$uuid" '(.inbounds[] | select(.protocol == "trojan")).settings.clients |= map(select(.password != $pass))' "$CONFIG_FILE" > /tmp/x.json && mv /tmp/x.json "$CONFIG_FILE"
            fi
            
            # Remove them from the tracking database
            sed -i "/$uuid/d" /etc/xray/clients.db
            XRAY_MODIFIED=true
        fi
    done < /etc/xray/clients.db
fi

# ==========================================
# 2. SAFELY CLEANUP EXPIRED SSH / SLOWDNS USERS
# ==========================================
# Loops through standard Linux users created by the VPN script (UID 1000+)
for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
    # Check their system expiry date
    exp_date=$(chage -l "$user" 2>/dev/null | grep "Account expires" | awk -F': ' '{print $2}')
    if [[ "$exp_date" != "never" && -n "$exp_date" ]]; then
        EXP_EPOCH=$(date -d "$exp_date" +"%s" 2>/dev/null)
        if [ -n "$EXP_EPOCH" ] && [ "$TODAY_EPOCH" -ge "$EXP_EPOCH" ]; then
            echo "[SSH/SlowDNS] Deleting expired user: $user" >> $LOG_FILE
            # Safely kill their active sessions and remove the account
            pkill -u "$user" 2>/dev/null
            userdel -r "$user" 2>/dev/null
        fi
    fi
done

# ==========================================
# 3. RESTART ONLY IF NECESSARY
# ==========================================
# We only restart Xray if a user was actually deleted.
if [ "$XRAY_MODIFIED" = true ]; then
    systemctl restart xray
    echo "[System] Xray config reloaded to drop expired connections." >> $LOG_FILE
else
    echo "[System] No expired Xray users found. Xray service untouched." >> $LOG_FILE
fi

echo "=== Cleanup Finished ===" >> $LOG_FILE
