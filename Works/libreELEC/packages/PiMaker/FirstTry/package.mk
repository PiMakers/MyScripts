# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)
# PROJECT=RPi ARCH=arm DEVICE=RPi4 make image
# sudo mount 192.168.1.20:/mnt/LinuxData/OF /mnt/LinuxData/OF
# cp  /home/pimaker/McELEC/target/LibreELEC-RPi4.arm-10.0.2.img.gz /mnt/LinuxData/OF/XLibreELEC-RPi4.arm-10.0.2.img.gz

#PKG_NAME="PiMaker"
PKG_NAME="FirstTry"
PKG_VERSION="v0.1"
PKG_REV="100"
#PKG_SHA256="[sha256 hash of the source file, downloaded from PKG_URL]"
PKG_ARCH="arm"
PKG_LICENSE="various"
PKG_SITE="http://example.com/libexample"
PKG_URL=""
PKG_MAINTAINER="PiMaker" # Full name or forum/GitHub nickname, if you want to be identified as the addon maintainer
PKG_DEPENDS_TARGET="kodi"
PKG_DEPENDS_TARGET+=" LibreELEC-settings RPi.GPIO"
PKG_DEPENDS_TARGET+=" toolchain"
PKG_DEPENDS_TARGET+=" mpg123"
PKG_DEPENDS_TARGET+=" alsa-lib"
#PKG_DEPENDS_TARGET+=" alsa-utils"
#[ ${MEDIACENTER} == "kodi" ] && PKG_DEPENDS_TARGET+=" kodi"
PKG_SECTION="virtual"
PKG_SHORTDESC="A bundle of tools and programs for use on the Raspberry Pi"
PKG_LONGDESC="This bundle currently includes RPi.GPIO, gpiozero and lan951x-led-ctl"
PKG_DISCAIMER="Raspberry Pi is a trademark of the Raspberry Pi Foundation http://www.raspberrypi.org"
PKG_TOOLCHAIN="manual"  #one of auto, meson, cmake, cmake-make, configure, make, ninja, autotools, manual

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

#pre_configure_target() {
#  do something, or drop it
#}

post_install() {
  # disable oe.wizzard
    LE_ADDON_INSTALL_DIR=${INSTALL}/usr/share/kodi/addons/service.libreelec.settings
    sed -i "s/None/'PiMaker'/g" ${LE_ADDON_INSTALL_DIR}/service.py
  
  # Mode Eustary
  #  cp ${INSTALL}/usr/share/kodi/addons/skin.estuary/colors/defaults.xml \
  #      ${INSTALL}/usr/share/kodi/addons/skin.estuary/colors/orig.xml
	# sed -i 's/[0-F][0-F][0-F][0-F][0-F][0-F][0-F][0-F][0-F]/\>FF000000/' ${INSTALL}/usr/share/kodi/addons/skin.estuary/colors/defaults.xml
  # rm -rf ${INSTALL}/usr/share/kodi/addons/skin.estuary
  # Estuary-modded:
    cp -a $(get_install_dir kodi)/.noinstall/skin.estuary ${INSTALL}/usr/share/kodi/addons/skin.estuary-modded
    sed -i 's/id="skin.estuary/id="skin.estuary-modded/;s/name="Estuary/name="Estuary-Moded/;s/phil65, Ichabod Fletchman/PiMaker/' \
     ${INSTALL}/usr/share/kodi/addons/skin.estuary-modded/addon.xml
    #cp ${INSTALL}/usr/share/kodi/addons/skin.estuary-modded/colors/defaults.xml ${INSTALL}/usr/share/kodi/addons/skin.estuary-modded/colors/black.xml
    sed 's/[0-F][0-F][0-F][0-F][0-F][0-F][0-F][0-F][0-F]/\>FF000000/' ${INSTALL}/usr/share/kodi/addons/skin.estuary-modded/colors/defaults.xml > \
    ${INSTALL}/usr/share/kodi/addons/skin.estuary-modded/colors/black.xml
    for m in Home DialogBusy DialogSeekBar
      do
        cp ${PKG_DIR}/config/DummyWindow.xml ${INSTALL}/usr/share/kodi/addons/skin.estuary-modded/xml/${m}.xml
      done

    sed -i 's/screensaver.xbmc.builtin.dim/skin.estuary-modded/' ${INSTALL}/usr/share/kodi/system/addon-manifest.xml

  ## create " /storage/.cache/services/sshd.conf" to enable sshd service at startup
    cat << EOF | sed 's/^.\{4\}//' >> ${INSTALL}/usr/lib/tmpfiles.d/z_04_openssh.conf

    ## enable sshd service at startup (by PiMaker)
    #d    /storage/.cache/services            0600 root root - -
    f    /storage/.cache/services/sshd.conf  0600 root root - -
    ## oe.settings
    f    /storage/.kodi/userdata/addon_data/service.libreelec.settings/oe_settings.xml
EOF

## config.txt HACKs
if [ -f ${INSTALL}/usr/share/bootloader/config.txt ]; then
    cat << 'EOF' | sed 's/^.\{4\}//' >> ${INSTALL}/usr/share/bootloader/config.txt

    # enable USB on CM4 (by PiMaker)
    # dtoverlay=dwc2,dr_mode=host
    otg_mode=1
    
    ## DAC berry:
    ## dtc -O dtb -o dacberry400.dtbo -b 0 -@c
    # dtoverlay=i2c1
    # dtoverlay=dacberry400
    # gpio=26=op,dh
    # Enable i2c overlay:

    # dtparam=i2c_arm=on
    # dtparam=i2s=on
EOF
fi

# /home/pimaker/McELEC/build.LibreELEC-RPi4.arm-10.0.2/image/system/usr/share/kodi/system/addon-manifest.xml
#if [ ${MEDIACENTER} == "kodi" ]; then
    cp ${PKG_DIR}/config/guisettings.xml ${INSTALL}/usr/share/kodi/config/guisettings.xml
    cp ${PKG_DIR}/config/advancedsettings.xml ${INSTALL}/usr/share/kodi/config/advancedsettings.xml

## Addons
    cp -r ${PKG_DIR}/addons ${INSTALL}/usr/share/kodi
    # sed -i s'/\>screensaver.xbmc.builtin.black/ optional\="true"\>service.autoexec/'  ${INSTALL}/usr/share/kodi/system/addon-manifest.xml
    sed -i s'/>screensaver.xbmc.builtin.black/ optional\="true"\>service.autoexec/'  \
      ${INSTALL}/usr/share/kodi/system/addon-manifest.xml
    # Enable to disable addon !resource.
    for m in  game. metadata. screensaver. kodi. resource
      do 
        sed -i s"/>${m}/ optional\=\"true\"\>${m}/g"  ${INSTALL}/usr/share/kodi/system/addon-manifest.xml
      done

    sed -i s'/>repository.kodi.game/ optional\="true"\>repository.kodi.game/'  ${INSTALL}/usr/share/kodi/system/addon-manifest.xml
#fi
}

make_target() {
  cd 
  python3 setup.py build --cross-compile
}

makeinstall_target() {
  python3 setup.py install --root=${INSTALL} --prefix=/usr
}

# see https://github.com/LibreELEC/LibreELEC.tv/blob/master/packages/readme.md for more
# take a look to other packages, for inspiration
