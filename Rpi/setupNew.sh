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

check_root() {
    # Must be root to install the hotspot
    echo ":::"
    if [[ $EUID -eq 0 ]];then
        echo "::: You are root - OK"
    else
        echo "::: sudo will be used for the install."
        # Check if it is actually installed
        # If it isn't, exit because the install cannot complete
        if [[ $(dpkg-query -s sudo) ]];then
            export SUDO="sudo"
            export SUDOE="sudo -E"
        else
            echo "::: Please install sudo or run this as root."
            exit 1
        fi
    fi
}
################
export LC_ALL=C

error () {
    echo "ERROR: $1"
}

set_defaults() {
    IS_RASPBIAN_LITE=0
    MAC_ADDRESS="$(cat /sys/class/net/wlan0/address)" || error ${MAC_ADDRESS}
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
    IS_CHROOTED=$(echo "${SUDO_COMMAND}" | grep -qv chroot; echo "$?")

    # (grep 'export LC_ALL=C' /boot/config.txt | sed -i 's/#//' || echo ".bashrc already patched" ) || \
    sed -i '/export LC_ALL=C/d' $HOME/.bashrc && echo "export LC_ALL=C" >> $HOME/.bashrc
}
# update_upgrade
update_upgrade () {
  ${SUDO} apt -y update
  echo "Upgrading..."
  ${SUDO} apt -y upgrade 2>&1 | grep -q autoremove && ${SUDO} apt -y autoremove --purge || echo "NOTHING TO AUTOREMOVE"
  ${SUDO} apt autoclean
  ${SUDO} apt clean
  echo "update Done!"
}

enable_ssh() {
    ${SUDO} touch /boot/ssh
}

change_login_pwd() {
    ${SUDOE} bash -c 'echo "pi:${NEW_LOGIN_PASSWD}" | chpasswd'
}

set_hostname() {
    #CURRENT_HOSTNAME=$(${SUDO} cat /etc/hostname | tr -d " \t\n\r")
    export CURRENT_HOSTNAME=$(cat /etc/hostname)
    ${SUDOE} bash -c 'echo ${NEW_HOSTNAME} > /etc/hostname'
    ${SUDOE} sed -i "s/127.0.1.1.*${CURRENT_HOSTNAME}/127.0.1.1\t${NEW_HOSTNAME}/g" /etc/hosts
}

remove_unused() {
    err=$(apt -y purge libreoffice* minecraft-pi wolfram-engine scratch* 2>&1) 		|| echo "ERROR: $err"
}

# Install dependencies
Install_dependencies () {
  echo "Installing dependences (dnsmasq hostapd arp-scan nfs-kernel-server haveged) ..."
  list="dnsmasq hostapd haveged"
  ${SUDO} apt -y install "${list}"    #dnsmasq hostapd haveged #arp-scan nfs-kernel-server haveged
  ${SUDO} service hostapd stop && ${SUDO} service dnsmasq stop
  echo "Done!"			
}

# Install OF dependencies
# If OF_ROOT not defined OF won't be updated!!!!!!!!!!!!!!!!!!!!!!
Install_OF_dependencies() {
    echo "Installing OF dependences ..."
    BASE_URL="https://raw.githubusercontent.com/openframeworks/openFrameworks/master/scripts/linux"
    OS=$(cat  /etc/os-release | grep '^ID=' | sed s/^'ID='//) && echo "OS=$OS"
    curl -l ${BASE_URL}/$OS/install_dependencies.sh | sed 's/$ROOT/${OF_ROOT}/g; 2 i\\n\"1\"=\"-y\"' | ${SUDOE} bash -s
    curl -l ${BASE_URL}/$OS/install_codecs.sh | sed 's/$ROOT/${OF_ROOT}/g; 2 i\\n\"1\"=\"-y\"' | ${SUDOE} bash -s
    echo "Done!"
}

# Make absolut path to relativ (for cross rootfs)
relativeSoftLinks(){
    #TODO make this multi threaded
    CWD=$PWD
    local path=('/usr/lib' '/usr/lib/arm-linux-gnueabihf')
    #path+=' /usr/lib/gcc/arm-linux-gnueabihf/6' # not shure not good !!
    for lnk in ${path[@]}; do
    echo "changeing links to relative in $lnk ..."
    cd ${lnk}
        for link in $(ls -la | grep "\-> /" | sed "s/.* \([^ ]*\) \-> \/\(.*\)/\1->\/\2/g"); do 
            lib=$(echo $link | sed "s/\(.*\)\->\(.*\)/\1/g"); 
            link=$(echo $link | sed "s/\(.*\)\->\(.*\)/\2/g"); 
            ${SUDO} rm $lib
            ${SUDO} ln -s ../../..$link $lib 
        done

        for f in *; do 
            error=$(grep " \/lib/" $f > /dev/null 2>&1; echo $?) 
            if [ $error -eq 0 ]; then 
                ${SUDO} sed -i "s/ \/lib/ ..\/..\/..\/lib/g" $f
                ${SUDO} sed -i "s/ \/usr/ ..\/..\/..\/usr/g" $f
            fi
        done
    done
    cd $CWD
}

# install_createAP
install_createAP() {
    cd /tmp
    ${SUDO} git clone https://github.com/oblique/create_ap
    cd create_ap
    ${SUDO} make install
}

add_wpa_supplicant_conf() {
    ${SUDOE} bash -c 'cat > /etc/wpa_supplicant/wpa_supplicant-${WIFI_INTERFACE}.conf' << EOF
# PubHub
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=HU
  
network={
    ssid="${INET_SSID}"
    psk="${WIFI_PWD}"
    key_mgmt=WPA-PSK
}
EOF
}

## silent_boot https://scribles.net/silent-boot-on-raspbian-stretch-in-console-mode/
silent_boot() {
   echo -e "1. Disabling \“Welcome to PIXEL” splash...\"\n"
      ${SUDO} systemctl mask plymouth-start.service

   echo -e "2. Removing Rainbow Screen...\n"

      ${SUDO} grep -q '^disable_splash' /boot/config.txt || \
      ${SUDO} grep -q '# disable_splash' /boot/config.txt && \
      ${SUDO} sed -i '/^# disable_splash/ s/# //' /boot/config.txt || \
      ( ${SUDO} bash -c 'echo -e "\n# Disable rainbow image at boot\t\t#PubHub" >> /boot/config.txt' && \
      ${SUDO} bash -c 'echo -e "disable_splash=1\t\t\t#PubHub" >> /boot/config.txt' )
   

   echo -e "3. Removing Raspberry Pi logo and blinking cursor adding:" \
           "\n   \"tty=3 logo.nologo vt.global_cursor_default=0\"" \
           "\n   at the end of the line in \"/boot/cmdline.txt\".\n"
	   # ${SUDO} grep -q 'logo.nologo' /boot/cmdline.txt || ${SUDO} sed -i 's/$/ logo.nologo/' /boot/cmdline.txt
	   ${SUDO} sed -i 's/ logo.nologo//g; s/ vt.global_cursor_default=0//g; s/console=tty1/console=tty3/;
         s/$/ logo.nologo vt.global_cursor_default=0/' /boot/cmdline.txt
      # ${SUDO} grep -q 'vt.global_cursor_default=0' /boot/cmdline.txt || ${SUDO} sed -i 's/$/ vt.global_cursor_default=0/' /boot/cmdline.txt
      # ${SUDO} grep -q 'tty=3' /boot/cmdline.txt || ${SUDO} sed -i 's/console=tty1/console=tty3/' /boot/cmdline.txt

   echo -e "4. Removing login message\n"
      touch ~/.hushlogin

   echo -e "5. Remove autologin message by modify/create /etc/systemd/system/getty@tty1.service.d/autologin.conf"
      ${SUDO} bash -c 'cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf' << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear --skip-login --noissue --login-options "-f pi" %I \$TERM
EOF
#   ${SUDO} sed -i '/^ExecStart=/ s/--autologin pi --noclear/--skip-login --noclear --noissue --login-options "-f pi"/' /etc/systemd/system/autologin\@.service

   echo -e "6. Change Boot To Cli\n"
      [ -f /etc/systemd/system/default.target ] && ${SUDO} rm /etc/systemd/system/default.target 
      ${SUDO} ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
}

more() {
# Populate `/etc/udev/rules.d/70-persistent-net.rules`

create_virtual_interface(){
${SUDO} bash -c 'cat > /etc/udev/rules.d/70-persistent-net.rules' << EOF
SUBSYSTEM=="ieee80211", ACTION=="add|change", ATTR{macaddress}=="${MAC_ADDRESS}", KERNEL=="phy0", \
RUN+="/sbin/iw phy phy0 interface add ap0 type __ap", \
RUN+="/bin/ip link set ap0 address ${MAC_ADDRESS}
EOF
}

# Populate `/etc/dnsmasq.conf`
configure_dnsmasq(){
[ -f /etc/dnsmasq.conf.orig ] || ${SUDO} cp /etc/dnsmasq.conf /etc/dnsmasq.conf.orig || echo "dnsmasq.conf backup failed!!!"
${SUDO} bash -c 'cat > /etc/dnsmasq.conf' << EOF
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
${SUDO} bash -c 'cat > /etc/hostapd/hostapd.conf' << EOF
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
wpa=2
wpa_passphrase=${AP_PASSPHRASE}
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP CCMP
rsn_pairwise=CCMP
EOF


# Populate `/etc/default/hostapd`
${SUDO} bash -c 'cat > /etc/default/hostapd' << EOF
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF
}


# Populate `/etc/wpa_supplicant/wpa_supplicant.conf`
${SUDO} bash -c 'cat > /etc/wpa_supplicant/wpa_supplicant.conf' << EOF
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
${SUDO} bash -c 'cat > /etc/network/interfaces' << EOF
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
${SUDO} bash -c 'cat > /bin/start_wifi.sh' << EOF
echo 'Starting Wifi AP and client...'
${SUDO} sysctl -w net.ipv4.ip_forward=1
${SUDO} iptables -t nat -A POSTROUTING -s 192.168.10.0/24 ! -d 192.168.10.0/24 -j MASQUERADE
# ${SUDO} systemctl restart dnsmasq
EOF
${SUDO} chmod +x /bin/start_wifi.sh
crontab -l | { cat; echo "@reboot /bin/start_wifi.sh"; } | crontab -
echo "Wifi configuration is finished! Please reboot your Raspberry Pi to apply changes..."

}

NewPi(){
    cmd="ssh -X pi@192.168.0.58"

    #shoud ssh in
    #change user&pwd
    #update&upgrade
    $cmd ${SUDO} apt -y update && ${SUDO} apt -y upgrade

    #install requvired progs: nfs-kernel-server nfs-common hostapd dnsmasq
    $cmd ${SUDO} apt install -y nfs-kernel-server nfs-common hostapd dnsmasq

    #setup nfs

}

setup() {
check_root
relativeSoftLinks &
update_upgrade
enable_ssh
change_login_pwd
set_hostname
add_wpa_supplicant_conf ## setup wifi inet
}

# change_login_pwd
setup


# set_defaults
# remove_unused
# Install_dependencies
# Install_OF_dependencies
# relativeSoftLinks
# cd $RPI_ROOT/usr/lib/gcc/arm-linux-gnueabihf/6

# silent_boot

#create_virtual_interface
#configure_dnsmasq