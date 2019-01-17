#https://softwarebakery.com//shrinking-images-on-linux

#########################     !/usr/bin/env bash
#### set -e
#/bin/bash

set -e

if [ $EUID ]; then
	echo "this script must be run as root"
	echo ""
	echo "usage:"
	echo "sudo "$0
	exit 1
fi

export LC_LOCAL=C

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"
LITE=""
# exit 1
if [ "$ARGS" == "lite" ]; then
 LITE="lite_"
fi

ROOT=$( cd "$(dirname "$0")" ; pwd -P )
echo -e " ROOT = $ROOT\n PROGNAME = $PROGNAME\n PROGDIR = $PROGDIR\n ARGS = $ARGS\n"
TEMP_FOLDER=/tmp
cd $ROOT

# MY_IP=$(hostname -I | sed 's/ .*//')
# https://downloads.raspberrypi.org/raspbian_lite_latest

# check if we have the latest img
latest_version() {
type curl || ( echo "curl not installed"; exit 1 )
LATEST_VERSION=$(curl https://downloads.raspberrypi.org/raspbian_${LITE}latest 2>/dev/null | sed '/href/!d; s/.zip.*//; s/.*\///')
echo LATEST_VERSION=$LATEST_VERSION
}

download_latest_raspbian() {
curl -LJ https://downloads.raspberrypi.org/raspbian_${LITE}latest -O || \
  ( echo "Error download $LATEST_VERSION..." && exit 1 )
}

get_latest_image() {
if [ ! -f $ROOT/$LATEST_VERSION.img ]; then
 echo "$LATEST_VERSION.img not found.\nSearching for $LATEST_VERSION.zip ..."
 if [ ! -f $ROOT/$LATEST_VERSION.zip ]; then
    echo "$LATEST_VERSION.zip not found. Downloading ..."
    download_latest_raspbian || (echo "Error download latest raspbian" && return 1)
 else echo "$LATEST_VERSION.zip found!"
 fi
unzip $LATEST_VERSION.zip || (echo "Error unzip latest raspbian" && return 1)
fi
return 0
}

RPI_ROOT=${ROTEMP_FOLDEROT}/rpifs/rootfs
RPI_BOOT=${TEMP_FOLDER}/rpifs/boot

#umount ${RPI_BOOT} ${RPI_ROOT} || true
mount_latest_img() {
LOOP_DEVICE=$(losetup -f)
losetup $LOOP_DEVICE $1 || echo "error losetup $LOOP_DEVICE $1  "
partprobe $LOOP_DEVICE 	|| echo "error partprobe $LOOP_DEVICE "
mkdir -p ${RPI_BOOT} ${RPI_ROOT}   || echo "error create ${RPI_BOOT} "
mount -n ${LOOP_DEVICE}p1 ${RPI_BOOT} || echo "error mounting ${RPI_BOOT}" 
mount -n ${LOOP_DEVICE}p2 ${RPI_ROOT} || echo "error mounting ${RPI_ROOT}" 
return 0
}

clean_up() {
echo "CleaningUp ...."

# umount everything if needed
dirs="$RPI_ROOT $RPI_BOOT"
for dir in $dirs; do
[[ "$(ls $dir)" != "" ]] && echo "dir not empty" && \
for x in $(mount | grep /home/pimaker/raspTemp/rpifs/$dir | sed 's/type.*//; s/.*on //'); do umount -lv "$x";done || \
 echo "$dir empty"
rm -r $dir
done
echo "clean_up: Bye-bye...."
}

chroot_raspbian() {
trap clean_up EXIT #2		# SIGINT
err=$(cp /usr/bin/qemu-arm-static ${RPI_ROOT}/usr/bin/ 2>&1) 	|| echo "ERROR: $err"
#sudo cp ${RPI_ROOT}/etc/resolv.conf 
err=$(cp /etc/resolv.conf ${RPI_ROOT}/etc/resolv.conf 2>&1) || echo "ERROR: $err"
err=$(mkdir -p ${RPI_ROOT}/mnt/LinuxData 2>&1) || echo "ERROR: $err"

cd ${RPI_ROOT}

err=$(mount --bind /proc ${RPI_ROOT}/proc/ 2>&1) 	|| echo "ERROR: $err"
err=$(mount --bind /dev ${RPI_ROOT}/dev/ 2>&1) 		|| echo "ERROR: $err"
err=$(mount --bind /dev/pts ${RPI_ROOT}/dev/pts 2>&1) 	|| echo "ERROR: $err"
err=$(mount --bind /sys ${RPI_ROOT}/sys/ 2>&1) 		|| echo "ERROR: $err"

err=$(mount --bind ${RPI_BOOT} ${RPI_ROOT}/boot/ 2>&1) 			|| echo "ERROR: $err"
err=$(mount --bind /mnt/LinuxData ${RPI_ROOT}/mnt/LinuxData 2>&1) 	|| echo "ERROR: $err"
cmd=/mnt/LinuxData/Scripts/Rpi/setupNew.sh
chroot . $cmd 						|| echo "ERROR: chroot"

sudo umount -v ${RPI_ROOT}/{sys,proc,dev/pts,dev,/boot,/mnt/LinuxData} || echo "error umount..."
# sudo umount ${RPI_ROOT}/mnt/LinuxData  || echo "error LinuxData"
# sudo umount ${RPI_ROOT}/boot/  || echo "error uBoot"

sudo rm ${RPI_ROOT}/usr/bin/qemu-arm-static || echo "error remove qemu-arm-static"
echo "chroot_raspbian: Bye-bye...."
}



latest_version
get_latest_image
#mount_latest_img $LATEST_VERSION.img || echo "error mounting $LATEST_VERSION.img"
#chroot_raspbian

#sudo umount -lv ${RPI_BOOT} || echo "could not umount RPI_BOOT ($RPI_BOOT)"
#sudo umount -lv ${RPI_ROOT} || echo "could not umount $RPI_ROOT"
#sudo losetup -d $LOOP_DEVICE || echo "could not umount losetup -d $LOOP_DEVICE"

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
umount ${RPI_BOOT} ${RPI_ROOT} && losetup -d $LOOP_DEVICE
NEW_IMG_NAME=modded_$(date +"%H%M%S")${IMG_NAME}
mv  ${IMG_NAME} ${NEW_IMG_NAME}
chown ${USER}:${USER} ${NEW_IMG_NAME}
