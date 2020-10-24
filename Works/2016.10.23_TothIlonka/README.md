# SetUp

# https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md#internet-sharing

install_dependencies () {
sudo apt-get update
sudo apt-get upgrade

sudo apt-get install dnsmasq hostapd

sudo systemctl stop dnsmasq
sudo systemctl stop hostapd

sudo reboot
}
# Configuring a static IP
# We are configuring a standalone network to act as a server, so the Raspberry Pi needs to have a static IP address assigned to the wireless port. This documentation assumes that we are using the standard 192.168.x.x IP addresses for our wireless network, so we will assign the server the IP address 192.168.4.1. It is also assumed that the wireless device being used is wlan0.

configure_dhcpd () {
if [[ ! -f /etc/dhcpcd.conf.orig ]]; then
    echo "backup dhcpcd.config ..."
    sudo cp /etc/dhcpcd.conf /etc/dhcpcd.conf.orig
fi
    cat  << EOF | sudo tee /etc/dhcpcd.conf
interface wlan0
    static ip_address=10.0.0.1/24
    nohook wpa_supplicant
EOF
sudo service dhcpcd restart
sudo systemctl daemon-reload
}

configure_dnsmasq () {
    cat << EOF | sudo tee /etc/dnsmasq.d/TI.conf
interface=wlan0      # Use the require wireless interface - usually wlan0
dhcp-range=10.0.0.2,10.0.0.10,255.255.255.0,24h
EOF
}


sudo nano /etc/hostapd/hostapd.conf

# To use the 5 GHz band, you can change the operations mode from hw_mode=g to hw_mode=a. Possible values for hw_mode are:

#a = IEEE 802.11a (5 GHz)
#b = IEEE 802.11b (2.4 GHz)
#g = IEEE 802.11g (2.4 GHz)
#ad = IEEE 802.11ad (60 GHz).

interface=wlan0
driver=nl80211
ssid=T.I.Remote
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=TI159550
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP

sudo nano /etc/default/hostapd

DAEMON_CONF="/etc/hostapd/hostapd.conf"

sudo systemctl start hostapd
sudo systemctl start dnsmasq

Add routing and masquerade
Edit /etc/sysctl.conf and uncomment this line:

net.ipv4.ip_forward=1
Add a masquerade for outbound traffic on eth0:

sudo iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE
Save the iptables rule.

sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
Edit /etc/rc.local and add this just above "exit 0" to install these rules on boot.

iptables-restore < /etc/iptables.ipv4.nat
Reboot