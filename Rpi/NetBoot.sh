#!/bin/bash

#set -e

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

HOST_IP=$(echo $(hostname -I) | sed 's/ .*//')
NFS_ROOT=/nfs
BOOT_FS=${NFS_ROOT}/boot
ROOT_FS=${NFS_ROOT}/root
${SUDO} mkdir -p -m 777 ${BOOT_FS}
${SUDO} mkdir -p -m 777 ${ROOT_FS}
IMG=$(zenity --file-selection)
echo $IMG 



mount_image() {
    LOOP_DEVICE=$(${SUDO} losetup -f)
    ${SUDO} losetup $LOOP_DEVICE $IMG
    ${SUDO} partprobe $LOOP_DEVICE 	|| echo "error partprobe $LOOP_DEVICE "
    #mkdir -p ${RPI_BOOT} ${RPI_ROOT}   || echo "error create ${RPI_BOOT} "
    ${SUDO} mount -n ${LOOP_DEVICE}p1 ${BOOT_FS} || echo "error mounting ${BOOT_FS}"
    ${SUDO} mount -n ${LOOP_DEVICE}p2 ${ROOT_FS} || echo "error mounting ${ROOT_FS}"
}


pepe(){
    # remove previous modifications
    sed '/PxeServer/d' ${BOOT_FS}/config.txt
    # delete all trailing blank lines at end of file
    sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' ${BOOT_FS}/config.txt
    echo "cmdline=netboot.txt   # PxeServer" | ${SUDO} tee -a ${BOOT_FS}/config.txt
}

## OnExportedFS:
prepare_cmdline() {
    if [ ! -f ${BOOT_FS}/cmdline.txt.orig ];then
        ${SUDO} cp ${BOOT_FS}/cmdline.txt ${BOOT_FS}/cmdline.txt.orig
    fi
    ${SUDO} bash -c "cat >> ${BOOT_FS}/netboot.txt" << EOF
dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=192.168.0.53:/rootfs,vers=4.1,proto=tcp,port=2049 rw ip=dhcp elevator=deadline rootwait plymouth.ignore-serial-consolesEOF
EOF
}

#fstab:
prepare_fstab() {
if [ ! -f ${ROOT_FS}/etc/fstab.orig ];then
    ${SUDO} cp ${ROOT_FS}/etc/fstab /etc/fstab.orig
fi
${SUDO} sed -i '/PxeServer/d' ${ROOT_FS}/etc/fstab
${SUDO} bash -c "cat >> ${ROOT_FS}/etc/fstab" << EOF
${HOST_IP}:/boot /boot nfs4 defaults 0 2  #PxeServer
EOF
}

configure_nfs() {
#${SUDO} sed -i '/PxeServer/d' /etc/exports
${SUDO} bash -c 'cat > /etc/exports' << EOF
${NFS_ROOT} ${HOST_IP%.*}.0/24(rw,fsid=0,sync,no_subtree_check,no_auth_nlm,insecure,no_root_squash)     #PxeServer
${BOOT_FS} ${HOST_IP%.*}.0/24(rw,sync,no_subtree_check,no_auth_nlm,insecure,no_root_squash)      #PxeServer
${ROOT_FS} ${HOST_IP%.*}.0/24(rw,sync,no_subtree_check,no_auth_nlm,insecure,no_root_squash)      #PxeServer
EOF
}

#/etc/dnsmasq.d/bootserver.conf:
configure_dnsmasq(){
[ -f /etc/dnsmasq.conf.orig ] || ${SUDO} cp /etc/dnsmasq.conf /etc/dnsmasq.conf.orig || echo "dnsmasq.conf backup failed!!!"
${SUDO} bash -c 'cat > /etc/dnsmasq.d/bootserver.conf' << EOF
port=0
#interface=eth0
interface=enp0s25
dhcp-range=192.168.0.0,proxy,255.255.255.0
dhcp-script=/bin/echo

#pxe-service=x86PC, "PXE Boot Menu", pxelinux
dhcp-boot=pxelinux.0
enable-tftp
log-dhcp
tftp-root=${BOOT_FS}
pxe-service=0,"Raspberry Pi Boot"
EOF
}



check_root
mount_image

configure_nfs
configure_dnsmasq

${SUDO} service 'dnsmasq nfs-kernel-server' restart

while ! $(zenity --question --text="Close the bootserver?")
do
    echo sleeping...
    sleep 10
done

${SUDO} service 'dnsmasq nfs-kernel-server' stop
sudo umount ${BOOT_FS}
sudo umount ${ROOT_FS}
sudo losetup -d $LOOP_DEVICE

${SUDO} sed -i '/PxeServer/d' /etc/exports
${SUDO} rm /etc/dnsmasq.d/bootserver.conf

${SUDO} service 'dnsmasq nfs-kernel-server' restart