# 🛰️ WAN IP simulator

Simulate multiple WAN networks using an Alpine Linux VM. This project configures 3 isolated TEST-NET ranges with DHCP, NAT, and IP forwarding to simulate a router-like environment.

> ⚠️ **WARNING:** This is intended for **test environments only**. It reconfigures your network interfaces, replaces firewall rules, and modifies IP forwarding. Run it only on **clean Alpine VMs** dedicated to this purpose.

---

## 📦 What This Project Does

- Configures 3 isolated interfaces with TEST-NET IPs:
  - `eth1`: `192.0.2.1/24` (TEST-NET-1)
  - `eth2`: `198.51.100.1/24` (TEST-NET-2)
  - `eth3`: `203.0.113.1/24` (TEST-NET-3)
- Enables routing/NAT from those interfaces to the internet via `eth0`
- Assigns DHCP ranges to each interface using `dnsmasq`
- Auto-starts on every boot using Alpine's `local.d` service

---

## 🧱 Requirements

- Alpine Linux VM (tested on **Alpine 3.21 VM edition**)
- **4 network interfaces**:
  - `eth0`: must be connected to the internet (WAN/uplink)
  - `eth1`, `eth2`, `eth3`: local internal test networks

> 💡 Tip: Label your VM's network interfaces in your hypervisor (e.g., VMware, VirtualBox) to match IP ranges — it makes them easier to manage.

---

## ⚡ Quick Start (Automatic Install)

Run this **single command as root** in your Alpine VM:

```sh
wget -O - https://raw.githubusercontent.com/roykoole/internet-simulator/main/bootstrap.sh | sh
```

This will:
- Install required packages (`bash`, `iptables`, `dnsmasq`, etc.)
- Download and run the configuration script
- Enable persistent boot-time startup
- Reboot into a fully working simulated environment

---

## 🔧 Manual Setup (Advanced Users)

If you prefer manual steps:

```sh
# Install dependencies
apk add nano bash iproute2 iptables dnsmasq wget

# Download and run the main script
wget https://raw.githubusercontent.com/roykoole/internet-simulator/main/ip.sh
chmod +x ip.sh
bash ./ip.sh

# Enable on boot using Alpine's local.d
cp ./ip.sh /etc/local.d/ipstart
chmod +x /etc/local.d/ipstart
rc-update add local default

# Reboot
halt
```

---

## 🌐 DHCP Setup Details

Each interface will act as a mini-subnet with its own pool:

| Interface | IP Address      | DHCP Range             |
|-----------|------------------|------------------------|
| `eth1`    | 192.0.2.1/24     | 192.0.2.100 – .200     |
| `eth2`    | 198.51.100.1/24  | 198.51.100.100 – .200  |
| `eth3`    | 203.0.113.1/24   | 203.0.113.100 – .200   |

---

## ♻️ Cleanup

If you need to undo everything, run:

```sh
wget https://raw.githubusercontent.com/roykoole/internet-simulator/main/cleanup.sh
chmod +x cleanup.sh
./cleanup.sh
```

This will:
- Stop DHCP
- Clear interface IPs
- Remove iptables rules
- Disable boot-time startup

---

## 🔐 Security Considerations

- This setup **removes all existing iptables rules** — avoid using on shared or production systems.
- Run only in **sandboxed VMs** where network isolation is guaranteed.
- DHCP pools are limited to reserved TEST-NET addresses and won’t conflict with real networks.

---

## 📁 Files in This Repository

- `ip.sh`: The main setup script
- `bootstrap.sh`: Automated one-liner installer
- `cleanup.sh`: Restores the VM to a clean state

---

## 🧪 Tested With

- Alpine Linux 3.21 (VirtualBox & VMware)
- 4 NICs (1 internet-connected, 3 internal-only)
- Clients like Kali Linux, Windows, TinyCore connected to each subnet

---

## 🛠️ Future Improvements (optional)

- Web dashboard for live interface monitoring
- Support for IPv6 test nets
- Optional DNS proxy or captive portal simulation

---

## 📜 License

MIT — use freely, but do so responsibly and never on shared or production infrastructure.

---

**Enjoy building your test lab!**