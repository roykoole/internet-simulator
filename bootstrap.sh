#!/bin/bash

set -e

echo "[?] Do you want to run the setup (ip.sh) or cleanup (cleanup.sh)?"
echo "    Type 'setup' to run ip.sh or 'cleanup' to run cleanup.sh."
read -r USER_CHOICE

if [ "$USER_CHOICE" = "setup" ]; then

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
elif [ "$USER_CHOICE" = "cleanup" ]; then
  echo "[+] Downloading cleanup.sh..."
  wget -O /root/cleanup.sh https://raw.githubusercontent.com/roykoole/internet-simulator/main/cleanup.sh
  chmod +x /root/cleanup.sh

  echo "[+] Running cleanup.sh..."
  bash /root/cleanup.sh
  echo "[✓] Cleanup complete."
else
  echo "[!] Invalid choice. Exiting."
  exit 1
fi
