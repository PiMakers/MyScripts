## https://libreelec.wiki/configuration/network-boot
## https://forum.libreelec.tv/thread/20163-rpi4-gpio-using-in-libreelec/
## https://www.raspberrypi.org/forums/viewtopic.php?t=134133 /net conf!!!!
## https://forum.kodi.tv/showthread.php?tid=260817

# sudo mount 192.168.1.20:/mnt/LinuxData/OF /mnt/LinuxData/OF
# umount $(df |sed '/mmcblk0/!d;s/p[0-9].*//')
#!/bin/bash
SUDO=sudo

#DEV_DIR=/mnt/LinuxData
HOST_OS=
TFTP_DIR=/tftpLE
IMG_DIR=/mnt/LinuxData/Install/img
#IMG_DIR=/mnt/LinuxData/OF/Borsi
STORAGE_DIR=/mnt/media/storage
# STORAGE_DIR=/media/pimaker/STORAGE

# mkdir -pv ${STORAGE_DIR}

DHCP=1
    if [ $DHCP -eq 1 ]; then
        HOST_IP=$(hostname -I | sed 's/ .*//')
    else
        HOST_IP=10.0.0.1
    fi

IMG=${IMG_DIR}/BorsiBase-10.0.0.img
IMG=/mnt/LinuxData/Install/zip/piCore64-13.1.zip

get_img(){
    if ! IMG=$(zenity --file-selection --file-filter="*.img *.zip *.gz" --filename=${IMG} 2>/dev/null); then
        # TODO download script
        if [ $(zenity --question --text="Download latest image?") ];then
            echo "Downloding latest image... (not implemented yet)"
            RASPBIAN_TYPE=lite
        fi
        echo "No img selected. Exit"; exit 1
    else 
        echo ":: selected IMG = $IMG"
        IMG_EXT=${IMG##*.} 
        case ${IMG##*.} in
            zip)
                echo :: ${IMG##*.}
                # test unzip $IMG -d ${IMG_DIR}/
                ;;
            gz)
                echo :: ${IMG##*.}
                DST_IMG=${IMG##*/} && DST_IMG=${DST_IMG%%.gz}
                gunzip -ck < $IMG > ${IMG_DIR}/${DST_IMG}                
                IMG=${IMG_DIR}/${DST_IMG}
                echo ":: extracted IMG = $IMG"
                ;;
            *)
                echo "What a Fuck???"
                ;;
        esac
        if [ ${IMG##*.} == "zip" ];then
            if [ ! -f ${IMG%.*}.img ];then
                unzip $IMG -d ${IMG_DIR}/
                IMG=$(basename ${IMG%.*}.img)
                IMG=${IMG_DIR}/$IMG
            fi
        fi
            echo ":: ---------- $IMG --------"
    fi
}

resizeImage() {
    read -p "Resize Img with (*4MB)? :" RESIZE
    if [ ! -z $RESIZE ]; then
    local COUNT=$RESIZE
    ${SUDO} bash -c "dd if=/dev/zero bs=4M count=${COUNT} >> ${IMG}" || ! echo ":::::::::::::: $?" || exit 10
    RESIZED=1
    fi
}

mountLE() {
    echo "Mounting ${IMG} ..."
    #LOOP_DEVICE=$(${SUDO} losetup -f)
    LOOP_DEVICE=$(${SUDO} losetup -fPL --show $IMG) || exit 11
    #${SUDO} losetup -P $LOOP_DEVICE $IMG || exit 11
    if [ $RESIZED ] ; then
        ${SUDO} parted -s -m ${LOOP_DEVICE} resizepart 2 100%
        ${SUDO} e2fsck -f -p ${LOOP_DEVICE}p2
        ${SUDO} resize2fs ${LOOP_DEVICE}p2
        echo "Resized!!!!!!!!!!!!!!!!!!!!!"
        RESIZED=0
    fi

    ${SUDO} mkdir -pv ${TFTP_DIR} ${STORAGE_DIR}
    ${SUDO} mount -v ${LOOP_DEVICE}p1 ${TFTP_DIR} || ( echo "error mounting ${TFTP_DIR}" && exit )
    
    ${SUDO} mount -v ${LOOP_DEVICE}p2 ${STORAGE_DIR} || ( echo "error mounting ${STORAGE_DIR}" && exit )
    # read -p "Press ENTER to continue..."
}

detectOS() {
    ROOT_FS=${STORAGE_DIR}
    if [ -f ${ROOT_FS}/etc/os-release ]; then
        . ${ROOT_FS}/etc/os-release
        echo ::ID=${ID}
    
        case $ID in
            ubuntu)
                # echo ":: HostOS Ubuntu!"
                HOST_OS="Ubuntu"
                ;;
            raspbian|debian)
                # echo ":: HostOS Raspios!"
                HOST_OS="Raspios"
                ID=pi
                ;;
            libreelec)
                # echo ":: HostOS LibreELEC!"
                HOST_OS="LibreELEC"
                BOOT_FS=/flash
                HOME_DIR=/storage
                ;;        
            *)
                echo ":: UnKnonw OS = $ID !!!"
                [ -z $ID ] && exit
        esac
    
    elif [ -d ${STORAGE_DIR}/tce ]; then
        # echo ":: HostOS piCore!"
        HOST_OS=piCore
        HOME_DIR=tc
    elif [[ `readlink /dev/disk/by-label/LIBREELEC` = "../../${LOOP_DEVICE##*/}p1" ]]; then
        HOST_OS="LibreELEC"
        HOME_DIR=${STORAGE_DIR}
    else
        echo ":: UnKnonw OS!!! Exit!"
    fi
    echo ":: HostOS ${HOST_OS} (ID=$ID)!"
}

# dtoverlay=dwc2,dr_mode=host
netBoot() {
    ${SUDO} mkdir -pv ${STORAGE_DIR}
    detectOS
    case ${HOST_OS} in
        piCore) 
                CMDLINE_TXT="zswap.compressor=lz4 zswap.zpool=z3fold console=tty1 root=/dev/ram0 rootwait quiet nortc loglevel=3 consoleblank=0 noembed nfsmount=${HOST_IP}:${STORAGE_DIR}:nolock,defaults host=CoreBase"

                # piCoreplayer
                #echo "dwc_otg.fiq_fsm_mask=0xF host=pCP dwc_otg.lpm_enable=0 console=tty1 root=/dev/ram0 rootwait quiet nortc loglevel=3 noembed smsc95xx.turbo_mode=N noswap consoleblank=0 waitusb=2 nfsmount=${HOST_IP}:${STORAGE_DIR}:nolock,defaults" | \
                #${SUDO} tee ${TFTP_DIR}/cmdline.nfsboot.${HOST_OS}
                ;;
     LibreELEC)
                CMDLINE_TXT="boot=NFS=${HOST_IP}:${TFTP_DIR} morequiet disk=NFS=${HOST_IP}:${STORAGE_DIR} rw ip=dhcp rootwait quiet systemd.show_status=0"
                ;;
       Raspios)
                sudo mount --bind ${TFTP_DIR} ${STORAGE_DIR}/boot
                local NFS_BOOT_TAG="/root,vers=4.1,proto=tcp,port=2049,nolock"
                CMDLINE_TXT="dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=${HOST_IP}:${STORAGE_DIR},vers=4.1,proto=tcp,port=2049,nolock rw ip=dhcp \
                elevator=deadline rootwait # plymouth.ignore-serial-consoles noswap"

                ${SUDO} sed -i 's/PARTUUID/#PARTUUID/g' ${STORAGE_DIR}/etc/fstab
                ;;
             *)
                cleanExit
                ;;
    esac
    
    echo "${CMDLINE_TXT}" | ${SUDO} tee ${TFTP_DIR}/cmdline.nfsboot.${HOST_OS}    
    
    ${SUDO} sed -i '/disable_splash/d' ${TFTP_DIR}/config.txt
    echo "disable_splash=1" | ${SUDO} tee -a ${TFTP_DIR}/config.txt

    ${SUDO} sed -i '/otg_mode/d' ${TFTP_DIR}/config.txt
    echo "otg_mode=1" | ${SUDO} tee -a ${TFTP_DIR}/config.txt

    ${SUDO} sed -i "/nfsboot.${HOST_OS}/d" ${TFTP_DIR}/config.txt
    echo "cmdline=cmdline.nfsboot.${HOST_OS}" | ${SUDO} tee -a ${TFTP_DIR}/config.txt

    ${SUDO} sed -i "/${HOST_OS}/d" /etc/exports
    echo "## NfsBoot ${HOST_OS}" | ${SUDO} tee -a /etc/exports
    echo -e "${STORAGE_DIR}\t${HOST_IP%.*}.0/24(rw,sync,no_subtree_check,insecure,no_root_squash,crossmnt,anonuid=0,anongid=0) #${HOST_OS}" | ${SUDO} tee -a /etc/exports
    echo -e "${TFTP_DIR}\t\t\t${HOST_IP%.*}.0/24(rw,sync,no_subtree_check,insecure,no_root_squash,crossmnt,anonuid=0,anongid=0) #${HOST_OS}" | ${SUDO} tee -a /etc/exports 

    ${SUDO} exportfs -r
    # ${SUDO} exportfs
    ${SUDO} service dnsmasq stop
    
    if [ $DHCP -eq 1 ]; then      
        DHCP_OPT="--dhcp-range=tag:piserver,${HOST_IP},proxy --port=0"
        echo "::DHCP = 1 !!!!!!"
    else
        DHCP_OPT="--dhcp-range=tag:piserver,${HOST_IP%.*}.2,${HOST_IP%.*}.10,12h --listen-address=127.0.0.1,10.0.0.1 --port=5300"
    fi

    TERMINAL_CMD=
    which lxterminal >/dev/null && TERMINAL_CMD='lxterminal -t "tftpBoot" -e'
    which gnome-terminal >/dev/null && TERMINAL_CMD='gnome-terminal -t "tftpBoot" --'
    echo ":: TERMINAL_CMD = ${TERMINAL_CMD}"

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
    INTERFACE=${WIRED_IFACE}

    MAC="*:*:*:*:*:*"
    
    #${TERMINAL_CMD} ${SUDO} dnsmasq --enable-tftp --tftp-root=${TFTP_DIR},${INTERFACE} -d --pxe-service=0,"Raspberry Pi Boot" --dhcp-host=${MAC},set:piserver \
    #    --tftp-unique-root=mac --pxe-prompt="Boot Raspberry Pi",1  --dhcp-reply-delay=1 ${DHCP_OPT} #--dhcp-reply-delay=1 --dhcp-host=e4:5f:01:1f:b7:54,set:piserver tag:piserver,
    # -z -b -a 192.168.10.142

    ${TERMINAL_CMD} ${SUDO} dnsmasq --enable-tftp --tftp-root=${TFTP_DIR},${INTERFACE} -d --pxe-service=0,"Raspberry Pi Boot" \
        --dhcp-host=${MAC2},set:piserver --dhcp-reply-delay=1 ${DHCP_OPT} --dhcp-host=${MAC},set:piserver --tftp-unique-root=mac --pxe-prompt="Boot Raspberry Pi",1 --ignore-address=192.168.10.1 #--dhcp-reply-delay=1 --dhcp-host=e4:5f:01:1f:b7:54,set:piserver tag:piserver,

    #${TERMINAL_CMD} ${SUDO} dnsmasq --enable-tftp --tftp-root=${TFTP_DIR},${INTERFACE} -d --pxe-service=0,"Raspberry Pi Boot" \
    #    --dhcp-reply-delay=1  ${DHCP_OPT} #--tftp-unique-root=mac --pxe-prompt="Boot Raspberry Pi",1 --dhcp-host=e4:5f:01:1f:b7:54,set:piserver tag:piserver,
    
    read -p "Press a key to stop NFSboot.."
}

qCommand() {
    ${TERMINAL_CMD} sudo dnsmasq --enable-tftp --tftp-root=/tftpLE,${INTERFACE} -d --pxe-service=0,"Raspberry Pi Boot" --dhcp-reply-delay=1 --dhcp-range=192.168.1.20,proxy --port=0
    ${TERMINAL_CMD} sudo dnsmasq --enable-tftp --tftp-root=/nfs/root/boot,${INTERFACE} -d --pxe-service=0,"Raspberry Pi Boot" --dhcp-reply-delay=1 --dhcp-range=192.168.1.20,proxy --port=0
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
    VERSION_ID="10.0"   #TODO set 10.0 if not defined
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
            xbmc.executebuiltin( "PlayerControl(RepeatAll)" )

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
    ## Disable RpiSplash
    ${SUDO} sed -i '/disable_splash/d' ${TFTP_DIR}/config.txt
    echo "disable_splash=1" | ${SUDO} tee -a ${TFTP_DIR}/config.txt
    
    ## Disable LibreELEC Splash
    sudo touch /tftpLE/oemsplash.png
    cat << EOF | sed 's/^.\{8\}//' | ${SUDO} tee ${STORAGE_DIR}/.kodi/userdata/advancedsettings.xml 1>/dev/null    
        <advancedsettings version="1.0">
            <services>
                <webserver>true</webserver>
                <!-- webserverport>8080</<webserverport -->
                <webserverpassword>raspi</webserverpassword>
                <webserverusername>KODI</webserverusername>
            </services>
            <splash>false</splash>
            <cache>
                <buffermode>1</buffermode>
                <memorysize>139460608</memorysize>
                <readfactor>20</readfactor>
            </cache>
            <gui>
                <smartredraw>false</smartredraw>
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
        ${SUDO} mkdir -pv ${STORAGE_DIR}/.cache/services
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
    # mkdir -pv .kodi/addons/script.button
            cat << EOF | sed 's/^.\{12\}//' | ${SUDO} tee ${STORAGE_DIR}/.kodi/addons/service.autoexec/autoexec.py 1>/dev/null
            import xbmc
            xbmc.executebuiltin( "SetVolume(30)" )
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
    read -p "Press a key to continue.."
    if [ -d /mnt/sqfs ];then
        sudo umount -lv /mnt/sqfs
        sudo rm -r /mnt/sqfs
    fi
    # remove this script's nfs shares (lines with #libreELEC) 
    ${SUDO} sed -i "/${HOST_OS}/d" /etc/exports
    ${SUDO} sed -i 's/#PARTUUID/PARTUUID/g' ${STORAGE_DIR}/etc/fstab
    
    # restart nfs server - TODO restore original sttate
    ${SUDO} service nfs-kernel-server restart
    # exportfs -r

    ${SUDO} sed -i "/cmdline=/d" ${TFTP_DIR}/config.txt
    sync
    # unmount mounted img
    mountpoint ${TFTP_DIR} && ${SUDO} umount -lv ${TFTP_DIR}
    mountpoint ${STORAGE_DIR} && ${SUDO} umount -lv ${STORAGE_DIR}
    ${SUDO} rm -r ${TFTP_DIR} ${STORAGE_DIR}
    # remove loopdevice
    ##losetup -l | sed '/piCore64-13.0.img/!d;s/ .*//'
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
    resizeImage
    mountLE
    #LEversion
    detectOS
    case ${HOST_OS} in
        *)
            echo "HOST_OS = ${HOST_OS} -------------- Do specific SetUp steps Here."
            ;;
    esac

    if [ ${HOST_OS}x == piCorex ]; then
        echo ":: Do piCore specific tasks here..."
    elif [ ${HOST_OS}x == "LibreELECx" ]; then  # if libreELEC in this case.)
        echo ":: Do libreELEC specific tasks here..."
        SETUP=1
        createSshKey
        [ $SETUP == 1 ] || echo ":: Skipping SetUp"
        [ $SETUP == 1 ] || playStartUpVideo
        [ $SETUP == 1 ] || wizzard
        [ $SETUP == 1 ] || skinHack
        [ $SETUP == 1 ] || disableSplash
    fi
    netBoot
    cleanExit
}

[ "${BASH_SOURCE}" == "${0}" ] && runLEnfsBoot


commands() {
    # import sys
    # sys.path.append('/storage/.kodi/addons/virtual.rpi-tools/lib')
    PATH=$PATH:/storage/.kodi/addons/script.module.kodi-six/libs/kodi_six
    kodi-send --host=192.168.1.4 --port=9777 --action="reboot" # 
    kodi-send --action="PlayerControl(Play)"
    kodi-send --action="ReloadSkin(reload)"
    kodi-send --action="Skin.ToggleDebug()"
    kodi-send --action="DialogOK(msg="oooooo",100)"
    kodi-send --action="RunScript('/storage/.kodi/myScripts/Animatics.py')"
    kodi-send --action="CECActivateSource"
    #xbmc.log( msg='This is a test string.', level=xbmc.LOGDEBUG)
    $INFO[Player.Title]
    $INFO[infolabel]
    #display_hdmi_rotate=-1
    #display_lcd_rotate=-1

}