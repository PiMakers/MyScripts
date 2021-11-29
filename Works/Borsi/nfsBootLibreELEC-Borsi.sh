## https://libreelec.wiki/configuration/network-boot
## https://forum.libreelec.tv/thread/20163-rpi4-gpio-using-in-libreelec/

# sudo mount 192.168.1.20:/mnt/LinuxData/OF /mnt/LinuxData/OF
#!/bin/bash
# http://192.168.10.2/webfig/#Terminal
# /interface ethernet poe set ether9 poe-out=off
# /interface ethernet poe set ether9 poe-out=forced-on
# /interface ethernet poe set ether9 poe-voltage=high
# /interface ethernet poe set ether9 poe-out=forced-on poe-voltage=high
# /interface ethernet comment ether13 comment="F5-Teremhang"
# /interface ethernet poe monitor ether2
hackMSYS() {
    device=/dev/mmcblk0
    mkfs.ext4 -F -L msys-overlay ${device}p2
    mkfs.ext4 -F -L msys-data ${device}p3
    touch /var/media/msys-boot/skip
    # mkdir -pv /var/media/msys-overlay/data/etc/init.d


# cp -r /var/media/msys-data/modules/msm_comlayer/client/working_dir/content /media/OF/Borsi/msys_backup/e2-vizelet
}


SUDO=sudo

#DEV_DIR=/mnt/LinuxData
TFTP_DIR=/tftpLE
IMG_DIR=/mnt/LinuxData/Install/img
STORAGE_DIR=/mnt/media/storage
# STORAGE_DIR=/media/pimaker/STORAGE
IMG_DIR=/media/pi


${SUDO} mkdir -pv -m 777 ${STORAGE_DIR}

DHCP=1
    if [ $DHCP -eq 1 ]; then
        HOST_IP=$(hostname -I | sed 's/ .*//')
    else
        HOST_IP=10.0.0.1
    fi

IMG=/mnt/LinuxData/OF/Borsi/BorsiBase-10.0.0.img

get_img(){
    if ! IMG=$(zenity --file-selection --file-filter="*.img *.zip *.gz" --filename=${IMG} 2>/dev/null); then
        # TODO download script
        if [ $(zenity --question --text="Download latest image?") ];then
            echo "Downloding latest image... (not implemented yet)"
            RASPBIAN_TYPE=lite
        fi
        echo "No img selected. Exit"; exit 1
    else 
        echo $IMG
        if [ ${IMG##*.} == "zip" -o ${IMG##*.} == "gz" ];then
            [ ${IMG##*.}=="gz" ] && UNZIP="gunzip" || UNZIP="unzip"
            if [ ! -f ${IMG%.*}.img ];then
                ${UNZIP} $IMG -d ${IMG_DIR}/
            fi
            IMG=$(basename ${IMG%.*}.img)
            IMG=${IMG_DIR}/$IMG
            echo $IMG
        fi
    fi
}

resizeImage() {
    local COUNT=2048
    ${SUDO} bash -c "dd if=/dev/zero bs=1M count=${COUNT} >> ${IMG}"
}

mountLE() {
    if [ ! -z $IMG ]; then
    LOOP_DEVICE=$(${SUDO} losetup -f)
    ${SUDO} losetup -P $LOOP_DEVICE $IMG
    ${SUDO} mkdir -pv ${TFTP_DIR}
    ${SUDO} mount -v ${LOOP_DEVICE}p1 ${TFTP_DIR} || ( echo "error mounting ${TFTP_DIR}" && exit )
    
    ${SUDO} mount -v ${LOOP_DEVICE}p2 ${STORAGE_DIR} || ( echo "error mounting ${STORAGE_DIR}" && exit )
    # read -p "Press ENTER to continue..."
    unset IMG
    else
        echo "NO IMAGE SELECTED!!!"
        exit
    fi

}

netBoot() {
    ${SUDO} mkdir -pv ${STORAGE_DIR}
    echo "boot=NFS=${HOST_IP}:${TFTP_DIR} morequiet disk=NFS=${HOST_IP}:${STORAGE_DIR} rw ip=dhcp rootwait quiet systemd.show_status=0" | \
        ${SUDO} tee ${TFTP_DIR}/cmdline.nfsboot.LE
    
    ${SUDO} sed -i '/nfsboot.LE/d' ${TFTP_DIR}/config.txt
    echo "cmdline=cmdline.nfsboot.LE" | ${SUDO} tee -a ${TFTP_DIR}/config.txt

    ${SUDO} sed -i '/libreELEC/d' /etc/exports
    echo "${STORAGE_DIR}      ${HOST_IP%.*}.0/24(rw,sync,no_subtree_check,insecure,no_root_squash,crossmnt,anonuid=0,anongid=0) #libreELEC" | ${SUDO} tee -a /etc/exports
    echo "${TFTP_DIR}   	${HOST_IP%.*}.0/24(rw,sync,no_subtree_check,insecure,no_root_squash,crossmnt,anonuid=0,anongid=0) #libreELEC" | ${SUDO} tee -a /etc/exports 

    ${SUDO} exportfs -r
    # ${SUDO} exportfs
    ${SUDO} service dnsmasq stop
    
    if [ $DHCP -eq 1 ]; then      
        DHCP_OPT="--dhcp-range=tag:piserver,${HOST_IP},proxy --port=0"
        echo "::DHCP = 1 !!!!!!"
    else
        DHCP_OPT="--dhcp-range=tag:piserver,${HOST_IP%.*}.2,${HOST_IP%.*}.10,12h --listen-address=127.0.0.1,10.0.0.1 --port=5300"
    fi

    for m in $(ls /sys/class/net)
    do
        case $m in
            w*)
                WIFI_IFACE=$m
                ;;
            e*)
                WIRED_IFACE=$m
                ;;
            *)
                if [ $m != lo ]; then
                    OTHER_IFACE=$m
                fi
                ;;
        esac
    done

    echo ":: Wired = ${WIRED_IFACE}"
    INTERFACE=${WIRED_IFACE}  #eth0  # enp0s25
    MAC="e4:5f:01:1f:b7:42"
    MAC="*:*:*:*:*:*"
    MAC="e4:5f:01:1f:b6:f4"
    MAC="e4:5f:01:1f:b9:1f"     #ab8aa887   192.168.10.129  E2-Vizelet                  192.168.10.1"
    MAC="e4:5f:01:1f:b9:1c"     #192.168.10.103  E9-5.16a_Radio              192.168.10.111  ether1"
    MAC="e4:5f:01:1f:b8:92"     #192.168.10.106  E9-5.6b_Könnyűzene          192.168.10.112  ether5"
    # MAC="e4:5f:01:1f:b6:fd"     #192.168.10.159  E7-Mikes                    192.168.10.110  ether1
    # MAC="e4:5f:01:1f:b7:06"     # 192.168.10.119  E7-Hadászat                 192.168.10.1
    # MAC="e4:5f:01:1f:b8:5f"     # 192.168.10.124  E1-Heraldika                --------------  ------
    # MAC="e4:5f:01:1f:b9:f1"     # 192.168.10.117  E8-MyHero                   192.168.10.1
    # MAC="e4:5f:01:1f:b7:00"     # 192.168.10.187  E9-Szalagos                 192.168.10.111  ether5
    #MAC="*:*:*:*:*:*"
    ${SUDO} dnsmasq --enable-tftp --tftp-root=${TFTP_DIR},${INTERFACE} -d --pxe-service=0,"Raspberry Pi Boot" --dhcp-host=${MAC},set:piserver \
        --tftp-unique-root=mac ${DHCP_OPT} #--dhcp-reply-delay=1 --pxe-prompt="Boot Raspberry Pi",1 --dhcp-host=e4:5f:01:1f:b7:54,set:piserver tag:piserver,
}

LEversion() {
    # ${SUDO} 
    sudo mkdir -pv /mnt/sqfs
    sudo mount /tftpLE/SYSTEM /mnt/sqfs -t squashfs -o loop || ( echo "error mounting /tftpLE/SYSTEM" && exit )
    . /mnt/sqfs/etc/os-release
    [ "${VERSION_ID%.*}" -gt 9 ] && echo ":: Ten" || echo ":: Nine"
    sudo umount -lv /mnt/sqfs
    sudo rm -r /mnt/sqfs

}

playStartUpVideo() {
    # xbmc.executebuiltin( "PlayMedia(/storage/.kodi/userdata/playlists/video/Borsi.m3u)" )
    ${SUDO} mkdir -pv ${STORAGE_DIR}/.kodi/addons/service.autoexec
    VERSION_ID=10
    if [[ "${VERSION_ID%.*}" -lt "10" ]]; then
        echo ":: Version 9 detected"
        cat << EOF | sed 's/^.\{12\}//' | ${SUDO} tee ${STORAGE_DIR}/.kodi/userdata/autoexec.py 1>/dev/null
            import xbmc
            xbmc.executebuiltin( "PlayMedia(/storage/videos/E8-Fire.mp4)" )
            xbmc.executebuiltin( "PlayerControl(repeat)" )
EOF
    else
        echo ":: Version 10 detected"
        cat << EOF | sed 's/^.\{12\}//' | ${SUDO} tee ${STORAGE_DIR}/.kodi/addons/service.autoexec/autoexec.py 1>/dev/null
            import xbmc
            """xbmc.executebuiltin( "PlayMedia(/storage/videos/E8-Fire.mp4)" )"""
            xbmc.executebuiltin( "PlayMedia(/storage/.kodi/userdata/playlists/video/Borsi.m3u)" )
            xbmc.executebuiltin( "PlayerControl(repeat)" )
EOF
        cat << EOF | sed 's/^.\{12\}//' | ${SUDO} tee ${STORAGE_DIR}/.kodi/addons/service.autoexec/addon.xml 1>/dev/null
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <addon id="service.autoexec" name="Autoexec Service" version="1.0.0" provider-name="your username">
                <requires>
                    <import addon="xbmc.python" version="3.0.0"/>
                </requires>
                <extension point="xbmc.service" library="autoexec.py">
                </extension>
                <extension point="xbmc.addon.metadata">
                    <summary lang="en_GB">Automatically run python code when Kodi starts.</summary>
                    <description lang="en_GB">The Autoexec Service will automatically be run on Kodi startup.</description>
                    <platform>all</platform>
                    <license>GNU GENERAL PUBLIC LICENSE Version 2</license>
                </extension>
            </addon>
EOF
 # addon id="virtual.rpi-tools
    fi
    echo ":: VERSION_ID=${VERSION_ID}"
}
 # ${STORAGE_DIR}/.kodi/userdata/addon_data/service.libreelec.settings/oe_settings.xml - WIZZARD + HOSTNAME!!!! KODI10
disableSplash() {
    # mkdir -pv ${STORAGE_DIR}/.kodi/userdata/
    ## Disable RpiSplash
    ${SUDO} sed -i '/disable_splash/d' ${TFTP_DIR}/config.txt
    echo "disable_splash=1" | ${SUDO} tee -a ${TFTP_DIR}/config.txt    
    ## Disable LibreELEC Splash
    echo | sudo tee /tftpLE/oemsplash.png
    cat << EOF | sed 's/^.\{8\}//' | ${SUDO} tee ${STORAGE_DIR}/.kodi/userdata/advancedsettings.xml 1>/dev/null    
        <advancedsettings version="1.0">
            <services>
                <webserver>true</webserver>
                <webserverpassword>raspi</webserverpassword>
                <webserverusername>KODI</webserverusername>
            </services>
            <splash>false</splash>
            <cache>
                <buffermode>1</buffermode>
                <memorysize>139460608</memorysize>
                <readfactor>20</readfactor>
            </cache>
        </advancedsettings>
EOF
}

wizzard() {
    sudo mkdir -pv ${STORAGE_DIR}/.kodi/userdata/addon_data/service.libreelec.settings
    cat << EOF | sed 's/^.\{4\}//' | ${SUDO} tee ${STORAGE_DIR}/.kodi/userdata/addon_data/service.libreelec.settings/oe_settings.xm 1>/dev/null    
    xml version="1.0" ?>
    <libreelec>
        <addon_config/>
            <settings>
                <system>
                        <wizard_completed>True</wizard_completed>
                </system>
                <services>
                        <wizard_completed>True</wizard_completed>
                </services>
                <about>
                        <wizard_completed>True</wizard_completed>
                </about>
                <libreelec>
                        <wizard_completed>True</wizard_completed>
                </libreelec>
            </settings>
        </libreelec>
EOF
}

createSshKey() {
        HOSTNAME=$(hostname -s)
        HOSTNAME=Borsi
        ${SUDO} mkdir -pv -m 700 ${STORAGE_DIR}/.ssh
        [ -f ~/.ssh/testkey@${HOSTNAME} ] || ${SUDO} ssh-keygen -q -N Pepe374189 -C testKey -f ~/.ssh/testkey@${HOSTNAME}
        ${SUDO} cat ~/.ssh/testkey@${HOSTNAME}.pub | ${SUDO} tee ${STORAGE_DIR}/.ssh/authorized_keys 1>/dev/null
        ${SUDO} chmod 600 ${STORAGE_DIR}/.ssh/authorized_keys
        ${SUDO} touch ${STORAGE_DIR}/.cache/services/sshd.conf
        echo "SSH_ARGS=-o 'PasswordAuthentication yes'" | ${SUDO} tee ${STORAGE_DIR}/.cache/services/sshd.conf
        echo "SSHD_DISABLE_PW_AUTH=false" | ${SUDO} tee -a ${STORAGE_DIR}/.cache/services/sshd.conf
}

skinHack() {
    if [ -d ${STORAGE_DIR}/.kodi/addons/skin.estuary_Borsi ]; then
      cp -r /usr/share/kodi/addons/skin.estuary ${STORAGE_DIR}/.kodi/addons/skin.estuary_Borsi
      sed -i 's/skin.estuary/skin.estuary_Borsi/g;s/Estuary/Estuary_Borsi/g; s/phil65, Ichabod Fletchman/PiMaker(Hollos)/' \
            .kodi/addons/skin.estuary_Borsi/addon.xml
    fi
}

scriptAddon() {
    # KODI 10
            mkdir -pv .kodi/addons/script.button
            cat << EOF | sed 's/^.\{12\}//' | ${SUDO} tee ${STORAGE_DIR}/.kodi/addons/service.autoexec/autoexec.py 1>/dev/null
            import xbmc
            """xbmc.executebuiltin( "PlayMedia(/storage/videos/E8-Fire.mp4)" )"""
            xbmc.executebuiltin( "PlayMedia(/storage/.kodi/userdata/playlists/video/Borsi.m3u)" )
            xbmc.executebuiltin( "PlayerControl(repeat)" )
EOF
        cat << EOF | sed 's/^.\{12\}//' | ${SUDO} tee ${STORAGE_DIR}/.kodi/addons/service.autoexec/addon.xml 1>/dev/null
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <addon id="service.autoexec" name="Autoexec Service" version="1.0.0" provider-name="your username">
                <requires>
                    <import addon="xbmc.python" version="3.0.0"/>
                </requires>
                <extension point="xbmc.service" library="autoexec.py">
                </extension>
                <extension point="xbmc.addon.metadata">
                    <summary lang="en_GB">Automatically run python code when Kodi starts.</summary>
                    <description lang="en_GB">The Autoexec Service will automatically be run on Kodi startup.</description>
                    <platform>all</platform>
                    <license>GNU GENERAL PUBLIC LICENSE Version 2</license>
                </extension>
            </addon>
EOF
}

cleanExit() {
    # remove this script's nfs shares (lines with #libreELEC) 
    ${SUDO} sed -i '/libreELEC/d' /etc/exports
    # restart nfs server - TODO restore original sttate
    ${SUDO} exportfs -r

    ${SUDO} sed -i '/nfsboot.LE/d' ${TFTP_DIR}/config.txt
    sync
    # unmount mounted img
    mountpoint ${TFTP_DIR} && ${SUDO} umount -lv ${TFTP_DIR}
    mountpoint ${STORAGE_DIR} && ${SUDO} umount -lv ${STORAGE_DIR}
    ${SUDO} rm -r ${TFTP_DIR}
    # remove loopdevice
    ${SUDO} losetup -d ${LOOP_DEVICE}
    exit 0
}

runLEnfsBoot() {
    trap 'echo "SIGINT !!!" && cleanExit ' INT
    get_img
    # resizeImage
    mountLE
    #LEversion
    #playStartUpVideo
    #disableSplash
    #wizzard
    createSshKey
    netBoot
    cleanExit
}



[ "${BASH_SOURCE}" == "${0}" ] && runLEnfsBoot


return

commands() {
    import sys
    # sys.path.append('/storage/.kodi/addons/virtual.rpi-tools/lib')
    PATH=$PATH:/storage/.kodi/addons/script.module.kodi-six/libs/kodi_six
    kodi-send --host=192.168.0.1 --port=9777 --action="Quit"
    kodi-send --action="PlayerControl(Play)"
    kodi-send --action="ReloadSkin(reload)"
    kodi-send --action="Skin.ToggleDebug()"
    kodi-send --action="DialogOK(msg="oooooo",100)"
    kodi-send --action="RunScript('/storage/.kodi/myScripts/Animatics.py')"
    xbmc.log( msg='This is a test string.', level=xbmc.LOGDEBUG )
}

others() {
   echo # PWM2.py
# Set RGB color

import sys
sys.path.append('/storage/.kodi/addons/virtual.rpi-tools/lib')
# sys.path.append('/storage/.kodi/mySripts')

import RPi.GPIO as GPIO
import time
# import random
import xbmc

button  = 14
P_RED   = 15     # adapt to your wiring
P_GREEN = 18   # ditto
P_BLUE  = 23    # ditto
fPWM = 50      # Hz (not higher with software PWM)

def setup():
    global pwmR, pwmG, pwmB
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(button, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
    GPIO.setup(P_RED, GPIO.OUT)
    GPIO.setup(P_GREEN, GPIO.OUT)
    GPIO.setup(P_BLUE, GPIO.OUT)
    pwmR = GPIO.PWM(P_RED, fPWM)
    pwmG = GPIO.PWM(P_GREEN, fPWM)
    pwmB = GPIO.PWM(P_BLUE, fPWM)
    pwmR.start(0)
    pwmG.start(0)
    pwmB.start(0)
 
def setColor(r, g, b):
    pwmR.ChangeDutyCycle(int(r / 255 * 100))
    pwmG.ChangeDutyCycle(int(g / 255 * 100))
    pwmB.ChangeDutyCycle(int(b / 255 * 100))
def setRed():
    pwmR.ChangeDutyCycle(100)
    pwmG.ChangeDutyCycle(0)
    pwmB.ChangeDutyCycle(0)
def setBlue():
    setColor(0,0,255)

print ("starting")
setup()

try:
    while True:
        button_state = GPIO.input(button)
        if  button_state == False:
            #print (r, g, b)
            setRed()
            print('Button Pressed...')
            xbmc.executebuiltin( "PlayerControl(Play)" )
            xbmc.executebuiltin( "PlayerControl(Next)" )
            while GPIO.input(button) == False:
                    setBlue()
                    time.sleep(0.2)
        else:
            setColor(0,100,0)
            time.sleep(1.0)
            setBlue()
            setBlue()

except KeyboardInterrupt:
    print ("CleaningUp...")
    pwmR.stop()
    pwmG.stop()
    pwmB.stop()
    GPIO.cleanup()   
}

