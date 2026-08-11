#!/bin/bash
# SSH Manager Module

clear
echo "====================================="
echo "           SSH MANAGER               "
echo "====================================="
read -p "Enter new username: " username
read -p "Enter password: " password
read -p "Enter active days (e.g., 30): " days

exp_date=$(date -d "+$days days" +"%Y-%m-%d")

if id "$username" &>/dev/null; then
    echo -e "\e[31m[ERROR]\e[0m User already exists!"
else
    useradd -e "$exp_date" -M -s /bin/false "$username"
    echo "$username:$password" | chpasswd
    echo -e "\e[32m[SUCCESS]\e[0m SSH Account Created!"
    echo "Username: $username"
    echo "Password: $password"
    echo "Expires : $exp_date"
fi

read -n 1 -s -r -p "Press any key to return to menu..."
