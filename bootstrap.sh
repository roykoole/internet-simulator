#!/bin/sh

set -e

echo "[+] Installing required packages..."
apk update
apk add --no-cache nano bash iproute2 iptables dnsmasq wget

echo "[+] Downloading ip.sh..."
wget -O /root/ip.sh https://raw.githubusercontent.com/roykoole/internet-simulator/main/ip.sh
chmod +x /root/ip.sh

echo "[+] Running ip.sh..."
bash /root/ip.sh

echo "[+] Setting up ip.sh to auto-run at boot..."
cp /root/ip.sh /etc/local.d/ipstart
chmod +x /etc/local.d/ipstart
rc-update add local default

echo "[✓] Setup complete. Rebooting in 10 seconds..."
sleep 10
reboot
