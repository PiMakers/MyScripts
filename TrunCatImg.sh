########################################################
# https://softwarebakery.com//shrinking-images-on-linux
########################################################

#!/bin/bash

#set -e

readme() {
    #getImageName () {
    #read -p "ImageName. " = IMAGE_NAME
    #}

    #IMAGE_NAME= "/home/pimaker/OF/Install/Pi/Img/WorkBackUps/ZwackTV(2016-11-05%201736).img"
    IMAGE_NAME=
    # sudo losetup /dev/loop0 /home/pimaker/Desktop/StretchDev(2018.04.11).img

    echo $IMAGE_NAME

    #if (!IMAGE_NAME) than: 
    #getImageName
    #fi

    wget -S https://downloads.raspberrypi.org/raspbian_latest -o /mnt/LinuxData/Raspbian_latest.zip
    #First we will enable loopback if it wasn't already enabled:
    sudo modprobe loop #sudo mkdir -p /tmp/test/ && sudo mount -o loop,rw,sync test.img /tmp/test ????

    #Next we create a device of the image:
    sudo losetup /dev/loop0 $IMAGE_NAME
    sudo partprobe /dev/loop0
    # sudo gparted /dev/loop0
    sudo losetup -d /dev/loop0
    fdisk -l $IMAGE_NAME
    #Note two things in the output:
    # The partition ends on block 9181183 (shown under End)
    # The block-size is 512 bytes (shown as sectors of 1 * 512)
    # We will use these numbers in the rest of the example. The block-size (512) is often the same, but the ending 
    # block (9181183) will differ for you.
    #The numbers mean that the parition ends on byte 9181183*512 of the file.
    #After that byte comes the unallocated-part. Only the first 9181183*512 bytes will be useful for our image.

    #Next we shrink the image-file to a size that can just contain the partition.
    #For this we will use the truncate command (thanks uggla!).
    #With the truncate command need to supply the size of the file in bytes.
    #The last block was 9181183 and block-numbers start at 0. That means we need (9181183+1)*512 bytes.
    #This is important, else the partition will not fit the image. So now we use truncate with the calculations:

    #truncate --size=$[(14336000+1)*512] '/dev/loop0 /home/pimaker/Desktop/StretchDev(2018.04.11).img'
    #Now copy the new image over to your phone, where it should act exactly the same as the old/big image.

}

#[ -z PATH_TO_IMG ] && 
#PATH_TO_IMG="${HOME}/2018-11-13-raspbian-stretch_T.I.img"

check_root() {
    # Must be root to install the hotspot
    echo ":::"
    if [ $EUID -eq 0 ];then
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


truncate_img() {
    [ $1 ] || ( echo "No image selected !" && exit )
    ## doit with gnome-disks
    #LOOP_DEVICE=$(${SUDO} losetup -f)
    LOOP_DEVICE=$(${SUDO} losetup -fPL --show ${1})
    ${SUDO} partprobe $LOOP_DEVICE 	|| echo "error partprobe $LOOP_DEVICE"
    ${SUDO} gnome-disks 
    #${SUDO} gparted $LOOP_DEVICE
    #${SUDO} losetup -d $LOOP_DEVICE
    local END_BLOCK=$( ${SUDO} fdisk -lo "End" $1 | sed '$!d')
    local END_SIZE=$( ${SUDO} fdisk -s --bytes -lo "Size" $1 | sed '$!d')
    echo -e "END_BLOCK = ${END_BLOCK}\nEND_SIZE = ${END_SIZE}"
    # truncate --size=$[(14336000+1)*512] '/dev/loop0 /home/pimaker/Desktop/StretchDev(2018.04.11).img'
    local SIZE=$(($(( ${END_BLOCK} + 1 ))*512)) && echo "SIZE = ${SIZE}"
    ${SUDO} truncate --size=${SIZE} ${1}
    echo "DONE!"
}
# no dpkg-query in libreELEC
# [ -d /flash ] || check_root
truncate_img  ${1}