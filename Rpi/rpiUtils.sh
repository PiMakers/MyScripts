# Serial No.-s of my Pi's
MY_SERIAL_NUMS+=(b0c7e328)       # Raspberry Pi 3 Model B Rev 1.2 Main Dev:192.168.1.3

defaultDirs() {
    export EXT_DRIVE=/mnt/LinuxData
    export DEV_DIR=${EXT_DRIVE}/OF
    export MYSCRIPTS_DIR=${DEV_DIR}/myGitHub/MyScripts
}
setUpSettings() {

    ## common
    export LC_ALL=C
    export EXT_DRIVE=/mnt/LinuxData
    export DEV_DIR=${EXT_DRIVE}/OF

    

    export USER=pi
    # export IS_CHROOTED=0


    ## PiTopDev
    export PLATFORM=v6l

    # export_rootfs.sh
    export NFS_CIENT=NUC.local
    export NFS_HOST=NUC.local

    ## setupNew.sh
    export NEW_LOGIN_PASSWD=raspi
    export NEW_HOSTNAME=PiTopDev

    # Wifi setup
    export WIFI_IFACE=wlan0
    export INET_SSID=Ste@diAP
    export WIFI_PWD=Pepe374189

    # AP setup
    export AP_IFACE=uap0
    export AP_IP="10.3.141.1"
    export AP_SSID="PiMakerAP®"
    export AP_PWD="12345678"
}

myPublicIP() {
    MY_PUBLIC_IP=$(curl -4 ifconfig.co)
    export MY_PUBLIC_IP=$MY_PUBLIC_IP}
}

check_root() {
    # Must be root to run this script
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

is_chrooted() {
    if [ " $( stat -c %d:%i /)" != "$(${SUDO} stat -c %d:%i /proc/1/root/.)" ]; then
        IS_CHROOTED=1 ;
    else 
        IS_CHROOTED=0;
    fi
    export  IS_CHROOTED=${IS_CHROOTED}
    echo IS_CHROOTED=${IS_CHROOTED}
    # return ${IS_CHROOTED}
}

detect_OS() {
    # OS=$(cat  /etc/os-release | grep '^ID=' | sed s/^'ID='//)
    OS=$(cat  /etc/os-release | sed '/^ID=/!d; s/^'ID='//')
    export "OS=$OS"
    echo "OS=$OS"
}

# echo BASHSOURCE=$BASHSOURCE
include() {
    if [ -f ${1} ]; then
        . ${1}
        if [ $VERBOSE ]; then
            echo "Available commands (${1##*/}):"
            sed '/() {/!d;s/() {//' ${1}
        fi
    else
        echo "ERROR: ${1} not found!!!"
        echo "sleeping 10s before quit"
        sleep 10
    fi
}

runUtils() {
    SW_DEPENDENCIES=""
    VARS=""
    SETUP_OPT=

    # check_root
    is_chrooted
    detect_OS
}

check_root
defaultDirs
[ "${BASH_SOURCE}" == "${0}" ] && runUtils

return || exit

parted -s -m $DISK resizepart 2 1