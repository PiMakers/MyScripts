# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)
# CONFIG_SND_SOC_TLV320AIC3X=m to projects/RPi/devices/RPi4/linux/linux.aarch64.conf

# PROJECT=RPi ARCH=arm DEVICE=RPi4 make image
# sudo mount 192.168.1.20:/mnt/LinuxData/OF /mnt/LinuxData/OF
# cp  /home/pimaker/McELEC/target/LibreELEC-RPi4.arm-10.0.2.img.gz /mnt/LinuxData/OF/XLibreELEC-RPi4.arm-10.0.2.img.gz

# commit 74847227fa66e7d8a40a088e66ccfe1e042ca007

PKG_NAME="DACberry-400"
PKG_VERSION="v0.1"
# PKG_VERSION="v0.1"
# PKG_GIT_SHA (optional) full hash of git commit
PKG_GIT_CLONE_BRANCH=main
PKG_GIT_CLONE_SINGLE=yes
PKG_GIT_CLONE_DEPTH=1
# PKG_GIT_SUBMODULE_DEPTH (optional) history of submodules to clone, must be a number

PKG_ARCH="arm"
PKG_LICENSE="various"
PKG_SITE="https://github.com/osaelectronics/DACBerry-400.git"
PKG_URL="https://github.com/osaelectronics/DACBerry-400/archive/refs/heads/main.zip"
PKG_MAINTAINER="PiMaker" # Full name or forum/GitHub nickname, if you want to be identified as the addon maintainer
# PKG_DEPENDS_TARGET="kodi LibreELEC-settings RPi.GPIO"
PKG_DEPENDS_TARGET=" toolchain dtc"
#PKG_DEPENDS_TARGET+=" mpg123"
#PKG_DEPENDS_TARGET+=" alsa-lib"
#PKG_DEPENDS_TARGET+=" alsa-utils"
#[ ${MEDIACENTER} == "kodi" ] && PKG_DEPENDS_TARGET+=" kodi"
PKG_SHORTDESC="OSA electronics DACberry400 s/m driver"
PKG_LONGDESC="OSA electronics DACberry400 s/m driver long"
PKG_DISCAIMER="PiMaker is a trademark of the High Density Kft."
PKG_TOOLCHAIN="manual"  #one of auto, meson, cmake, cmake-make, configure, make, ninja, autotools, manual
PKG_IS_KERNEL_PKG="yes"

#pre_unpack() {
#  chmod 777 ${SOURCES}/${PKG_NAME}/${PKG_NAME}-${PKG_VERSION}.zip
#}

# change /home/pimaker/McELEC/projects/RPi/devices/RPi4/linux/linux.aarch64.conf
# CONFIG_SND_SOC_TLV320AIC3X=m

unpack() {
  cd ${SOURCES}/${PKG_NAME}
  unzip -o ${PKG_NAME}-${PKG_VERSION}.zip 
}
post_unpack() {
  #cd
  # rm -rf ${SOURCES}/${PKG_NAME}/DACberry400-v0.1.zip
    cat > ${SOURCES}/${PKG_NAME}/Makefile << "EOF"
SHELL := /bin/bash
obj-m += dacberry400.o
dacberry400.o += -DDEBUG

ARCH = ${TARGET_KERNEL_ARCH}
CROSS_COMPILE ?=
KVER  ?= $(if $(KERNELRELEASE),$(KERNELRELEASE),$(shell uname -r))
KSRC ?= $(if $(KERNEL_SRC),$(KERNEL_SRC),/lib/modules/$(KVER)/build)

all: modules

modules:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KSRC) M=$(shell pwd)  modules

cleanx:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KSRC) M=$(shell pwd)
EOF

 sed -i 's/all/modules/' ${SOURCES}/${PKG_NAME}/DACBerry-400-main/src/Makefile
 sed -i 's/symmetric_rate/symmetric_rates/' ${SOURCES}/${PKG_NAME}/DACBerry-400-main/src/dacberry400.c
 sed -i 's/tlv320aic3x.1-0018/tlv320aic3x-codec.1-0018/' ${SOURCES}/${PKG_NAME}/DACBerry-400-main/src/dacberry400.c
 cp ${SOURCES}/${PKG_NAME}/DACBerry-400-main/src/* ${BUILD}/build/DACberry-400-v0.1
 cp ${SOURCES}/${PKG_NAME}/DACBerry-400-main/dacberry400.dts ${BUILD}/build/DACberry-400-v0.1
 cp -f ${SOURCES}/${PKG_NAME}/Makefile ${BUILD}/build/DACberry-400-v0.1
 # cp ${SOURCES}/${PKG_NAME}/DACBerry-400-main/dacberry400.dts ${PARENT_PKG}/xxx.ppp
}

pre_make_target() {
  unset LDFLAGS
}

make_target() {
  make modules \
       ARCH=${TARGET_KERNEL_ARCH} \
       KSRC=$(kernel_path) \
       CROSS_COMPILE=${TARGET_KERNEL_PREFIX}
}


makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
  mkdir -p ${INSTALL}/$(get_full_module_dir)/kernel/sound/soc/bcm
    # cp *.ko ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
    cp *.ko ${INSTALL}/$(get_full_module_dir)/kernel/sound/soc/bcm
  # bcm2835-bootloader-231daece7cbf9282736efa7d254b3e4859f8e73b/usr/share/bootloader/config.txt
  CONFIG_TXT=$(find ${BUILD}/install_pkg/bcm2835-bootloader* -name config.txt)
  CONFIG_TXT=$(get_install_dir bcm2835-bootloader)/usr/share/bootloader/config.txt
  # dtc -O dtb -o dacberry400.dtbo -b 0 -@ dacberry400.dts
  echo "# DACberry400:" >> $CONFIG_TXT
  echo "# dtoverlay=i2c1" >> $CONFIG_TXT
  echo "# dtoverlay=dacberry400" >> $CONFIG_TXT
  echo "# gpio=26=op,dh" >> $CONFIG_TXT
  echo "# Enable i2c overlay:" >> $CONFIG_TXT
  echo "# dtparam=i2c_arm=on" >> $CONFIG_TXT
  echo "# dtparam=i2s=on" >> $CONFIG_TXT
}

  # cp ${SOURCES}/${PKG_NAME}/DACBerry-400-main/dacberry400.dts ${INSTALL}/usr/share/bootloader

# see https://github.com/LibreELEC/LibreELEC.tv/blob/master/packages/readme.md for more
# take a look to other packages, for inspiration
