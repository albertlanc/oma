#!/bin/bash
while true; do
    clear
    echo -e "\e[38;5;51m╔════════════════════════════════════════════════════════╗\e[0m"
    echo -e "\e[38;5;51m║\e[0m \e[1m\e[38;5;214m                  SSH ACCOUNT MANAGER                   \e[0m\e[38;5;51m║\e[0m"
    echo -e "\e[38;5;51m╚════════════════════════════════════════════════════════╝\e[0m"
    echo -e "  \e[38;5;51m[1]\e[0m \e[36mCreate SSH User (with Pub Key)\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[2]\e[0m \e[36mDelete SSH User\e[0m"
    echo -e ""
    echo -e "  \e[38;5;51m[3]\e[0m \e[36mList Active SSH Users\e[0m"
    echo -e ""
    echo -e "  \e[38;5;196m[0]\e[0m \e[31mBack to Main Menu\e[0m"
    echo -e "\e[38;5;51m════════════════════════════════════════════════════════\e[0m"
    read -p " Select an option [0-3]: " ssh_opt

    case $ssh_opt in
        1)
            read -p "Enter new username: " username
            if id "$username" &>/dev/null; then
                echo -e "\e[31m[!] User already exists!\e[0m"
            else
                read -p "Enter password for $username: " password
                useradd -m -s /bin/bash "$username"
                echo "$username:$password" | chpasswd
                
                # Generate SSH Key pair for the user
                sudo -u "$username" mkdir -p /home/"$username"/.ssh
                sudo -u "$username" ssh-keygen -t rsa -b 2048 -N "" -f /home/"$username"/.ssh/id_rsa >/dev/null 2>&1
                sudo -u "$username" cp /home/"$username"/.ssh/id_rsa.pub /home/"$username"/.ssh/authorized_keys
                chmod 700 /home/"$username"/.ssh
                chmod 600 /home/"$username"/.ssh/authorized_keys
                
                PUBKEY=$(cat /home/"$username"/.ssh/id_rsa.pub)
                
                clear
                echo -e "\e[32m[SUCCESS] SSH User created successfully!\e[0m"
                echo -e "────────────────────────────────────────────────────────"
                echo -e "Username : $username"
                echo -e "Password : $password"
                echo -e "Public Key:\n\e[33m$PUBKEY\e[0m"
                echo -e "────────────────────────────────────────────────────────"
            fi
            read -p "Press Enter to continue..."
            ;;
        2)
            read -p "Enter username to delete: " username
            if id "$username" &>/dev/null; then
                userdel -r "$username"
                echo -e "\e[32m[SUCCESS] User $username deleted.\e[0m"
            else
                echo -e "\e[31m[!] User does not exist.\e[0m"
            fi
            sleep 1.5
            ;;
        3)
            clear
            echo -e "\e[33m--- Active SSH Users ---:\e[0m"
            awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd
            read -p "Press Enter to continue..."
            ;;
        0)
            break
            ;;
        *)
            echo -e "\e[31m[!] Invalid option.\e[0m"
            sleep 1.5
            ;;
    esac
done
