## https://gist.github.com/jkullick/9b02c2061fbdf4a6c4e8a78f1312a689

#!/bin/bash

check_root() {
    # Must be root to install the hotspot
    echo ":::"
    if [[ $EUID -eq 0 ]];then
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
            exit
        fi
    fi
}

DOWNLOAD_DIR='/mnt/LinuxData/Install/img'
LATEST_VERSION=

readonly BASE_URL="https://downloads.raspberrypi.org"
SET_DEFAULTS=0
OS_NAME="raspios_armhf"                        # raspbian | raspios
#IMG_ARCH="arm64"                               # armhf | arm64
OS_TYPE=""                                     # lite | full | ""
OS_VERS="latest"                               # by_date | latest 

cleanUp() {
    echo "Cleaning ..."
    #mountpoint /mnt/dev/pts /mnt/dev
    ${SUDO} umount -lv /mnt/{dev/pts,dev,sys,proc,boot,}
    if [ ! -z ${LOOP_DEVICE} ]; then
        ${SUDO} losetup -d ${LOOP_DEVICE}
    fi
}

# if sourced, exit with "return"
exit() {
    trap 'echo "FuckYou!!! (exit)"' EXIT
    trap 'echo "FuckYouToo !!! (return)"' RETURN
    #[ "${BASH_SOURCE}" == "${0}" ] || ( EXIT_CMD=return && echo "EXIT_CMD=${EXIT_CMD}" )
    cleanUp
    kill -2 $$
}

latest_version() {
    type curl > /dev/null || ( echo "curl not installed" && exit 1 )
    IMG_NAME=${OS_NAME}
    for m in ${OS_TYPE} ${IMG_ARCH} "latest"
        do
            IMG_NAME="${IMG_NAME}_$m"
        done
    DL_URL=${BASE_URL}/${IMG_NAME}
    LATEST_VERSION=$(curl ${DL_URL} 2>/dev/null | sed '/href/!d; s/.zip.*//; s/.*\///')
    [ -z $LATEST_VERSION ] && echo "Unable to determine latest version!!!" && exit
    echo ${LATEST_VERSION}
}

download_latest() {
    latest_version
    cd ${DOWNLOAD_DIR}
    if [ -f $LATEST_VERSION.zip ]; then
        echo "$LATEST_VERSION.zip already downloded."
    else
        curl -LJ ${DL_URL} -o $LATEST_VERSION.zip || \
        ( echo "Error download $LATEST_VERSION..." && return 1)
    fi
}

dl_raspbian() {
    OS_PARAMS=$(zenity --forms zenity --timeout=5 --separator="," --add-combo=OS --combo-values="raspbian|raspios_armhf|raspios_arm64" \
         --add-combo=type --combo-values="default|lite|full" \
         --add-combo="release date" --combo-values="by date|latest")
    if [ $? = 5  ];then 
        SET_DEFAULTS=1
        res=$(zenity --warning --extra-button="Retry" --timeout=3 --ellipsize --text="Default options:\nOS_NAME: ${OS_NAME}\nIMG_ARCH: ${IMG_ARCH}\nOS_VERS: ${OS_VERS}" )
        if [ ${res} == "Retry" ]; then
            SET_DEFAULTS=0
        fi
        
    fi
    if [ "${SET_DEFAULTS}" == 0 ]; then
        if [ -z "${OS_PARAMS}" ]; then
            zenity --warning --timeout=3 --text="Aborted !!!"
            exit
        fi
        LIST=()
        OLD_IFS=$IFS
        IFS=','
        for m in ${OS_PARAMS}
         do 
            if [ $m == " " ];then
                case ${#LIST[@]} in
                    0)
                        while [ "$m" == " " ]
                            do
                                m=$(zenity --forms --separator="," --add-combo=OS --combo-values="raspbian|raspios_armhf|raspios_arm64")
                            done
                        ;;
                    1)
                        while [ "$m" == " " ]
                            do
                                # Remove lines after lite, full options implemented by raspberrypi.org
                                if [ "${LIST[0]}" == "raspios_arm64" ];then     # line to remove !!!!!!!!!!!!!!!
                                    m="default"                                 # line to remove !!!!!!!!!!!!!!!
                                else                                            # line to remove !!!!!!!!!!!!!!!
                                    m=$(zenity --forms --separator="," --add-combo=type --combo-values="default|lite|full")
                                fi                                              # line to remove !!!!!!!!!!!!!!!
                            done
                        ;;
                    2)
                        while [ "$m" == " " ]
                            do
                                m=$(zenity --forms --separator="," --add-combo="release date" --combo-values="by date|latest")
                            done
                        ;;                        
                    *)
                        echo "It could never happens!!!!" ${#LIST[@]}
                        ;;
                esac

            fi
            LIST+=($m)
         done
        IFS=$OLD_IFS
        OS_NAME=${LIST[0]}
        OS_TYPE=${LIST[1]/default/}
        OS_VERS=${LIST[2]}
    fi
    if [ "${OS_NAME}" == "${OS_NAME/_arm64/}" ]; then
        IMG_ARCH=armhf
        if [ "${OS_NAME}" == "raspbian" ]; then
            IMG_ARCH=
        fi
    else
        IMG_ARCH=arm64
        # This must be deleted when lite, full options implemented by raspberrypi.org
        OS_TYPE=
        zenity --warning --timeout=3 --text="lite &amp; full options are not implemented yet by raspberrypi.org! Rest to default"
    fi
    # echo "OS_NAME = ${OS_NAME/_${IMG_ARCH}} OS_TYPE=${OS_TYPE} OS_VERS=${OS_VERS} IMG_ARCH = ${IMG_ARCH}"
    if [ "${OS_VERS}" == "latest" ]; then
        IMG_NAME=${OS_NAME/_${IMG_ARCH}}
        for m in ${OS_TYPE} ${IMG_ARCH} "latest"
            do
                IMG_NAME+="_$m"
            done
        DL_URL=${BASE_URL}/${IMG_NAME}
        IMG_NAME=$(curl ${DL_URL} | sed '/href/!d; s/.zip.*/.zip/; s/.*\///')
    else
        DL_URL=${BASE_URL}/${OS_NAME}/images
        OS_VERS=$(zenity --list  --radiolist --column="" --column="select OS to download" " " $(curl -LJs ${DL_URL} | sed '/alt="\[DIR\]"/!d;s/^.*href="//g;s|/.*| |'))
        DL_URL=${DL_URL}/${OS_VERS}
        IMG_NAME=$(curl -LJs ${DL_URL} | sed '/torrent/!d;s/^.*href="//g;s|/.*||;s/.torrent.*//')
        DL_URL=${DL_URL}/${IMG_NAME}
    fi
    
    echo "DL_URL=${DL_URL} PWD=$PWD IMG_NAME=${IMG_NAME}"
    if [ -f ${DOWNLOAD_DIR}/${IMG_NAME} ];then
        echo "${DOWNLOAD_DIR}/${IMG_NAME} already downloaded!!"
    else
        curl -L ${DL_URL} -o ${DOWNLOAD_DIR}/${IMG_NAME}
    fi
}

# Program start here

check_root
${SUDO} service dnsmasq stop
dl_raspbian

exit
# install dependecies
${SUDO} apt-get install -y qemu qemu-user-static binfmt-support

# download raspbian image
download_latest

# extract raspbian image
cd ${DOWNLOAD_DIR}
latest_version
unzip ${LATEST_VERSION}.zip

# extend raspbian image by 1gb
dd if=/dev/zero bs=1M count=1024 >> ${LATEST_VERSION}.img

# set up image as loop device
LOOP_DEVICE=$(${SUDO} losetup -f)
${SUDO} losetup -P ${LOOP_DEVICE} ${LATEST_VERSION}.img

${SUDO} parted "$LOOP_DEVICE" u s resizepart 2 100%
# check file system
${SUDO} e2fsck -f -y -v -C 0 ${LOOP_DEVICE}p2

#expand partition
${SUDO} resize2fs -p ${LOOP_DEVICE}p2

# mount partition
${SUDO} mount -o rw ${LOOP_DEVICE}p2  /mnt
${SUDO} mount -o rw ${LOOP_DEVICE}p1 /mnt/boot

# mount binds
${SUDO} mount --bind /dev /mnt/dev/
${SUDO} mount --bind /sys /mnt/sys/
${SUDO} mount --bind /proc /mnt/proc/
${SUDO} mount --bind /dev/pts /mnt/dev/pts

# ld.so.preload fix
sed -i 's/^/#/g' /mnt/etc/ld.so.preload

# copy qemu binary
cp /usr/bin/qemu-arm-static /mnt/usr/bin/

# chroot to raspbian
${SUDO} chroot /mnt /bin/bash
	# do stuff...

# revert ld.so.preload fix
sed -i 's/^#//g' /mnt/etc/ld.so.preload

# unmount everything
${SUDO} umount -lv /mnt/{dev/pts,dev,sys,proc,boot,}

# unmount loop device
${SUDO} losetup -d ${LOOP_DEVICE}