# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)
# to packages/PiMaker
# PROJECT=RPi ARCH=arm DEVICE=RPi4 make image
# sudo mount 192.168.1.20:/mnt/LinuxData/OF /mnt/LinuxData/OF
# cp  /home/pimaker/McELEC/target/LibreELEC-RPi4.arm-10.0.2.img.gz /mnt/LinuxData/OF/XLibreELEC-RPi4.arm-10.0.2.img.gz
# ??? comment out ??? packages\addons\addon-depends\rpi-tools-depends\RPi.GPIO\package.mk make_target() section???


PKG_NAME="PiMaker"
PKG_VERSION="v0.1"
PKG_REV="100"
#PKG_SHA256="[sha256 hash of the source file, downloaded from PKG_URL]"
PKG_ARCH="arm"
PKG_LICENSE="various"
PKG_SITE="http://example.com/libexample"
PKG_URL=""
PKG_MAINTAINER="PiMaker" # Full name or forum/GitHub nickname, if you want to be identified as the addon maintainer
PKG_DEPENDS_TARGET=" FirstTry"
PKG_DEPENDS_TARGET+=" bcm2835-bootloader" # prepair config.txt
PKG_DEPENDS_TARGET+=" kodi DACberry-400"
PKG_DEPENDS_TARGET+=" toolchain"
#PKG_DEPENDS_TARGET+=" mpg123"
#PKG_DEPENDS_TARGET+=" alsa-lib"
#PKG_DEPENDS_TARGET+=" alsa-utils"
#[ ${MEDIACENTER} == "kodi" ] && PKG_DEPENDS_TARGET+=" kodi"
PKG_SECTION="virtual"
PKG_SHORTDESC="A bundle of tools and programs for use on the Raspberry Pi"
PKG_LONGDESC="This bundle currently includes RPi.GPIO, gpiozero and lan951x-led-ctl"
PKG_DISCAIMER="Raspberry Pi is a trademark of the Raspberry Pi Foundation http://www.raspberrypi.org"
PKG_TOOLCHAIN="manual"  #one of auto, meson, cmake, cmake-make, configure, make, ninja, autotools, manual

GET_HANDLER_SUPPORT=" git"
# SKIN_DEFAULT="skin.estuary"

# KODI_BLURAY_SUPPORT="no"
# PKG_DEPENDS_TARGET+=" libbluray"

#PKG_IS_ADDON="yes"
# PKG_ADDON_NAME="[proper name of the addon that is shown at the repo]"
# PKG_ADDON_TYPE="xbmc.python.module"
# PKG_ADDON_PROJECTS="RPi ARM"
# PKG_ADDON_PROVIDES="executable"
# PKG_ADDON_REQUIRES="some.addon:0.0.0"

#PKG_CMAKE_OPTS_TARGET="-DWITH_EXAMPLE_PATH=/storage/.example
#                      "

# see https://github.com/LibreELEC/LibreELEC.tv/blob/master/packages/readme.md for more
# take a look to other packages, for inspiration
