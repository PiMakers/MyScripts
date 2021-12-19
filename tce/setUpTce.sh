#!/bin/bash

SUDO=sudo
IMG=/mnt/LinuxData/Install/img/piCore64-13.1.img
# cd /tmp && wget https://distro.ibiblio.org/tinycorelinux/13.x/aarch64/releases/RPi/piCore64-13.1.zip



mountImg() {
    [ -z $1 ] || IMG=$1
    [ -f $IMG ] && echo ":: selected IMG = $IMG" || exit
    # resize
    read -p "Resize Img?" RESIZE
    if [ -z RESIZE ]; then
    local COUNT=$RESIZE
    ${SUDO} bash -c "dd if=/dev/zero bs=4M count=${COUNT} >> ${IMG}"
    echo "Resized!!!!!!!!!!!!!!!!!!!!!"
    fi
    
    sudo mkdir -pv /mnt/tmp
    LOOP_DEVICE=$(${SUDO} losetup -fP --show $IMG)
    sudo mount ${LOOP_DEVICE}p1 /mnt/tmp
    # cp /mnt/tmp/*.img /mnt/tmp/rootfs*.gz /tmp
    read -p "Pre...!"
    sudo umount -lv /mnt/tmp
    sudo losetup -dv ${LOOP_DEVICE}
    sudo rm -r /mnt/tmp
}

tmp2() {
    sudo mkdir -pv /tmp/extract
    zcat /tmp/rootfs*.gz | sudo cpio -i -H newc -d -D /tmp/extract

    cd /media/pimaker/piCore64_TCE/tce/optional
    list=`ls *.tcz`
    for x in $list
    do 
        echo ${x%%.*}
        sudo mkdir  /tmp/${x%%.*}
        mount $x /tmp/${x%%.*}
        cp -a  /tmp/${x%%.*}/* /tmp/openssl.tcz
        umount -v /tmp/${x%%.*}
        rm -r /tmp/${x%%.*}
    done

}

#[ "${BASH_SOURCE}" == "${0}" ] && mountImg


setwebapp() {
    # /usr/local/etc/fonts/fonts.conf -> /tmp/tcloop/fontconfig/usr/local/etc/fonts/fonts.conf
    # create link!!?? /usr/local/etc/init.d/dbus status -> /tmp/tcloop/dbus/usr/local/etc/init.d/dbus status START!!!
    [ df| grep -q /mnt/LinuxData/OF ] || sudo mount -onolock,defaults NUC:/mnt/LinuxData/OF /mnt/LinuxData/OF
    cp -r /mnt/LinuxData/OF/myGitHub/Borsi/webapps /opt
    npm i --prefix=/opt/webapps/hadaszat
    export FONTCONFIG_PATH=/usr/local/etc/fonts
    tce-load -wi node.js nss atk at-spi2-atk gtk3 libasound libcups Xorg #dbus #dbus-glib dbus-python3.8
    # tce-load -wi Xorg glib2
    filetool.sh -b
    #flwm aterm wbar
    sed -i '/dbus start/d' /opt/bootlocal.sh
    echo /usr/local/etc/init.d/dbus start >> /opt/bootlocal.sh
    ## FONTCONFIG_PATH=/usr/local/etc/fonts DISPLAY=:0 dbus-launch npm start --prefix=/opt/webapps/hadaszat
        npm i --prefix=/opt/webapps/hadaszat
    # DISPLAY=:0 npm start --prefix=/opt/webapps/hadaszat
    npm start --prefix=/opt/webapps/hadaszat
    # sudo chmod -R 777 /mnt/LinuxData/OF/myGitHub/Borsi/webapps
    # tce-load -ciw Xorg nss node.js
    # vt.global_cursor_default=0 > cmdline.txt
    # [CM4]         > config.txt
    # otg_mode=1    > config.txt
    #/usr/local/bin/Xorg -nocursor -nolisten tcp & > $HOME/.xsession

    cat << EOF sudo tee /usr/local/share/X11/xorg.conf.d/20-noblank.conf
    Section "ServerFlags"
        Option          "BlankTime" "0"
        Option          "StandbyTime" "0"
        Option          "OffTime" "0"
        Option          "SuspendTime" "0"
    EndSection

    Section "Monitor"
        Option "DPMS" "false"
    EndSection
EOF
}

createSshKey() {
    [ -f ~/.ssh/testkey@NUC.pub ] || ${SUDO} ssh-keygen -q -N Pepe374189 -C testKey -f ~/.ssh/testkey@`hostname -s`
    cat ~/.ssh/testkey@`hostname -s`.pub | ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 tc@192.168.1.8 'cat >authorized_keys && mkdir -pv -m 700 .ssh && mv authorized_keys .ssh'
    cmd='ssh tc@192.168.1.8'
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 tc@192.168.1.8 'filetool.sh -b && sudo reboot'
}

mountOF() {
    [ df|/mnt/LinuxData/OF ] || sudo mkdir -pv -m 777 /mnt/LinuxData/OF
    [ df|grep -q  /mnt/LinuxData/OF ] || sudo mount -onolock,defaults NUC:/mnt/LinuxData/OF /mnt/LinuxData/OF
    cp -r  /mnt/LinuxData/OF/myGitHub/Borsi/webapps /opt
}

[ "${BASH_SOURCE}" == "${0}" ] && \
createSshKey
mountOF


setUp() {
    sudo mkdir -pv /mnt/LinuxData/OF && sudo mount 192.168.1.20:/mnt/LinuxData/OF /mnt/LinuxData/OF
    mpv --loop-file /mnt/LinuxData/OF/Borsi/Videos/E2-7.11_Piocak.mp4
}

tmpSH() {
    DEV_DIR=/mnt/LinuxData/Install
    IMG_DIR=${DEV_DIR}/zip
    IMG_NAME=piCore64-13.1.zip
    IMG=${IMG_DIR}/${IMG_NAME}
    # IMG=${IMG%%.*}.img
    # echo ${IMG}
    return
    cd /tmp/ex
    sudo find | sudo cpio -o -H newc | gzip -9 > ../pimaker.gz
    #advdef -z4 ../myimg.gz

    if [ ${IMG_NAME##*.} == zip ]; then
        unzip -v $IMG -d $IMG_DIR
        IMG=$IMG_DIR/${IMG##*/}

    fi
}