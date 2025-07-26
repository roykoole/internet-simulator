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

echo "[+] Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1
sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'

echo "[+] Setting up iptables NAT rules..."
iptables -t nat -F
iptables -F

# Masquerade all outbound traffic through WAN_IFACE
iptables -t nat -A POSTROUTING -o $WAN_IFACE -j MASQUERADE

# Set FORWARD rules for each TESTNET interface
for entry in "${TESTNETS[@]}"; do
  IFACE=$(echo $entry | cut -d ' ' -f1)
  iptables -A FORWARD -i $IFACE -o $WAN_IFACE -j ACCEPT
  iptables -A FORWARD -i $WAN_IFACE -o $IFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
done

# Inter-TEST-NET routing
iptables -A FORWARD -i eth1 -o eth2 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT

iptables -A FORWARD -i eth1 -o eth3 -j ACCEPT
iptables -A FORWARD -i eth3 -o eth1 -j ACCEPT

iptables -A FORWARD -i eth2 -o eth3 -j ACCEPT
iptables -A FORWARD -i eth3 -o eth2 -j ACCEPT

echo "[+] NAT Gateway for TEST-NETs is now active."


echo "[+] Writing persistent dnsmasq DHCP configuration to /etc/dnsmasq.d/testnet.conf..."

mkdir -p /etc/dnsmasq.d

cat <<EOF > /etc/dnsmasq.d/testnet.conf
interface=eth1
interface=eth2
interface=eth3
bind-interfaces
domain-needed
bogus-priv
dhcp-range=192.0.2.100,192.0.2.200,12h
dhcp-range=198.51.100.100,198.51.100.200,12h
dhcp-range=203.0.113.100,203.0.113.200,12h
dhcp-option=option:dns-server,1.1.1.1
log-dhcp
EOF

echo "[+] Starting dnsmasq using persistent configuration..."
dnsmasq --conf-file=/etc/dnsmasq.d/testnet.conf

echo "[✓] Setup complete. DHCP running on eth1, eth2, eth3."

# Optional: create a boot-time local service to start dnsmasq
echo "[+] Installing startup script for dnsmasq..."

cat <<EOF > /etc/local.d/dnsmasq-dhcp.start
#!/bin/sh
dnsmasq --conf-file=/etc/dnsmasq.d/testnet.conf
EOF

chmod +x /etc/local.d/dnsmasq-dhcp.start
rc-update add local
