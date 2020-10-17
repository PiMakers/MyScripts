#######################################################
# https://softwarebakery.com//shrinking-images-on-linux
# sudo apt install qemu-utils kpartx parted
#########################     !/usr/bin/env bash
##### dependency 18.04
# sudo apt install qemu-user-static
# ? sudo apt install qemu-utils ?
# qemu-img resize -f raw /home/pimaker/Downloads/2018-11-13-raspbian-stretch.img +2G
# sudo parted /dev/loop11 resizepart 2 100%
 

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

##### dependency 18.04 sudo apt install qemu-user-static
# qemu-img resize -f raw /home/pimaker/Downloads/2018-11-13-raspbian-stretch.img +2G
install_dependencies () {

    which parted 1>/dev/null || dependencies+='parted'
    which qemu-arm-static 1>/dev/null || dependencies+=' qemu-utils'
    echo $dependencies
    [ -z $dependencies ] || ${SUDO} apt install $dependencies

}
export LC_LOCAL=C

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"
#RASPBIAN_TYPE="full_" # full / lite / ""
# exit 1

for  arg in ${ARGS}  
    do
        if [ "$arg" == "lite" ]; then
        export RASPBIAN_TYPE="lite_"
        else
            if [ "$arg" == "full" ]; then
                export RASPBIAN_TYPE="full_" 
            fi
        fi
    done

export RASPBIAN_TYPE="full_"    #!!!!!!!!!!!!!!!
echo "RASPBIAN_TYPE=$RASPBIAN_TYPE"

ROOT=$( cd "$(dirname "$0")" ; pwd -P )
echo -e " ROOT = $ROOT\n PROGNAME = $PROGNAME\n PROGDIR = $PROGDIR\n ARGS = $ARGS\n"

[ -d ${HOME}/Downloads ] || mkdir -p ${HOME}/Downloads && export DOWNLOAD_DIR=${HOME}/Downloads
export TEMP_DIR=/tmp
export RPI_FS=${TEMP_DIR}/rpifs
export RPI_ROOT=${RPI_FS}/rootfs
export RPI_BOOT=${RPI_FS}/boot
export OS_NAME=${OS_NAME:-raspbian} # raspios|raspbian

#cd $ROOT

# check if we have the latest img
latest_version() {
    type curl || ( echo "curl not installed"; exit 1 )
    LATEST_VERSION=$(curl https://downloads.raspberrypi.org/${OS_NAME}_${RASPBIAN_TYPE}latest 2>/dev/null | sed '/href/!d; s/.zip.*//; s/.*\///')
    [ ! -z $LATEST_VERSION ] || (echo "Unable to determine latast version!!!"; return 1)
    export LATEST_VERSION=$LATEST_VERSION
}

download_latest_raspbian() {
    cd ${DOWNLOAD_DIR}
    curl -LJ https://downloads.raspberrypi.org/${OS_NAME}_${RASPBIAN_TYPE}latest -o $LATEST_VERSION.zip || \
    ( echo "Error download $LATEST_VERSION..." && return 1)
}
export LATEST_VERSION=${LATEST_VERSION:-}
get_latest_image() {
    cd ${DOWNLOAD_DIR}
    if [ ! -f $LATEST_VERSION.img ]; then
        echo -e "$LATEST_VERSION.img not found.\nSearching for $LATEST_VERSION.zip ..."
        if [ ! -f $LATEST_VERSION.zip ]; then
            echo "$LATEST_VERSION.zip not found. Downloading ..."
            download_latest_raspbian || echo "Error download latest raspbian"
        else echo "$LATEST_VERSION.zip found!"
        fi
        unzip $LATEST_VERSION.zip || (echo "Error unzip latest raspbian" && exit 101)
    else 
        echo "$LATEST_VERSION.img founded!"
    fi
    ${SUDO} cp -v ${LATEST_VERSION}.img ${TEMP_DIR}
    cd ${TEMP_DIR}
}

# resize $1=image_name $ $2 +/- size G/M
resize_image() {
    RESIZED=0
    [ ! -f "$1" ] && [ -z "$2" ] && echo "Not resized!!!!" && return
    #[[ ${RESIZE} == 1 ]] && [[ $( expr $(stat -c %s $1) / 1024 / 1024) < 5120 ]] && \
    ${SUDO} qemu-img resize -f raw "$1" +2G && RESIZED=1
    LOOP_DEVICE=$(${SUDO} losetup -f)
    ${SUDO} losetup $LOOP_DEVICE $1
    OLD_DISKID="$(${SUDO} fdisk -l "$LOOP_DEVICE" | sed -n 's/Disk identifier: 0x\([^ ]*\)/\1/p')"
    ${SUDO} partprobe $LOOP_DEVICE 	|| echo "error partprobe $LOOP_DEVICE "
    #end_sector=$(${SUDO} fdisk -l -o End $LOOP_DEVICE | sed '$!d')
    #echo "end_sector =${end_sector}"
    #[ ${RESIZED} ] && 
    [[ ${RESIZED} == 1 ]] && ${SUDO} parted "$LOOP_DEVICE" u s resizepart 2 100% && \
    ${SUDO} e2fsck -f -y -v -C 0 ${LOOP_DEVICE}p2 1>/dev/null && \
    ${SUDO} resize2fs -p ${LOOP_DEVICE}p2 #|| ( echo "partitionERROR" && exit )
    DISKID="$(${SUDO} fdisk -l "${LOOP_DEVICE}" | sed -n 's/Disk identifier: 0x\([^ ]*\)/\1/p')"

    end_sector=$(${SUDO} fdisk -l -o End $LOOP_DEVICE | sed '$!d')
    echo "end_sector =${end_sector}"
    # fix_partuuid
    echo "olD: ${OLD_DISKID}\n new : ${DISKID}"
    [[ ${RESIZED} == 1 ]] && ( ${SUDO} sed -i "s/${OLD_DISKID}/${DISKID}/g" ${RPI_ROOT}/etc/fstab && \
    ${SUDO} sed -i "s/${OLD_DISKID}/${DISKID}/" ${RPI_BOOT}/cmdline.txt )
    ${SUDO} losetup -d $LOOP_DEVICE
    RESIZED=1
}

#umount ${RPI_BOOT} ${RPI_ROOT} || true
mount_image() {
    LOOP_DEVICE=$(${SUDO} losetup -f)
    ${SUDO} losetup $LOOP_DEVICE $1
    ${SUDO} partprobe $LOOP_DEVICE 	|| echo "error partprobe $LOOP_DEVICE "
    mkdir -p ${RPI_BOOT} ${RPI_ROOT}   || echo "error create ${RPI_BOOT} "
    ${SUDO} mount -n ${LOOP_DEVICE}p1 ${RPI_BOOT} || echo "error mounting ${RPI_BOOT}"
    ${SUDO} mount -n ${LOOP_DEVICE}p2 ${RPI_ROOT} || echo "error mounting ${RPI_ROOT}"
}

clean_up() {
    echo "CleaningUp ...."
    # umount everything if needed
    USER=${OLD_USER}
    HOME=${OLD_HOME}

    ${SUDO} umount -lv ${RPI_ROOT}/{mnt/LinuxData,sys,proc,dev/pts,dev,boot}

    dirs="${RPI_ROOT} ${RPI_BOOT} ${RPI_FS}"
    for dir in $dirs
        do
        [[ "$(ls $dir)" != "" ]] && echo "dir not empty" || \
        for x in $(mount | grep $dir | sed '/sda/d; s/type.*//; s/.*on //');
            do
                ${SUDO} umount -lv "$x" || echo "ERROR: cannot remove dir $x";
            done || \
            echo "$dir now empty removing..."
            ${SUDO} rm -r $dir
        done
    ${SUDO} losetup -v -d $LOOP_DEVICE || echo "could not umount losetup -d $LOOP_DEVICE"
    echo "clean_up: Bye-bye...."
}

chroot_raspbian () {
    trap clean_up SIGINT 2
    # trap my_exit SIGINT 2
    [ -z $1 ] || LATEST_VERSION=$1
    echo "LATEST_VERSION=$LATEST_VERSION.img" && \
    mount_image ${LATEST_VERSION}.img
    # sleep 100
    ${SUDO} cp /usr/bin/qemu-arm-static ${RPI_ROOT}/usr/bin/qemu-arm-static
    ${SUDO} cp /etc/resolv.conf ${RPI_ROOT}/etc/resolv.conf
    ${SUDO} mv ${RPI_ROOT}/etc/ld.so.preload ${RPI_ROOT}/etc/ld.so.preload.orig
    # ${SUDO} cp -r /mnt/LinuxData/OF/myGitHub/MyScripts ${RPI_ROOT}/home/pi/
    # ${SUDO} touch /boot/PiMaker.log
    
    cd ${RPI_ROOT}

    ${SUDO} mount --bind /proc ${RPI_ROOT}/proc/
    ${SUDO} mount --bind /dev ${RPI_ROOT}/dev/
    ${SUDO} mount --bind /dev/pts ${RPI_ROOT}/dev/pts
    ${SUDO} mount --bind /sys ${RPI_ROOT}/sys/
    ${SUDO} mount --bind ${RPI_BOOT} ${RPI_ROOT}/boot/
    
    ${SUDO} mkdir -p ${RPI_ROOT}/mnt/LinuxData
    ${SUDO} mount --bind /mnt/LinuxData ${RPI_ROOT}/mnt/LinuxData
    
    cmd='/home/pi/MyScripts/Rpi/temp.sh'
    OLD_USER=${USER}
    OLD_HOME=${HOME}
    #SUDO_USER=pi
    USER=pi
    HOME=/home/${USER}
    #err=$(${SUDO} chroot . $cmd) || echo "ERROR:  $err !!!!!!!!!!!"  
    ${SUDO} chroot --userspec=pi:root . || echo "ERROR:  $err !!!!!!!!!!!" #$cmd || echo "ERROR:  $err !!!!!!!!!!!"
    
    my_exit
    
    echo "chroot_raspbian: Bye-bye...."

    read -p "Save changes? (y/any)" IMG_NAME
    [[ ${IMG_NAME} != "y" ]] && ${SUDO} rm ${TEMP_DIR}/${LATEST_VERSION}.img && exit 101
    read -p "Type a name (extension) for new img: " IMG_NAME
    # mv  ${HOME}/Downloads/${LATEST_VERSION}.img "${LATEST_VERSION}_${IMG_NAME}.img"
    ${SUDO} mv  ${TEMP_DIR}/${LATEST_VERSION}.img "/mnt/LinuxData/SavedDiscImges/${LATEST_VERSION}${IMG_NAME}.img"
    echo "Image saved as /mnt/LinuxData/SavedDiscImges/${LATEST_VERSION}${IMG_NAME}.img"
    #chown ${USER}:${USER} ${NEW_IMG_NAME}
    #read -p "Write SD card ? (y any)" IMG_NAME
    #[ ${IMG_NAME} == "y"] && sudo dd bs=1M if=$LATEST_VERSION_${IMG_NAME}.img of=/dev/sdx
}

my_exit () {
  echo "MyExit....."
    # ******************
    USER=${OLD_USER}
    HOME=${OLD_HOME}
    #cd
    err=$(${SUDO} umount -lv ${RPI_ROOT}/{mnt/LinuxData/,sys,proc,dev/pts,dev,boot})  || echo "$err"

    err=$(${SUDO} rm ${RPI_ROOT}/usr/bin/qemu-arm-static) || echo "$err"
    err=$(${SUDO} rm ${RPI_ROOT}/etc/resolv.conf) || echo "$err"
    [ -f ${RPI_ROOT}/etc/ld.so.preload.orig ] && ${SUDO} mv ${RPI_ROOT}/etc/ld.so.preload.orig ${RPI_ROOT}/etc/ld.so.preload

    sync
    ${SUDO} umount -lv ${RPI_BOOT}
    ${SUDO} umount -lv ${RPI_ROOT}
    ${SUDO} losetup -v -d $LOOP_DEVICE
    err=$(${SUDO} rm -r ${RPI_FS}) || echo "$err"
    
    echo "chroot_raspbian: Bye-bye...."
    read -p "Save changes? (y/any)" IMG_NAME
    [[ ${IMG_NAME} != "y" ]] && ${SUDO} rm ${TEMP_DIR}/${LATEST_VERSION}.img && exit 101
    read -p "Type a name (extension) for new img: " IMG_NAME
    #mv  ${HOME}/Downloads/${LATEST_VERSION}.img "${LATEST_VERSION}_${IMG_NAME}.img"
    ${SUDO} mv  ${TEMP_DIR}/${LATEST_VERSION}.img "/mnt/LinuxData/SavedDiscImges/${LATEST_VERSION}${IMG_NAME}.img"
    echo "Image saved as /mnt/LinuxData/SavedDiscImges/${LATEST_VERSION}${IMG_NAME}.img"
    #chown ${USER}:${USER} ${NEW_IMG_NAME}
    #read -p "Write SD card ? (y any)" IMG_NAME
    #[ ${IMG_NAME} == "y"] && sudo dd bs=1M if=$LATEST_VERSION_${IMG_NAME}.img of=/dev/sdx


    ${SUDO} rm ${RPI_ROOT}/usr/bin/qemu-arm-static || echo "error remove qemu-arm-static"    
    ${SUDO} umount -lv ${RPI_BOOT} || echo "could not umount RPI_BOOT ($RPI_BOOT)"
    ${SUDO} umount -lv ${RPI_ROOT} || echo "could not umount $RPI_ROOT"
    ${SUDO} losetup -d $LOOP_DEVICE || echo "could not umount losetup -d $LOOP_DEVICE"
    echo "MyExit happend!!!!"
    #exit 101
}

check_root
# install_dependencies
 latest_version
 get_latest_image
 chroot_raspbian # "/mnt/LinuxData/SavedDiscImges/2019-04-08-raspbian-stretch_PiTop"
# chroot_raspbian #"${HOME}/2018-11-13-raspbian-stretch_T.I.img"
# clean_up

echo "exited normally"

# exit 0

more() {

  sed -i '/LinuxData/d' ${RPI_ROOT}/etc/fstab
  echo "#192.168.0.13:/LinuxData /mnt/LinuxData nfs rw  0  0" >> ${RPI_ROOT}/etc/fstab
  echo "//192.168.0.13/LinuxData /mnt/LinuxData cifs username=pimaker,password=raspi,vers=2.0,iocharset=utf8,file_mode=0777,dir_mode=0777 0 0" >> ${RPI_ROOT}/etc/fstab
  sed -i 'export LC_ALL=C' ${RPI_ROOT}/home/pi/.bashrc
  echo "export LC_ALL=C" >> ${RPI_ROOT}/home/pi/.bashrc
  cat > ${RPI_ROOT}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf << EOF
  country=HU
  ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
  update_config=1

  network={
      scan_ssid=1
      ssid="${CLIENT_SSID}"
      psk="${CLIENT_PASSPHRASE}"
  #    key_mgmt=WPA-PSK
  #    priority=99
  }
EOF
  [ -e ${RPI_ROOT}/etc/wpa_supplicant/wpa_supplicant.conf ] && rm ${RPI_ROOT}/etc/wpa_supplicant/wpa_supplicant.conf

  sync
  sleep 5
  umount ${RPI_BOOT} ${RPI_ROOT} && sudo losetup -d $LOOP_DEVICE
  NEW_IMG_NAME=modded_$(date +"%H%M%S")${IMG_NAME}
  mv  ${IMG_NAME} ${NEW_IMG_NAME}
  chown ${USER}:${USER} ${NEW_IMG_NAME}

}