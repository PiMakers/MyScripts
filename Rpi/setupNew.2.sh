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

# CHECK_ROOT=0
# UPDATE=0
# SSH_SH=0 # TODO Not works !!!!!!!!!!!!!!!!

setup=""

# CHECK_ROOT
[ ! -z $CHECK_ROOT ] && [ $CHECK_ROOT == 1 ] && setup+='check_root'
[ ! -z $UPDATE ] && [ $UPDATE == "true" ] && setup+=' update'
[ ! -z $SSH_SH ] && [ $SSH_SH == 1 ] && setup+=" $(. ssh.sh)"

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

update() {
    ${SUDO} apt update && ${SUDO} apt upgrade -y
    ${SUDO} apt autoremove && ${SUDO} apt autoclean && ${SUDO} apt clean
}



for command in $setup
do 
    echo "command: $command" && "${command}"
done