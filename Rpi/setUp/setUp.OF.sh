#!/bin/bash

DEV_DIR=/mnt/LinuxData/OF
GITHUB_DIR=${DEV_DIR}/GitHub

#.      ${DEV_DIR}/myGitHub/MyScripts/Rpi/setUp/setUpNew.sh
#/mnt/LinuxData/OF/myGitHub/MyScripts/Rpi/setUp/setUpNew.sh
. /mnt/LinuxData/OF/myGitHub/MyScripts/Rpi/setUp/setupNew.sh
echo "available cmds: "
#echo "$(sed '/\(\) {/!d;s/\(\) \{//' ${DEV_DIR}/myGitHub/MyScripts/Rpi/setUp/setUpNew.sh)"
echo "$(sed '/() {/!d;s/() {//' /mnt/LinuxData/OF/myGitHub/MyScripts/Rpi/setUp/setupNew.sh)"

download.OF() {
    cd ${GITHUB_DIR}
    git clone --depth=1 https://github.com/openframeworks/openFrameworks.git
    cd openFrameworks
    # for projectGenerator & apothecary:
    git submodule init && git submodule update
    OF_VER=$(sed '/OF_VERSION_MINOR/!d;s/.* //' libs/openFrameworks/utils/ofConstants.h)
    echo "OF_VERSION = ${OF_VER}"
    export OF_ROOT=${PWD}
}

runOFscripts() {
    # If rasp|bian rename to de|bian
    ${SUDO} ${OF_ROOT}/scripts/linux/${OS_NAME/rasp/de}/install_dependencies.sh -y
    ${SUDO} ${OF_ROOT}/scripts/linux/${OS_NAME/rasp/de}/install_codecs.sh -y
    ${SUDO} ${OF_ROOT}/scripts/linux/download_libs.sh -n
    ${SUDO} ${OF_ROOT}/scripts/linux/download_libs.sh -n -p linuxarmv6l
    ${SUDO} ${OF_ROOT}/scripts/linux/compileOF.sh
    ${SUDO} ${OF_ROOT}/scripts/linux/projectGenerator.sh
}
setUp.OF() {
    execMode
    detectSystem
    download.OF
    runOFscripts
}

check_root
[ "${BASH_SOURCE}" == "${0}" ] && setUp.OF