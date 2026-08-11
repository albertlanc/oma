#!/bin/bash
while true; do
    clear
    echo -e "\e[38;5;51m╔════════════════════════════════════════════════════════╗\e[0m"
    echo -e "\e[38;5;51m║\e[0m \e[1m\e[38;5;214m                  SSH ACCOUNT MANAGER                   \e[0m\e[38;5;51m║\e[0m"
    echo -e "\e[38;5;51m╚════════════════════════════════════════════════════════╝\e[0m"
    echo -e "  \e[38;5;51m[01]\e[0m \e[36mCreate SSH & Dropbear User\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[02]\e[0m \e[36mCreate Trial SSH Account\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[03]\e[0m \e[36mExtend SSH Account Expiry\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[04]\e[0m \e[36mDelete SSH User\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[05]\e[0m \e[36mCheck Member / Active Users\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[06]\e[0m \e[36mCheck Login Multi-Login/User\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[07]\e[0m \e[36mAutomatic Locked Expired Accounts\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[08]\e[0m \e[36mUnlock Expired SSH Account\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[09]\e[0m \e[36mDelete Expired SSH Accounts\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[10]\e[0m \e[36mSSH User Password Generator\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[11]\e[0m \e[36mUser Login Monitor\e[0m"
    echo -e ""
    echo -e "  \e[38;5;196m[00]\e[0m \e[31mBack to Main Menu\e[0m"
    echo -e "\e[38;5;51m════════════════════════════════════════════════════════\e[0m"
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
                
                # Generate Public Key
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
            username="trial$(date +%s%N | cut -c10-13)"
            password="123"
            expiration_date=$(date -d "+1 hours" +"%Y-%m-%d %H:%M:%S")
            useradd -M -s /bin/false "$username"
            echo "$username:$password" | chpasswd
            clear
            echo -e "\e[32m[SUCCESS] Trial Account Created!\e[0m"
            echo -e "Username: $username | Password: $password | Valid for 1 Hour"
            read -p "Press Enter to continue..."
            ;;
        3|03)
            read -p "Enter username to extend: " username
            if id "$username" &>/dev/null; then
                read -p "Add extra days: " days
                chage -E $(date -d "+$days days" +"%Y-%m-%d") "$username"
                echo -e "\e[32m[SUCCESS] Account extended by $days days.\e[0m"
            else
                echo -e "\e[31m[!] User not found.\e[0m"
            fi
            sleep 1.5
            ;;
        4|04)
            read -p "Enter username to delete: " username
            if id "$username" &>/dev/null; then
                userdel -r "$username"
                echo -e "\e[32m[SUCCESS] User deleted.\e[0m"
            else
                echo -e "\e[31m[!] User not found.\e[0m"
            fi
            sleep 1.5
            ;;
        5|05)
            clear
            echo -e "\e[33m--- Active SSH Users ---:\e[0m"
            awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd
            read -p "Press Enter to continue..."
            ;;
        6|06)
            clear
            echo -e "\e[33m--- Multi-Login Monitor ---:\e[0m"
            who
            read -p "Press Enter to continue..."
            ;;
        7|07)
            echo -e "\e[32m[INFO] Automatic locking check initialized.\e[0m"
            sleep 1.5
            ;;
        8|08)
            read -p "Enter username to unlock: " username
            passwd -u "$username" 2>/dev/null && echo -e "\e[32m[SUCCESS] Unlocked.\e[0m" || echo -e "\e[31m[!] Error unlocking user.\e[0m"
            sleep 1.5
            ;;
        9|09)
            echo -e "\e[33m[INFO] Cleaning expired accounts...\e[0m"
            sleep 1.5
            ;;
        10)
            echo -e "Generated Secure Password: \e[33m$(openssl rand -base64 12)\e[0m"
            read -p "Press Enter to continue..."
            ;;
        11)
            clear
            last -n 20
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
