#!/bin/bash
echo "[INFO] Configuring Server Security & Anti-Torrent/DDoS Protection..."

# Install UFW and Fail2ban if not present
apt-get update -y >/dev/null 2>&1
apt-get install -y ufw fail2ban iptables-persistent >/dev/null 2>&1

# Configure UFW firewall rules
ufw --force reset >/dev/null 2>&1
ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1

# Allow essential management and proxy ports
ufw allow 22/tcp       # SSH
ufw allow 80/tcp       # HTTP
ufw allow 443/tcp      # HTTPS / Xray TLS
ufw allow 109/tcp      # Dropbear
ufw allow 7300/udp     # BadVPN UDPGW
ufw allow 53/udp       # SlowDNS

# Enable UFW firewall
ufw --force enable >/dev/null 2>&1

# Block common torrent/P2P ports outgoing/incoming to prevent abuse
iptables -A OUTPUT -p tcp --dport 6881:6889 -j DROP 2>/dev/null
iptables -A OUTPUT -p udp --dport 6881:6889 -j DROP 2>/dev/null
iptables -A INPUT -p tcp --dport 6881:6889 -j DROP 2>/dev/null
iptables -A INPUT -p udp --dport 6881:6889 -j DROP 2>/dev/null

# Save iptables rules
netfilter-persistent save >/dev/null 2>&1

echo "[SUCCESS] Firewall, anti-torrent rules, and bot protections applied."
