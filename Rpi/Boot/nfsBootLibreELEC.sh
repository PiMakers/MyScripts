## https://libreelec.wiki/configuration/network-boot
## https://forum.libreelec.tv/thread/20163-rpi4-gpio-using-in-libreelec/
## https://www.raspberrypi.org/forums/viewtopic.php?t=134133 /net conf!!!!
## https://forum.kodi.tv/showthread.php?tid=260817

# sudo mount 192.168.1.20:/mnt/LinuxData/OF /mnt/LinuxData/OF
#!/bin/bash
SUDO=sudo

#DEV_DIR=/mnt/LinuxData
TFTP_DIR=/tftpLE
IMG_DIR=/mnt/LinuxData/Install/img
STORAGE_DIR=/mnt/media/storage
# STORAGE_DIR=/media/pimaker/STORAGE

mkdir -pv ${STORAGE_DIR}

DHCP=1
    if [ $DHCP -eq 1 ]; then
        HOST_IP=$(hostname -I | sed 's/ .*//')
    else
        HOST_IP=10.0.0.1
    fi

IMG=${IMG_DIR}/LibreELEC-RPi4.arm-9.97.1.img
#LibreELEC-RPi4.arm-9.2.6.img

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
        if [ ${IMG##*.}=="zip" -o ${IMG##*.}=="gz" ];then
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
    local COUNT=6144
    ${SUDO} bash -c "dd if=/dev/zero bs=1M count=${COUNT} >> ${IMG}"
}

mountLE() {
    LOOP_DEVICE=$(${SUDO} losetup -f)
    ${SUDO} losetup -P $LOOP_DEVICE $IMG
    ${SUDO} mkdir -pv ${TFTP_DIR}
    ${SUDO} mount -v ${LOOP_DEVICE}p1 ${TFTP_DIR} || ( echo "error mounting ${TFTP_DIR}" && exit )
    
    ${SUDO} mount -v ${LOOP_DEVICE}p2 ${STORAGE_DIR} || ( echo "error mounting ${STORAGE_DIR}" && exit )
    # read -p "Press ENTER to continue..."
}

# dtoverlay=dwc2,dr_mode=host
netBoot() {
    ${SUDO} mkdir -pv ${STORAGE_DIR}
    echo "boot=NFS=${HOST_IP}:${TFTP_DIR} morequiet disk=NFS=${HOST_IP}:${STORAGE_DIR} rw ip=dhcp rootwait quiet systemd.show_status=0" | \
        ${SUDO} tee ${TFTP_DIR}/cmdline.nfsboot.LE
    
    ${SUDO} sed -i '/disable_splash/d' ${TFTP_DIR}/config.txt
    echo "disable_splash=1" | ${SUDO} tee -a ${TFTP_DIR}/config.txt

    ${SUDO} sed -i '/nfsboot.LE/d' ${TFTP_DIR}/config.txt
    echo "cmdline=cmdline.nfsboot.LE" | ${SUDO} tee -a ${TFTP_DIR}/config.txt

    ${SUDO} sed -i '/libreELEC/d' /etc/exports
    echo "${STORAGE_DIR}      ${HOST_IP%.*}.0/24(rw,sync,no_subtree_check,insecure,no_root_squash,crossmnt,anonuid=0,anongid=0) #libreELEC" | ${SUDO} tee -a /etc/exports
    echo "${TFTP_DIR}   	${HOST_IP%.*}.0/24(rw,sync,no_subtree_check,insecure,no_root_squash,crossmnt,anonuid=0,anongid=0) #libreELEC" | ${SUDO} tee -a /etc/exports 

    ${SUDO} exportfs -r
    # ${SUDO} exportfs
    ${SUDO} service dnsmasq stop
    
    if [ $DHCP -eq 1 ]; then      
        DHCP_OPT="--dhcp-range=${HOST_IP},proxy --port=0"
        echo "::DHCP = 1 !!!!!!"
    else
        DHCP_OPT="--dhcp-range=${HOST_IP%.*}.2,${HOST_IP%.*}.10,12h --listen-address=127.0.0.1,10.0.0.1 --port=5300"
    fi
    gnome-terminal -t "tftpBoot" -- ${SUDO} dnsmasq --enable-tftp --tftp-root=${TFTP_DIR},enp0s25 -d --pxe-service=0,"Raspberry Pi Boot" \
        --dhcp-reply-delay=1  ${DHCP_OPT} #--tftp-unique-root=mac --pxe-prompt="Boot Raspberry Pi",1 --dhcp-host=e4:5f:01:1f:b7:54,set:piserver tag:piserver,
    
    read -p "Press a key to continue.."
}

LEversion() {
    # ${SUDO} 
    sudo mkdir -pv /mnt/sqfs
    sudo mount /tftpLE/SYSTEM /mnt/sqfs -t squashfs -o loop
    . /mnt/sqfs/etc/os-release
    [ "${VERSION_ID%.*}" -gt 9 ] && echo ":: Ten" || echo ":: Nine"
}

playStartUpVideo() {
    # xbmc.executebuiltin( "PlayMedia(/storage/.kodi/userdata/playlists/video/Borsi.m3u)" )
    ${SUDO} mkdir -pv ${STORAGE_DIR}/.kodi/addons/service.autoexec
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
            <addon id="service.autoexec" name="Autoexec Service" version="1.0.0" provider-name="PiMaker">
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
# addon id="virtual.rpi-tools"
    fi
    echo ":: VERSION_ID=${VERSION_ID}"
}

 # ${STORAGE_DIR}/.kodi/userdata/addon_data/service.libreelec.settings/oe_settings.xml - WIZZARD + HOSTNAME!!!! KODI10
disableSplash() {
    # mkdir -pv ${STORAGE_DIR}/.kodi/userdata/
    ## disable RPI splash
    ${SUDO} sed -i '/disable_splash/d' ${TFTP_DIR}/config.txt
    echo "disable_splash=1" | ${SUDO} tee -a ${TFTP_DIR}/config.txt

    # Disable LibreELEC Splash
    echo | sudo tee /tftpLE/oemsplash.png
    cat << EOF | sed 's/^.\{8\}//' | ${SUDO} tee ${STORAGE_DIR}/.kodi/userdata/advancedsettings.xml 1>/dev/null    
        <advancedsettings version="1.0">
            <services>
                <webserver>true</webserver>
                <webserverport>8080</<webserverport>
                <webserverpassword>raspi</webserverpassword>
                <webserverusername>KODI</webserverusername>
            </services>
            <splash>false</splash>
            <cache>
                <buffermode>1</buffermode>
                <memorysize>209715200</memorysize>
                <readfactor>20</readfactor>
            </cache>
            <gui>
                <smartredraw>true</smartredraw>
            </gui>
        </advancedsettings>
EOF
}

wizzard() {
    sudo mkdir -pv ${STORAGE_DIR}/.kodi/userdata/addon_data/service.libreelec.settings
    cat << EOF | sed 's/^.\{4\}//' | ${SUDO} tee ${STORAGE_DIR}/.kodi/userdata/addon_data/service.libreelec.settings/oe_settings.xml 1>/dev/null    
    <?xml version="1.0" ?>
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
    if [ ! -d ${STORAGE_DIR}/.kodi/addons/skin.estuary_Borsi ]; then
        if [ -d /mnt/sqfs ];then
            ${SUDO} cp -r /mnt/sqfs/usr/share/kodi/addons/skin.estuary ${STORAGE_DIR}/.kodi/addons/skin.estuary_Borsi
            ${SUDO} sed -i 's/skin.estuary/skin.estuary_Borsi/g;s/Estuary/Estuary_Borsi/g; s/phil65, Ichabod Fletchman/PiMaker(Hollos)/' \
                ${STORAGE_DIR}/.kodi/addons/skin.estuary_Borsi/addon.xml
        else
            echo ":: Squasfs didn't extracted !!!"
        fi
    else
        echo ":: SkinHack already done!!"
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
    ${SUDO} killall dnsmasq
    if [ -d /mnt/sqfs ];then
        sudo umount -lv /mnt/sqfs
        sudo rm -r /mnt/sqfs
    fi
    # remove this script's nfs shares (lines with #libreELEC) 
    ${SUDO} sed -i '/libreELEC/d' /etc/exports
    # restart nfs server - TODO restore original sttate
    ${SUDO} service nfs-kernel-server restart
    # exportfs -r

    ${SUDO} sed -i '/nfsboot.LE/d' ${TFTP_DIR}/config.txt
    # unmount mounted img
    mountpoint ${TFTP_DIR} && ${SUDO} umount -lv ${TFTP_DIR}
    mountpoint ${STORAGE_DIR} && ${SUDO} umount -lv ${STORAGE_DIR}
    ${SUDO} rm -r ${TFTP_DIR}
    # remove loopdevice
    ${SUDO} losetup -d ${LOOP_DEVICE}
    exit 0
}

rotateDisplay() {
    echo "video=HDMI-A-1:1920x1080M@60,margin_left=0,margin_right=0,margin_top=0,margin_bottom=0,rotate=180,reflect_x TO THE CMDLINE"
    # echo "disable_fw_kms_setup=0 TO THE config.txt or in distroconfig.txt"
}

fs-resize() {
    DISK=/dev/mmcblk0
    umount ${DISK}p2 || (echo "NOT RESIZED" && sleep 5 && exit )
    parted -s -m ${DISK} resizepart 2 100%
    e2fsck -f -p ${DISK}p2
    resize2fs ${DISK}p2
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
    #createSshKey
    #skinHack
    netBoot
    cleanExit
}



[ "${BASH_SOURCE}" == "${0}" ] && runLEnfsBoot


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
    xbmc.log( msg='This is a test string.', level=xbmc.LOGDEBUG)
    $INFO[Player.Title]
    $INFO[infolabel] 

}

others() {
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

