# ls /media/pi
# sudo apt autoremove
# sudo apt autoclean
# sudo apt clean
# sudo apt purge -y pi-bluetooth rp-prefapps thonny rp-bookshelf


${SUDO} mount 192.168.1.20:/mnt/LinuxData/OF /mnt/LinuxData/OF
ls /mnt/LinuxData/OF
ls /mnt/LinuxData/OF/tmp
# xzcat /mnt/LinuxData/OF/tmp/LibreELEC-Borsi.img.xz | sudo dd of$
# sudo raspi-config
ls /dev/mmc*
mkdir /media/LIBREELEC /media/STORAGE
sudo mkdir -pv /media/LIBREELEC /media/STORAGE

sudo mount /dev/mmcblk0p1 /media/LIBREELEC
ls /media/LIBREELEC
ls /media/STORAGE
sudo mount /dev/mmcblk0p2 /media/STORAGE




IMG=/mnt/LinuxData/OF/LibreELEC-RPi4.arm-9.97.1.img.gz
gzip -dc ${IMG} | ${SUDO} dd of=/dev/mmcblk0 bs=4M

SUDO=sudo
DISK=/dev/mmcblk0
${SUDO} umount ${DISK}p2

${SUDO} parted ${DISK} u s resizepart 2 100%
${SUDO} e2fsck -f -y -v -C 0 ${DISK}p2
${SUDO} resize2fs -p ${DISK}p2

sudo mount /dev/mmcblk0p2 /media/STORAGE
sudo mount 192.168.1.20:/mnt/LinuxData/OF /mnt/LinuxData/OF

ls /media/STORAGE
sudo mount /dev/mmcblk0p2 /media/STORAGE
sudo umount /media/STORAGE

sudo mount /dev/mmcblk0p2 /media/STORAGE
sudo mount 192.168.1.20:/mnt/LinuxData/OF /mnt/LinuxData/OF

sudo umount /media/STORAGE
umount /dev/mmcblk0p2
gzip -dc ${IMG} | sudo dd of=/dev/mmcblk0 bs=4M
sudo mount /dev/mmcblk0p2 /media/pi/STORAGE
sudo mount /dev/mmcblk0p2 /media/STORAGE
umount /dev/mmcblk0p2
sudo umount /dev/mmcblk0p2
sudo reboot