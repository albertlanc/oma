#!/bin/bash
# Advanced SSH Manager Module with Numbered Selection Sub-Menus
DOMAIN_CONF="/opt/vpn_platform/domain.conf"
LIMITS_CONF="/opt/vpn_platform/ssh_limits.conf"

load_domain() {
    if [ -f "$DOMAIN_CONF" ]; then
        source "$DOMAIN_CONF"
    fi
}

get_user_limit() {
    local username="$1"
    if [ -f "$LIMITS_CONF" ]; then
        local limit=$(grep "^$username:" "$LIMITS_CONF" | cut -d: -f2)
        if [ -n "$limit" ]; then
            echo "$limit"
            return
        fi
    fi
    echo "2" # Default limit if not specified
}

while true; do
    load_domain
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "             ADVANCED SSH MANAGER                "
    echo -e "\e[36m=================================================\e[0m"
    echo -e "  [01] Create SSH Account (Detailed Output & Payloads)"
    echo -e "  [02] Renew SSH Account (Interactive List)"
    echo -e "  [03] Change Password (Interactive List)"
    echo -e "  [04] Suspend/Lock Account (Interactive List)"
    echo -e "  [05] Unsuspend/Unlock Account (Interactive List)"
    echo -e "  [06] Delete SSH Account (Interactive List)"
    echo -e "  [07] Check Multi-Login (Active Sessions)"
    echo -e "  [08] Auto-Kill Multi-Login (Enforce Limits)"
    echo -e "  [09] Bulk Account Creation"
    echo -e "  [10] View User Session History (IP Logs)"
    echo -e "  [11] View Accounts Expiring Soon"
    echo -e "  [00] Back to Main Menu"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [00-11]: " option
    case $option in
        01|1)
            clear
            echo -e "\e[33m=== CREATE SSH ACCOUNT ===\e[0m"
            read -p "Enter username: " username
            read -p "Enter password: " password
            read -p "Enter Max Login (concurrent limit): " max_login
            read -p "Enter active duration in days: " days
            if id "$username" &>/dev/null; then
                echo -e "\e[31m[ERROR] User already exists!\e[0m"
            else
                exp_date=$(date -d "+$days days" +"%Y-%m-%d")
                current_epoch=$(date +%s)
                exp_epoch=$(date -d "$exp_date" +%s)
                days_remaining=$(( (exp_epoch - current_epoch) / 86400 ))
                useradd -e "$exp_date" -M -s /bin/false "$username"
                echo "$username:$password" | chpasswd
                mkdir -p /opt/vpn_platform
                sed -i "/^$username:/d" "$LIMITS_CONF" 2>/dev/null
                echo "$username:$max_login" >> "$LIMITS_CONF"
                server_ip=$(hostname -I | awk '{print $1}')
                dom="${SERVER_DOMAIN:-$server_ip}"
                
                # Fetch SlowDNS public key dynamically from standard paths
                slowdns_pub="Not Generated"
                for pub_path in "/etc/slowdns/server.key.pub" "/root/slowdns.pub" "/etc/slowdns/server.pub" "/etc/slowdns/pub.key"; do
                    if [ -f "$pub_path" ] && [ -s "$pub_path" ]; then
                        slowdns_pub=$(cat "$pub_path")
                        break
                    fi
                done
                ns=$(cat /etc/xray/ns-domain 2>/dev/null || cat /root/nsdomain 2>/dev/null || echo "${SERVER_NS:-ns-$dom}")

                clear
                echo -e "\e[36m=================================================\e[0m"
                echo -e "          SSH ACCOUNT CREATED SUCCESSFULLY       "
                echo -e "\e[36m=================================================\e[0m"
                echo -e "  Username          : \e[32m$username\e[0m"
                echo -e "  Password          : \e[32m$password\e[0m"
                echo -e "  Max Login Limit   : $max_login Device(s)"
                echo -e "  Total Active Days : $days Days"
                echo -e "  Days Remaining    : \e[33m$days_remaining Days\e[0m (Expires: $exp_date)"
                echo -e "\e[36m-------------------------------------------------\e[0m"
                echo -e "  Server IP / Host  : $server_ip"
                echo -e "  Domain            : $dom"
                echo -e "  Name Server (NS)  : $ns"
                echo -e "  SlowDNS Pub Key   : \e[32m${slowdns_pub}\e[0m"
                echo -e "\e[36m-------------------------------------------------\e[0m"
                echo -e "  PORTS CONFIGURATION:"
                echo -e "    - SSH Normal    : 22"
                echo -e "    - SSH WebSocket : 80 (NoTLS) / 443 (TLS)"
                echo -e "    - SlowDNS       : 53"
                echo -e "\e[36m-------------------------------------------------\e[0m"
                echo -e "  PAYLOAD SAMPLES:"
                echo -e "    \e[33m[WebSocket Payload (Port 80 Non-TLS)]:\e[0m"
                echo -e "    GET /ssh-ws HTTP/1.1[crlf]Host: $dom[crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf][crlf]"
                echo -e "\e[36m=================================================\e[0m"
            fi
            ;;
        02|2)
            clear
            echo -e "\e[33m=== RENEW SSH ACCOUNT ===\e[0m"
            echo -e " No. | Username         | Current Expiration"
            echo -e "-------------------------------------------------"
            users=($(awk -F: '$3 >= 1000 {print $1}' /etc/passwd))
            if [ ${#users[@]} -eq 0 ]; then
                echo -e "\e[31m[INFO] No custom user accounts found on this system.\e[0m"
            else
                for i in "${!users[@]}"; do
                    u="${users[$i]}"
                    num=$((i + 1))
                    exp=$(chage -l "$u" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
                    printf " [%02d] | %-16s | %s\n" "$num" "$u" "$exp"
                done
                echo -e "-------------------------------------------------"
                read -p "Select account number or type username to renew: " selection
                if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#users[@]}" ]; then
                    username="${users[$((selection - 1))]}"
                else
                    username="$selection"
                fi
                if id "$username" &>/dev/null; then
                    read -p "Add how many days to extend? " days
                    current_exp_raw=$(chage -l "$username" | grep "Account expires" | cut -d: -f2 | xargs)
                    if [ "$current_exp_raw" = "never" ] || [ -z "$current_exp_raw" ]; then
                        base_date=$(date +%Y-%m-%d)
                    else
                        curr_epoch=$(date -d "$current_exp_raw" +%s 2>/dev/null || echo 0)
                        today_epoch=$(date +%s)
                        if [ "$curr_epoch" -gt "$today_epoch" ]; then
                            base_date="$current_exp_raw"
                        else
                            base_date=$(date +%Y-%m-%d)
                        fi
                    fi
                    new_exp=$(date -d "$base_date +$days days" +"%Y-%m-%d")
                    chage -E "$new_exp" "$username"
                    echo -e "\e[32m[SUCCESS] Account $username successfully renewed until $new_exp.\e[0m"
                else
                    echo -e "\e[31m[ERROR] User '$username' does not exist.\e[0m"
                fi
            fi
            ;;
        03|3)
            clear
            echo -e "\e[33m=== CHANGE SSH PASSWORD ===\e[0m"
            echo -e " No. | Username         | Current Expiration"
            echo -e "-------------------------------------------------"
            users=($(awk -F: '$3 >= 1000 {print $1}' /etc/passwd))
            if [ ${#users[@]} -eq 0 ]; then
                echo -e "\e[31m[INFO] No custom user accounts found on this system.\e[0m"
            else
                for i in "${!users[@]}"; do
                    u="${users[$i]}"
                    num=$((i + 1))
                    exp=$(chage -l "$u" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
                    printf " [%02d] | %-16s | %s\n" "$num" "$u" "$exp"
                done
                echo -e "-------------------------------------------------"
                read -p "Select account number or type username to change password: " selection
                if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#users[@]}" ]; then
                    username="${users[$((selection - 1))]}"
                else
                    username="$selection"
                fi
                if id "$username" &>/dev/null; then
                    read -p "Enter new password for $username: " password
                    echo "$username:$password" | chpasswd
                    echo -e "\e[32m[SUCCESS] Password updated securely for $username.\e[0m"
                else
                    echo -e "\e[31m[ERROR] User '$username' does not exist.\e[0m"
                fi
            fi
            ;;
        04|4)
            clear
            echo -e "\e[33m=== SUSPEND / LOCK SSH ACCOUNT ===\e[0m"
            echo -e " No. | Username         | Current Expiration"
            echo -e "-------------------------------------------------"
            users=($(awk -F: '$3 >= 1000 {print $1}' /etc/passwd))
            if [ ${#users[@]} -eq 0 ]; then
                echo -e "\e[31m[INFO] No custom user accounts found on this system.\e[0m"
            else
                for i in "${!users[@]}"; do
                    u="${users[$i]}"
                    num=$((i + 1))
                    exp=$(chage -l "$u" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
                    printf " [%02d] | %-16s | %s\n" "$num" "$u" "$exp"
                done
                echo -e "-------------------------------------------------"
                read -p "Select account number or type username to suspend: " selection
                if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#users[@]}" ]; then
                    username="${users[$((selection - 1))]}"
                else
                    username="$selection"
                fi
                if id "$username" &>/dev/null; then
                    usermod -L "$username"
                    pkill -u "$username" 2>/dev/null
                    echo -e "\e[32m[SUCCESS] Account $username has been locked and active sessions terminated.\e[0m"
                else
                    echo -e "\e[31m[ERROR] User '$username' does not exist.\e[0m"
                fi
            fi
            ;;
        05|5)
            clear
            echo -e "\e[33m=== UNSUSPEND / UNLOCK SSH ACCOUNT ===\e[0m"
            echo -e " No. | Username         | Current Expiration"
            echo -e "-------------------------------------------------"
            users=($(awk -F: '$3 >= 1000 {print $1}' /etc/passwd))
            if [ ${#users[@]} -eq 0 ]; then
                echo -e "\e[31m[INFO] No custom user accounts found on this system.\e[0m"
            else
                for i in "${!users[@]}"; do
                    u="${users[$i]}"
                    num=$((i + 1))
                    exp=$(chage -l "$u" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
                    printf " [%02d] | %-16s | %s\n" "$num" "$u" "$exp"
                done
                echo -e "-------------------------------------------------"
                read -p "Select account number or type username to unsuspend: " selection
                if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#users[@]}" ]; then
                    username="${users[$((selection - 1))]}"
                else
                    username="$selection"
                fi
                if id "$username" &>/dev/null; then
                    usermod -U "$username"
                    echo -e "\e[32m[SUCCESS] Account $username has been unlocked.\e[0m"
                else
                    echo -e "\e[31m[ERROR] User '$username' does not exist.\e[0m"
                fi
            fi
            ;;
        06|6)
            clear
            echo -e "\e[33m=== DELETE SSH ACCOUNT ===\e[0m"
            echo -e " No. | Username         | Current Expiration"
            echo -e "-------------------------------------------------"
            users=($(awk -F: '$3 >= 1000 {print $1}' /etc/passwd))
            if [ ${#users[@]} -eq 0 ]; then
                echo -e "\e[31m[INFO] No custom user accounts found on this system.\e[0m"
            else
                for i in "${!users[@]}"; do
                    u="${users[$i]}"
                    num=$((i + 1))
                    exp=$(chage -l "$u" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
                    printf " [%02d] | %-16s | %s\n" "$num" "$u" "$exp"
                done
                echo -e "-------------------------------------------------"
                read -p "Select account number or type username to delete: " selection
                if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#users[@]}" ]; then
                    username="${users[$((selection - 1))]}"
                else
                    username="$selection"
                fi
                if id "$username" &>/dev/null; then
                    read -p "Purge home directory/mail as well? [y/N]: " purge_home
                    if [[ "$purge_home" =~ ^[Yy]$ ]]; then
                        userdel -r "$username" 2>/dev/null
                    else
                        userdel -f "$username" 2>/dev/null
                    fi
                    sed -i "/^$username:/d" "$LIMITS_CONF" 2>/dev/null
                    echo -e "\e[32m[SUCCESS] Account $username deleted completely.\e[0m"
                else
                    echo -e "\e[31m[ERROR] User '$username' does not exist.\e[0m"
                fi
            fi
            ;;
        07|7)
            clear
            echo -e "\e[33m=== CHECK ACTIVE MULTI-LOGIN SESSIONS ===\e[0m"
            echo -e " No. | Username         | Max Limit | Active Conn | Status"
            echo -e "-------------------------------------------------------------"
            users=($(awk -F: '$3 >= 1000 {print $1}' /etc/passwd))
            if [ ${#users[@]} -eq 0 ]; then
                echo -e "\e[31m[INFO] No custom user accounts found on this system.\e[0m"
            else
                for i in "${!users[@]}"; do
                    u="${users[$i]}"
                    num=$((i + 1))
                    max_l=$(get_user_limit "$u")
                    active_conn=$(ps -u "$u" 2>/dev/null | grep -E "sshd|dropbear" | wc -l)
                    if [ "$active_conn" -gt "$max_l" ]; then
                        status="\e[31mEXCEEDED\e[0m"
                    elif [ "$active_conn" -gt 0 ]; then
                        status="\e[32mACTIVE\e[0m"
                    else
                        status="\e[90mIDLE\e[0m"
                    fi
                    printf " [%02d] | %-16s | %-9s | %-11s | %s\n" "$num" "$u" "$max_l" "$active_conn" "$status"
                done
                echo -e "-------------------------------------------------------------"
            fi
            ;;
        08|8)
            clear
            echo -e "\e[33m=== AUTO-KILL MULTI-LOGIN ENFORCEMENT ===\e[0m"
            echo -e " Scanning all accounts against configured device limits..."
            echo -e "-------------------------------------------------------------"
            echo -e " Username         | Limit | Active | Action Taken"
            echo -e "-------------------------------------------------------------"
            users=($(awk -F: '$3 >= 1000 {print $1}' /etc/passwd))
            if [ ${#users[@]} -eq 0 ]; then
                echo -e "\e[31m[INFO] No accounts to enforce.\e[0m"
            else
                killed_count=0
                for u in "${users[@]}"; do
                    max_l=$(get_user_limit "$u")
                    active_conn=$(ps -u "$u" 2>/dev/null | grep -E "sshd|dropbear" | wc -l)
                    if [ "$active_conn" -gt "$max_l" ]; then
                        pkill -u "$u" sshd 2>/dev/null
                        pkill -u "$u" dropbear 2>/dev/null
                        printf " %-16s | %-5s | %-6s | \e[31mKILLED (Over Limit)\e[0m\n" "$u" "$max_l" "$active_conn"
                        ((killed_count++))
                    else
                        printf " %-16s | %-5s | %-6s | \e[32mNormal (Within Limit)\e[0m\n" "$u" "$max_l" "$active_conn"
                    fi
                done
                echo -e "-------------------------------------------------------------"
                echo -e "\e[32m[SUCCESS] Enforcement complete. Terminated over-limit sessions for $killed_count user(s).\e[0m"
            fi
            ;;
        09|9)
            clear
            echo -e "\e[33m=== ADVANCED BULK ACCOUNT CREATION ===\e[0m"
            read -p "Enter base username prefix: " base_user
            read -p "Enter common password for all accounts: " password
            read -p "Enter max login (concurrent device limit): " max_login
            read -p "Enter active duration in days: " days
            read -p "Enter number of accounts to generate: " count
            if [ -z "$base_user" ] || [ -z "$password" ] || [ -z "$count" ]; then
                echo -e "\e[31m[ERROR] All fields are required!\e[0m"
            else
                exp_date=$(date -d "+$days days" +"%Y-%m-%d")
                clear
                echo -e "\e[36m=================================================\e[0m"
                echo -e "          BULK GENERATION RESULTS REPORT         "
                echo -e "\e[36m=================================================\e[0m"
                echo -e " No. | Username         | Password    | Limit | Expires"
                echo -e "-------------------------------------------------"
                mkdir -p /opt/vpn_platform
                success_count=0
                for i in $(seq 1 "$count"); do
                    username="${base_user}${i}"
                    if ! id "$username" &>/dev/null; then
                        useradd -e "$exp_date" -M -s /bin/false "$username"
                        echo "$username:$password" | chpasswd
                        sed -i "/^$username:/d" "$LIMITS_CONF" 2>/dev/null
                        echo "$username:$max_login" >> "$LIMITS_CONF"
                        printf " [%02d] | %-16s | %-11s | %-5s | %s\n" "$i" "$username" "$password" "$max_login" "$exp_date"
                        ((success_count++))
                    else
                        printf " [%02d] | %-16s | \e[31mSkipped (Exists)\e[0m\n" "$i" "$username"
                    fi
                done
                echo -e "-------------------------------------------------"
                echo -e "\e[32m[SUCCESS] Successfully generated $success_count account(s).\e[0m"
            fi
            ;;
        10|10)
            clear
            echo -e "\e[33m=== VIEW USER SESSION HISTORY (IP LOGS) ===\e[0m"
            echo -e " No. | Username         | Current Expiration"
            echo -e "-------------------------------------------------"
            users=($(awk -F: '$3 >= 1000 {print $1}' /etc/passwd))
            if [ ${#users[@]} -eq 0 ]; then
                echo -e "\e[31m[INFO] No custom user accounts found on this system.\e[0m"
            else
                for i in "${!users[@]}"; do
                    u="${users[$i]}"
                    num=$((i + 1))
                    exp=$(chage -l "$u" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
                    printf " [%02d] | %-16s | %s\n" "$num" "$u" "$exp"
                done
                echo -e "-------------------------------------------------"
                read -p "Select account number or type username to view logs: " selection
                if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#users[@]}" ]; then
                    username="${users[$((selection - 1))]}"
                else
                    username="$selection"
                fi
                if id "$username" &>/dev/null; then
                    clear
                    echo -e "\e[36m=================================================\e[0m"
                    echo -e " SESSION HISTORY & LOGIN IP LOGS FOR: \e[32m$username\e[0m"
                    echo -e "\e[36m=================================================\e[0m"
                    last "$username" | head -n 15
                    echo -e "\e[36m-------------------------------------------------\e[0m"
                else
                    echo -e "\e[31m[ERROR] User '$username' does not exist.\e[0m"
                fi
            fi
            ;;
        11|11)
            clear
            echo -e "\e[33m=== ACCOUNTS EXPIRING SOON ===\e[0m"
            echo -e " No. | Username         | Expiration Date    | Status"
            echo -e "-------------------------------------------------"
            users=($(awk -F: '$3 >= 1000 {print $1}' /etc/passwd))
            if [ ${#users[@]} -eq 0 ]; then
                echo -e "\e[31m[INFO] No custom user accounts found.\e[0m"
            else
                count=0
                current_epoch=$(date +%s)
                for i in "${!users[@]}"; do
                    u="${users[$i]}"
                    exp_raw=$(chage -l "$u" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
                    if [ "$exp_raw" != "never" ] && [ -n "$exp_raw" ]; then
                        exp_epoch=$(date -d "$exp_raw" +%s 2>/dev/null || echo 0)
                        if [ "$exp_epoch" -gt 0 ]; then
                            diff_days=$(( (exp_epoch - current_epoch) / 86400 ))
                            if [ "$diff_days" -le 7 ] && [ "$diff_days" -ge 0 ]; then
                                ((count++))
                                printf " [%02d] | %-16s | %-18s | \e[33mExpiring in %d days\e[0m\n" "$count" "$u" "$exp_raw" "$diff_days"
                            elif [ "$diff_days" -lt 0 ]; then
                                ((count++))
                                printf " [%02d] | %-16s | %-18s | \e[31mExpired\e[0m\n" "$count" "$u" "$exp_raw"
                            fi
                        fi
                    fi
                done
                if [ "$count" -eq 0 ]; then
                    echo -e "\e[32m[INFO] No accounts expiring within the next 7 days.\e[0m"
                fi
            fi
            echo -e "-------------------------------------------------"
            ;;
        00|0)
            break
            ;;
        *)
            echo "Invalid option."
            sleep 1
            ;;
    esac
    read -n 1 -s -r -p "Press any key to return to SSH menu..."
done
