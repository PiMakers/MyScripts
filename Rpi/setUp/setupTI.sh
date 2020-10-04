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

## PIMAKER_BASE_ADDR=https://raw.githubusercontent.com/PiMakers
# SCRIPT_ADDR=/MyScripts/edit/Rpi/setUp/setupTI.sh  # | bash -s
## Rpi/Boot/overlay+nfs.sh
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

set_defaults() {
    export LC_ALL=C
    REMOTE_GIT_BASE_URL=https://raw.githubusercontent.com/PiMakers/MyScripts/edit
    #"${2}"
    WLAN_AP=wlan0
    AP_SSID="T.I.Remote"
    #"${3}"
    AP_PASSPHRASE="TI159550"
    #"${4}"
    ROOT=$(dirname "$0")

    [ -f /etc/os-release ] && OS=$(cat  /etc/os-release | sed '/^'ID='/!d;s/^'ID='//')

    # (grep 'export LC_ALL=C' /boot/config.txt | sed -i 's/#//' || echo ".bashrc already patched" ) || \
    sed -i '/export LC_ALL=C/d' $HOME/.bashrc && echo -e "\nexport LC_ALL=C" >> $HOME/.bashrc || echo "no bashrc"
}

# update_upgrade
update_upgrade () {
  curl ${REMOTE_GIT_BASE_URL}/Rpi/setUp/setupNew.sh | bash -s
  if [ getLastAptUpdate > 7 ]; then
        ${SUDO} apt -y update
        echo "Upgrading..."
        ${SUDO} apt -y upgrade 2>&1 | grep -q autoremove && ${SUDO} apt -y autoremove --purge || echo "NOTHING TO AUTOREMOVE"
        ${SUDO} apt autoclean
        ${SUDO} apt clean
        echo "update Done!"
  fi
}

# Install dependencies
Install_dependencies () {
  echo "Installing dependences (dnsmasq hostapd haveged) ..."
  list="dnsmasq hostapd haveged"
  ${SUDO} apt -y install ${list}    #dnsmasq hostapd haveged #arp-scan nfs-kernel-server haveged
  ${SUDO} service hostapd stop && ${SUDO} service dnsmasq stop

  echo "Done!"			
}

configure_hostapd(){
    echo "Configurering hostapd"
    echo "Writing conf (/etc/hostapd/hostapd.conf) ..."
    ${SUDO} systemctl unmask hostapd.service
    [ -f /etc/hostapd/hostapd.conf.orig ] || ${SUDO} cp /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.orig
    ${SUDO} cat > /etc/hostapd/hostapd.conf << EOF
    # PiMaker

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
    # ${SUDO} sed -i '/^ExecStart=/ s/--no clear/--skip-login --noclear --noissue --login-options "-f pi"/' /lib/systemd/system/getty@.service
    echo "2. Remove autologin message by modify autologin service\n"
    # ${SUDO} raspi-config nonint do_boot_behaviour B2
    # ${SUDO} sed -i '/^ExecStart=/ s/--noclear/--skip-login --noclear --noissue --login-options "-f pi"/ %' /lib/systemd/system/getty@.service
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
