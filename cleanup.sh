#!/bin/bash

set -e

echo "[−] Stopping dnsmasq..."
pkill -f dnsmasq || true

echo "[−] Removing iptables rules..."
iptables -F
iptables -t nat -F

echo "[−] Disabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=0
echo 0 > /proc/sys/net/ipv4/ip_forward

echo "[−] Flushing IP addresses from test interfaces..."
for IFACE in eth1 eth2 eth3; do
  ip addr flush dev $IFACE || true
  ip link set $IFACE down || true
done

echo "[−] Removing ipstart autostart script..."
rm -f /etc/local.d/ipstart
rc-update del local default || true

echo "[−] Cleanup complete."
