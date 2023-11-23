#!/bin/bash
readMe() {
    READMEMD=`cat << 'EOF'
    ## http://www.tinycorelinux.net/13.x/aarch64/releases/RPi/piCore64-13.1.zip
    ## http://www.tinycorelinux.net/corebook.pdf
    ## https://github.com/tinycorelinux
    ## http://www.tinycorelinux.net/13.x/aarch64/releases/RPi/src/
    # http://tinycorelinux.net/faq.html#timezone
EOF`
echo ${READMEMD}
}
BASE_DIR=/mnt/LinuxData/OF
TCE_DIR=${BASE_DIR}/tce.remote
MAIN_VERSION=14
SUB_VERSION=0
VERSION=${MAIN_VERSION}.${SUB_VERSION}


if [ -d ${BASE_DIR} ]; then
    if [ ${HOSTNAME^^} == "NUC" ]; then
        echo "hostname = ${HOSTNAME^^}"
    else
        mountpoint ${BASE_DIR}
    fi
fi

installDep() {
    sudo apt install git bc bison flex libssl-dev make libc6-dev libncurses5-dev
}

getSources() {
    cd ${TCE_DIR}
    sudo wget http://www.tinycorelinux.net/${MAIN_VERSION}.x/aarch64/releases/RPi/src -O kernel.src
}

installDep
getSources
readMe