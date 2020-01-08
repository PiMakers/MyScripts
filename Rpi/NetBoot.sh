## 

#!/bin/bash


#trap "echo SIGINT && exit" SIGINT

#set -e

# if sourced exit with "return"
exit() {
    trap "echo FuckYou!!!" EXIT
    trap "echo FuckYouToo" RETURN
    [ "${BASH_SOURCE}" == "${0}" ] || EXIT_CMD=return && echo "EXIT_CMD=${EXIT_CMD}" 
    kill -2 $$
}

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
            exit
        fi
    fi
}

check_dependency(){
    $1 && return
    depends_on="dnsmasq"s
    depends_on+=" nfs-kernel-server"
    depends_on+=" zenity"
    depends_on+=" curl"
    for i in $depends_on; do
        if [[ $(dpkg-query -s $i) ]];then
            echo "$i installed!"
        else
            echo "Dependency $i NOT installed!"
            needed+=" $i"
        fi
    done
    # install unmet dependencies
    if [ ! -z needed ]; then
        ${SUDO} apt install $needed
    fi
}

HOST_IP=$(echo $(hostname -I) | sed 's/ .*//')
NFS_ROOT=/nfs
BOOT_FS=${NFS_ROOT}/boot
ROOT_FS=${NFS_ROOT}/root
IMG_FOLDER=/mnt/LinuxData/Downloads
serials="b0c7e328"

get_img(){
    if ! IMG=$(zenity --file-selection --file-filter="*.img *.zip" --filename=${IMG_FOLDER}/2019-09-26-raspbian-buster-full-netboot.img 2>/dev/null); then
        echo "No img selected. Exit"; exit 1
    else 
        echo $IMG
        if [ ${IMG##*.}=="zip" ];then
            if [ ! -f ${IMG%.*}.img ];then
                unzip $IMG -d ${IMG_FOLDER}/
            fi
            IMG=${IMG%.*}.img
            echo $IMG
        fi
    fi
}

mount_image() {
    LOOP_DEVICE=$(${SUDO} losetup -f)
    ${SUDO} losetup $LOOP_DEVICE $IMG
    ${SUDO} partprobe $LOOP_DEVICE 	|| echo "error partprobe $LOOP_DEVICE "
    #mkdir -p ${RPI_BOOT} ${RPI_ROOT}   || echo "error create ${RPI_BOOT} "
    ${SUDO} mkdir -p -m 777 ${BOOT_FS}
    ${SUDO} mkdir -p -m 777 ${ROOT_FS}
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
        ${SUDO} bash -c "cat > ${BOOT_FS}/cmdline.txt" << EOF
dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=192.168.0.53:/root,vers=4.1,proto=tcp,port=2049 rw ip=dhcp elevator=deadline rootwait plymouth.ignore-serial-consoles noswap
EOF
    fi
}

hack() {
#   ${SUDO} mkdir -m 755 boot.bak
    files=" start.elf \
            start4.elf \
            bcm2710-rpi-3-b.dtb \
            bcm2711-rpi-4-b.dtb \
            fixup.dat"
    for file in  $files
    do
        ${SUDO} curl https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/${file} -o ${BOOT_FS}/${file}
    done

}

#fstab:
prepare_fstab() {
    if [ ! -f ${ROOT_FS}/etc/fstab.orig ];then
        ${SUDO} cp ${ROOT_FS}/etc/fstab ${ROOT_FS}/etc/fstab.orig
        ${SUDO} sed -i 's/PARTUUID/#PARTUUID/g' ${ROOT_FS}/etc/fstab
        ${SUDO} sed -i '/PxeServer/d' ${ROOT_FS}/etc/fstab
        # delete all trailing blank lines at end of file
        sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' ${ROOT_FS}/etc/fstab
    fi
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

configure_dnsmasq(){
[ -f /etc/dnsmasq.conf.orig ] || ${SUDO} cp /etc/dnsmasq.conf /etc/dnsmasq.conf.orig || echo "dnsmasq.conf backup failed!!!"
${SUDO} bash -c 'cat > /etc/dnsmasq.d/bootserver.conf' << EOF
#PXE BootServer by PiMaker®
bind-dynamic
log-dhcp
enable-tftp
tftp-root=${BOOT_FS}
#tftp-unique-root=mac
#local-service
#host-record=piserver,192.168.0.53

port=0
#interface=eth0
interface=enp0s25
dhcp-range=${HOST_IP%.*}.0,proxy,255.255.255.0

dhcp-script=/bin/echo

#pxe-service=x86PC, "PXE Boot Menu", pxelinux
dhcp-boot=pxelinux.0
pxe-service=0,"Raspberry Pi Boot"
#dhcp-range=tag:piserver,192.168.0.53,proxy
#pxe-service=tag:piserver,0,"Raspberry Pi Boot"
#dhcp-reply-delay=tag:piserver,1

#dhcp-host=b8:27:eb:c7:e3:28,set:piserver
#dhcp-host=b8:27:eb:d0:2e:74,set:piserver
# Pi4
# dhcp-host=b8:27:eb:d0:2e:74,set:piserver
EOF
}

remove_dphys-swapfile(){
    ${SUDO} rm /nfs/root/etc/systemd/system/multi-user.target.wants/dphys-swapfile.service
    for (( i=2;i<=5;i++ ))
    do
        ${SUDO} rm -f ${ROOT_FS}/etc/rc$i.d/S01dphys-swapfile
    done
}

check_root
get_img
mount_image
prepare_cmdline
prepare_fstab
remove_dphys-swapfile
hack
#
 ${SUDO} rm -f /nfs/root/etc/rc3.d/S01resize2fs_once

#exit

configure_nfs
configure_dnsmasq
${SUDO} service 'dnsmasq nfs-kernel-server' restart

while ! $(zenity --question --text="Close the bootserver?" 2>/dev/null)
do
    echo sleeping...
    sleep 10
done

${SUDO} service 'dnsmasq nfs-kernel-server' stop
#
sudo ln -s ../init.d/resize2fs_once /nfs/root/etc/rc3.d/S01resize2fs_once

sync
${SUDO} umount -lv ${BOOT_FS}
${SUDO} umount -lv ${ROOT_FS}
${SUDO} losetup -d $LOOP_DEVICE
${SUDO} rm -R ${BOOT_FS} ${ROOT_FS}


${SUDO} sed -i '/PxeServer/d' /etc/exports
${SUDO} rm /etc/dnsmasq.d/bootserver.conf

${SUDO} service 'nfs-kernel-server' restart

:
# rc2-5 /nfs/root/etc/rc3.d/S01dphys-swapfile -> ../init.d/dphys-swapfile
# sudo rm /nfs/root/etc/systemd/system/multi-user.target.wants/dphys-swapfile.service
# sudo ln -s /dev/null /nfs/root/etc/systemd/system/multi-user.target.wants/dphys-swapfile.service
# sudo ln -s  /lib/systemd/system/dphys-swapfile.service /nfs/root/etc/systemd/system/multi-user.target.wants/dphys-swapfile.service
# Insert gpio-halt into rc.local before final 'exit 0'
# sed -i "s/^exit 0/service ssh start \\nexit 0/g" /etc/rc.local >/dev/null

#/etc/systemd/system/multi-user.target.wants/dphys-swapfile.service -> /lib/systemd/system/dphys-swapfile.service

# /nfs/boot/config.txt
# /nfs/boot/start.elf
# /nfs/boot/fixup.dat
# /nfs/boot/cmdline.txt
# /nfs/boot/bcm2710-rpi-3-b.dtb
# /nfs/boot/kernel7.img

# sudo apt purge python-games mu-editor minecraft-pi libreoffice-pi scratch* wolfram* claws-mail libreoffice*

## https://www.bitpi.co/2015/02/14/prevent-raspberry-pi-from-sleeping/
# sudo nano /etc/xdg/lxsession/LXDE-pi/autostart 
## @xset s noblank
## @xset s off
## @xset -dpms

#sudo nano /etc/lightdm/lightdm.conf
#Anywhere below the [SeatDefaults] header, add:

#xserver-command=X -s 0 -dpms
#This will set your blanking timeout to 0 and turn off your display power management signaling.

#sudo curl https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/start.elf -o /nfs/boot/start.elf

## The umount command will fail to detach the share when the mounted volume is in use. \
## To find out which processes are accessing the NFS share, use the fuser command:
# fuser -m MOUNT_POINT

## piserver dnsmasq
### This is an auto-generated file. DO NOT EDIT

#bind-dynamic
#log-dhcp
#enable-tftp
#tftp-root=/var/lib/piserver/tftproot
#tftp-unique-root=mac
#local-service
#host-record=piserver,192.168.0.53
#dhcp-range=tag:piserver,192.168.0.53,proxy
#pxe-service=tag:piserver,0,"Raspberry Pi Boot"
#dhcp-reply-delay=tag:piserver,1

#dhcp-host=b8:27:eb:c7:e3:28,set:piserver
#dhcp-host=b8:27:eb:d0:2e:74,set:piserver


## Pi 4 netboot : https://hackaday.com/2019/11/11/network-booting-the-pi-4/
## https://github.com/raspberrypi/rpi-eeprom/blob/master/firmware/raspberry_pi4_network_boot_beta.md

#sudo apt-get update
#sudo apt-get upgrade
#wget https://github.com/raspberrypi/rpi-eeprom/raw/master/firmware/beta/pieeprom-2019-12-03.bin
#rpi-eeprom-config pieeprom-2019-12-03.bin > bootconf.txt
#sed -i s/0x1/0x21/g bootconf.txt
#rpi-eeprom-config --out pieeprom-2019-12-03-netboot.bin --config bootconf.txt pieeprom-2019-12-03.bin
#sudo rpi-eeprom-update -d -f ./pieeprom-2019-12-03-netboot.bin
#cat /proc/cpuinfo