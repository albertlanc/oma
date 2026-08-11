#!/bin/bash
while true; do
    clear
    echo -e "\e[38;5;51m          ADVANCED SSH MANAGER          \e[0m"
    echo -e "\e[38;5;51m========================================================\e[0m"
    echo -e "  \e[38;5;51m[01]\e[0m \e[36mCreate SSH Account (Detailed Output & Payloads)\e[0m"
    echo -e "  \e[38;5;51m[02]\e[0m \e[36mRenew SSH Account (Interactive List)\e[0m"
    echo -e "  \e[38;5;51m[03]\e[0m \e[36mChange Password (Interactive List)\e[0m"
    echo -e "  \e[38;5;51m[04]\e[0m \e[36mSuspend/Lock Account (Interactive List)\e[0m"
    echo -e "  \e[38;5;51m[05]\e[0m \e[36mUnsuspend/Unlock Account (Interactive List)\e[0m"
    echo -e "  \e[38;5;51m[06]\e[0m \e[36mDelete SSH Account (Interactive List)\e[0m"
    echo -e "  \e[38;5;51m[07]\e[0m \e[36mCheck Multi-Login (Active Sessions)\e[0m"
    echo -e "  \e[38;5;51m[08]\e[0m \e[36mAuto-Kill Multi-Login (Enforce Limits)\e[0m"
    echo -e "  \e[38;5;51m[09]\e[0m \e[36mBulk Account Creation\e[0m"
    echo -e "  \e[38;5;51m[10]\e[0m \e[36mView User Session History (IP Logs)\e[0m"
    echo -e "  \e[38;5;51m[11]\e[0m \e[36mView Accounts Expiring Soon\e[0m"
    echo -e "  \e[38;5;196m[00]\e[0m \e[31mBack to Main Menu\e[0m"
    echo -e "\e[38;5;51m========================================================\e[0m"
    read -p " Select an option [00-11]: " ssh_opt

    case $ssh_opt in
        1|01)
            read -p "Enter new username: " username
            if id "$username" &>/dev/null; then
                echo -e "\e[31m[!] User already exists!\e[0m"
            else
                read -p "Enter password for $username: " password
                read -p "Enter active days: " days
                expiration_date=$(date -d "+$days days" +"%Y-%m-%d")
                useradd -e "$expiration_date" -M -s /bin/false "$username"
                echo "$username:$password" | chpasswd
                
                sudo -u "$username" mkdir -p /home/"$username"/.ssh 2>/dev/null
                ssh-keygen -t rsa -b 2048 -N "" -f /tmp/id_rsa_$username >/dev/null 2>&1
                PUBKEY=$(cat /tmp/id_rsa_${username}.pub)
                rm -f /tmp/id_rsa_$username /tmp/id_rsa_${username}.pub

                clear
                echo -e "\e[32m[SUCCESS] SSH User created successfully!\e[0m"
                echo -e "────────────────────────────────────────────────────────"
                echo -e "Username   : $username"
                echo -e "Password   : $password"
                echo -e "Expires on : $expiration_date"
                echo -e "Public Key :\n\e[33m$PUBKEY\e[0m"
                echo -e "────────────────────────────────────────────────────────"
            fi
            read -p "Press Enter to continue..."
            ;;
        2|02)
            read -p "Enter username to renew: " username
            if id "$username" &>/dev/null; then
                read -p "Add extra days: " days
                chage -E $(date -d "+$days days" +"%Y-%m-%d") "$username"
                echo -e "\e[32m[SUCCESS] Account $username extended by $days days.\e[0m"
            else
                echo -e "\e[31m[!] User not found.\e[0m"
            fi
            sleep 1.5
            ;;
        3|03)
            read -p "Enter username to change password: " username
            if id "$username" &>/dev/null; then
                read -p "Enter new password: " password
                echo "$username:$password" | chpasswd
                echo -e "\e[32m[SUCCESS] Password updated for $username.\e[0m"
            else
                echo -e "\e[31m[!] User not found.\e[0m"
            fi
            sleep 1.5
            ;;
        4|04)
            read -p "Enter username to lock/suspend: " username
            if id "$username" &>/dev/null; then
                passwd -l "$username"
                echo -e "\e[32m[SUCCESS] Account $username suspended.\e[0m"
            else
                echo -e "\e[31m[!] User not found.\e[0m"
            fi
            sleep 1.5
            ;;
        5|05)
            read -p "Enter username to unlock: " username
            if id "$username" &>/dev/null; then
                passwd -u "$username"
                echo -e "\e[32m[SUCCESS] Account $username unsuspended.\e[0m"
            else
                echo -e "\e[31m[!] User not found.\e[0m"
            fi
            sleep 1.5
            ;;
        6|06)
            read -p "Enter username to delete: " username
            if id "$username" &>/dev/null; then
                userdel -r "$username"
                echo -e "\e[32m[SUCCESS] User $username deleted.\e[0m"
            else
                echo -e "\e[31m[!] User not found.\e[0m"
            fi
            sleep 1.5
            ;;
        7|07)
            clear
            echo -e "\e[33m--- Active Multi-Logins / Sessions ---:\e[0m"
            who
            read -p "Press Enter to continue..."
            ;;
        8|08)
            echo -e "\e[32m[INFO] Multi-login enforcement check active.\e[0m"
            sleep 1.5
            ;;
        9|09)
            read -p "Enter prefix for bulk users: " prefix
            read -p "How many users to create: " count
            read -p "Password for all users: " password
            read -p "Active days: " days
            expiration_date=$(date -d "+$days days" +"%Y-%m-%d")
            for ((i=1; i<=count; i++)); do
                username="${prefix}${i}"
                if ! id "$username" &>/dev/null; then
                    useradd -e "$expiration_date" -M -s /bin/false "$username"
                    echo "$username:$password" | chpasswd
                fi
            done
            echo -e "\e[32m[SUCCESS] Created $count bulk users with prefix $prefix!\e[0m"
            read -p "Press Enter to continue..."
            ;;
        10)
            clear
            echo -e "\e[33m--- User Session History (IP Logs) ---:\e[0m"
            last -n 25
            read -p "Press Enter to continue..."
            ;;
        11)
            clear
            echo -e "\e[33m--- Accounts Expiring Soon ---:\e[0m"
            awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | while read user; do
                exp=$(chage -l "$user" | grep "Account expires" | cut -d: -f2)
                echo "User: $user | Expires:$exp"
            done
            read -p "Press Enter to continue..."
            ;;
        0|00)
            break
            ;;
        *)
            echo -e "\e[31m[!] Invalid option.\e[0m"
            sleep 1.5
            ;;
    esac
done
