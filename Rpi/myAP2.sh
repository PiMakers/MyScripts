# sudo service dnsmasq restart
# sudo service dhcpcd restart
# sudo service hostapd restart
# sudo nanno /etc/dhcpcd.conf
# sudo systemctl daemon-reload
# sudo hostapd /etc/hostapd/hostapd.conf
# sudo nano /etc/hostapd/hostapd.conf

# cp /mnt/LinuxData/nexmon/patches/bcm43430a1/7_45_41_46/nexmon/brcmfmac_4.14.y-nexmon/brcmfmac.ko /lib/modules/4.14.34-v7+/kernel/drivers/net/wireless/broadcom/brcm80211/brcmfmac/brcmfmac.ko
#
intall_mod(){
sudo cp  myAP/fw/brcmfmac.ko.nexmon_7_45_41_46 /lib/modules/4.14.34-v7+/kernel/drivers/net/wireless/broadcom/brcm80211/brcmfmac/brcmfmac.ko
sudo cp myAP/fw/brcmfmac43430-sdio.bin.orig.nexmon_7_45_41_46 /lib/firmware/brcm/brcmfmac43430-sdio.bin
sudo depmod -a
}

uninstall_mod(){
sudo cp  myAP/fw/brcmfmac.ko.orig /lib/modules/4.14.34-v7+/kernel/drivers/net/wireless/broadcom/brcm80211/brcmfmac/brcmfmac.ko
sudo cp myAP/fw/brcmfmac43430-sdio.bin.orig /lib/firmware/brcm/brcmfmac43430-sdio.bin
sudo depmod -a
}

# 
# sudo dnsmasq -d -C create_ap_conf/dnsmasq.conf

# sudo net rpc shutdown -I 192.168.0.3 -U Administrator%Pepe374189
# wpa_passphrase myessid mypassword >> /etc/wpa_supplicant/wpasupplicant.conf


temp() {
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

sudo /bin/ip link set wlan0 down
sudo /bin/ip link set wlan0 name wlan1
sudo /sbin/iw phy phy0 interface add wlan0 type __ap
sudo /bin/ip link set wlan0 address b8:27:eb:c1:47:26

sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -s 192.168.12.0/24 ! -d 192.168.12.0/24 -j MASQUERADE
sudo dnsmasq -d -C create_ap_conf/dnsmasq.conf

sudo hostapd create_ap_conf/hostapd.conf



********************************* Bridge

sudo bash -c 'echo 1 > /proc/sys/net/ipv4/conf/all/proxy_arp'
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo ip ro add 192.168.0.59/32 dev eth0
}

wifi_login() {
#cat > /etc/
	wpa_passphrase $YOUR_SSID $YOUR_PASSWORD >> tmp.txt
}


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

create_udev_iface() {
get_new_macaddr wlan1
sudo bash -c 'cat > /etc/udev/rules.d/70-persistent-net.rules' << EOF
SUBSYSTEM=="ieee80211", ACTION=="add|change", ATTR{macaddress}=="${MAC_ADDRESS}", KERNEL=="phy0", \\
  RUN+="/bin/ip link set wlan0 name wlan1"  \\
  RUN+="/sbin/iw phy phy0 interface add wlan0 type __ap addr ${NEW_MAC_ADDRESS}"
#, \\
#  RUN+="/bin/ip link set wlan0 address ${NEW_MAC_ADDRESS}"
EOF
}

MAC_ADDRESS=$(get_macaddr wlan0)
NEW_MAC_ADDRESS=$(get_new_macaddr wlan0)
create_udev_iface
cat /etc/udev/rules.d/70-persistent-net.rules
