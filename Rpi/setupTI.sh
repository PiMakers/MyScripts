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
# http://www.sgv417.jp/~makopi/blog/wp-content/uploads/2017/09/03-VPN_Router_Mode.txt

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

get_init_sys() {
  if command -v systemctl > /dev/null && systemctl | grep -q '\-\.mount'; then
    SYSTEMD=1
  elif [ -f /etc/init.d/cron ] && [ ! -h /etc/init.d/cron ]; then
    SYSTEMD=0
  else
    echo "Unrecognised init system"
    return 1
  fi
  echo "SYSTEMD=$SYSTEMD"
}

set_defaults() {
export LC_ALL=C

WLAN_AP=wlan0
AP_SSID="T.I.Remote"
AP_PASSPHRASE="TI159550"

NEW_HOSTNAME=TIremote

#set hostname
CURRENT_HOSTNAME=$(${SUDO} cat /etc/hostname | tr -d " \t\n\r")
${SUDO} bash -c "echo ${NEW_HOSTNAME} > /etc/hostname"
${SUDO} sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts

# (grep 'export LC_ALL=C' /boot/config.txt | sed -i 's/#//' || echo ".bashrc already patched" ) || \
[ -z $SUDO_USER ] && IS_CHROOT=0 || IS_CHROOT=1

#RASPBIAN_TYPE=$(${SUDO} grep /)

[ -f /etc/os-release ] && OS=$(cat  /etc/os-release | sed '/^'ID='/!d;s/^'ID='//')

# (grep 'export LC_ALL=C' /boot/config.txt | sed -i 's/#//' || echo ".bashrc already patched" ) || \
echo "enabling ssh"
${SUDO} touch /boot/ssh
# ~/.profile not created automaticli
${SUDO} cp /etc/skel/.profile ~/.profile

# change passwd:
${SUDO} bash -c 'echo "pi:raspi" | chpasswd'
}

# update_upgrade
update_upgrade () {
  ${SUDO} apt -y update 
  echo "Upgrading..."
  ${SUDO} apt -y upgrade | grep -q autoremove && ${SUDO} apt -y autoremove --purge || echo "NOTHING TO AUTOREMOVE"
  ${SUDO} apt autoclean
  ${SUDO} apt clean
  echo "$0: Done!"
}

# Install dependencies
Install_dependencies () {
    dependencies="dnsmasq hostapd haveged node.js npm"
    echo "Installing dependences ( $dependencies ) ..."
    ${SUDO} apt -y install $dependencies    #dnsmasq hostapd haveged #arp-scan nfs-kernel-server haveged
    [[ $IS_CHROOT == 0 ]] && ${SUDO} service hostapd stop && ${SUDO} service dnsmasq stop
    echo "$0: Done!"
}

configure_hostapd() {
    echo "Configurering hostapd"
    echo "Writing conf (/etc/hostapd/hostapd.conf) ..."

    [ -f /etc/hostapd/hostapd.conf ] && [ ! -f /etc/hostapd/hostapd.conf.orig ] &&  \
        ${SUDO} cp /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.orig
    ${SUDO} bash -c 'cat > /etc/hostapd/hostapd.conf' << EOF
# T.I.App
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
interface=${WLAN_AP}
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
    [ -f /etc/default/hostapd.orig ] || ${SUDO} cp /etc/default/hostapd /etc/default/hostapd.orig
    ${SUDO} sed -i 's/^#DAEMON_CONF\=\"\"/DAEMON_CONF\=\"\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd
    [[ $IS_CHROOT == 0 ]] && echo "Resarting hostapd service..."
    [[ $IS_CHROOT == 0 ]] && ${SUDO} service hostapd restart
    echo "$0: Done!"
}

# Populate `/etc/dnsmasq.conf`
configure_dnsmasq(){
    [ -f /etc/dnsmasq.conf ] && [ ! -f /etc/dnsmasq.conf.orig ] && \
        ${SUDO} cp /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
    ${SUDO} bash -c 'cat > /etc/dnsmasq.conf' << EOF
interface=lo,wlan0
#bind-interfaces
server=8.8.8.8
domain-needed
bogus-priv
dhcp-range=10.0.0.2,10.0.0.5,1000d
address=/#/10.0.0.1
EOF
    [[ $IS_CHROOT == 0 ]] && echo "Resarting dnsmasq service..."
    [[ $IS_CHROOT == 0 ]] && ${SUDO} service dnsmasq restart
    echo "$0 Done!"
}

configure_dhcpcd () {
[ -f /etc/dhcpcd.conf ] && [ ! -f /etc/dhcpcd.conf.orig ] && \
    ${SUDO} cp /etc/dhcpcd.conf /etc/dhcpcd.conf.orig
    ${SUDO} sed -i /T.I.App/d /etc/dhcpcd.conf
    ${SUDO} bash -c 'cat >> /etc/dhcpcd.conf' << EOF
interface wlan0                                 # T.I.App
static ip_address=10.0.0.1/24                   # T.I.App
EOF
    [[ $IS_CHROOT == 0 ]] && echo "Resarting dhcpcd service..."
    [[ $IS_CHROOT == 0 ]] && ${SUDO} service dhcpcd restart
    echo "$0 Done!"
}

# silent_boot https://scribles.net/silent-boot-on-raspbian-stretch-in-console-mode/
silent_boot_to_CLI() {
    echo -e "1. Set boot to console mode (vs. grafical.target)\n"
    ${SUDO} systemctl set-default multi-user.target
#    ${SUDO} sed -i '/^ExecStart=/ s/--no clear/--skip-login --noclear --noissue --login-options "-f pi"/' /lib/systemd/system/getty@.service
    echo "2. Remove autologin message by modify autologin service\n"
#    ${SUDO} raspi-config nonint do_boot_behaviour B2
#    ${SUDO} sed -i '/^ExecStart=/ s/--noclear/--skip-login --noclear --noissue --login-options "-f pi"/ %' /lib/systemd/system/getty@.service
    ${SUDO} ln -fs /etc/systemd/system/autologin@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
    ${SUDO} bash -c 'cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf' << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --noclear --skip-login --login-options "-f pi" %I ${TERM}
EOF


    echo "3. Disabling \“Welcome to PIXEL” splash...\"\n"
    ${SUDO} systemctl mask plymouth-start.service

    echo "4. Removing Rainbow Screen...\n"

    ${SUDO} grep '^disable_splash' /boot/config.txt || \
    ${SUDO} grep '# disable_splash' /boot/config.txt && \
    ${SUDO} sed -i '/^# disable_splash/ s/# //' /boot/config.txt || \
        ( ${SUDO}  bash -c 'echo -e "\n# Disable rainbow image at boot\t\t#PubHub" >> /boot/config.txt' && \
        ${SUDO}  bash -c 'echo -e "disable_splash=1\t\t\t#PubHub" >> /boot/config.txt' )

    echo "5. Removing: Raspberry Pi logo and blinking cursor\n Adding: 'loglevel=3' from/to /boot/cmdline.txt"
    echo -e "by adding \"logo.nologo vt.global_cursor_default=0\" at the end of the line in \"/boot/cmdline.txt\".\n"
	${SUDO} grep 'logo.nologo' /boot/cmdline.txt || ${SUDO} sed -i 's/$/ logo.nologo/' /boot/cmdline.txt
	${SUDO} sed -i 's/ vt.global_cursor_default=0//' /boot/cmdline.txt
    ${SUDO} sed -i 's/$/ vt.global_cursor_default=0/' /boot/cmdline.txt
    # remove boot messages:
    ${SUDO} sed -i 's/ loglevel=[01245]// s/$/ loglevel=3/' /boot/cmdline.txt
    
    echo "6. Removing login message\n"
    ${SUDO} touch ~/.hushlogin
}


install_app () {
    cd
    git clone --depth=1 https://github.com/PiMakers/Works.git
    mv Works/TothIlonkaApp TothIlonkaApp
    rm -rf Works
    cat TothIlonkaApp/videos/SplittedVideos/T.I.Final/Final* > TothIlonkaApp/videos/T.I.Final.mp4
    rm -rf TothIlonkaApp/videos/SplittedVideos/T.I.Final
    cat TothIlonkaApp/videos/SplittedVideos/T.I.FinalLoop/FinalLoop* > TothIlonkaApp/videos/T.I.FinalLoop.mp4
    rm -rf TothIlonkaApp/videos/SplittedVideos
    ##TODO Add startup script to .bashrc and silent boot 
    [ -f /home/pi/.bashrc ] && ${SUDO} sed -i /T.I.App/d /home/pi/.bashrc
    ${SUDO} bash -c 'cat >> /home/pi/.bashrc' << EOF

case \$(tty) in                  # T.I.App
    /dev/tty1)                  # T.I.App
    cd /home/pi/TothIlonkaApp   # T.I.App       
    node main.js                # T.I.App
esac                            # T.I.App

export LC_ALL=C                 # T.I.App
EOF
        #overlock memorysplit ssh key&setup +security port forwarding...
}

check_root
set_defaults
update_upgrade
# set pwd
# set ssh + sshd config + key security
# remove_unused
# add/remove user
Install_dependencies
configure_dhcpcd
configure_dnsmasq
configure_hostapd
silent_boot_to_CLI
install_app
echo "T.I.App install done"
#create_virtual_interface