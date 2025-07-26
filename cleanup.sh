#!/bin/bash

set -e

echo "[+] Stopping dnsmasq service..."
pkill -f dnsmasq || echo "[!] dnsmasq not running."

echo "[+] Removing dnsmasq configuration..."
rm -f /etc/dnsmasq.d/testnet.conf
rm -f /etc/local.d/dnsmasq-dhcp.start

echo "[+] Flushing IP addresses from interfaces..."
for iface in eth1 eth2 eth3; do
  ip addr flush dev $iface || echo "[!] Failed to flush $iface."
  ip link set $iface down || echo "[!] Failed to bring $iface down."
done

echo "[+] Disabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=0
echo 0 > /proc/sys/net/ipv4/ip_forward

echo "[+] Clearing iptables rules..."
iptables -t nat -F
iptables -F

echo "[+] Removing ip.sh auto-run configuration..."
rm -f /etc/local.d/ipstart

echo "[+] Removing cleanup.sh itself (optional)..."
rm -f /root/cleanup.sh

echo "[✓] Cleanup complete. System is restored to its original state."
