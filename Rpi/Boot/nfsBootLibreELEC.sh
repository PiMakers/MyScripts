## https://libreelec.wiki/configuration/network-boot

#!/bin/bash
SUDO=sudo

#DEV_DIR=/mnt/LinuxData
TFTP_DIR=/tftpLE
IMG_DIR=/mnt/LinuxData/Install/img
STORAGE_DIR=/mnt/media/storage

IMG=${IMG_DIR}/LibreELEC-RPi4.arm-9.2.6.img

get_img(){
    if ! IMG=$(zenity --file-selection --file-filter="*.img *.zip *.gz" --filename=${IMG_DIR}/2019-09-26-raspbian-buster-full-netboot.img 2>/dev/null); then
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

mountLE() {
    LOOP_DEVICE=$(${SUDO} losetup -f)
    ${SUDO} losetup -P $LOOP_DEVICE $IMG
    ${SUDO} mkdir -pv ${TFTP_DIR}
    ${SUDO} mount -v ${LOOP_DEVICE}p1 ${TFTP_DIR} || echo "error mounting ${BOOT_FS}"
}

prepare() {
    HOST_IP=$(hostname -I | sed 's/ .*//')
    ${SUDO} mkdir -pv ${STORAGE_DIR}
    echo "boot=NFS=${HOST_IP}:${TFTP_DIR} disk=NFS=${HOST_IP}:/mnt/media/storage rw ip=dhcp rootwait" | \
        ${SUDO} tee ${TFTP_DIR}/cmdline.nfsboot.LE
    
    ${SUDO} sed -i '/nfsboot.LE/d' ${TFTP_DIR}/distroconfig.txt
    echo "cmdline=cmdline.nfsboot.LE" | ${SUDO} tee -a ${TFTP_DIR}/distroconfig.txt

    ${SUDO} sed -i '/libreELEC/d' /etc/exports
    echo "/mnt/media/storage      ${HOST_IP%.*}.0/24(rw,sync,no_subtree_check,insecure,no_root_squash,crossmnt,anonuid=0,anongid=0) #libreELEC
${TFTP_DIR}			${HOST_IP%.*}.0/24(rw,sync,no_subtree_check,insecure,no_root_squash,crossmnt,anonuid=0,anongid=0) #libreELEC" | ${SUDO} tee -a /etc/exports 

    ${SUDO} exportfs -r
    # ${SUDO} exportfs
    ${SUDO} service dnsmasq stop
    ${SUDO} dnsmasq --enable-tftp --port=0 --tftp-root=${TFTP_DIR},enp0s25 -d --pxe-service=0,"Raspberry Pi Boot" --pxe-prompt="Boot Raspberry Pi",1 \
        --dhcp-range=${HOST_IP},proxy --tftp-unique-root=mac --dhcp-reply-delay=1
    echo "DNSM_PI=?!"
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

}

runLEnfsBoot() {
    get_img
    mountLE
    prepare
    cleanExit
}

trap 'echo "SIGINT !!!" && cleanExit ' INT

[ "${BASH_SOURCE}" == "${0}" ] && runLEnfsBoot