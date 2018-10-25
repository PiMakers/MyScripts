#https://softwarebakery.com//shrinking-images-on-linux
#!/bin/bash

set -e

#getImageName () {
#read -p "ImageName. " = IMAGE_NAME
#}

#IMAGE_NAME= "/home/pimaker/OF/Install/Pi/Img/WorkBackUps/ZwackTV(2016-11-05%201736).img"
IMAGE_NAME=
sudo losetup /dev/loop0 /home/pimaker/Desktop/StretchDev(2018.04.11).img

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

sudo gparted /dev/loop0

sudo losetup -d /dev/loop0

fdisk -l $IMAGE_NAME

Note two things in the output:

The partition ends on block 9181183 (shown under End)
The block-size is 512 bytes (shown as sectors of 1 * 512)
We will use these numbers in the rest of the example. The block-size (512) is often the same, but the ending block (9181183) will differ for you. The numbers mean that the parition ends on byte 9181183*512 of the file. After that byte comes the unallocated-part. Only the first 9181183*512 bytes will be useful for our image.

Next we shrink the image-file to a size that can just contain the partition. For this we will use the truncate command (thanks uggla!). With the truncate command need to supply the size of the file in bytes. The last block was 9181183 and block-numbers start at 0. That means we need (9181183+1)*512 bytes. This is important, else the partition will not fit the image. So now we use truncate with the calculations:

$ truncate --size=$[(14336000+1)*512] '/dev/loop0 /home/pimaker/Desktop/StretchDev(2018.04.11).img'
Now copy the new image over to your phone, where it should act exactly the same as the old/big image.
