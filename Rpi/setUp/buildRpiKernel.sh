## https://www.raspberrypi.org/documentation/linux/kernel/building.md#default_configuration

dep() {
    ## local build:
    sudo apt install git bc bison flex libssl-dev make

    #source
    git clone --depth=1 https://github.com/raspberrypi/linux /mnt/LinuxData/OF/GitHub/RpiKernel

    cd linux
    KERNEL=kernel
    BOARD=rpi2_3_3Plus ##rpi1_Zero_ZeroW | rpi4
    
    CONFIG=bcm2709_defconfig
    ## Raspberry Pi 1, Pi Zero, Pi Zero W, and Compute Module default build configuration
    CONFIG=bcmrpi_defconfig

    ## Raspberry Pi 2, Pi 3, Pi 3+, and Compute Module 3 default build configuration
    CONFIG=bcm2709_defconfig
    ## Raspberry Pi 4 default build configuration
    CONFIG=bcm2711_defconfig

    ## local buld
    make -j ${CONFIG} 
    echo "CONFIG_LOCALVERSION=-v7l-MY_CUSTOM_KERNEL" >>  ${CONFIG}
    make -j4 zImage modules dtbs
    sudo make modules_install
    sudo cp arch/arm/boot/dts/*.dtb /boot/
    sudo cp arch/arm/boot/dts/overlays/*.dtb* /boot/overlays/
    sudo cp arch/arm/boot/dts/overlays/README /boot/overlays/
    sudo cp arch/arm/boot/zImage /boot/$KERNEL.img

    ##CrossBuild:
    ## Cross
    sudo apt install git bc bison flex libssl-dev make libc6-dev libncurses5-dev
    ## Install the 32-bit toolchain for a 32-bit kernel
    sudo apt install crossbuild-essential-armhf

    ## Or, install the 64-bit toolchain for a 64-bit kernel
    sudo apt install crossbuild-essential-arm64

    make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- ${CONFIG}
}

copyR() {
    ## For 32-bit
    sudo env PATH=$PATH make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=mnt/ext4 modules_install
    ## For 64-bit
    sudo env PATH=$PATH make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=mnt/ext4 modules_install

}

cpyTmp() {
    SRC_DIR=/mnt/LinuxData/OF/GitHub/RpiKernel
    RPI_BOOT_FS=/tftpboot/177b3502
    ARCH=arm
    KERNEL=kernel
    sudo cp ${RPI_BOOT_FS}/$KERNEL.img ${RPI_BOOT_FS}/$KERNEL-backup.img
    sudo cp ${SRC_DIR}/arch/arm/boot/Image ${RPI_BOOT_FS}/$KERNEL.img
    sudo cp ${SRC_DIR}/arch/arm/boot/dts/*.dtb ${RPI_BOOT_FS}/
    sudo mkdir -pv ${RPI_BOOT_FS}/overlays
    sudo cp ${SRC_DIR}/arch/arm/boot/dts/overlays/*.dtb* ${RPI_BOOT_FS}/overlays/
    sudo cp ${SRC_DIR}/arch/arm/boot/dts/overlays/README ${RPI_BOOT_FS}/overlays/
    #sudo umount ${RPI_BOOT_FS}
    #sudo umount mnt/ext4
}