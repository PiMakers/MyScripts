#!/bin/bash

TFTP_LE="/tftpLE"
TFTP="/tftp"

SERIALS="6e602275 \
         a0125889 \
         fae119f1"

BOOTFILES=" kernel.img \
            kernel.img.md5 \
            SYSTEM \
            SYSTEM.md5 \
            fixup.dat \
            start.elf \
            config.txt \
            distroconfig.txt \
            bcm2711-rpi-400.dtb \
            bcm2711-rpi-cm4.dtb \
            cmdline.nfsboot.LibreELEC"

i=11
for s in ${SERIALS}
    do
        sudo mkdir -pv ${TFTP}/${s}/overlays
        sudo ln -fs ${TFTP_LE}/overlays ${TFTP}/${s}/overlays
        for m in ${BOOTFILES}
            do
                # echo ${m}
                sudo ln -fs ${TFTP_LE}/${m} ${TFTP}/${s}/${m}
                # echo "hurrah!!!"
            done
        for
        for o in `ls /${TFTP_LE}/overlays*`
            do
                sudo ln -fs ${TFTP_LE}/overlays/${o} ${TFTP}/${s}/overlays/${o}
            done
        sudo cp  ${TFTP_LE}/config.txt ${TFTP}/${s}/
        cat << EOF | sudo tee ${TFTP}}/${s}/cmdline.nfsboot.LibreELEC
boot=NFS=10.120.136.7:/tftpLE morequiet rw ip=10.120.136.0${i} hostname=install${i} rootwait quiet nosplash
EOF
    i=$(($i+1))
    done