## https://libreelec.wiki/configuration/network-boot
## https://forum.libreelec.tv/thread/20163-rpi4-gpio-using-in-libreelec/

# sudo mount 192.168.1.20:/mnt/LinuxData/OF /mnt/LinuxData/OF
#!/bin/bash
SUDO=sudo

#DEV_DIR=/mnt/LinuxData
TFTP_DIR=/tftpLE
IMG_DIR=/mnt/LinuxData/Install/img
STORAGE_DIR=/mnt/media/storage
# STORAGE_DIR=/media/pimaker/STORAGE

mkdir -pv ${STORAGE_DIR}

DHCP=0
    if [ $DHCP -eq 1 ]; then
        HOST_IP=$(hostname -I | sed 's/ .*//')
    else
        HOST_IP=10.0.0.1
    fi

IMG=${IMG_DIR}/LibreELEC-RPi4.arm-9.95.4.img
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
    local COUNT=2048
    ${SUDO} bash -c "dd if=/dev/zero bs=1M count=${COUNT} >> ${IMG}"
}

mountLE() {
    LOOP_DEVICE=$(${SUDO} losetup -f)
    ${SUDO} losetup -P $LOOP_DEVICE $IMG
    ${SUDO} mkdir -pv ${TFTP_DIR}
    ${SUDO} mount -v ${LOOP_DEVICE}p1 ${TFTP_DIR} || ( echo "error mounting ${TFTP_DIR}" && exit )
    
    ${SUDO} mount -v ${LOOP_DEVICE}p2 ${STORAGE_DIR} || ( echo "error mounting ${STORAGE_DIR}" && exit )
    read -p "Press ENTER to continue..."
}

prepare() {
    ${SUDO} mkdir -pv ${STORAGE_DIR}
    echo "boot=NFS=${HOST_IP}:${TFTP_DIR} disk=NFS=${HOST_IP}:${STORAGE_DIR} rw ip=dhcp rootwait quiet" | \
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
        DHCP_OPT="--dhcp-range=${HOST_IP},proxy --port=0"
        echo "::DHCP = 1 !!!!!!"
    else
        DHCP_OPT="--dhcp-range=${HOST_IP%.*}.2,${HOST_IP%.*}.10,12h --listen-address=127.0.0.1,10.0.0.1 --port=5300"
    fi
    ${SUDO} dnsmasq --enable-tftp --tftp-root=${TFTP_DIR},enp0s25 -d --pxe-service=0,"Raspberry Pi Boot" --pxe-prompt="Boot Raspberry Pi",1 \
        --tftp-unique-root=mac --dhcp-reply-delay=1 ${DHCP_OPT} #--dhcp-range=${DHCP_RANGE}
}

LEversion() {
    # ${SUDO} 
    sudo mkdir -pv /mnt/sqfs
    sudo mount /tftpLE/SYSTEM /mnt/sqfs -t squashfs -o loop
    . /mnt/sqfs/etc/os-release
    [ "${VERSION_ID%.*}" -gt 9 ] && echo ":: Ten" || echo ":: Nine"
    sudo umount -lv /mnt/sqfs
    sudo rm -r /mnt/sqfs

}

playStartUpVideo() {
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
            xbmc.executebuiltin( "PlayMedia(/storage/videos/E8-Fire.mp4)" )
            xbmc.executebuiltin( "PlayerControl(repeat)" )
            print("HURRÁH")
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
    fi
    echo ":: VERSION_ID=${VERSION_ID}"
}
# ${STORAGE_DIR}/.kodi/userdata/addon_data/service.libreelec.settings/oe_settings.xml - WIZZARD + HOSTNAME!!!! KODI10
disableSplash() {
    # mkdir -pv ${STORAGE_DIR}/.kodi/userdata/
    # Disable LibreELEC Splash
    echo | sudo tee /tftpLE/oemsplash.png
    cat << EOF | sed 's/^.\{8\}//' | ${SUDO} tee ${STORAGE_DIR}/.kodi/userdata/advancedsettings.xml 1>/dev/null    
        <advancedsettings version="1.0">
            <services>
                <webserver>true</webserver>
                <webserverpassword>raspi</webserverpassword>
                <webserverusername>KODI</webserverusername>
            </services>
            <splash>false</splash>
        </advancedsettings>    
EOF
}

createSshKey() {
        HOSTNAME=$(hostname -s)
        ${SUDO} mkdir -pv -m 700 ${STORAGE_DIR}/.ssh
        [ -f ~/.ssh/testkey@${HOSTNAME} ] || ${SUDO} ssh-keygen -q -N Pepe374189 -C testKey -f ~/.ssh/testkey@${HOSTNAME}
        ${SUDO} cat ~/.ssh/testkey@${HOSTNAME}.pub | ${SUDO} tee ${STORAGE_DIR}/.ssh/authorized_keys 1>/dev/null
        ${SUDO} chmod 600 ${STORAGE_DIR}/.ssh/authorized_keys
}

cleanExit() {
    # remove this script's nfs shares (lines with #libreELEC) 
    ${SUDO} sed -i '/libreELEC/d' /etc/exports
    # restart nfs server - TODO restore original sttate
    ${SUDO} exportfs -r

    ${SUDO} sed -i '/nfsboot.LE/d' ${TFTP_DIR}/distroconfig.txt
    # unmount mounted img
    mountpoint ${TFTP_DIR} && ${SUDO} umount -lv ${TFTP_DIR}
    ${SUDO} rm -r ${TFTP_DIR}
    # remove loopdevice
    ${SUDO} losetup -d ${LOOP_DEVICE}
    exit 0
}

runLEnfsBoot() {
    trap 'echo "SIGINT !!!" && cleanExit ' INT
    get_img
    #resizeImage
    mountLE
    LEversion
    playStartUpVideo
    disableSplash
    createSshKey
    prepare
    cleanExit
}



[ "${BASH_SOURCE}" == "${0}" ] && runLEnfsBoot


commands() {
    import sys
    # sys.path.append('/storage/.kodi/addons/virtual.rpi-tools/lib')
    PATH=$PATH:/storage/.kodi/addons/script.module.kodi-six/libs/kodi_six
    kodi-send --host=192.168.0.1 --port=9777 --action="Quit"
    kodi-send --action='RunScript("/path/to/script.py")'
}

