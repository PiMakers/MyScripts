#!/bin/bash

## https://linuxhint.com/iscsi_storage_server_ubuntu/
## https://www.howtoforge.com/how-to-setup-iscsi-storage-server-on-ubuntu-1804/
## iSCSI Naming and Discovery: https://tools.ietf.org/html/rfc3721
## https://gist.github.com/luk6xff/9f8d2520530a823944355e59343eadc1

set +e
#trap 'KILL -HUP ($jobs -p)' HUP

# if sourced, exit with "return"
exit() {
    trap "echo FuckYou!!!" EXIT
    trap "echo FuckYouToo" RETURN
    [ "${BASH_SOURCE}" == "${0}" ] || EXIT_CMD=return && echo "EXIT_CMD=${EXIT_CMD}" 
    cleanUp
    kill -2 $$
}

detect_system () {
    if [ -z $WSL_DISTRO_NAME ]; then
        echo "WSL!"
        break;
    else
        . /usr/lib/os-release
    fi
}

install_dependencies() {
    sudo apt update
    sudo apt install -y \
        tgt \
        dnsmasq \
        binfmt-support \
        qemu-user-static \
        zenity
    sudo apt autoremove
}

SUDO=sudo
OVERLAY=0
iSCSI_ROOT=/mnt/LinuxData/iscsi
RPI_IMG_DIR=$iSCSI_ROOT

TEMP=/mnt/LinuxData/tmp
RPI_ROOT_FS=${TEMP}/root

IMG_FOLDER=/mnt/LinuxData/Install/img

#. ~/.profile

#IMAGE section

download_latest_raspbian() {
    IMG_OS_NAME=raspios
    IMG_OS_ARCH=arm64       # arm64 | armhf
    IMG_OS_VERSION=latest
    IMG_OS_TYPE=            # full | lite
    IMG_NAME=${IMG_OS_NAME}
    for m in "${IMG_OS_TYPE}" "${IMG_OS_ARCH}" "${IMG_OS_VERSION}" ; do
        [ -z $m ] || IMG_NAME+="_${m}"
    done
    #echo IMG_NAME=${IMG_NAME}
    DL_LINK=$(curl -Is https://downloads.raspberrypi.org/${IMG_NAME} | sed '/location: /!d;s/.*: //')
    DL_LINK=${DL_LINK/p:/ps:}
    IMG_NAME=$(basename ${DL_LINK})    
    curl -L ${DL_LINK/p:/ps:} -o "${IMG_FOLDER}/${IMG_NAME}" || \
        ( echo "Error download $LATEST_VERSION..." && return 1)
}

get_img(){
    if ! IMG=$(zenity --file-selection --file-filter="*.img *.zip *.ISO" --filename=${RPI_IMG_DIR}/any.img 2>/dev/null); then
        # TODO download script
        if ! $(zenity --question --text="Download image?");then
            echo "Downloding latest image... (not implemented yet)"
            #RASPBIAN_TYPE=lite
        else
            echo "No img selected. Exit"; exit 1
        fi
    else
        sudo mkdir -pv ${iSCSI_ROOT}/blocks
        if [ ${IMG##*.}=="zip" ];then
            if [ ! -f ${IMG%.*}.img ];then
                sudo unzip -o $IMG -d ${iSCSI_ROOT}/blocks
            else
                sudo cp -v ${IMG%.*}.img ${iSCSI_ROOT}/blocks/
            fi
            IMG=${IMG%.*}.img
        else
            if ( $IMG == ${iSCSI_ROOT}/blocks/${IMG##*/} ); then
                echo "Already set!!!"
            else
                sudo cp $IMG ${iSCSI_ROOT}/blocks/
            fi
        fi
    fi
    IMG_ARCH=${IMG##*/} && IMG_ARCH=${IMG_ARCH%.*} && IMG_ARCH=${IMG_ARCH##*-}
}

mount_img() {
    if [ $OVERLAY == 1 ]; then
        UPPER_DIR=${TEMP}/upper
        ${SUDO} mkdir -pv -m 755 ${UPPER_DIR}/data
        ${SUDO} mkdir -pv -m 777 ${UPPER_DIR}/work
        #${SUDO} chown $USER:$USER ${UPPER_DIR}/data
        ${SUDO} chown root:root ${UPPER_DIR}/data
    fi
    
    export LOOP_DEVICE=$(sudo losetup --show -f -P ${iSCSI_ROOT}/blocks/${IMG##*/})
    sudo mkdir -pv ${RPI_ROOT_FS}
    sudo mount -v ${LOOP_DEVICE}p2 ${RPI_ROOT_FS}

    if [ $OVERLAY == 1 ]; then
        OVERLAY_FS_ROOT=${iSCSI_ROOT}/overlay
        ${SUDO} mkdir -p -m 777 ${OVERLAY_FS_ROOT}
        LOWER_DIRS=${RPI_ROOT_FS}
        ${SUDO} mount -v -t overlay -o lowerdir=${LOWER_DIRS},upperdir=${UPPER_DIR}/data,workdir=${UPPER_DIR}/work  none ${OVERLAY_FS_ROOT}
        RPI_ROOT_FS=${OVERLAY_FS_ROOT}
    fi
    RPI_BOOT_FS=${RPI_ROOT_FS}/boot
    ${SUDO} mount -v ${LOOP_DEVICE}p1 ${RPI_ROOT_FS}/boot || echo "error mounting ${RPI_BOOT_FS}"
}

#echo ${IMG##*/}
IQN=iqn.1961-06.$(uname -n).local
TARGET_IQN="${IQN}:rpis"
INITIATOR_IQN="${IQN}.initiator:rpi-blog"
    export NETWORK_SUBNET=$(echo $(hostname -I) | sed 's/ .*//')
    if [ -z $WSL_DISTRO_NAME ]; then 
        ISCSI_TARGET_IP=${NETWORK_SUBNET}
    else
        # wsl (proxy)
        ISCSI_TARGET_IP=$(ipconfig.exe | sed '/IPv4/!d;s/.*: //' | sed -n 1p)
    fi
echo ${ISCSI_TARGET_IP}

ISCSI_TARGET_PORT=3260
PI_SERIAL=
CMD=/boot/sh.sh

chrootScript() {
    if [ "${IMG_ARCH}" == "arm64" ]; then
        IMG_ARCH="v8+"
    else
        if [ "${IMG_ARCH}" == "armhf" ]; then
            IMG_ARCH="v7+"
        else 
            echo "UNKNOWN image arch!!!"
            exit
        fi
    fi    

    cat << EOF | ${SUDO} tee ${RPI_ROOT_FS}${CMD}
    #!/bin/bash
    export LC_ALL=C
    #export DISPLAY=$(hostname):0
    apt update
    apt upgrade -y
    apt autoremove -y
    apt autoclean
    apt clean
    apt install -y open-iscsi
    PI_KERNEL_VERSION=\$(echo "\$(ls /lib/modules)" | sed "/${IMG_ARCH}.*/!d")
    echo PI_KERNEL_VERSION=\${PI_KERNEL_VERSION}
    update-initramfs -v -k \${PI_KERNEL_VERSION} -c 1>/dev/null
    touch /boot/iscsi_cmdline.txt
    sed "s/quiet .*//;s/$/ip=::::raspi:eth0:dhcp ISCSI_INITIATOR=${INITIATOR_IQN} ISCSI_TARGET_NAME=$TARGET_IQN ISCSI_TARGET_IP=$ISCSI_TARGET_IP ISCSI_TARGET_PORT=${ISCSI_TARGET_PORT} rw/" \
    /boot/cmdline.txt | tee /boot/iscsi_cmdline.txt
    
    if [ -f /boot/iscsi_config.txt ];then
        sed -i '/cmdline/d;/initramfs/d' /boot/iscsi_config.txt
    fi
    echo "initramfs initrd.img-\${PI_KERNEL_VERSION} followkernel" >> /boot/iscsi_config.txt
          
    echo "cmdline=iscsi_cmdline.txt" >> /boot/iscsi_config.txt

    sed -i '/include iscsi_config.txt/d' /boot/config.txt    
    echo "include iscsi_config.txt" >> /boot/config.txt

    # enable_ssh
    if [ ! -h /etc/systemd/system/multi-user.target.wants/ssh.service ]; then
        ${SUDO} ln -s /lib/systemd/system/ssh.service /etc/systemd/system/multi-user.target.wants/ssh.service
    fi
EOF
    sudo chmod +x ${RPI_ROOT_FS}${CMD}
}

# ip=<rpi ip>:<iscsi server ip>:<your router ip>:<rpi netmask>:<rpi hostname>:eth0:off
# iscsi_t_ip=<your iscsi server ip> iscsi_i=iqn.2016.03.localdomain.raspberrypi:openiscsi-initiator iscsi_t=iqn.2016.03.localdomain.myservername:raspberrypi rw root=/dev/ram0 init=/linuxrc rootfs=ext4 rootdev=UUID=aaaaa-bbbbb-ccccc-ddddd-eeeee-fffff elevator=deadline rootwait panic=15
prepare_img() {
    ARCH=$(dpkg --print-architecture)

    #    ${SUDO} cp /usr/bin/qemu-arm-static ${RPI_ROOT}/usr/bin/qemu-arm-static
    ${SUDO} cp /etc/resolv.conf ${RPI_ROOT_FS}/etc/resolv.conf
    if [ ! -n "$XAUTHORITY" ]; then
        sudo cp "$XAUTHORITY" ${RPI_ROOT_FS}/root/Xauthority
        export XAUTHORITY=/root/Xauthority
    fi
    
    # ld.so.preload fix
    if [ -f ${RPI_ROOT_FS}/etc/ld.so.preload ]; then
        ${SUDO} sed -i 's/^/#/g' ${RPI_ROOT_FS}/etc/ld.so.preload
    fi
    ${SUDO} mount -v --bind /dev ${RPI_ROOT_FS}/dev
    ${SUDO} mount -v --bind /dev/pts ${RPI_ROOT_FS}/dev/pts
    ${SUDO} mount -v --bind /proc ${RPI_ROOT_FS}/proc
    ${SUDO} mount -v --bind /sys ${RPI_ROOT_FS}/sys

    ${SUDO}  chroot ${RPI_ROOT_FS} $CMD
    
    # unmount everything
    ${SUDO} umount -lv ${RPI_ROOT_FS}/{dev/pts,dev,sys,proc}
    
    # revert ld.so.preload fix
    if [ -f ${RPI_ROOT_FS}/etc/ld.so.preload ]; then
        ${SUDO} sed -i 's/^#//g' ${RPI_ROOT_FS}/etc/ld.so.preload
    fi

    if [ -n "$XAUTHORITY" ]; then
        ${SUDO} rm -f "${RPI_ROOT_FS}/root/Xauthority"
    fi
}

cleanUp() {
    sync
    ${SUDO} service dnsmasq stop
    ${SUDO} rm /etc/dnsmasq.d/bootserver.conf
    ${SUDO} service tgt stop
    echo "CleaningUp..."    
    if [ $OVERLAY == 1 ]; then
        sudo umount -l ${OVERLAY_FS_ROOT}
        read -p "removing upper dir"
        ${SUDO} rm -r ${UPPER_DIR}
        RPI_ROOT_FS=${TEMP}/root
    fi
    ${SUDO} umount -l ${RPI_BOOT_FS}
    ${SUDO} umount -l ${RPI_ROOT_FS}
    ${SUDO} losetup -d ${LOOP_DEVICE}
    ${SUDO} rm -r ${RPI_ROOT_FS}
}

## https://www.geek-share.com/detail/2555438287.html
## https://linux.die.net/man/5/targets.conf#:~:text=tgt%2Dadmin%20uses%20%2Fetc%2F,to%20define%20targets%20and%20LUNs.
create_iscsi_conf() {
    ${SUDO} service tgt stop    
    cat << EOF | ${SUDO} tee  /etc/tgt/conf.d/${TARGET_IQN}.conf
 <target ${TARGET_IQN}>
    ## Target-level Directives:
    backing-store ${iSCSI_ROOT}/blocks/${IMG##*/}
    # direct-store <path>
    ##  This overrides the "default-driver" global directive!
    # driver                # iscsi (default)| iser
    # initiator-address ${ISCSI_INITIATOR_IP}   # ALL | ${ISCSI_INITIATOR_IP}
    initiator-name ${INITIATOR_IQN}
    ## If no "incominguser" is specified, it is not used. This directive may be used multiple times per target.
    # incominguser <user> <userpassword>
    ## If no "outgoinguser" is specified, it is not used. This directive may be used multiple times per target.
    # outgoinguser <user> <userpassword>
    ##  Define the tid of the controller. Default is next available integer.
    # controller_tid <val>
 </target>
EOF
    sudo service tgt restart
    sudo tgtadm --lld iscsi --mode target --op show
}

PXEDHCPproxyAndTFTPserver() {
    #export DISPLAY=:0
    #$ssh_cmd "sudo shutdown -now"
    sudo service dnsmasq stop
    #sudo rm /etc/dnsmasq.d/bootserver.conf

    TFTP_ROOT=${TFTP_ROOT:-"/tftpboot"}
    
    sudo rm -r ${TFTP_ROOT}
    sudo mkdir -p ${TFTP_ROOT}/${PI_SERIAL}
    sudo cp -r ${RPI_BOOT_FS}/* ${TFTP_ROOT} #/${PI_SERIAL}

    #sudo cp ${IMG} ${iSCSI_ROOT}/blocks/${IMG##*/}
    
    cat << EOF | sudo tee /etc/dnsmasq.d/bootserver.conf 
    port=0
    dhcp-range=${SERVER_IP},proxy
    log-dhcp
    log-queries

    enable-tftp
    tftp-root=${TFTP_ROOT}
    tftp-unique-root=mac
    pxe-service=0,"Raspberry Pi Boot   "
    pxe-prompt="Boot Raspberry Pi", 1
    dhcp-no-override
    dhcp-reply-delay=1
EOF

  #sudo service dnsmasq enable
  sudo service dnsmasq start
  
  if $(zenity --question --text="Close iSCSI server?" --display=$DISPLAY) ;then
    sudo service dnsmasq stop
    sudo rm /etc/dnsmasq.d/bootserver.conf
    sudo service tgt stop
    exit
  fi
}

hacking_img() {
    # enable_ssh
    if [ ! -h ${RPI_ROOT_FS}/etc/systemd/system/multi-user.target.wants/ssh.service ]; then
        ${SUDO} ln -s /lib/systemd/system/ssh.service ${RPI_ROOT_FS}/etc/systemd/system/multi-user.target.wants/ssh.service
    fi

    # remove open-iscsi unloaded module
    ${SUDO} sed -i 's/^ib_iser/#ib_iser/' ${RPI_ROOT_FS}/lib/modules-load.d/open-iscsi.conf
}

run() {
    install_dependencies
    get_img
    mount_img
    chrootScript
    prepare_img
    create_iscsi_conf
    PXEDHCPproxyAndTFTPserver
}

run

exit
#iqn.2020-06.com.Win10x64-Edit.initiator:rpi-blog

Install_and_Configure_iSCSI_Initiator() {
  ${SUDO} apt install open-iscsi -y
  ${SUDO} iscsiadm -m discovery -t st -p ${ISCSI_TARGET_IP}
  # You should see the available target in the following output:
  # ${ISCSI_TARGET_IP}:3260,1 iqn.2019-11.example.com:lun1
  #The above command also generates two files with LUN information. You can see them with the following command:
  ls -l /etc/iscsi/nodes/iqn.2019-11.example.com\:lun1/${ISCSI_TARGET_IP}\,3260\,1/ /etc/iscsi/send_targets/${ISCSI_TARGET_IP},3260/

  # You should see the following files:

  #/etc/iscsi/nodes/iqn.2019-11.example.com:lun1/${ISCSI_TARGET_IP},3260,1/:
  #total 4
  #-rw------- 1 root root 1840 Nov  8 13:17 default

  #/etc/iscsi/send_targets/${ISCSI_TARGET_IP},3260/:
  #total 8
  #lrwxrwxrwx 1 root root  66 Nov  8 13:17 iqn.2019-11.example.com:lun1,${ISCSI_TARGET_IP},3260,1,default -> /etc/iscsi/nodes/iqn.2019-11.example.com:lun1/${ISCSI_TARGET_IP},3260,1
  #-rw------- 1 root root 547 Nov  8 13:17 st_confi

  # Next, you will need to edit default file and define the CHAP information that you have configured on iSCSI target to access the iSCSI target from the iSCSI initiator.

  nano /etc/iscsi/nodes/iqn.2019-11.example.com\:lun1/192.168.0.103\,3260\,1/default
  # Add / Change the following lines:

  node.session.auth.authmethod = CHAP  
  node.session.auth.username = iscsi-user
  node.session.auth.password = password          
  node.session.auth.username_in = iscsi-target
  node.session.auth.password_in = secretpass         
  node.startup = automatic

  ${SUDO} service open-iscsi restart

}

iscsi_start() {
  iscsistart -i ${INITIATOR_IQN} -t $TARGET_IQN -a $ISCSI_TARGET_IP -p ${ISCSI_TARGET_PORT}
  "# -i, --initiatorname=name set InitiatorName to name (Required)
  # -t, --targetname=name    set TargetName to name (Required)
  -g, --tgpt=N             set target portal group tag to N (Required)
  # -a, --address=A.B.C.D    set IP address to A.B.C.D (Required)
  # -p, --port=N             set port to N (Default 3260)
  -u, --username=N         set username to N (optional)
  -w, --password=N         set password to N (optional
  -U, --username_in=N      set incoming username to N (optional)
  -W, --password_in=N      set incoming password to N (optional)
  -d, --debug=debuglevel   print debugging information 
  -b, --fwparam_connect    create a session to the target using iBFT or OF
  -N, --fwparam_network    bring up the network as specified by iBFT or OF
  -f, --fwparam_print      print the iBFT or OF info to STDOUT 
  -P, --param=NAME=VALUE   set parameter with the name NAME to VALUE
  -h, --help               display this help and exit
  -v, --version            display version and exit"
}

run

uninstallUnused() {
    # 2020-05-27-raspios-buster-full-armhf.img
    list+=("wolfram* libreoffice *minecraft*" )
}