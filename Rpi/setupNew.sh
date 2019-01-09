#!/bin/bash

# The script configures simultaneous AP and Managed Mode Wifi on Raspberry Pi Zero W (should also work on Raspberry Pi 3)
# Usage: curl https://gist.githubusercontent.com/lukicdarkoo/6b92d182d37d0a10400060d8344f86e4/raw | sh -s WifiSSID WifiPass APSSID APPass
# Licence: GPLv3
# Author: Darko Lukic <lukicdarkoo@gmail.com>
# Special thanks to: https://albeec13.github.io/2017/09/26/raspberry-pi-zero-w-simultaneous-ap-and-managed-mode-wifi/

# Useful commands:
# vcgencmd display_power 0/1	# turn monitor off/on
# sed -i '/<pattern>/s/^#*/#/g' file #(to comment out)
# sed -i '/<pattern>/s/^#*//g' file #(to uncomment)

set -e

checkRoot () {
if [ $EUID != 0 ]; then
	echo "this script must be run as root"
	echo ""
	echo "usage:"
	echo "sudo "$0
	exit $exit_code
fi
}

set_defaults() {
IS_RASPBIAN_LITE=0
MAC_ADDRESS="$(cat /sys/class/net/wlan0/address)"
CLIENT_SSID="Ste@diAP"
#"${1}"
CLIENT_PASSPHRASE="AsdfghjklkjhgfdsAsdfghjkl"
#"${2}"
AP_SSID="PubHubAP"
#"${3}"
AP_PASSPHRASE="12345678"
#"${4}"
ROOT=$(dirname "$0")
OS=$(cat  /etc/os-release | sed '/^'ID='/!d;s/^'ID='//')


# (grep 'export LC_ALL=C' /boot/config.txt | sed -i 's/#//' || echo ".bashrc already patched" ) || \
sed -i '/export LC_ALL=C/d' $HOME/.bashrc && echo "export LC_ALL=C" >> $HOME/.bashrc
}

remove_unused() {
err=$(apt -y purge libreoffice* minecraft-pi wolfram-engine scratch* 2>&1) 		|| echo "ERROR: $err"
}

# update_upgrade
update_upgrade(){
  sudo apt -y update
  sudo apt -y upgrade 2>&1 | grep -q autoremove && sudo apt -y autoremove --purge || echo "NOTHING TO AUTOREMOVE"
  sudo apt autoclean
  sudo apt clean
  echo "update Done!"
}



# Install dependencies
Install_dependencies() {
  echo "Installing dependences (dnsmasq hostapd arp-scan nfs-kernel-server codeblocks haveged) ..."
  sudo apt -y install dnsmasq hostapd arp-scan nfs-kernel-server codeblocks haveged curl
  sudo service hostapd stop && sudo service dnsmasq stop
  echo "Done!"			
}

# Install OF dependencies
Install_OF_dependencies() {
  echo "Installing OF dependences ..."
BASE_URL="https://raw.githubusercontent.com/openframeworks/openFrameworks/master/scripts/linux"
OS=$(cat  /etc/os-release | grep '^ID=' | sed s/^'ID='//) && echo "OS=$OS"
curl -l ${BASE_URL}/$OS/install_dependencies.sh | sed 's/apt-get/apt-get -y/' | sudo bash -s
curl -l ${BASE_URL}/$OS/install_codecs.sh | sed 's/apt-get/apt-get -y/' | sudo bash -s
  echo "Done!"
}

# Make absolut path to relativ (for cross rootfs)
relativeSoftLinks(){
#TODO make this multi threaded
local path=('/usr/lib' '/usr/lib/arm-linux-gnueabihf')
for lnk in ${path[@]}; do
echo "changeing links to relative in $lnk ..."
 cd ${lnk}
    for link in $(ls -la | grep "\-> /" | sed "s/.* \([^ ]*\) \-> \/\(.*\)/\1->\/\2/g"); do 
        lib=$(echo $link | sed "s/\(.*\)\->\(.*\)/\1/g"); 
        link=$(echo $link | sed "s/\(.*\)\->\(.*\)/\2/g"); 
        rm $lib
        ln -s ../../..$link $lib 
    done

    for f in *; do 
        error=$(grep " \/lib/" $f > /dev/null 2>&1; echo $?) 
        if [ $error -eq 0 ]; then 
            sed -i "s/ \/lib/ ..\/..\/..\/lib/g" $f
            sed -i "s/ \/usr/ ..\/..\/..\/usr/g" $f
        fi
    done
done
}



# install_createAP
install_createAP() {
    cd /tmp
    sudo git clone https://github.com/oblique/create_ap
    cd create_ap
    sudo make install
}

# silent_boot https://scribles.net/silent-boot-on-raspbian-stretch-in-console-mode/
silent_boot() {
echo "1. Disabling \“Welcome to PIXEL” splash...\"\n"
systemctl mask plymouth-start.service

echo "2. Removing Rainbow Screen...\n"

grep '^disable_splash' /boot/config.txt || \
grep '# disable_splash' /boot/config.txt && \
sed -i '/^# disable_splash/ s/# //' /boot/config.txt || \
( echo -e "\n# Disable rainbow image at boot\t\t#PubHub" >> /boot/config.txt && \
echo -e "disable_splash=1\t\t\t#PubHub" >> /boot/config.txt )

echo "3. Removing: Raspberry Pi logo and blinking cursor\n Adding: 'loglevel=3' from/to /boot/cmdline.txt"
echo "by adding \"logo.nologo vt.global_cursor_default=0\" at the end of the line in \"/boot/cmdline.txt\".\n"
	grep 'logo.nologo' /boot/cmdline.txt || sed -i 's/$/ logo.nologo/' /boot/cmdline.txt
	grep 'vt.global_cursor_default=0' /boot/cmdline.txt || sed -i 's/$/ vt.global_cursor_default=0/' /boot/cmdline.txt
    IS_RASPBIAN_LITE && echo "Raspbian Lite detected!!\n" && \
    (grep 'loglevel=3' /boot/cmdline.txt || sed -i 's/$/ loglevel=3/' /boot/cmdline.txt) || echo "Raspbian Lite Not Detected!!\n"

echo "4. Removing login message\n"
touch ~/.hushlogin

echo "5. Remove autologin message by modify autologin service\n"
sed -i '/^ExecStart=/ s/--autologin pi --noclear/--skip-login --noclear --noissue --login-options "-f pi"/' /etc/systemd/system/autologin\@.service
}


more() {
# Populate `/etc/udev/rules.d/70-persistent-net.rules`
create_virtual_interface(){
sudo bash -c 'cat > /etc/udev/rules.d/70-persistent-net.rules' << EOF
SUBSYSTEM=="ieee80211", ACTION=="add|change", ATTR{macaddress}=="${MAC_ADDRESS}", KERNEL=="phy0", \
RUN+="/sbin/iw phy phy0 interface add ap0 type __ap", \
RUN+="/bin/ip link set ap0 address ${MAC_ADDRESS}
EOF
}

# Populate `/etc/dnsmasq.conf`
configure_dnsmasq(){
sudo bash -c 'cat > /etc/dnsmasq.conf' << EOF
interface=lo,ap0
no-dhcp-interface=lo,wlan0
bind-interfaces
server=8.8.8.8
domain-needed
bogus-priv
dhcp-range=192.168.10.50,192.168.10.150,12h
EOF
}

# Populate `/etc/hostapd/hostapd.conf`
configure_hostapd(){
sudo bash -c 'cat > /etc/hostapd/hostapd.conf' << EOF
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
interface=ap0
driver=nl80211
ssid=${AP_SSID}
hw_mode=g
channel=11
wmm_enabled=0
macaddr_acl=0
auth_algs=1
wpa=2PASSPHRASE
wpa_passphrase=${AP_PASSPHRASE}
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP CCMP
rsn_pairwise=CCMP
EOF


# Populate `/etc/default/hostapd`
sudo bash -c 'cat > /etc/default/hostapd' << EOF
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF
}


# Populate `/etc/wpa_supplicant/wpa_supplicant.conf`
sudo bash -c 'cat > /etc/wpa_supplicant/wpa_supplicant.conf' << EOF
country=HU
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="${CLIENT_SSID}"
    psk="${CLIENT_PASSPHRASE}"
    id_str="AP1"
}
EOF

# Populate `/etc/network/interfaces`
sudo bash -c 'cat > /etc/network/interfaces' << EOF
source-directory /etc/network/interfaces.d

auto lo
auto ap0
auto wlan0
iface lo inet loopback

allow-hotplug ap0
iface ap0 inet static
    address 192.168.10.1
    netmask 255.255.255.0
    hostapd /etc/hostapd/hostapd.conf

allow-hotplug wlan0
iface wlan0 inet manual
    wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf
iface AP1 inet dhcp
EOF

# Populate `/bin/start_wifi.sh`
sudo bash -c 'cat > /bin/start_wifi.sh' << EOF
echo 'Starting Wifi AP and client...'
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -s 192.168.10.0/24 ! -d 192.168.10.0/24 -j MASQUERADE
# sudo systemctl restart dnsmasq
EOF
sudo chmod +x /bin/start_wifi.sh
crontab -l | { cat; echo "@reboot /bin/start_wifi.sh"; } | crontab -
echo "Wifi configuration is finished! Please reboot your Raspberry Pi to apply changes..."

}

NewPi(){
cmd="ssh -X pi@192.168.0.58"

#shoud ssh in
#change user&pwd
#update&upgrade
$cmd sudo apt -y update && sudo apt -y upgrade

#install requvired progs: nfs-kernel-server nfs-common hostapd dnsmasq
$cmd sudo apt install -y nfs-kernel-server nfs-common hostapd dnsmasq

#setup nfs

}


# checkRoot
# set_defaults
# remove_unused
# update_upgrade
# Install_dependencies
# Install_OF_dependencies
# cd $RPI_ROOT/usr/lib
# relativeSoftLinks
# cd $RPI_ROOT/usr/lib/arm-linux-gnueabihf
# relativeSoftLinks
# cd $RPI_ROOT/usr/lib/gcc/arm-linux-gnueabihf/6
# relativeSoftLinks # maybe not nessery
# silent_boot

#create_virtual_interface
#configure_dnsmasq
