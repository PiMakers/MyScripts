#######################################################
# https://softwarebakery.com//shrinking-images-on-linux
# sudo apt install qemu-utils kpartx parted
#########################     !/usr/bin/env bash
#### set -e
#!/bin/bash

##### dependency 18.04 sudo apt install qemu-user-static
 
set -e

check_root () {
if [ $EUID ]; then
	echo "this script must be run as root"
	echo ""
	echo "usage:"
	echo "sudo "$0
	exit 1
fi
}

export LC_LOCAL=C

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"
RASPBIAN_TYPE="" # full_ / lite_ /
# exit 1
if [ "$ARGS" == "lite" ]; then
 RASPBIAN_TYPE="lite_"
  else if [ "$ARGS" == "full" ]; then
  RASPBIAN_TYPE="full_" 
  fi
fi

ROOT=$( cd "$(dirname "$0")" ; pwd -P )
echo -e " ROOT = $ROOT\n PROGNAME = $PROGNAME\n PROGDIR = $PROGDIR\n ARGS = $ARGS\n"
export TEMP_FOLDER=/tmp
export RPI_FS=${TEMP_FOLDER}/rpifs
export RPI_ROOT=${RPI_FS}/rootfs
export RPI_BOOT=${RPI_FS}/boot

cd $ROOT

# MY_IP=$(hostname -I | sed 's/ .*//')
# https://downloads.raspberrypi.org/raspbian_lite_latest

# check if we have the latest img
latest_version() {
type curl || ( echo "curl not installed"; return 1 )
LATEST_VERSION=$(curl https://downloads.raspberrypi.org/raspbian_${RASPBIAN_TYPE}latest 2>/dev/null | sed '/href/!d; s/.zip.*//; s/.*\///')
[ ! -z $$LATEST_VERSION ] || (echo "Unable to determine latast version!!!"; return 1)
echo LATEST_VERSION=$LATEST_VERSION || return 1
}

download_latest_raspbian() {
#cd ${HOME}/Downloads
curl -LJ https://downloads.raspberrypi.org/raspbian_${RASPBIAN_TYPE}latest -O || \
  ( echo "Error download $LATEST_VERSION..." && return 1)
}

get_latest_image() {
cd ${HOME}/Downloads
if [ ! -f $LATEST_VERSION.img ]; then
 echo "$LATEST_VERSION.img not found.\nSearching for $LATEST_VERSION.zip ..."
 if [ ! -f $LATEST_VERSION.zip ]; then
    echo "$LATEST_VERSION.zip not found. Downloading ..."
    download_latest_raspbian || echo "Error download latest raspbian"
 else echo "$LATEST_VERSION.zip found!"
 fi
 unzip $LATEST_VERSION.zip || (echo "Error unzip latest raspbian" && exit 101)
fi
return 0
}



#umount ${RPI_BOOT} ${RPI_ROOT} || true
mount_latest_img() {
LOOP_DEVICE=$(sudo losetup -f)
[[ ! -z "$1" ]] && err=$(sudo losetup $LOOP_DEVICE $1) || (echo "$err" && return 1)
sudo partprobe $LOOP_DEVICE 	|| echo "error partprobe $LOOP_DEVICE "

mkdir -p ${RPI_BOOT} ${RPI_ROOT}   || echo "error create ${RPI_BOOT} "
sudo mount -n ${LOOP_DEVICE}p1 ${RPI_BOOT} || echo "error mounting ${RPI_BOOT}" 
sudo mount -n ${LOOP_DEVICE}p2 ${RPI_ROOT} || echo "error mounting ${RPI_ROOT}" 
}

clean_up() {
echo "CleaningUp ...."

# umount everything if needed
err=$(sudo umount -v ${RPI_ROOT}/{sys,proc,dev/pts,dev,/boot,/mnt/LinuxData} 2>&1) || echo -e "$err"
dirs="$RPI_ROOT $RPI_BOOT ${RPI_FS}"
for dir in $dirs; do
[[ "$(ls $dir)" != "" ]] && echo "dir not empty" && \
for x in $(mount | grep $dir | sed 's/type.*//; s/.*on //'); do umount -lv "$x";done || \
 echo "$dir now empty removing..."
err=$(sudo rm -r $dir 2>/dev/null)|| ( echo "ERROR: $err" && return 101)
done
echo "clean_up: Bye-bye...."
}

chroot_raspbian () {
trap clean_up EXIT 2 SIGINT
# sleep 100
err=$(sudo cp /usr/bin/qemu-arm-static ${RPI_ROOT}/usr/bin/ 2>&1) 	|| ( echo "ERROR: $err" && return 101)
#sudo cp ${RPI_ROOT}/etc/resolv.conf 
err=$(sudo cp /etc/resolv.conf ${RPI_ROOT}/etc/resolv.conf 2>&1) || ( echo "ERROR: $err" && return 101)
#err=$(sudo mkdir -p ${RPI_ROOT}/mnt/LinuxData 2>&1) || ( echo "ERROR: $err" && return 101)

cd ${RPI_ROOT}

err=$(sudo mount --bind /proc ${RPI_ROOT}/proc/ 2>&1) 	|| ( echo "ERROR: $err" && return 101)
err=$(sudo mount --bind /dev ${RPI_ROOT}/dev/ 2>&1) 		|| ( echo "ERROR: $err" && return 101)
err=$(sudo mount --bind /dev/pts ${RPI_ROOT}/dev/pts 2>&1) 	|| ( echo "ERROR: $err" && return 101)
err=$(sudo mount --bind /sys ${RPI_ROOT}/sys/ 2>&1) 		|| ( echo "ERROR: $err" && return 101)

err=$(sudo mount --bind ${RPI_BOOT} ${RPI_ROOT}/boot/ 2>&1) 			|| ( echo "ERROR: $err" && return 101)
#err=$(sudo mount --bind /mnt/LinuxData ${RPI_ROOT}/mnt/LinuxData 2>&1) 	|| ( echo "ERROR: $err" && return 101)
# cmd=/mnt/LinuxData/Scripts/Rpi/setupNew.sh
# chroot . $cmd 						|| echo "ERROR: chroot"
sudo chroot . "apt update"  || ( echo "ERROR: chroot" && clean_up )

err=$(sudo umount -v ${RPI_ROOT}/{sys,proc,dev/pts,dev,/boot,/mnt/LinuxData} 2>&1) || echo -e "$err"
# sudo umount ${RPI_ROOT}/mnt/LinuxData  || echo "error LinuxData"
# sudo umount ${RPI_ROOT}/boot/  || echo "error uBoot"

sudo rm ${RPI_ROOT}/usr/bin/qemu-arm-static || echo "error remove qemu-arm-static"
echo "chroot_raspbian: Bye-bye...."
}



my_exit () {
sudo umount -lv ${RPI_BOOT} || echo "could not umount RPI_BOOT ($RPI_BOOT)"
sudo umount -lv ${RPI_ROOT} || echo "could not umount $RPI_ROOT"
sudo losetup -d $LOOP_DEVICE || echo "could not umount losetup -d $LOOP_DEVICE"
}

latest_version
get_latest_image
mount_latest_img $LATEST_VERSION.img || echo "error mounting $LATEST_VERSION.img"
#chroot_raspbian
#my_exit


echo "exited normally" && exit 0


# enable ssh
touch ${RPI_BOOT}/ssh

#############
# Silent Boot
#############
# 1. remove: Logo, blinking cursor, add:loglevel=3
grep -q 'logo.nologo' ${RPI_BOOT}/cmdline.txt || sed -i 's/$/ logo.nologo/' ${RPI_BOOT}/cmdline.txt
grep -q 'vt.global_cursor_default=0' ${RPI_BOOT}/cmdline.txt || sed -i 's/$/ vt.global_cursor_default=0/' ${RPI_BOOT}/cmdline.txt
grep -q 'loglevel=' ${RPI_BOOT}/cmdline.txt || sed -i 's/$/ loglevel=3/' ${RPI_BOOT}/cmdline.txt

# Remove Rainbow Screen
grep -q '^disable_splash' ${RPI_BOOT}/config.txt || \
grep -q '# disable_splash' ${RPI_BOOT}/config.txt && \
sed -i '/^# disable_splash/ s/# //' ${RPI_BOOT}/config.txt || \
( echo -e "\n# Disable rainbow image at boot\t\t#PubHub" >> ${RPI_BOOT}/config.txt && \
echo -e "disable_splash=1\t\t\t#PubHub" >> ${RPI_BOOT}/config.txt )



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
