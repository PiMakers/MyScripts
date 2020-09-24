## https://linuxhint.com/iscsi_storage_server_ubuntu/
## https://www.howtoforge.com/how-to-setup-iscsi-storage-server-on-ubuntu-1804/
## iSCSI Naming and Discovery: https://tools.ietf.org/html/rfc3721
## https://gist.github.com/luk6xff/9f8d2520530a823944355e59343eadc1

set +e

export LC_ALL=C

VERBOSE=1
PI0=1
PI_SERIAL=b0c7e328          # Raspberry Pi 3 Model B Rev 1.2 Main Dev:192.168.1.3
DEV_DIR=/mnt/LinuxData/OF
MYSCRIPTS_DIR=${DEV_DIR}/myGitHub/MyScripts
SCRIPT_NAME=${BASH_SOURCE[0]##*/}
SCRIPT_PATH=${BASH_SOURCE[0]%/*}
cd ${SCRIPT_PATH}
    SCRIPTS_LIST+=(
        ${MYSCRIPTS_DIR}/Rpi/rpiUtils.sh
        ${MYSCRIPTS_DIR}/Rpi/setUp/setupNew.sh
        ${MYSCRIPTS_DIR}/Rpi/Boot/dl_raspbian.sh
        )
    for sh in ${SCRIPTS_LIST[@]}
        do
            if [ -f $sh ]; then
                echo -e "********* \n* ${sh##*/}\n*********" 
                sed '/sed /d;/() {/!d;s/() {//' $sh
                . $sh
            else 
                echo "::: $sh not found"
            fi
        done
        echo -e "*******************\n* endOfFunctionList\n*******************"                


OVERLAY=0
iSCSI_ROOT=/mnt/LinuxData/iscsi
RPI_IMG_DIR=$iSCSI_ROOT/blocks

TEMP=/mnt/LinuxData/tmp
RPI_ROOT_FS=${TEMP}/root
RPI_BOOT_FS=${RPI_ROOT_FS}/boot

IMG_FOLDER=/mnt/LinuxData/Install/img
IMG_FOLDER=${iSCSI_ROOT}/blocks

# if sourced, exit with "return"
cleanExit() {
    #trap "echo FuckYou!!!" EXIT
    #trap "echo FuckYouToo" RETURN
    [ "${BASH_SOURCE}" == "${0}" ] || EXIT_CMD=return && echo "::EXIT_CMD=${EXIT_CMD}" 
    [ "${BASH_SOURCE}" == "${0}" ] && cleanUp
    kill -2 $$
}



detect_system () {
    if [ -z $WSL_DISTRO_NAME ]; then
        echo "WSL!"
        break;
    else
        . /usr/lib/os-release
        echo ${ID}
    fi
}

install_dependencies() {
    sudo apt update 1>/dev/null
    sudo apt -y dist-upgrade 1>/dev/null

    aptList+=(tgt)               # targeting iSCSI
    aptList+=(dnsmasq)           # tftp boot server
    aptList+=(binfmt-support)    # cross compile arm
    aptList+=(qemu-user-static)  # cross compile arm
    aptList+=(zenity)            # show messages
    aptList+=(libusb-1.0-0-dev)  # for usbboot
    
    sudo apt install -y ${aptList[@]} 1>/dev/null
    sudo apt -y autoremove --purge 1>/dev/null
    sudo apt autoclean 1>/dev/null
    sudo apt clean

}

#IMAGE section
get_img(){
                sudo mkdir -pv ${IMG_FOLDER}
    if ! IMG=$(zenity --file-selection --file-filter="*.img *.zip *.ISO" --filename=${RPI_IMG_DIR}/any.img 2>/dev/null); then
        # TODO download script
        if $(zenity --question --text="Download image?");then
            echo "Downloding latest image... (not implemented yet) $PWD"
            if [ -f ./dl_raspbian.sh ]; then
                #include ./dl_raspbian.sh
                dl_raspbian
                extractImg
                [ ${VERBOSE} ] && echo ":: IMG = ${IMG} "
            fi
            #RASPBIAN_TYPE=lite
        else
            echo "No img selected. Exit"
            cleanExit
        fi
    elif [ ${IMG##*.}=="zip" ];then
            if [ ! -f ${IMG%.*}.img ];then
                sudo unzip -o $IMG -d ${IMG_FOLDER}
            else
                sudo cp -v ${IMG%.*}.img ${IMG_FOLDER}
            fi
            IMG=${IMG%.*}.img
    elif [ ${IMG} == ${IMG_FOLDER}/${IMG##*/} ]; then
                echo "Already set!!!"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
    else
                sudo cp $IMG ${IMG_FOLDER}
    fi
}

mount_img() {
    if [ $OVERLAY == 1 ]; then
        UPPER_DIR=${TEMP}/upper
        ${SUDO} mkdir -pv -m 755 ${UPPER_DIR}/data
        ${SUDO} mkdir -pv -m 777 ${UPPER_DIR}/work
        #${SUDO} chown $USER:$USER ${UPPER_DIR}/data
        ${SUDO} chown root:root ${UPPER_DIR}/data
    fi
    
    LOOP_DEVICE=$(sudo losetup --show -f -P ${IMG_FOLDER}/${IMG##*/}) || exit
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
    ${SUDO} mount -v ${LOOP_DEVICE}p1 ${RPI_BOOT_FS} || echo "error mounting ${RPI_BOOT_FS}"

    IMG_ARCH=$(sed '/arm_64bit/!d;s/arm_64bit=//' ${RPI_BOOT_FS}/config.txt)
    if [ "x${IMG_ARCH}" == "x1" ];then
        IMG_ARCH=aarch64
        PI0=0
    elif [ "x${PI0}" == "x1" ]; then
        IMG_ARCH=armel
    else
        IMG_ARCH=armhf
    fi
    [ ${VERBOSE} ] && echo ":: IMG_ARCH = ${IMG_ARCH}"
}

iscsiSettings() {
    IQN=iqn.1961-06.$(uname -n).local
    TARGET_IQN="${IQN}:rpis"
    INITIATOR_IQN="${IQN}.initiator:${PI_SERIAL}"
    if [ -z $WSL_DISTRO_NAME ]; then 
        if [ "${IMG_ARCH}" == "armel" ]; then
            SERVER_IP=10.42.0.1
        else
            SERVER_IP=$(hostname -I | sed 's/ .*//')
        fi
    else
            # wsl (proxy)
        SERVER_IP=$(ipconfig.exe | sed '/IPv4/!d;s/.*: //' | sed -n 1p)
    fi
    ISCSI_TARGET_IP=${SERVER_IP}
    [ ${VERBOSE} ] && echo ":: ISCSI_TARGET_IP = ${ISCSI_TARGET_IP}"

    ISCSI_TARGET_PORT=3260
}

chrootScript() {
    CMD=sh.sh
    iscsiSettings

    CLIENT_IP=
    SERVER_IP=
    GW_IP=
    NETMASK=

    if [ "${IMG_ARCH}" == "aarch64" ]; then
        KERNEL_TAG="v8+"
        # cmdline IP conf for 64bit OS
        HOSTNAME=PiArm64
        DEVICE=eth0
        AUTOCONF=dhcp
    elif [ "${IMG_ARCH}" == "armhf" ]; then
        KERNEL_TAG="v7+"
        # cmdline IP conf for 64bit OS
        HOSTNAME=PiArmHF
        DEVICE=eth0
        AUTOCONF=dhcp        
    elif [ "${IMG_ARCH}" == "armel" ]; then
        KERNEL_TAG="[0-9][0-9]+"
        # cmdline IP conf for Pi0; Pi1  # ip=::::pi::
        CLIENT_IP=${SERVER_IP%.*}.15    # 10.42.0.15
        # SERVER_IP=10.42.0.1           # configured in iscsiSettings
        GW_IP=
        NETMASK=255.255.255.0
        HOSTNAME=Pi0
        DEVICE=usb0
        AUTOCONF=static
        # cmdline
        echo "#[PI0]" | ${SUDO} tee -a ${RPI_BOOT_FS}/config.iscsi
        echo -e "# enable OTG\n#dtoverlay=dwc2" | ${SUDO} tee -a ${RPI_BOOT_FS}/config.iscsi
        ## modules needed by overlayfs, usb-boot (open-iscsi added while installed)
        ## modules needed by usb-boot:
        modules+=(g_ether)
        modules+=(libcomposite)
        modules+=(u_ether)
        modules+=(udc-core)
        modules+=(usb_f_rndis)
        modules+=(usb_f_ecm)

        for m in ${modules[@]}
            do
                if [ ! $(grep $m ${RPI_ROOT_FS}/etc/initramfs-tools/modules) > /dev/null ]; then
                    echo $m | ${SUDO} tee -a ${RPI_ROOT_FS}/etc/initramfs-tools/modules
                    echo "added $m to modules"
                fi
            done        
        CMDLINE_TAG=" modules-load=dwc2,g_ether g_ether.host_addr=5e:a1:4f:5d:cf:d2"
    else 
        echo "UNKNOWN image arch!!!"
        exit
    fi

    CMDLINE_IP=${CLIENT_IP}:${SERVER_IP}:${GW_IP}:${NETMASK}:${HOSTNAME}:${DEVICE}:${AUTOCONF}
    [ ${VERBOSE} ] && echo ":: CMD = ${RPI_BOOT_FS}/${CMD}"
    
    PI_KERNEL_VERSION=$(ls ${RPI_ROOT_FS}/lib/modules | sed "/${KERNEL_TAG}.*/"'!d')
    [ ${VERBOSE} ] && echo ":: PI_KERNEL_VERSION = ${PI_KERNEL_VERSION}"

    ${SUDO} sed -i '/include/d' ${RPI_BOOT_FS}/config.txt    
    echo "include config.iscsi" | ${SUDO} tee ${RPI_BOOT_FS}/config.txt

    [ -f ${RPI_BOOT_FS}/config.iscsi ] && ${SUDO} rm ${RPI_BOOT_FS}/config.iscsi

    case ${IMG_ARCH} in
        armel)
            echo "[PI0]" | ${SUDO} tee -a ${RPI_BOOT_FS}/config.iscsi
            echo -e "# enable OTG\ndtoverlay=dwc2" | ${SUDO} tee -a ${RPI_BOOT_FS}/config.iscsi
            ;;
        armhf|aarch64)
            echo "[PI3]" | ${SUDO} tee -a ${RPI_BOOT_FS}/config.iscsi
            ;;
        *)
            echo "UNKNONW IMG_ARCH ${IMG_ARCH}"
            ;;
    esac
            
    echo "initramfs initrd.img-${PI_KERNEL_VERSION} followkernel" | ${SUDO} tee -a ${RPI_BOOT_FS}/config.iscsi
    echo "cmdline=cmdline.iscsi.${IMG_ARCH/0/}" | ${SUDO} tee -a ${RPI_BOOT_FS}/config.iscsi
    
    ${SUDO} touch ${RPI_BOOT_FS}/cmdline.iscsi.${IMG_ARCH/0/}
    sed "s/quiet .*//;s/$/ip=${CMDLINE_IP}${CMDLINE_TAG} ISCSI_INITIATOR=${INITIATOR_IQN} ISCSI_TARGET_NAME=$TARGET_IQN ISCSI_TARGET_IP=$ISCSI_TARGET_IP ISCSI_TARGET_PORT=${ISCSI_TARGET_PORT} rw/" \
    ${RPI_BOOT_FS}/cmdline.txt | ${SUDO} tee ${RPI_BOOT_FS}/cmdline.iscsi.${IMG_ARCH/0/} 1>/dev/null

    cat << EOF | sed 's/^.\{8\}//' | ${SUDO} tee ${RPI_BOOT_FS}/${CMD} 1>/dev/null
        #!/bin/bash

        export LC_ALL=C
        apt update 1>/dev/null
        # apt -y upgrade 1>/dev/null
        # apt -y autoremove --purge
        # apt autoclean
        # apt clean
        ## set screenbalanking off:
        raspi-config nonint do_blanking 1
        
        apt install -y open-iscsi 1>/dev/null
        # PI_KERNEL_VERSION=\$(ls /lib/modules | sed "/${KERNEL_TAG}.*/!d")
        # PI_KERNEL_VERSION=${PI_KERNEL_VERSION}
        update-initramfs -v -k ${PI_KERNEL_VERSION} -c 1>/dev/null
        
        ## remove open-iscsi unloaded module
        sed -i 's/^ib_iser/#ib_iser/' /lib/modules-load.d/open-iscsi.conf
EOF
    sudo chmod +x ${RPI_BOOT_FS}/${CMD}
}

# ip=<rpi ip>:<iscsi server ip>:<your router ip>:<rpi netmask>:<rpi hostname>:eth0:off
# iscsi_t_ip=<your iscsi server ip> iscsi_i=iqn.2016.03.localdomain.raspberrypi:openiscsi-initiator iscsi_t=iqn.2016.03.localdomain.myservername:raspberrypi rw root=/dev/ram0 init=/linuxrc rootfs=ext4 rootdev=UUID=aaaaa-bbbbb-ccccc-ddddd-eeeee-fffff elevator=deadline rootwait panic=15
prepare_img() {
    ARCH=$(dpkg --print-architecture)
    if [ ${ARCH} != ${IMG_ARCH} ]; then
        case ${IMG_ARCH} in
            armel)
                ${SUDO} cp -v /usr/bin/qemu-armeb-static ${RPI_ROOT_FS}/usr/bin/qemu-armeb-static
                ;;
            armhf)
                ${SUDO} cp -v /usr/bin/qemu-arm-static ${RPI_ROOT_FS}/usr/bin/qemu-arm-static
                ;;
            aarch64)
                ${SUDO} cp -v /usr/bin/qemu-aarch64-static ${RPI_ROOT_FS}/usr/bin/qemu-aarch64-static
                ;;
        esac
    fi

    ${SUDO} cp -v /etc/resolv.conf ${RPI_ROOT_FS}/etc/resolv.conf
    # ${SUDO} cp /usr/bin/qemu-arm-static ${RPI_ROOT}/usr/bin/qemu-arm-static

    if [ x${XAUTHORITY} != "x" ] && [ -f ${XAUTHORITY} ]; then
        sudo cp -v ${XAUTHORITY} ${RPI_ROOT_FS}/root/Xauthority
        XAUTHORITYorig=${XAUTHORITY}
        export XAUTHORITY=/root/Xauthority
    fi
    
    # ld.so.preload fix
    if [ -f ${RPI_ROOT_FS}/etc/ld.so.preload ]; then
        ${SUDO} sed -i 's/^/# /g' ${RPI_ROOT_FS}/etc/ld.so.preload
    fi

    ${SUDO} mount -v --bind /dev ${RPI_ROOT_FS}/dev
    ${SUDO} mount -v --bind /dev/pts ${RPI_ROOT_FS}/dev/pts
    ${SUDO} mount -v --bind /proc ${RPI_ROOT_FS}/proc
    ${SUDO} mount -v --bind /sys ${RPI_ROOT_FS}/sys

    ${SUDO}  chroot ${RPI_ROOT_FS} update-initramfs -cv -k all 1>/dev/null
    #/boot/$CMD
    
    # first sync changes, then unmount everything
    sync
    ${SUDO} umount -lv ${RPI_ROOT_FS}/{dev/pts,dev,sys,proc}
    
    # revert ld.so.preload fix
    if [ -f ${RPI_ROOT_FS}/etc/ld.so.preload ]; then
        ${SUDO} sed -i 's/^# //g' ${RPI_ROOT_FS}/etc/ld.so.preload
    fi

    ${SUDO} rm -v ${RPI_ROOT_FS}/usr/bin/qemu-arm-static
    ${SUDO} rm -v ${RPI_ROOT_FS}/etc/resolv.conf

    if [ -f ${RPI_ROOT_FS}/root/Xauthority ]; then
        ${SUDO} rm -vf ${RPI_ROOT_FS}/root/Xauthority
        if [ x${XAUTHORITYorig} != "x" ]; then
            export XAUTHORITY=${XAUTHORITYorig}
            unset XAUTHORITYorig
        fi
    fi
    
}

cleanUp() {
    [ ${VERBOSE} ] && echo ":: Syncing to disk..."
    sync
    [ ${VERBOSE} ] && echo ":: Stopping usbboot..."
    ${SUDO} pkill rpiboot
    echo ":: Stopping dnsmasq service..."
    ${SUDO} service dnsmasq stop
    if [ -f /etc/dnsmasq.d/bootserver.conf ];then
        ${SUDO} rm /etc/dnsmasq.d/bootserver.conf
    fi
    mountpoint -q  ${TFTP_ROOT} && ${SUDO} umount -lv ${TFTP_ROOT}
    [ ${VERBOSE} ] && echo ":: Stopping tgt service..."
    ${SUDO} service tgt stop
    [ ${VERBOSE} ] && echo ":: CleaningUp..."
    if [ $OVERLAY == 1 ]; then
        sudo umount -l ${OVERLAY_FS_ROOT}
        read -p "removing upper dir"
        ${SUDO} rm -r ${UPPER_DIR}
        RPI_ROOT_FS=${TEMP}/root
    fi
    if [ "x${RPI_BOOT_FS}" != "x" ] && mountpoint -q ${RPI_BOOT_FS};then
        ${SUDO} umount -lv ${RPI_BOOT_FS}
    fi
    if [ "x${RPI_ROOT_FS}" != "x" ] && mountpoint -q ${RPI_ROOT_FS}; then
        ${SUDO} umount -lv ${RPI_ROOT_FS}
    fi
    if [ "x${LOOP_DEVICE}" != "x" ]; then
        ${SUDO} losetup -d ${LOOP_DEVICE}
    fi
        if [ -d ${RPI_ROOT_FS} ]; then
        ${SUDO} rm -r ${RPI_ROOT_FS}
    fi
}

trap 'echo "catched INT" && exit' INT
trap 'echo "catched RETURN" ' RETURN
trap 'echo "catched EXIT" ' EXIT


## https://www.geek-share.com/detail/2555438287.html
## https://linux.die.net/man/5/targets.conf#:~:text=tgt%2Dadmin%20uses%20%2Fetc%2F,to%20define%20targets%20and%20LUNs.
create_iscsi_conf() {
    iscsiSettings
    ${SUDO} service tgt stop    
    cat << EOF | ${SUDO} tee  /etc/tgt/conf.d/${TARGET_IQN}.conf 1>/dev/null
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
    [ ${VERBOSE} ] && sudo tgtadm --lld iscsi --mode target --op show
}

TFTPserver() {
    #$ssh_cmd "sudo shutdown -now"
    sudo service dnsmasq stop
    #sudo rm /etc/dnsmasq.d/bootserver.conf

    TFTP_ROOT=${TFTP_ROOT:-"/tftpboot"}
    
    mountpoint -q ${TFTP_ROOT} || sudo rm -r ${TFTP_ROOT}
    sudo mkdir -pv ${TFTP_ROOT}/${PI_SERIAL}
    #sudo cp -r ${RPI_BOOT_FS}/* ${TFTP_ROOT} #/${PI_SERIAL}
    ${SUDO} mount -v ${LOOP_DEVICE}p1 ${TFTP_ROOT}

    #sudo cp ${IMG} ${iSCSI_ROOT}/blocks/${IMG##*/}
    for m in $(ls /sys/class/net)
        do
            case $m in
                w*)
                    WIFI_IFACE=$m
                    ;;
                e*)
                    WIRED_IFACE=$m
                    ;;
                *)
                        if [ $m != lo ]; then
                            OTHER_IFACE=$m
                        fi
                    ;;
            esac
        done

    cat << EOF | sed 's/^.\{8\}//' | sudo tee /etc/dnsmasq.d/bootserver.conf 1>/dev/null
        # PiMaker
        port=0
        interface=${WIRED_IFACE}
        dhcp-range=${NETWORK_SUBNET},proxy
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
  sudo service systemd-resolved stop
  sudo service dnsmasq start
}

startUsbBoot() {
    if [ -d ${DEV_DIR}/GitHub/usbboot ]; then
        USBBOOT_DIR=${DEV_DIR}/GitHub/usbboot
    else
        mkdir -pv ${DEV_DIR}/GitHub
        git clone --depth=1 https://github.com/raspberrypi/usbboot ${USBBOOT_DIR}
        ${SUDO} make -j -C ${USBBOOT_DIR}
        #${DEV_DIR}/GitHub/usbboot/Makefile
    fi
    if [ ! -f ${RPI_BOOT_FS}/bootcode.bin.orig ]; then
        ${SUDO} mv ${RPI_BOOT_FS}/bootcode.bin ${RPI_BOOT_FS}/bootcode.bin.orig
        ${SUDO} cp -v ${USBBOOT_DIR}/msd/bootcode.bin ${RPI_BOOT_FS}/bootcode.bin
        #${SUDO} curl -LJ https://github.com/raspberrypi/firmware/raw/master/boot/bootcode.bin -o ${RPI_BOOT_FS}/bootcode.bin
    fi
    gnome-terminal -t TITLE --wait -- ${SUDO} ${USBBOOT_DIR}/rpiboot -d ${RPI_BOOT_FS} -v -l -o &
}

manageServices() {
    E_BTN_STARTSTOP="stop"
    while :
        do
            res=$(zenity --question --text="Close iSCSI usbboot server?" --extra-button=${E_BTN_STARTSTOP} --display=$DISPLAY) 
            if [ $? == 1 ];then
                case $res in
                    start)
                        echo "${EXTRA_BUTTON_TXT}!!!"
                        EXTRA_BUTTON_TXT=stop
                        ;;                
                    stop)
                        echo "${EXTRA_BUTTON_TXT}!!!"
                        EXTRA_BUTTON_TXT=start
                        ;;
                    *)
                        res=No
                        echo "$res"
                        ;;
                esac
            else
                cleanUp
                break
            fi
        done
        #exit
}

hackImg() {
    #create_ssh_keypair:
    HOSTNAME=$(hostname -s)
    ${SUDO} mkdir -pv -m 700 ${RPI_ROOT_FS}/home/pi/.ssh
    ${SUDO} chown -R 1000:1000 ${RPI_ROOT_FS}/home/pi
    [ -f ~/.ssh/testkey@${HOSTNAME} ] || ${SUDO} ssh-keygen -q -N Pepe374189 -C testKey -f ~/.ssh/testkey@${HOSTNAME}
    ${SUDO} cat ~/.ssh/testkey@${HOSTNAME}.pub | sudo tee ${RPI_ROOT_FS}/home/pi/.ssh/authorized_keys 1>/dev/null
    ${SUDO} chmod 600 ${RPI_ROOT_FS}/home/pi/.ssh/authorized_keys
    ${SUDO} chown 1000:1000 ${RPI_ROOT_FS}/home/pi/.ssh/authorized_keys

    # enable_ssh
    if [ ! -h ${RPI_ROOT_FS}/etc/systemd/system/multi-user.target.wants/ssh.service ]; then
        ${SUDO} ln -s /lib/systemd/system/ssh.service ${RPI_ROOT_FS}/etc/systemd/system/multi-user.target.wants/ssh.service
    fi
    #enable_ssh
    # remove open-iscsi unloaded module
    ${SUDO} sed -i 's/^ib_iser/#ib_iser/' ${RPI_ROOT_FS}/lib/modules-load.d/open-iscsi.conf
}

run() {
    # install_dependencies
    get_img
    mount_img
    chrootScript
    prepare_img
    # setUpNew:
    create_ssh_keypair
    enable_ssh
    do_blanking
    


    create_iscsi_conf
    TFTPserver
    [ "x${PI0}" == "x1" ] && startUsbBoot
    manageServices    
}

[ "${BASH_SOURCE}" == "${0}" ] && run

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

uninstallUnused() {
    # 2020-05-27-raspios-buster-full-armhf.img
    list+=("wolfram* libreoffice *minecraft*" )
}