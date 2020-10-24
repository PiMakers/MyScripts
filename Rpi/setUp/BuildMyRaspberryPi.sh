#!/bin/bash

SCRIPT_NAME=${BASH_SOURCE[0]##*/}
SCRIPT_PATH=${BASH_SOURCE[0]%/*}
SRC_BASE_DIR=/mnt/LinuxData/OF/GitHub/BuildMyRaspberryPi
APP_NAMES=(gpioexpander)
APP_NAMES+=(scriptexecutor)

    #download Buildroot: https://buildroot.org/downloads/buildroot-2020.02.6.tar.gz
    BASE_ADDR=https://buildroot.org/downloads
    BR_VERSION=2017.05
    BR_VERSION=2020.02.6

    BUILDROOT=buildroot-${BR_VERSION}
    # PATH_TO_BUILDROOT=${SCRIPT_PATH}
    PATH_TO_BUILDROOT=/mnt/LinuxData/OF/GitHub/BuildMyRaspberryPi/${BUILDROOT}

makeAll() {
    for app in ${APP_NAMES[@]}
        do
            case $app in
              gpioexpander)
                            SUB_DIR=gpioexpand
                            BR2_LINUX_KERNEL_INTREE_DTS_NAME="${BR2_LINUX_KERNEL_INTREE_DTS_NAME} bcm2708-rpi-0"
                            ;;
            scriptexecutor) 
                            SUB_DIR=scriptexecute
                            TARGET=_cm1
                            ;;
                         *)  
                echo "Unsupported app $app"
                exit
                ;;
            esac
        APP_NAME=$app
        echo "Making ${APP_NAME} ..."
        makeApp ${APP_NAME}
        done
}

makeApp() {
#    [ "x$1" != "x" ] && APP_NAME=$1 ||  (echo "No APP to make!!!" && exit 1)
    [ -z $1 ] || APP_NAME=$1 ||  (echo "No APP to make!!!" && exit 1)
    cd ${SRC_BASE_DIR}
    # Download if needed

    # extract:
    if [ ! -e ${SRC_BASE_DIR}/$BUILDROOT ]; then
        if [ ! -f ${SRC_BASE_DIR}/${BUILDROOT}.tar.gz ]; then
            curl ${BASE_ADDR}/${BUILDROOT}.tar.gz -O ${SRC_BASE_DIR}/${BUILDROOT}.tar.gz
        fi
        tar xzf ${SRC_BASE_DIR}/${BUILDROOT}.tar.gz
    fi

    # BUILDROOT=${APP_NAME}/${BUILDROOT}
    # cd ${APP_NAME}
    if [ "${BR_VERSION}" == "2017.02" ]; then
        local BUILDROOT_PKGS_BASE_DIR=https://git.busybox.net/buildroot/tree/package
        ## PATCH buildroot-2017.02/output/build/host-m4-1.4.18 !!! _IO_ftrylockfile -> _IO_EOF_SEEN on all places!!!
        curl -s ${BUILDROOT_PKGS_BASE_DIR}/m4/0001-fflush-adjust-to-glibc-2.28-libio.h-removal.patch -o ${BUILDROOT}/package/m4/0001-fflush-adjust-to-glibc-2.28-libio.h-removal.patch
        curl -s ${BUILDROOT_PKGS_BASE_DIR}/m4/0002-fflush-be-more-paranoid-about-libio.h-change.patch -o ${BUILDROOT}/package/m4/0002-fflush-be-more-paranoid-about-libio.h-change.patch
    fi

    make -C ${SRC_BASE_DIR}/${BUILDROOT} BR2_EXTERNAL="${SRC_BASE_DIR}/${APP_NAME}/${SUB_DIR}" ${SUB_DIR}${TARGET}_defconfig

    cd ${SRC_BASE_DIR}/${APP_NAME}
    read -p "Press a key to continue..."
    make -C ${SRC_BASE_DIR}/${BUILDROOT} BR2_EXTERNAL="${SRC_BASE_DIR}/${APP_NAME}/${SUB_DIR}"
    exit

    make -C $BUILDROOT BR2_EXTERNAL="${SRC_BASE_DIRs}/${APP_NAME}/${SUB_DIR}"

    USBBOOT_DIR=${DEV_DIR}/GitHub/usbboot
    RPI_BOOT_DIR=${USBBOOT_DIR}/boot/${APP_NAME}
    rm -r ${RPI_BOOT_DIR}
    mkdir -pv ${RPI_BOOT_DIR}/overlays


    cp -v $BUILDROOT/output/images/rootfs.cpio.gz ${RPI_BOOT_DIR}/${SUB_DIR}.img
    cp -v $BUILDROOT/output/images/zImage ${RPI_BOOT_DIR}/kernel.img
    cp -v $BUILDROOT/output/images/dwc2-overlay.dtb ${RPI_BOOT_DIR}/overlays/dwc2.dtbo

    cp $BUILDROOT/output/images/rpi-firmware/*.elf ${RPI_BOOT_DIR}
    cp $BUILDROOT/output/images/rpi-firmware/*.dat ${RPI_BOOT_DIR}
    cp $BUILDROOT/output/images/rpi-firmware/bootcode.bin ${RPI_BOOT_DIR}
    cp $BUILDROOT/output/images/*.dtb ${RPI_BOOT_DIR}


    cp ${APP_NAME}/output/*.txt ${RPI_BOOT_DIR}

    echo
    echo Build ${APP_NAME} complete. Files are in ${RPI_BOOT_DIR} folder.
    echo
    testBuid
}

testBuid() {
    sudo pkill rpiboot
    gnome-terminal -t "Raspberry Pi USBboot" -- ${SUDO} ${USBBOOT_DIR}/rpiboot -d ${RPI_BOOT_DIR} -v -l -o
}

trap 'echo "stopping rpi boot..." && sudo pkill rpiboot' EXIT
trap 'echo "Next ..." ' INT

makeAll
testBuid