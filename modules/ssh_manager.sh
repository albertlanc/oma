#!/bin/bash
# Advanced SSH Manager Module

while true; do
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "             ADVANCED SSH MANAGER                "
    echo -e "\e[36m=================================================\e[0m"
    echo -e "  [01] Create SSH Account (Isolated Shell)"
    echo -e "  [02] Renew SSH Account"
    echo -e "  [03] Change Password"
    echo -e "  [04] Suspend/Lock Account"
    echo -e "  [05] Unsuspend/Unlock Account"
    echo -e "  [06] Delete SSH Account"
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
            read -p "Enter new username: " username
            read -p "Enter password: " password
            read -p "Enter active days (e.g., 30): " days
            exp_date=$(date -d "+$days days" +"%Y-%m-%d")
            if id "$username" &>/dev/null; then
                echo -e "\e[31m[ERROR]\e[0m User already exists!"
            else
                # -s /bin/false ensures the user cannot execute shell commands (Chroot/Jail effect)
                useradd -e "$exp_date" -M -s /bin/false "$username"
                echo "$username:$password" | chpasswd
                echo -e "\e[32m[SUCCESS]\e[0m Account Created: $username | Expires: $exp_date"
            fi
            ;;
        02|2)
            read -p "Enter username to renew: " username
            if id "$username" &>/dev/null; then
                read -p "Add how many days? " days
                exp_date=$(date -d "+$days days" +"%Y-%m-%d")
                chage -E "$exp_date" "$username"
                echo -e "\e[32m[SUCCESS]\e[0m Account $username renewed until $exp_date."
            else
                echo -e "\e[31m[ERROR]\e[0m User does not exist."
            fi
            ;;
        03|3)
            read -p "Enter username: " username
            if id "$username" &>/dev/null; then
                read -p "Enter new password: " password
                echo "$username:$password" | chpasswd
                echo -e "\e[32m[SUCCESS]\e[0m Password updated for $username."
            else
                echo -e "\e[31m[ERROR]\e[0m User does not exist."
            fi
            ;;
        04|4)
            read -p "Enter username to suspend: " username
            if id "$username" &>/dev/null; then
                usermod -L "$username"
                echo -e "\e[32m[SUCCESS]\e[0m Account $username has been locked."
            else
                echo -e "\e[31m[ERROR]\e[0m User does not exist."
            fi
            ;;
        05|5)
            read -p "Enter username to unsuspend: " username
            if id "$username" &>/dev/null; then
                usermod -U "$username"
                echo -e "\e[32m[SUCCESS]\e[0m Account $username has been unlocked."
            else
                echo -e "\e[31m[ERROR]\e[0m User does not exist."
            fi
            ;;
        06|6)
            read -p "Enter username to delete: " username
            if id "$username" &>/dev/null; then
                userdel -f "$username" 2>/dev/null
                echo -e "\e[32m[SUCCESS]\e[0m Account $username deleted."
            else
                echo -e "\e[31m[ERROR]\e[0m User does not exist."
            fi
            ;;
        07|7)
            echo -e "\e[33mChecking active SSH/Dropbear sessions...\e[0m"
            echo "User | Active Connections"
            # Counts process instances per user. Can be tailored to specific VPN ports.
            for user in $(awk -F: '$3 >= 1000 {print $1}' /etc/passwd); do
                count=$(ps -u "$user" 2>/dev/null | grep -E "sshd|dropbear" | wc -l)
                if [ "$count" -gt 0 ]; then
                    echo "$user : $count connections"
                fi
            done
            ;;
        08|8)
            read -p "Enter max allowed connections per user (e.g., 2): " max_conn
            echo -e "\e[33mScanning and enforcing limits...\e[0m"
            for user in $(awk -F: '$3 >= 1000 {print $1}' /etc/passwd); do
                count=$(ps -u "$user" 2>/dev/null | grep -E "sshd|dropbear" | wc -l)
                if [ "$count" -gt "$max_conn" ]; then
                    echo -e "Killing sessions for \e[31m$user\e[0m ($count connections)"
                    pkill -u "$user" sshd
                    pkill -u "$user" dropbear
                    # 3-Strike logic would log this event to a file and lock after 3 entries
                fi
            done
            echo -e "\e[32m[SUCCESS]\e[0m Enforcement complete."
            ;;
        09|9)
            read -p "Enter base username (e.g., user): " base_user
            read -p "Enter password for all: " password
            read -p "How many accounts to create? " count
            read -p "Active days: " days
            exp_date=$(date -d "+$days days" +"%Y-%m-%d")
            for i in $(seq 1 "$count"); do
                username="${base_user}${i}"
                if ! id "$username" &>/dev/null; then
                    useradd -e "$exp_date" -M -s /bin/false "$username"
                    echo "$username:$password" | chpasswd
                    echo "Created: $username"
                fi
            done
            echo -e "\e[32m[SUCCESS]\e[0m Batch creation complete."
            ;;
        10|10)
            read -p "Enter username to view history: " username
            echo -e "\e[33mRecent logins for $username:\e[0m"
            last "$username" | head -n 10
            ;;
        11|11)
            echo -e "\e[33mChecking account expirations...\e[0m"
            for user in $(awk -F: '$3 >= 1000 && $7 != "/usr/sbin/nologin" {print $1}' /etc/passwd); do
                exp=$(chage -l "$user" | grep "Account expires" | cut -d: -f2)
                echo "$user :$exp"
            done
            ;;
        00|0)
            break
            ;;
        *) 
            echo "Invalid option. Please try again."
            sleep 1
            ;;
    esac
    read -n 1 -s -r -p "Press any key to return to SSH menu..."
done
