#!/bin/bash
set -e

# TODO

ROOT_DIR=maci
WIFI_INTERFACE=wlan0
AP_INTERFACE=ap0
WIFI_SSID="Ste@diAP"
WIFI_PWD="AsdfghjklkjhgfdsAsdfghjkl"
WPA_SSID="MyPPP"
WPA_PWD="12345678"
GATEAWAY="10.3.141.1"


# DNSMASQ_OPTS="$DNSMASQ_OPTS --local-service"
# ROOT_DS="/usr/share/dns/root.ds"

#if [ -f $ROOT_DS ]; then
#   DNSMASQ_OPTS="$DNSMASQ_OPTS `sed -e s/". IN DS "/--trust-anchor=.,/ -e s/" "/,/g $ROOT_DS | tr '\n' ' '`" 
#fi


get_macaddr() {
#    is_interface "$1" || return
    cat "/sys/class/net/${1}/address"
}

get_all_macaddrs() {
    cat /sys/class/net/*/address
}

get_new_macaddr() {
#    local OLDMAC NEWMAC LAST_BYTE i
    MAC_ADDRESS=$(get_macaddr "$1")
    LAST_BYTE=$(printf %d 0x${MAC_ADDRESS##*:})
#    mutex_lock
    for i in {1..255}; do
        NEW_MAC_ADDRESS="${MAC_ADDRESS%:*}:$(printf %02x $(( ($LAST_BYTE + $i) % 256 )))"
        (get_all_macaddrs | grep "$NEW_MAC_ADDRESS" > /dev/null 2>&1) || break
    done
#    mutex_unlock
    echo $NEW_MAC_ADDRESS
}

backup_everything() {
cp /lib/dhcpcd/dhcpcd-hooks/10-wpa_supplicant $ROOT_DIR/BackUp/10-wpa_supplicant
cp /etc/hostapd/hostapd.conf $ROOT_DIR/BackUp/hostapd.conf
cp /etc/dnsmasq.conf $ROOT_DIR/BackUp/dnsmasq.conf

}

create_udev_iface() {
get_new_macaddr ${WIFI_INTERFACE}
sudo bash -c 'cat > /etc/udev/rules.d/70-persistent-net.rules' << EOF
SUBSYSTEM=="ieee80211", ACTION=="add|change", ATTR{macaddress}=="${MAC_ADDRESS}", KERNEL=="phy0", \\
  RUN+="/sbin/iw phy phy0 interface add ${AP_INTERFACE} type __ap", \\
  RUN+="/bin/ip link set ${AP_INTERFACE} address ${NEW_MAC_ADDRESS}"
EOF
}


create_files() {
mkdir -p $ROOT_DIR/BackUp

# /etc/network/interfaces.d/ap
cat > /etc/network/interfaces.d/ap << EOF
# PubHub
allow-hotplug ${AP_INTERFACE}
auto ${AP_INTERFACE}
iface ${AP_INTERFACE} inet static
    address ${GATEAWAY}	#10.3.141.1
    netmask 255.255.255.0
EOF
#sudo chmod +x $ROOT_DIR/ap

# /etc/udev/rules.d/90-wireless.rules
get_new_macaddr ${WIFI_INTERFACE}
cat > /etc/udev/rules.d/90-wireless.rules << EOF
# PubHub
ACTION=="add", SUBSYSTEM=="ieee80211", KERNEL=="phy0", \\
 RUN+="/sbin/iw phy %k interface add ${AP_INTERFACE} type __ap" \\
 RUN+="/bin/ip link set ${AP_INTERFACE} address ${NEW_MAC_ADDRESS}"
EOF
# sudo chmod +x /etc/udev/rules.d/90-wireless.rules
cat /etc/udev/rules.d/90-wireless.rules

# /lib/dhcpcd/dhcpcd-hooks/10-wpa_supplicant
cat > /lib/dhcpcd/dhcpcd-hooks/10-wpa_supplicant << EOF
# PubHub
if [ -z "$wpa_supplicant_conf" ]; then
	for x in \
		/etc/wpa_supplicant/wpa_supplicant-"$interface".conf \
		/etc/wpa_supplicant/wpa_supplicant.conf \
		/etc/wpa_supplicant-"$interface".conf \
		/etc/wpa_supplicant.conf \
	; do
		if [ -s "$x" ]; then
			wpa_supplicant_conf="$x"
			break
		fi
	done
fi
: ${wpa_supplicant_conf:=/etc/wpa_supplicant.conf}

if [ "$ifwireless" = "1" ] && \
    type wpa_supplicant >/dev/null 2>&1 && \
    type wpa_cli >/dev/null 2>&1
then
	if [ "$reason" = "IPV4LL" ]; then
		wpa_supplicant -B -i${WIFI_INTERFACE} -f/var/log/wpa_supplicant.log -c/etc/wpa_supplicant/wpa_supplicant.conf
#		wpa_supplicant -B -i${WIFI_INTERFACE} -f/var/log/wpa_supplicant.log -c"$wpa_supplicant.conf"

	fi
fi
EOF
#chmod +x $ROOT_DIR/10-wpa_supplicant
}

create_files

cat > /etc/wpa_supplicant/wpa_supplicant.conf << EOF
# PubHub
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
country=HU
update_config=1

network={
    ssid="${WIFI_SSID}"
    scan_ssid=1
    psk="${WIFI_PWD}"
    key_mgmt=WPA-PSK
}
EOF
#wpa_cli reconfigure
cat /etc/wpa_supplicant/wpa_supplicant.conf

# Install the packages you need for DNS, Access Point and Firewall rules.
apt update || echo "HHHHHHOOOOOOOPPPPPPPP"
apt install -y hostapd dnsmasq iptables-persistent || echo "HHHHHHOOOOOOOPPPPPPPP"
apt autoremove autoclean clean

cat > /etc/hostapd/hostapd.conf << EOF
# PubHub
interface=${AP_INTERFACE}
ssid=${WPA_SSID}
hw_mode=g
channel=6
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=${WPA_PWD}
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF
echo -e "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\" \t\t# PubHub" >> /etc/default/hostapd

cat >> /etc/dnsmasq.conf << EOF

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -s 10.3.141.0/24 ! -d 10.3.141.0/24 -j MASQUERADE
iptables-save > /etc/iptables/rules.v4
reboot

# create_files
