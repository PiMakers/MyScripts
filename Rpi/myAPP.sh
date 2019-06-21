## https://github.com/peebles/rpi3-wifi-station-ap-stretch/blob/master/README.md
# RASPBERRY PI 3 - WIFI STATION+AP

# SETTING UP A RASPBERRY PI AS AN ACCESS POINT IN A STANDALONE NETWORK (NAT)
# https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md#internet-sharing

# # https://github.com/billz/raspap-webgui/


# Running the Raspberry Pi 3 as a Wifi client (station e.g.:STA) and access point (AP) from the single built-in wifi.

# The access point device is created before networking
# starts (using udev) and there is no need to run anything from `/etc/rc.local`.  No reboot, no scripts.

## Use Cases

# The Rpi 3 wifi chipset can support running an access point and a station function simultaneously.  One
# use case is a device that connects to the cloud (the station, via a user's home wifi network) but
# that needs an admin interface (the access point) to configure the network.  The user powers on the
# device, then logs into the access point using a specified SSID/password.  The user runs a browser
# and connects to the access point IP address (or hostname), which is running a web server to configure
# the station network (the user's wifi).

# Another use case might be to create a guest interface to your home wifi.  You can configure the client
# side with your wifi particulars, then configure the access point with a password you can give out to your
# guests.  When the party's over, change the access point password.

#!/bin/bash

set -e

INSTALL=-1
PROGNAME="$0"
ROOT=$(dirname "$0")

#  AP_IP=10.3.141.1
[ -z ${WIFI_SSID} ] && WIFI_SSID="Ste@diAP"
[ -z ${WIFI_PASSWD} ] && WIFI_PASSWD="Pepe374189"

[ -z $AP_IP ] && AP_IP="10.0.0.1"
[ -z ${AP_SSID} ] && AP_SSID="PiMakerNet®"
[ -z $LEASE_TIME ] && LEASE_TIME="12d"  # infinite

[ -z $WIRT_IFACE ] && WIRT_IFACE=uap

echo "WIFI_SSID=${WIFI_SSID}"
echo "WIFI_PASSWD=${WIFI_PASSWD}"
echo "AP_IP=${AP_IP}"
echo "LEASE_TIME=${LEASE_TIME}"


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

select_mode() {
    PS3='Please enter your choice: '
    options=( "Install" "Uninstall" 'Library mode' "Quit" )
    # options+=( "More_Choises1" "More_Choises2" ... )
    # unset options[0]
    # options[2]="pocok"
    # arr=( "${arr[@]:0:2}" "new_element" "${arr[@]:2}" )
    select opt in "${options[@]}"
    do
        case $opt in
            "Install")
                echo "Installing $PROGNAME ..."
                INSTALL=1
                break 
                ;;
            "Uninstall")
                echo "Uninstalling $PROGNAME ..."
                INSTALL=0
                break 
                ;;
            "Library mode")
                echo "Using $PROGNAME as prog. library..."
                INSTALL=2
                break
                ;;
            "Quit")
                break
                ;;
            *) 
                echo "invalid option $REPLY"
                echo "Using $PROGNAME as prog. library..."
                break
                ;;
        esac
    done
}

## Install requred packages for DNS, Access Point and Firewall rules.
install_dependencies() {
    apt-get update
    apt-get install -y hostapd dnsmasq # iptables-persistent
    ## Since the configuration files are not ready yet, turn the new software off as follows:
    # systemctl stop dnsmasq
    # systemctl stop hostapd
}

is_interface() {
    [[ -z "$1" ]] && return 1
    [[ -d "/sys/class/net/${1}" ]]
}

get_macaddr() {
    is_interface "$1" || return
    cat "/sys/class/net/${1}/address"
}

get_all_macaddrs() {
    cat /sys/class/net/*/address
}

get_new_macaddr() {
    local MAC_ADDRESS NEW_MAC_ADDRESS LAST_BYTE i
    MAC_ADDRESS=$(get_macaddr "$1")
    LAST_BYTE=$(printf %d 0x${MAC_ADDRESS##*:})
    # mutex_lock
    for i in {1..255}; do
        NEW_MAC_ADDRESS="${MAC_ADDRESS%:*}:$(printf %02x $(( ($LAST_BYTE + $i) % 256 )))"
        (get_all_macaddrs | grep "$NEW_MAC_ADDRESS" > /dev/null 2>&1) || break
    done
    # mutex_unlock
    echo $NEW_MAC_ADDRESS
}

## add/remove soft AP device
create_udev_rule() {
    #TODO change macaddress
    # MAC_ADDRESS=$(get_macaddr $WIFI_INTERFACE)
    # NEW_MAC_ADDRESS=$(get_new_macaddr $WIFI_INTERFACE)
    # bash -c 'cat > /etc/udev/rules.d/70-persistent-net.rules' << EOF
    #SUBSYSTEM=="ieee80211", ACTION=="add|change", ATTR{macaddress}=="${MAC_ADDRESS}", KERNEL=="phy0", \\
    #  RUN+="/sbin/iw phy phy0 interface add ap0 type __ap", \\
    #  RUN+="/bin/ip link set ap0 address ${NEW_MAC_ADDRESS}"
    #EOF

    local file_name="/etc/udev/rules.d/90-wireless.rules"
    if [ "$1" == 1 ];then
    #${SUDO} bash -c 'cat > ${file_name}' << EOF
    ${SUDO} bash -c 'cat > /etc/udev/rules.d/90-wireless.rules' << EOF
# PiMaker®

ACTION=="add", SUBSYSTEM=="ieee80211", KERNEL=="phy0", \\
RUN+="/sbin/iw phy %k interface add ${WIRT_IFACE} type __ap"
EOF
        echo "${file_name} created"
    else
        if [ -f "${file_name}" ]; then 
            ${SUDO} rm "${file_name}" && \
            echo "${file_name} removed"
        fi
    fi

    ${SUDO} service networking stop
    ${SUDO} udevadm control --reload-rules || echo "clean jjjjjjjjjjjjjjjj"
    ${SUDO} udevadm trigger --attr-match=subsystem=net || echo "clean jjjjjjjjjjjjjjjj"
    ${SUDO} service networking start
    ${SUDO} service dhcpcd restart
}


## configure/unconfigure soft AP interface
configure_interface() {
    local file_name="/etc/network/interfaces.d/PubHubAP"
    if [ "$1" == 1 ];then
        cat > ${file_name} << EOF
# PiMaker®

allow-hotplug uap0
auto uap0
iface uap0 inet static
#     address 10.3.141.1
      address ${AP_IP}
      netmask 255.255.255.0
EOF
        echo "${file_name} created"
    elif [ -f "${file_name}" ]; then
        rm "${file_name}" || ( echo "ERROR: remove ${file_name}" && exit 11)
        echo "${file_name} removed"
    fi
}

## patch dhcpcd-hook to restore STA after hostapd inited.
patch_10_wpa_supplicant(){
    local file_name="/lib/dhcpcd/dhcpcd-hooks/10-wpa_supplicant"
    [ -f $file_name ] || (echo "ERROR: No $file_name"; exit 11)
    sed -i '/# PiMaker®/d' $file_name
    if [ "$1" == 1 ];then
        sed -i '/DEPARTED)/a \        NOCARRIER)\      wpa_supplicant_stop; wpa_supplicant_start;;\t\t\t# PiMaker®\
                *)\              syslog info "PubHUb: reason = $reason interface = $interface";; # PiMaker®' $file_name
        # TODO check if wait.conf ( rm /etc/systemd/system/dhcpcd.service.d/wait.conf )
        echo "$file_name patched !"
    else
        echo "$file_name recovered \!"
    fi
}

## Set up the client wifi STA on wlan0.
# TODO make encription
add_wpa_supplicant_conf() {
    if [ "$1" == 1 ];then
        if [ -f ${ROOT}/BackUp/wpa_supplicant.conf.orig ]; then
            cp /etc/wpa_supplicant/wpa_supplicant.conf ${ROOT}/BackUp/wpa_supplicant.conf.orig 
        fi
    #TODO encrypt psk
    cat > /etc/wpa_supplicant/wpa_supplicant.conf << EOF
# PiMaker®
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=HU

network={
    #ssid="Ste@diAP"
    ssid=${WIFI_SSID}
    psk=${WIFI_PASSPWD}
    key_mgmt=WPA-PSK
}
EOF
    echo "Setting up the client wifi (STA) on wlan0."
    elif [ -f ${ROOT}/BackUp/wpa_supplicant.conf.orig ]; then
    cp ${ROOT}/BackUp/wpa_supplicant.conf.orig /etc/wpa_supplicant/wpa_supplicant.conf
    else
    echo "Something went Wrong Setting up the client wifi (STA) on wlan0."
    fi
}

configure_dnsmasq() {
    if [ "$1" == 1 ];then
    if [ -f ${ROOT}/BackUp/dnsmasq.conf.orig ]; then
    cp /etc/dnsmasq.conf ${ROOT}/BackUp/dnsmasq.conf.orig
    fi
    cat > tmp << EOF
bogus-priv                                                  # PiMaker®
domain-needed                                               # PiMaker®
interface=lo,wlan0                                          # PiMaker®
#no-dhcp-interface=lo,wlan0                                 # PiMaker®
bind-interfaces                                             # PiMaker®
server=8.8.8.8                                              # PiMaker®
dhcp-range=${AP_IP%:*}:50,${AP_IP%:*}:255,${LEASE_TIME}     # PiMaker®
#dhcp-range=10.3.141.50,10.3.141.255,12h                    # PiMaker®

# IP Forward (yes)                                          # PiMaker®
# dhcp-option=19,1                                          # PiMaker®

# Source Routing (yes)                                      # PiMaker®
# dhcp-option=20,1                                          # PiMaker®
EOF
    echo "configuring dnsmasq..."
    elif [ -f ${ROOT}/BackUp/dnsmasq.conf.orig ]; then
        cp ${ROOT}/BackUp/dnsmasq.conf.orig /etc/dnsmasq.conf
    else 
        echo "Somthing went Wrong configuring dnsmasq"
    fi
}

## /etc/hostapd/hostapd.conf
configure_hostapd() {
    if [ "$1" == 1 ];then
        if [ -f ${ROOT}/BackUp/hostapd.conf.orig ]; then
        cp /etc/hostapd/hostapd.conf ${ROOT}/BackUp/hostapd.conf.orig
    fi
    ${SUDO} bash -c 'cat > /etc/hostapd/hostapd.conf' << EOF
# PiMaker®

ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
interface=uap0
driver=nl80211
ssid=${AP_SSID}
hw_mode=g
channel=13
# wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=${WIFI_PASSWD}
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF
    echo "configuring hostapd..."
    elif [ -f ${ROOT}/BackUp/hostapd.conf.orig ]; then
        cp ${ROOT}/BackUp/hostapd.conf.orig /etc/hostapd/hostapd.conf
    else 
        echo "Somthing went Wrong configuring hostapd"
    fi
    echo "Done!"
}

## patch /etc/default/hostapd
default_hostapd() {
    local file_name="/etc/default/hostapd"
    sed -i '/# PiMaker®/d' $file_name
    if [ "$1" == 1 ];then
    cat >> $file_name << EOF
DAEMON_CONF="/etc/hostapd/hostapd.conf"    # PiMaker®
EOF
    echo "$file_name patched"
    else
    echo "$file_name restored"
    fi
}

patch_dhcpcd_conf() {
    local file_name="/etc/dhcpcd.conf"
    ${SUDO} sed -i '/# PiMaker®/d' $file_name
    if [ "$1" == 1 ];then
        ${SUDO} bash -c 'cat >> $file_name' << EOF
denyinterfaces uap0    # PiMaker®
EOF
        echo "$file_name patched"
    else
        echo "$file_name restored"
    fi
}

## Bridge AP to cient side
Bridge_AP_to_cient() {
    # echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    # sudo sysctl -w net.ipv4.ip_forward=1
    # sudo iptables -t nat -D  POSTROUTING -o eth0 -j MASQUERADE
    # iptables-restore < /etc/iptables.ipv4.nat # PiMaker®
    # sed "/$pattern/s/^#*/$exp2/g" $file_name #(pattern="net.ipv4.ip_forward=1"; exp2="" to uncomment, exp2="#" to comment out; file_name="/etc/sysctl.conf")
    local append_or_del="-A"
    [ "$INSTALL" == 1 ] || append_or_del="-D"
    #echo ${INSTALL} > /proc/sys/net/ipv4/ip_forward
    #iptables -t nat ${append_or_del} POSTROUTING -s 10.3.141.0/24 ! -d 10.3.141.0/24 -j MASQUERADE
    iptables -t nat ${append_or_del} POSTROUTING -s ${AP_IP}/24 ! -d ${AP_IP}/24 -j MASQUERADE
    iptables-save > /etc/iptables/rules.v4
}



check_root
select_mode
[ "${INSTALL}" ] || ( echo "INSTALL = $INSTALL" && exit 2 )
exit 0

create_udev_rule ${INSTALL}
configure_interface $INSTALL
patch_10_wpa_supplicant ${INSTALL}
add_wpa_supplicant_conf ${INSTALL}
configure_dnsmasq ${INSTALL}
configure_hostapd ${INSTALL}
default_hostapd ${INSTALL}
patch_dhcpcd_conf ${INSTALL}
# Bridge_AP_to_cient ${INSTALL}
# exit 111


## REBOOT!
#    reboot
    

