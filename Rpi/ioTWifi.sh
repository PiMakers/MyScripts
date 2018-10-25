# SETTING UP A RASPBERRY PI AS AN ACCESS POINT IN A STANDALONE NETWORK (NAT)
# https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md#internet-sharing

#/bin/bash

set -e

# iptables-restore < /etc/iptables.ipv4.nat
# sysctl -w net.ipv4.ip_forward=1
# sudo iptables -t nat -D  POSTROUTING -o eth0 -j MASQUERADE
# iptables-restore < /etc/iptables.ipv4.nat # PubHub
# cat /proc/sys/net/ipv4/ip_forward

update() {
sudo apt-get update
sudo apt-get upgrade
}

install_dependencies() {
sudo apt-get install dnsmasq hostapd

## Since the configuration files are not ready yet, turn the new software off as follows:
sudo systemctl stop dnsmasq
sudo systemctl stop hostapd
}

Configuring_static_IP() {
cat >> /etc/dhcpcd.conf << EOF
interface wlan0
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant
EOF

sudo service dhcpcd restart

# dnsmasq_conf
sudo cp /etc/dnsmasq.conf /etc/dnsmasq.conf.orig  
cat >> /etc/dnsmasq.conf << EOF
# PubHub
interface=wlan0      # Use the require wireless interface - usually wlan0
  dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
EOF

# hostapd_conf
cat > /etc/hostapd/hostapd.conf << EOF
interface=wlan0
driver=nl80211
ssid=NameOfNetwork
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=12345678
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

cat >> /etc/default/hostapd << EOF
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF

sudo systemctl start hostapd
sudo systemctl start dnsmasq

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo 1 > \/proc\/sys\/net\/ipv4\/ip_forward #RASPAP'
# iptables -t nat -A POSTROUTING -j MASQUERADE #RASPAP'

iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE

}


update
install_dependencies
Configuring_static_IP
