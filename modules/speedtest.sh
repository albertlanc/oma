#!/bin/bash
CYAN='\e[36m'; GREEN='\e[32m'; YELLOW='\e[33m'; NC='\e[0m'

clear
echo -e "${CYAN}==========================================${NC}"
echo -e "          SERVER SPEED & PING TEST         "
echo -e "${CYAN}==========================================${NC}"

echo -e "\n${YELLOW}[INFO] Testing connection to Google & Cloudflare...${NC}\n"

echo -e "${GREEN}1. Latency (Ping) Test:${NC}"
ping -c 4 8.8.8.8

echo -e "\n${GREEN}2. Server Download Speed Test (100MB chunk):${NC}"
curl -o /dev/null --progress-bar https://speed.cloudflare.com/__down?bytes=104857600

echo -e "\n${GREEN}[✓] Speed test completed successfully!${NC}"
echo ""
read -p "Press Enter to return to the menu..."
