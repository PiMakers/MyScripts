## https://dev.webonomic.nl/how-to-run-or-boot-raspbian-on-a-raspberry-pi-zero-without-an-sd-card
## https://dev.webonomic.nl/connecting-to-a-raspberry-pi-zero-with-just-an-usb-cable-i
## http://retinal.dehy.de/docs/doku.php?id=technotes:raspberryrootnfs

. ../utils
## local vars

HOST_IP=$(echo $(hostname -I) | sed 's/ .*//')
NFS_ROOT=/USBBoot
NFS_VERSION=3
#BOOT_FS=${NFS_ROOT}/boot
ROOT_FS=${NFS_ROOT}/root
BOOT_FS=${ROOT_FS}/boot
IMG_FOLDER=/mnt/LinuxData/Downloads
serials="b0c7e328 dc:a6:32:66:0a:2c"

WORK_FOLDER=/tmp
cd ${WORK_FOLDER}

USBBoot_utility() {
    git clone --depth=1 https://github.com/raspberrypi/usbboot
    cd usbboot
    ${SUDO} apt-get install libusb-1.0-0-dev
    make -j
    cd ..
}

get_img(){
    if ! IMG=$(zenity --file-selection --file-filter="*.img *.zip" --filename=${IMG_FOLDER}/2019-09-26-raspbian-buster-full-netboot.img 2>/dev/null); then
        echo "No img selected. Exit"; exit 1
    else 
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
    ${SUDO} losetup -P $LOOP_DEVICE $IMG
    ${SUDO} partprobe $LOOP_DEVICE 	|| echo "error partprobe $LOOP_DEVICE "
    #mkdir -p ${RPI_BOOT} ${RPI_ROOT}   || echo "error create ${RPI_BOOT} "
    # ${SUDO} mkdir -p -m 777 ${BOOT_FS}
    ${SUDO} mkdir -p -m 777 ${ROOT_FS}
    # ${SUDO} mount -n ${LOOP_DEVICE}p1 ${BOOT_FS} || echo "error mounting ${BOOT_FS}"
    ${SUDO} mount -n ${LOOP_DEVICE}p2 ${ROOT_FS} || echo "error mounting ${ROOT_FS}"
    ${SUDO} mount -n ${LOOP_DEVICE}p1 ${ROOT_FS}/boot || echo "error mounting ${ROOT_FS}/boot"
}

NFS_ROOT=/mnt/LinuxData/pi
PI_BOOT=${NFS_ROOT}/boot
PI_ROOT=${NFS_ROOT}/root
SUDO=sudo

others1() {
${SUDO}  mkdir -p {$PI_BOOT,$PI_ROOT}
LOOP_DEVICE=$(${SUDO}  losetup -f)
${SUDO}  losetup -P ${LOOP_DEVICE} $IMG
${SUDO} mount ${LOOP_DEVICE}p1 ${PI_BOOT}
${SUDO} mount ${LOOP_DEVICE}p2 ${PI_ROOT}
# Then we need the Raspberry Pi Zero to connect to the USB cable, and netboot Stretch. For that we need NFS mount.We have to set that up on the laptop and on the Pi.
}

others2() {
sudo apt install nfs-kernel-server
Make the /pi/root folder a NFS mount point,  add this in the NFS config file `/etc/exports`

echo "/pi/root 10.42.0.14(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
Save and restart the NFS server.

sudo systemctl start nfs-server.service
 sudo exportfs -a
That’s done on the laptop. Now move to the pi Zero for the last parts.

Prepare the Pi Zero
#Edit config.txt in the boot directory (/pi/boot) to enable USB OTG mode and add some instructions to add initramfs. This will load extra kernel modules, so the Pi Zero can use the USB cable as an ethernet connection.

Add these 4 lines in config.txt  :

# enable OTG
 dtoverlay=dwc2
 # set initramfs
 initramfs initrd.img followkernel
Then add make your  cmdline.txt look like this:

otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=10.42.0.1:/pi/root rw ip=10.42.0.14:10.42.0.1::255.255.255.0:pi:usb0:static elevator=deadline modules-load=dwc2,g_ether fsck.repair=yes rootwait g_ether.host_addr=5e:a1:4f:5d:cf:d2
## Let’s explain this.
#  We need NFS mount (root=/dev/nfs),
# we set the network address (nfsroot=10.42.0.1:/pi/root rw) rw is read/write.
# We need the modules dwc2 ethernet gadget and g_ether and we set a a fixed ethernet MAC address to ease, and we set the network addresses.

#ip=10.42.0.14:10.42.0.1::255.255.255.0:pi:usb0:static
# ip=<client-ip>:<server-ip>:<gw-ip>:<netmask>:<hostname>:<device>:<autoconf> 
## Remember Ubuntu/Linux will set USB networks on the 10.42.0.1 address range, and we give the pi the fixed address 10.42.0.14.
# Please read my other posts about setting up an USB connnecting with the pi Zero, if you need more information.
# https://dev.webonomic.nl/connecting-to-a-raspberry-pi-zero-with-just-an-usb-cable-ii

Now we need to make a initramfs to supply some needed kernel modules.
# This is the best done on another Pi 1 or Pi Zero.
# We need to add the g_ether module and it dependencies in initramfs.

make_initramfs() {
# sudo apt install initramfs-tools
#Add modules to the modules file:

        ${SUDO} bash -c "cat >> ${ROOT_FS}/etc/initramfs-tools/modules" << EOF

## PiZero USB-boot:
g_ether
libcomposite
u_ether
udc-core
usb_f_rndis
usb_f_ecm
EOF

# create the initramfs .

${SUDO} update-initramfs -c -k `uname -r`
# It will be saved (initrd.img-4.9.80+ or newer) in the boot directory.
# Copy that file to the boot directory on your laptop: /pi/boot/, and name it initrd.img.
# As long it is the same name as in the config.txt file, it’s OK.
}

# enable ssh
# ln -s /lib/systemd/system/ssh.service /etc/systemd/system/multi-user.target.wants/ssh.service
Connect your Pi
Connect your Pi. Run the utility rpiboot:

usbboot/rpiboot -d /pi/boot/ 
Make sure you set the connection on shared. And your Pi Zero will boot, a  bit slowly.

ssh pi@10.42.0.14 

sudo apt update && sudo apt upgrade -y

#The Raspberry Pi Zero is really a 5 dollar computer in the end. No SD card, no keyboard, no monitor, no mouse needed. Just a Zero and an (old  Phone) USB micro cable.

#All your changes will persist. The image in your directory will update. When you decide you need a SD card in the end, just flash the image to a SD card.

#eportfs temp
#OF
#/mnt/LinuxData/OF 192.168.1.0/24(rw,no_subtree_check,no_root_squa$

#PiServer
/var/lib/piserver/os *(ro,no_subtree_check,no_root_squash,fsid=105$

#/nfs 192.168.1.0/24(rw,fsid=0,sync,no_subtree_check,no_auth_nlm,i$
#/nfs/root *(rw,sync,no_subtree_check,no_auth_nlm,insecure,no_root$

/mnt/LinuxData/OF *(rw,no_subtree_check,no_root_squash,fsid=1000)
/nfs/root *(rw,sync,no_subtree_check,no_root_squash,crossmnt)

}