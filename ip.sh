#!/bin/bash

set -e

WAN_IFACE="eth0"

TESTNETS=(
  "eth1 192.0.2.1/24"     # TEST-NET-1
  "eth2 198.51.100.1/24"  # TEST-NET-2
  "eth3 203.0.113.1/24"   # TEST-NET-3
)

echo "[+] Configuring TEST-NET interfaces..."
for entry in "${TESTNETS[@]}"; do
  IFACE=$(echo $entry | cut -d ' ' -f1)
  IPADDR=$(echo $entry | cut -d ' ' -f2)

  echo "[+] Setting $IFACE with IP $IPADDR..."
  ip addr flush dev $IFACE
  ip addr add $IPADDR dev $IFACE
  ip link set $IFACE up
done

echo "[+] Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "[+] Setting up iptables NAT rules..."
iptables -t nat -F
iptables -F
iptables -t nat -A POSTROUTING -o $WAN_IFACE -j MASQUERADE

for entry in "${TESTNETS[@]}"; do
  IFACE=$(echo $entry | cut -d ' ' -f1)
  iptables -A FORWARD -i $IFACE -o $WAN_IFACE -j ACCEPT
  iptables -A FORWARD -i $WAN_IFACE -o $IFACE -j ACCEPT
done

echo "[+] Installing dnsmasq if not already installed..."
if ! command -v dnsmasq >/dev/null 2>&1; then
  apk update && apk add --no-cache dnsmasq
fi

echo "[+] Killing any running dnsmasq instance..."
pkill -f dnsmasq || true

echo "[+] Creating temporary dnsmasq config..."
DNSMASQ_CONF="/tmp/dnsmasq_testnet.conf"
cat > "$DNSMASQ_CONF" <<EOF
interface=eth1
dhcp-range=192.0.2.100,192.0.2.200,12h

interface=eth2
dhcp-range=198.51.100.100,198.51.100.200,12h

interface=eth3
dhcp-range=203.0.113.100,203.0.113.200,12h

bind-interfaces
log-dhcp
EOF

echo "[+] Starting dnsmasq with custom config..."
dnsmasq --conf-file="$DNSMASQ_CONF"

echo "[✓] Setup complete. DHCP running on eth1, eth2, eth3."
