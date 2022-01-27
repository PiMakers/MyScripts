## https://onedrive.live.com/?cid=04E1AFAA94739671&id=4E1AFAA94739671%21330810&parId=4E1AFAA94739671%21307716&o=OneUp

#!/bin/bash
hopp() {
    mkdir -pv /var/media/OF
    mount 192.168.1.20:/mnt/LinuxData/OF /media/OF
    /media/OF/myGitHub/MyScripts/Rpi/Boot/BorsiEEpromUpd.sh
}

. /etc/os-release

if [ $ID == "libreelec" ]; then
    mount -oremount,rw /flash
    TMP_DIR=/storage/.kodi/temp
else
    SUDO=sudo
    SUDOE='sudo -E'
    TMP_DIR=/tmp
fi

echo "$ID detected"

TMP_DIR=/tmp

    cat << EOF | sed 's/^.\{8\}//' | ${SUDO} tee ${TMP_DIR}/boot.conf
        [all]
        BOOT_UART=0
        WAKE_ON_GPIO=1
        POWER_OFF_ON_HALT=1

        # Try  Network -> MSD/USB -> SD- > Loop
        BOOT_ORDER=0xf12

        # Set to 0 to prevent bootloader updates from USB/Network boot
        # For remote units EEPROM hardware write protection should be used.
        ENABLE_SELF_UPDATE=1

        # default=0 silent=1
        DISABLE_HDMI=1

        #DHCP_TIMEOUT=45000
        #DHCP_REQ_TIMEOUT=4000
        #TFTP_FILE_TIMEOUT=30000
        #TFTP_IP=
        #TFTP_PREFIX=0
        SD_BOOT_MAX_RETRIES=0
        NET_BOOT_MAX_RETRIES=0

        [none]
        FREEZE_VERSION=0
EOF

CM4_ENABLE_RPI_EEPROM_UPDATE=1 ${SUDOE} rpi-eeprom-config --apply ${TMP_DIR}/boot.conf && RES="$?"

echo "::RES = $RES ---------------------------------------------------------" 
if [ $RES ]; then

    echo "***************************************************************"
    echo "*                      SUCCSESS!!!!!!!                        *"
    echo "***************************************************************"

    PI_SERIAL=`cat /proc/cpuinfo | grep Serial | awk -F ': ' '{print $2}' | tail -c 9`
    PI_MAC=`ip addr show eth0 | grep ether | awk '{print $2}'`
    if [ ! -f /boot/BorsiSerials.txt ]; then
        echo -e "BORSI CM4\n serials:\tmac address:\n" | ${SUDO} tee -a /boot/BorsiSerials.txt
    fi
    #${SUDO} sed -i "/${PI_SERIAL}/d" /boot/BorsiSerials.txt
    #echo -e "${PI_SERIAL}\t${PI_MAC}" ${SUDO} tee -a /boot/BorsiSerials.txt || true
    #cat -n /boot/BorsiSerials.txt || true
    #sleep 10
    #${SUDO} shutdown now 
else
    echo "---------------------------------------------------------------"
    echo "-                       FAILED!!!!!!!!                        -"
    echo "---------------------------------------------------------------"
    sleep 5
    reboot
fi