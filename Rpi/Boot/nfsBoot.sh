## Pi 4 netboot : https://hackaday.com/2019/11/11/network-booting-the-pi-4/
## https://github.com/raspberrypi/rpi-eeprom/blob/master/firmware/raspberry_pi4_network_boot_beta.md
## http://retinal.dehy.de/docs/doku.php?id=technotes:raspberryrootnfs
## https://xinau.ch/notes/ubuntu-network-installation-with-pxe/


## PAM: https://bbs.archlinux.org/vaiewtopic.php?id=224912 
#!/bin/bash

## setenforce 0/1 disable SElinux
## restorecon -Rv restore security

    #ssh-keygen -f "/home/pimaker/.ssh/known_hosts" -R "192.168.1.3"
    #ssh_cmd='ssh -X pi@192.168.1.3 $1'

#trap "echo SIGINT && exit" SIGINT

#set -e

# /mnt/LinuxData/OF/myGitHub/MyScripts/Rpi/Boot/NetBoot.sh

VERBOSE=1
OVERLAY=0
MOUNT_DEV_DIR=1
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

trap "cleanUp" INT
    # trap 'echo "FuckYou!!!" && cleanUp' EXIT
trap "echo FuckYouToo" RETURN
# if sourced, exit with "return"
exit() {
#    trap "echo FuckYou!!!" EXIT
#    trap "echo FuckYouToo" RETURN
    [ "${BASH_SOURCE}" == "${0}" ] || EXIT_CMD=return && echo "EXIT_CMD=${EXIT_CMD}" 
    # if [ -z ${iSCSi} ]; then
        [ "${BASH_SOURCE}" == "${0}" ] && cleanUp
    # fi
    ${SUDO} kill -2 $$
}

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

check_dependency() {
    # $1 && return
    depends_on="dnsmasq"
    depends_on+=" nfs-kernel-server"
    depends_on+=" zenity"
    depends_on+=" curl"
    depends_on+=" pv"
    for i in $depends_on; do
        if [[ $(dpkg-query -s $i) ]];then
            echo "$i installed!"
        else
            echo "Dependency $i NOT installed!"
            needed+=" $i"
        fi
    done
    # install unmet dependencies
    if [ ! -z needed ]; then
        ${SUDO} apt install $needed
    fi
}

NFS_VERS=4
DHCP=1
    if [ $DHCP -eq 1 ]; then
        HOST_IP=$(hostname -I | sed 's/ .*//')
    else
        HOST_IP=10.0.0.1
    fi
NFS_ROOT=/nfs
TEMP=/tmp
TEMP=/mnt/LinuxData/tmp
MAKE_INITRAMFS=0

serials="b0c7e328 dc:a6:32:66:0a:2c"
PI4_serial[0]="177b3502"
PI4_macs[0]="dc:a6:32:66:0a:2c"
CM4="e4:5f:01:1f:b7:06"
# /proc/device-tree/model|serial:
# Raspberry Pi 3 Model B Rev 1.2 | 00000000b0c7e328
# [ $OVERLAY == 1 ] && OVERLAY_FS_ROOT=${NFS_ROOT}/root && NFS_ROOT=/tmp


ROOT_FS=${NFS_ROOT}/root
BOOT_FS=${NFS_ROOT}/boot

RPI_ROOT_FS=${ROOT_FS}

BOOT_FS=${ROOT_FS}/boot
if [ $OVERLAY == 1 ]; then
    RPI_ROOT_FS=${TEMP}/root
    UPPER_DIR=${TEMP}/upper
fi

#IMAGE section
getImg(){
    [ ${VERBOSE} ] && echo ":: Geting rpi img ..."
    sudo mkdir -pv ${IMG_FOLDER}
    if ! IMG=$(zenity --file-selection --file-filter="*.img *.zip *.ISO *xz" --filename="${IMG_FOLDER}/2021-05-07-raspios-buster-arm64.img" 2>/dev/null); then
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
            cleanUp
        fi
    else
        # echo :::::::::::::::::${IMG##*.}
        IMG_NAME=${IMG##*/}
        if [ "${IMG##*.}" == "zip" ];then
                if [ ! -f ${IMG%.*}.img ];then
                    sudo unzip -o $IMG -d ${IMG_FOLDER}
                else
                    sudo cp -v ${IMG%.*}.img ${IMG_FOLDER}
                fi
                IMG=${IMG_FOLDER}/${IMG_NAME%.*}.img
        elif [ ${IMG##*.} == "xz" ];then
            if [ ! -f ${IMG%.*} ];then
                ${SUDO}  xzcat ${IMG} | pv -s 2G | ${SUDO} dd bs=4M of=${IMG%.*}
                IMG=${IMG_FOLDER}/${IMG_NAME%.*}
            else
                sudo cp -v ${IMG%.*} ${IMG_FOLDER}
            fi
            IMG=${IMG%.*}
        elif [ ${IMG} == ${IMG_FOLDER}/${IMG##*/} ]; then
                    echo "Already set!!!"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
        else
                    sudo cp $IMG ${IMG_FOLDER}
        fi
    fi
}


resize_image() {
    RESIZED=0
    #[ ! -f "$1" ] && [ -z "$2" ] && echo "Not resized!!!!" && return
    #[[ ${RESIZE} == 1 ]] && [[ $( expr $(stat -c %s $1) / 1024 / 1024) < 5120 ]] && \
    ${SUDO} qemu-img resize -f raw "$IMG" +2G && RESIZED=1
    LOOP_DEVICE=$(${SUDO} losetup -f)
    ${SUDO} losetup $LOOP_DEVICE $IMG
    OLD_DISKID="$(${SUDO} fdisk -l "$LOOP_DEVICE" | sed -n 's/Disk identifier: 0x\([^ ]*\)/\1/p')"
    ${SUDO} partprobe $LOOP_DEVICE 	|| echo "error partprobe $LOOP_DEVICE "
    #end_sector=$(${SUDO} fdisk -l -o End $LOOP_DEVICE | sed '$!d')
    #echo "end_sector =${end_sector}"
    #[ ${RESIZED} ] && 
    [[ ${RESIZED} == 1 ]] && ${SUDO} parted "$LOOP_DEVICE" u s resizepart 2 100% && \
    ${SUDO} e2fsck -f -y -v -C 0 ${LOOP_DEVICE}p2 1>/dev/null && \
    ${SUDO} resize2fs -p ${LOOP_DEVICE}p2 #|| ( echo "partitionERROR" && exit )
    DISKID="$(${SUDO} fdisk -l "${LOOP_DEVICE}" | sed -n 's/Disk identifier: 0x\([^ ]*\)/\1/p')"

    end_sector=$(${SUDO} fdisk -l -o End $LOOP_DEVICE | sed '$!d')
    echo "end_sector =${end_sector}"
    # fix_partuuid
    echo -ne " old : ${OLD_DISKID}\n new : ${DISKID}\n"
    [[ ${RESIZED} == 1 ]] && ( ${SUDO} sed -i "s/${OLD_DISKID}/${DISKID}/g" ${RPI_ROOT}/etc/fstab && \
    ${SUDO} sed -i "s/${OLD_DISKID}/${DISKID}/" ${RPI_BOOT}/cmdline.txt )
    # is this the img boot fs??? check ntfs3!!!
    ${SUDO} touch ${RPI_BOOT}/ResizedImg   
    ${SUDO} losetup -d $LOOP_DEVICE
    RESIZED=1
}

resizeImage() {
    local COUNT=1024
    ${SUDO} bash -c "dd if=/dev/zero bs=1M count=${COUNT} >> ${IMG}"
}

mountImage() {
    LOOP_DEVICE=$(${SUDO} losetup -f)
    ${SUDO} losetup -P $LOOP_DEVICE $IMG
    local mount_opt="-oro"
    if [ ${OVERLAY} != 1 ]; then
        ${SUDO} partprobe $LOOP_DEVICE 	|| echo "error partprobe $LOOP_DEVICE"
        mount_opt=
    fi
    #mkdir -p ${RPI_BOOT} ${RPI_ROOT}   || echo "error create ${RPI_BOOT} "
    
    ${SUDO} mkdir -pv -m 777 ${RPI_ROOT_FS}
    ${SUDO} chown $USER:$USER ${RPI_ROOT_FS}
    # ${SUDO} mount -n ${LOOP_DEVICE}p1 ${BOOT_FS} || echo "error mounting ${BOOT_FS}"
    ${SUDO} mount -vn ${mount_opt} ${LOOP_DEVICE}p2 ${RPI_ROOT_FS} || echo "error mounting ${ROOT_FS}"


    if [ ${OVERLAY} == 1 ]; then
        ${SUDO} mkdir -pv -m 755 ${UPPER_DIR}/data
        ${SUDO} mkdir -pv -m 777 ${UPPER_DIR}/work
        #${SUDO} chown $USER:$USER ${UPPER_DIR}/data
        ${SUDO} chown root:root ${UPPER_DIR}/data
    fi
    if [ ${OVERLAY} == 2 ]; then    
        # overlayfs hacks
        ${SUDO} mkdir -p -m 0755 ${UPPER_DIR}/data/etc/systemd/system/systemd-logind.service.d
        #        ${SUDO} bash -c "cat > ${UPPER_DIR}/data/etc/systemd/system/systemd-logind.service.d/nfs_on_overlayfs.conf" << EOF
        #[Service]
        #IPAddressAllow=10.42.1.0/24
        #EOF
    fi
    if [ ${OVERLAY} == 1 ]; then
        ################################
        #        ${SUDO} mkdir -p -m 0755 ${UPPER_DIR}/data/etc/systemd/system/systemd-logind.service.d
        #        ${SUDO} bash -c "cat > ${UPPER_DIR}/data/etc/systemd/system/systemd-logind.service.d/nfs_on_overlayfs.conf" << EOF
        #[Service]
        #IPAddressAllow=192.168.1.0/24
        #EOF

        if true; then
            ## read -p "Press a key to continue..."
            #TODO: do them with systemd-tmpfiles !!!
            #${SUDO} cp -aR ${RPI_ROOT_FS}/tmp ${UPPER_DIR}/data
            #${SUDO} cp -aR ${RPI_ROOT_FS}/dev ${UPPER_DIR}/data
            #${SUDO} cp -aR ${RPI_ROOT_FS}/var ${UPPER_DIR}/data
            #${SUDO} cp -aR ${RPI_ROOT_FS}/run ${UPPER_DIR}/data

            ${SUDO} cp -aR ${RPI_ROOT_FS}/etc ${UPPER_DIR}/data
            #${SUDO} mkdir -m 755 ${UPPER_DIR}/data/etc
            #${SUDO} cp -aR ${RPI_ROOT_FS}/etc/triggerhappy ${UPPER_DIR}/data/etc
            #${SUDO} cp -aR ${RPI_ROOT_FS}/etc/cron* ${UPPER_DIR}/data/etc
            #${SUDO} cp -aR ${RPI_ROOT_FS}/etc/X11 ${UPPER_DIR}/data/etc
            #${SUDO} cp -aR ${RPI_ROOT_FS}/etc/pam.d ${UPPER_DIR}/data/etc


            #${SUDO} cp -aR ${RPI_ROOT_FS}/usr ${UPPER_DIR}/data/
            ${SUDO} mkdir -p -m 755 ${UPPER_DIR}/data/usr
            ${SUDO} cp -aR ${RPI_ROOT_FS}/usr/share ${UPPER_DIR}/data/usr
            #${SUDO} cp -aR ${RPI_ROOT_FS}/usr/share/alsa ${UPPER_DIR}/data/usr/share
            #${SUDO} mkdir -p -m 755 ${UPPER_DIR}/data/usr/share/fonts/truetype
            #${SUDO} cp -aR ${RPI_ROOT_FS}/usr/share/fonts/truetype/piboto ${UPPER_DIR}/data/usr/share/fonts/truetype

            #${SUDO} cp -aR ${RPI_ROOT_FS}/home ${UPPER_DIR}/data/home
        fi
        ###############################
            OVERLAY_FS_ROOT=${ROOT_FS}
        ${SUDO} mkdir -pv -m 777 ${OVERLAY_FS_ROOT}
        LOWER_DIRS=${RPI_ROOT_FS}
        ${SUDO} mount -v -t overlay -o lowerdir=${LOWER_DIRS},upperdir=${UPPER_DIR}/data,workdir=${UPPER_DIR}/work,index=on,nfs_export=on,redirect_dir=on none ${OVERLAY_FS_ROOT}
        # ${SUDO} mount -v -t overlay -o lowerdir=${RPI_ROOT_FS}/etc:${RPI_ROOT_FS}/opt:${RPI_ROOT_FS}/bin,upperdir=${UPPER_DIR}/data,workdir=${UPPER_DIR}/work,index=on,nfs_export=on,redirect_dir=on   none ${OVERLAY_FS_ROOT}
        #${SUDO} mount -v -t overlay -o lowerdir=${RPI_ROOT_FS},upperdir=${UPPER_DIR}/data,workdir=${UPPER_DIR}/work,index=on,nfs_export=on,redirect_dir=on,xino=auto  none ${OVERLAY_FS_ROOT}
    fi    
    if [ "$NFS_VERS" == 3 ]; then
        ${SUDO} mkdir -p -m 777 ${BOOT_FS}
    fi
    # LEDE doesn't have /root/boot
    ${SUDO} mkdir -pv -m 777 ${BOOT_FS}
    ${SUDO} mount -v ${LOOP_DEVICE}p1 ${BOOT_FS} || echo "error mounting ${BOOT_FS}"
    ${SUDO} mkdir -p -m 777 ${RPI_ROOT_FS}/mnt/LinuxData/OF
    # ${SUDO} mount --bind  /mnt/LinuxData/OF ${RPI_ROOT_FS}/mnt/LinuxData/OF || echo "error mounting ${BOOT_FS}"
    # ${SUDO} mount --bind  /mnt/LinuxData/OF/usbboot/boot ${BOOT_FS} || echo "error mounting ${BOOT_FS}"
}

detectOS() {
    if [ -f ${ROOT_FS}/etc/os-release ]; then
        . ${ROOT_FS}/etc/os-release
        echo ::ID=${ID}
    fi
    
    case $ID in
        ubuntu)
            echo "-----------------------Hurrah!!!!"
            ;;
        raspbian|debian)
            echo "-----------------------RASPberryPi Detected!!!"
            ID=pi
            ;;
        *)
            echo ID=$ID ---------------------------
    esac
}

    ## OnExportedFS:
    # dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/nfs \
    # nfsroot=<server-ip>:/<nfs-root>,udp,nfsvers=3,rsize=32768,wsize=32768, \
    # hard,intr rw ip=dhcp rootwait elevator=deadline
prepare_cmdline() {
                # ip=<client-ip>:<server-ip>:<gw-ip>:<netmask>:<hostname>:<device>:<autoconf>
                CLIENT_IP=
                SERVER_IP=
                GW_IP=
                NETMASK=
                HOSTNAME=EthernetPi
                DEVICE=eth0
                AUTOCONF=dhcp
                IP=${CLIENT_IP}:${SERVER_IP}:${GW_IP}:${NETMASK}:${HOSTNAME}:${DEVICE}:${AUTOCONF}

    if [ "$NFS_VERS" == 3 ]; then
        local NFS_BOOT_TAG="${ROOT_FS},vers=3,rsize=32768,wsize=32768,hard,intr"
    else
        local NFS_BOOT_TAG="/root,vers=4.1,proto=tcp,port=2049,nolock"
    fi
        #${SUDO} bash -c "cat > ${BOOT_FS}/cmdline.nfsboot.${DEVICE}" << EOF
        cat << EOF | sed 's/^.\{12\}//' | ${SUDO} tee ${BOOT_FS}/cmdline.nfsboot.${DEVICE} 1>/dev/null
            #dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=${HOST_IP}:${ROOT_FS},vers=3, rw ip=10.42.0.14:10.42.0.1::255.255.255.0:::dhcp elevator=deadline rootwait plymouth.ignore-serial-consoles noswap #init=/bin/ro-root.sh
            dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=${HOST_IP}:${NFS_BOOT_TAG} rw ip=dhcp elevator=deadline rootwait # plymouth.ignore-serial-consoles noswap
            #dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=10.42.0.1:/pi/root rw ip=10.42.0.14:10.42.0.1::255.255.255.0:pi:usb0:static elevator=deadline modules-load=dwc2,g_ether fsck.repair=yes rootwait g_ether.host_addr=5e:a1:4f:5d:cf:d2
EOF
    #KERNEL_TAG="[0-9][0-9]+"
    PI0_KERNEL_VERSION=$(ls ${ROOT_FS}/lib/modules | sed '/[0-9][0-9]+.*/!d')
    
    ${SUDO} sed -r -i '/(cmdline=|include config)/d'  ${BOOT_FS}/config.txt
    echo "cmdline=cmdline.nfsboot.${DEVICE}" | ${SUDO} tee -a ${BOOT_FS}/config.txt 1>/dev/null
    ## pi0 starthere
    echo "include config.pi0" | ${SUDO} tee -a ${BOOT_FS}/config.txt 1>/dev/null
    cat << EOF | ${SUDO} tee ${BOOT_FS}/config.pi0 1>/dev/null
    [pi0]
    # cmdline
    cmdline=cmdline.nfsboot.pi0
 
    # set initramfs
    initramfs initrd.img-${PI0_KERNEL_VERSION} followkernel

    ### Device Tree: 
    #enable OTG (OnTheGo)
    dtoverlay=dwc2,dr_mode=peripheral
EOF

                KERNEL_VERSION=$(ls ${RPI_ROOT_FS}/lib/modules | sed '/[0-9][0-9]+/!d')
                # sudo update-initramfs -c -k ${KERNEL_VERSION}
                CLIENT_IP=10.42.0.15
                SERVER_IP=10.42.0.1 # ${CLIENT_IP%.*}.1
                GW_IP=
                NETMASK=255.255.255.0
                HOSTNAME=Pi0
                DEVICE=usb0
                AUTOCONF=static
                IP=${CLIENT_IP}:${SERVER_IP}:${GW_IP}:${NETMASK}:${HOSTNAME}:${DEVICE}:${AUTOCONF}
        # ${SUDO} bash -c "cat > ${BOOT_FS}/cmdline.nfsboot.pi0" << EOF
        cat << EOF | sed 's/^.\{12\}//' | ${SUDO} tee ${BOOT_FS}/cmdline.nfsboot.pi0 1>/dev/null
            # pi0 USB-boot:
            dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=${SERVER_IP}:${ROOT_FS} rw ip=${IP} elevator=deadline modules-load=dwc2,g_ether fsck.repair=yes rootwait g_ether.host_addr=5e:a1:4f:5d:cf:d2
            #dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=${SERVER_IP}:${NFS_BOOT_TAG} rw ip=${IP} elevator=deadline rootwait plymouth.ignore-serial-consoles noswap
EOF

    ## /proc/cmdline iscsi
    # coherent_pool=1M
    # snd_bcm2835.enable_compat_alsa=0
    # snd_bcm2835.enable_hdmi=1
    # snd_bcm2835.enable_headphones=1
    # bcm2708_fb.fbwidth=1824
    # bcm2708_fb.fbheight=984
    # bcm2708_fb.fbswap=1
    # smsc95xx.macaddr=B8:27:EB:ED:34:47
    # vc_mem.mem_base=0x1ec00000
    # vc_mem.mem_size=0x20000000
    # console=ttyAMA0,115200
    # console=tty1
    # root=PARTUUID=58ce116e-02
    # rootfstype=ext4
    # elevator=deadline
    # fsck.repair=yes rootwait
    # rw
    # ip=10.42.0.15:10.42.0.1::255.255.255.0:pi:usb0:static
    # modules-load=dwc2,g_ether
    # fsck.repair=yes
    # rootwait
    # g_ether.host_addr=5e:a1:4f:5d:cf:d2
    # ISCSI_INITIATOR=iqn.1961-06.NUC.local.initiator:rpi-blog
    # ISCSI_TARGET_NAME=iqn.1961-06.NUC.local:rpis
    # ISCSI_TARGET_IP=10.42.0.1
    # ISCSI_TARGET_PORT=3260
}

createInitramfs() {
    if [ -f ${RPI_ROOT_FS}/etc/initramfs-tools/modules -a MAKE_INITRAMFS == 1]; then
        ## modules needed by overlayfs, usb-boot (open-iscsi added while installed) 13463858
        modules+=(overlay)
        ## modules needed by usb-boot:
        modules+=(g_ether)
        modules+=(libcomposite)
        modules+=(u_ether)
        modules+=(udc-core)
        modules+=(usb_f_rndis)
        modules+=(usb_f_ecm)

        for m in ${modules[@]}
            do
                if [ ! $(grep -q $m ${RPI_ROOT_FS}/etc/initramfs-tools/modules) ]; then
                    echo $m | ${SUDO} tee -a ${RPI_ROOT_FS}/etc/initramfs-tools/modules
                    echo "added $m to modules"
                fi
            done        

        ${SUDO} chroot ${RPI_ROOT_FS} update-initramfs -v -c -k 5.4.51+
    else
        echo "update-initramfs tools not installed! Skip..."
        MAKE_INITRAMFS=0
    fi
}

prepare_fstab() {
    ${SUDO} sed -i '/PxeServer/d' ${ROOT_FS}/etc/fstab
    # delete all trailing blank lines at end of file
    ${SUDO} sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' ${ROOT_FS}/etc/fstab
    
    if [ ! -f ${ROOT_FS}/etc/fstab.orig ];then
        ${SUDO} cp ${ROOT_FS}/etc/fstab ${ROOT_FS}/etc/fstab.orig
        ${SUDO} sed -i 's/PARTUUID/#PARTUUID/g' ${ROOT_FS}/etc/fstab
    fi
    
    ## MovedTo mountImage()
    if false; then 
            ${SUDO} bash -c "cat >> ${ROOT_FS}/etc/fstab" << EOF
    ${HOST_IP}:/mnt/LinuxData/OF /mnt/LinuxData/OF nfs4 defaults          0       2 #PxeServer
EOF
    fi
}

configure_nfs() {
    ${SUDO} sed -i '/PxeServer/d' /etc/exports
    # delete all trailing blank lines at end of file
    ${SUDO} sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' /etc/exports
    if [ "$NFS_VERS" == 4 ]; then
    #${SUDO} bash -c 'cat >> /etc/exports' << EOF
        cat << EOF | sed 's/^.\{12\}//' | ${SUDO} tee -a /etc/exports 1>/dev/null
            # /mnt/LinuxData/OF 192.168.1.0/24(rw,sync,no_subtree_check,insecure,no_root_squash,crossmnt,anonuid=1000,anongid=1000)  #PxeServer

            # NFSv.4                                                                 PxeServer
            ${NFS_ROOT} ${HOST_IP%.*}.0/24(rw,fsid=0,sync,no_subtree_check,no_auth_nlm,insecure,no_root_squash,crossmnt) #PxeServer
            ${ROOT_FS} ${HOST_IP%.*}.0/24(rw,sync,no_subtree_check,insecure,no_root_squash,crossmnt,anonuid=1000,anongid=1000)  #PxeServer

            # ${ROOT_FS}/etc ${HOST_IP%.*}.0/24(rw,sync,no_subtree_check,insecure,no_root_squash,crossmnt)   #PxeServer
            # ${ROOT_FS}/home/pi ${HOST_IP%.*}.0/24(rw,fsid=1000,sync,no_subtree_check,insecure,no_root_squash,crossmnt)   #PxeServer

            # Pi0                                                                 PxeServer
            ${NFS_ROOT} ${CLIENT_IP%.*}.0/24(rw,fsid=0,sync,no_subtree_check,no_auth_nlm,insecure,no_root_squash,crossmnt) #PxeServer
            ${ROOT_FS} ${CLIENT_IP%.*}.0/24(rw,sync,no_subtree_check,insecure,no_root_squash,crossmnt,anonuid=1000,anongid=1000)  #PxeServer
EOF
    else
        #${SUDO} bash -c 'cat >> /etc/exports' << EOF
        cat << EOF | sed 's/^.\{8\}//' | ${SUDO} tee /etc/exports 1>/dev/null

            # NFSv.3                                                                 PxeServer
            /mnt/LinuxData/OF *(rw,no_subtree_check,no_root_squash,fsid=1000)       #PxeServer
            ${BOOT_FS} *(rw,sync,no_subtree_check,no_root_squash,crossmnt)          #PxeServer
            ${ROOT_FS} *(rw,sync,no_subtree_check,no_root_squash,crossmnt,fsid=0)   #PxeServer
EOF
    #${SUDO} /mnt/LinuxData/OF/usbboot/rpiboot -l -d /nfs/root/boot
    fi
}
    # sudo service systemd-resolved stop
    # ${SUDO} systemctl is-active -q systemd-resolved
configure_dnsmasq() {
    # SUDO=sudo VERBOSE=1 DHCP=1 BOOT_FS=/nfs/root/boot 
    ${SUDO} systemctl is-active -q systemd-resolved && ${SUDO} service systemd-resolved stop
    
    if [[ $VERBOSE == 1 ]]; then
        TFTP_DIR=${BOOT_FS}
    
        if [ $DHCP -eq 1 ]; then      
            HOST_IP=$(hostname -I | sed 's/ .*//')
            DHCP_OPT="--dhcp-range=${HOST_IP},proxy --port=0"
            ## gnome-terminal -t "tftpBoot" -- sudo dnsmasq --enable-tftp --tftp-root=/nfs/root/boot,enp0s25 -d --pxe-service=0,"Raspberry Pi Boot" --dhcp-reply-delay=1 --dhcp-range=192.168.1.20,proxy --port=0
        else
            HOST_IP=10.0.0.1
            DHCP_OPT="--dhcp-range=${HOST_IP%.*}.2,${HOST_IP%.*}.100,1h --port=5353"
        fi
        gnome-terminal -t "tftpBoot" -- ${SUDO} dnsmasq --enable-tftp --tftp-root=${TFTP_DIR},enp0s25 -d --pxe-service=0,"Raspberry Pi Boot" \
            --dhcp-reply-delay=1 ${DHCP_OPT} #--dhcp-range=${DHCP_RANGE} --tftp-unique-root=mac --pxe-prompt="Boot Raspberry Pi",1 

    else
        cat << EOF | sed 's/^.\{12\}//'| ${SUDO} tee /etc/dnsmasq.d/nfsBoot.conf  1>/dev/null
            #PXE BootServer by PiMaker®
            bind-dynamic
            log-dhcp
            ## tftp:
            enable-tftp                         # Enable integrated read-only TFTP server.
            tftp-root=${ROOT_FS}/boot           # Export files by TFTP only from the specified subtree.
            tftp-unique-root=mac                # Add client IP or hardware address to tftp-root.
            # tftp-secure                       # Allow access only to files owned by the user running dnsmasq.
            tftp-no-fail                        # Do not terminate the service if TFTP directories are inaccessible.
            # tftp-max=<integer>                # Maximum number of concurrent TFTP transfers (defaults to 50).
            # tftp-mtu=<integer>                # Maximum MTU to use for TFTP transfers.
            # tftp-no-blocksize                 # Disable the TFTP blocksize extension.
            # tftp-lowercase                    # Convert TFTP filenames to lowercase
            # tftp-port-range=<start>,<end>     # Ephemeral port range for use by TFTP transfers.

            local-service

            # port=0
            #interface=eth0
            interface=enp0s25
            dhcp-no-override
            dhcp-script=/bin/echo

            dhcp-boot=pxelinux.0
            dhcp-range=tag:piserver,${HOST_IP},proxy
            pxe-service=tag:piserver,0,"Raspberry Pi Boot"
            dhcp-reply-delay=tag:piserver,1

            dhcp-host=b8:27:eb:c7:e3:28,set:piserver
            ## Headless Pi3
            dhcp-host=b8:27:eb:d0:2e:74,set:piserver
            # Pi4
            dhcp-host=dc:a6:32:66:0a:2c,set:piserver
            # CM3+
            dhcp-host=b8:27:eb:e6:06:53,set:piserver
            # CM4
            dhcp-host=dc:a6:32:da:04:2d,set:piserver
            dhcp-host=e4:5f:01:1f:b7:4e,set:piserver
EOF
        ${SUDO} service dnsmasq start
    fi
}

remove_dphys-swapfile() {
    if [ -h ${ROOT_FS}/etc/systemd/system/multi-user.target.wants/dphys-swapfile.service ];then
        ${SUDO} rm ${ROOT_FS}/etc/systemd/system/multi-user.target.wants/dphys-swapfile.service
        for (( i=2;i<=5;i++ ))
        do
            [ -h ${ROOT_FS}/etc/rc$i.d/S01dphys-swapfile ] && ${SUDO} rm -f ${ROOT_FS}/etc/rc$i.d/S01dphys-swapfile
        done

        if [ ${OVERLAY} == 2 ]; then
                rm -f ${ROOT_FS}/etc/init.d/apply_noobs_os_config \
                ${ROOT_FS}/etc/rc2.d/S01apply_noobs_os_config \
                ${ROOT_FS}/etc/init.d/resize2fs_once \
                ${ROOT_FS}/etc/rc3.d/resize2fs_once \
                ${ROOT_FS}/etc/systemd/system/multi-user.target.wants/regenerate_ssh_host_keys.service
        fi
    fi
}

enable_ssh() {
    if [ ! -h ${ROOT_FS}/etc/systemd/system/multi-user.target.wants/ssh.service ]; then
        ${SUDO} ln -s /lib/systemd/system/ssh.service ${ROOT_FS}/etc/systemd/system/multi-user.target.wants/ssh.service
        [ VERBOSE == 1 ] && echo ":: SSH Enabled"
    fi
}

create_ssh_keypair() {
    HOSTNAME=$(hostname -s) 
    # SUDO=sudo OT_FS=/nfs/root ID=pi
    if [ ${OVERLAY} == 1 ]; then
        #local ROOT_FS=${UPPER_DIR}/data
        echo "KapdBe!"
    fi
        ${SUDO} mkdir -pv -m 700 ${ROOT_FS}/home/${ID}/.ssh
        ${SUDO} chown -R 1000:1000 ${ROOT_FS}/home/${ID}
        [ -f ~/.ssh/testkey@${HOSTNAME} ] || ${SUDO} ssh-keygen -q -N Pepe374189 -C testKey -f ~/.ssh/testkey@${HOSTNAME}
        ${SUDO} cat ~/.ssh/testkey@${HOSTNAME}.pub | sudo tee ${ROOT_FS}/home/${ID}/.ssh/authorized_keys 1>/dev/null
        ${SUDO} chmod 600 ${ROOT_FS}/home/${ID}/.ssh/authorized_keys
        ${SUDO} chown 1000:1000 ${ROOT_FS}/home/${ID}/.ssh/authorized_keys

    if [ ${OVERLAY} == 2 ]; then
        ${SUDO} cp -a /etc/timezone "${ROOT_FS}/etc"
        ${SUDO} cp -a /etc/localtime "${ROOT_FS}/etc"
        #fi
        #if [ -d "${ROOT_FS}/etc/default" ]; then
            ${SUDO} cp -a /etc/default/keyboard "${ROOT_FS}/etc/default"
        #fi
        #if [ -d "${ROOT_FS}/etc/console-setup" ]; then
            ${SUDO} cp -a /etc/console-setup/cached* "${ROOT_FS}/etc/console-setup"
    fi
}

enable_inet_for_usbboot() {
    SUDO=sudo
    ROOT_FS=/nfs/root
    IFACE_USB=usb0
    IFACE_INET=enp0s25
    INSTALL=1
    #AP_IP=10.42.0.14
    #local 
    append_or_del="-A"
    [ "$INSTALL" == 1 ] || append_or_del="-D" && echo $append_or_del
    echo ${INSTALL} | ${SUDO} tee /proc/sys/net/ipv4/ip_forward > /dev/null
    ${SUDO} iptables -t nat ${append_or_del} POSTROUTING -o ${IFACE_INET} -j MASQUERADE
    ${SUDO} iptables ${append_or_del} FORWARD -i ${IFACE_USB} -o ${IFACE_INET} -j ACCEPT
    ${SUDO} iptables ${append_or_del} FORWARD -i ${IFACE_INET} -o ${IFACE_USB} -j ACCEPT
}

prepareDhcpcd() {
    if [ ${PI0} == 1 ]; then
    CLIENT_IFACE=usb0   # if PI0 OTG
    ${SUDO} sed -i '/PxeServer/d' ${ROOT_FS}/etc/dhcpcd.conf
    # delete all trailing blank lines at end of file
    ${SUDO} sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' ${ROOT_FS}/etc/dhcpcd.conf
    cat << EOF | sed 's/^.\{8\}//'| ${SUDO} tee -a ${ROOT_FS}/etc/dhcpcd.conf

        ## Enable inet for OTG ethernet (PxeServer)
        interface ${CLIENT_IFACE}           #PxeServer
        static ip_address=${${CLIENT_IP}}   #PxeServer
        static routers=${SERVER_IP}         #PxeServer
EOF
    fi
    if [ ${EXEC_ON_PI0} == 1 ]; then
        ${SUDO} service dhcpcd restart
    fi
}

startRpiBoot() {
    RPIBOOT_DIR=/mnt/LinuxData/OF/GitHub/usbboot
    if [ ! -f ${BOOT_FS}/bootcode.bin.orig ]; then
        ${SUDO} mv ${BOOT_FS}/bootcode.bin ${BOOT_FS}/bootcode.bin.orig
    fi
    ${SUDO} cp -v ${RPIBOOT_DIR}/msd/bootcode.bin ${BOOT_FS}/bootcode.bin
    #${SUDO} curl -LJ https://github.com/raspberrypi/firmware/raw/master/boot/bootcode.bin -o ${RPI_BOOT_FS}/bootcode.bin
    gnome-terminal -t TITLE --wait -- ${SUDO} ${RPIBOOT_DIR}/rpiboot -d ${BOOT_FS} -v -l -o &
}

cleanUp() {
    ${SUDO} pkill rpiboot
    ${SUDO} pkill dnsmasq
    ${SUDO} service 'dnsmasq' stop
    ${SUDO} service 'nfs-kernel-server' stop

    #sudo ln -s ../init.d/resize2fs_once ${ROOT_FS}/etc/rc3.d/S01resize2fs_once
    ## vnc-server:
    #sudo ln -s /usr/lib/systemd/system/vncserver-x11-serviced.service /etc/systemd/system/multi-user.target.wants/vncserver-x11-serviced.service
    #sudo ln -s /lib/systemd/system/triggerhappy.service /etc/systemd/system/multi-user.target.wants/triggerhappy.service
    if [ -f ${ROOT_FS}/etc/fstab.orig ]; then
        ${SUDO} mv ${ROOT_FS}/etc/fstab.orig ${ROOT_FS}/etc/fstab
    fi
    sync
    if `mountpoint ${BOOT_FS}/mnt/LinuxData/OF 1>/dev/null`; then
        ${SUDO} umount -lv ${BOOT_FS}/mnt/LinuxData/OF
    fi
    ${SUDO} umount -lv ${BOOT_FS}

    ${SUDO} umount -lv ${ROOT_FS}

    if [ ${OVERLAY} == 1 ]; then
        ${SUDO} umount -lv ${RPI_ROOT_FS}
        ${SUDO} rm -R ${RPI_ROOT_FS}
        if res=$(zenity --question --text="remove ${UPPER_DIR}?" --display=${DISPLAY}); then
            echo "removing ${UPPER_DIR} ..."
            ${SUDO} rm -R ${UPPER_DIR}
        fi

    fi

    if [ "${LOOP_DEVICE}" ]; then
        ${SUDO} losetup -d $LOOP_DEVICE || echo "hopp!!!!!!!!!!!!!!!!"
    fi
    ${SUDO} rm -R ${ROOT_FS} #${BOOT_FS}


    ${SUDO} sed -i '/PxeServer/d' /etc/exports

    ${SUDO} rm /etc/dnsmasq.d/nfsBoot.conf || true
    ${SUDO} service 'nfs-kernel-server' restart
    #else
        # CleanUp variabels
        # NFS_VERS=4
        #IMG_FOLDER=/mnt/LinuxData/Install/img
        # OVERLAY=0
        # HOST_IP=$(echo $(hostname -I) | sed 's/ .*//')
        # NFS_ROOT=/nfs
        # TEMP=/tmp

        # [ $OVERLAY == 1 ] && OVERLAY_FS_ROOT=${NFS_ROOT}/root && NFS_ROOT=/tmp


        # ROOT_FS=${NFS_ROOT}/root
        # BOOT_FS=${NFS_ROOT}/boot

        # RPI_ROOT_FS=${ROOT_FS}

        # BOOT_FS=${ROOT_FS}/boot
        if [ $OVERLAY == 1 ]; then
            RPI_ROOT_FS=${TEMP}/root
            UPPER_DIR=${TEMP}/upper
        fi

        # serials="b0c7e328 dc:a6:32:66:0a:2c"
        echo "Sourced CleanUp happend!!!"
# fi
#        exit
}

runNfsBoot() {
    # check_root //movedToRoot!
    check_dependency
    getImg
    #resizeImage
    mountImage
    detectOS
    prepare_cmdline
    prepare_fstab
    remove_dphys-swapfile
    #hack
    # setup options
    enable_ssh
    create_ssh_keypair
    #createInitramfs
    #prepareDhcpcd

    # ${SUDO} rm -f ${ROOT_FS}/etc/rc3.d/S01resize2fs_once
    # ${SUDO} rm -f ${ROOT_FS}/etc/systemd/system/multi-user.target.wants/triggerhappy.service
    #exit

    configure_nfs
    configure_dnsmasq

    ${SUDO} service rpcbind restart
    ${SUDO} service nfs-kernel-server restart
    # ${SUDO} service dnsmasq restart
    #startRpiBoot
    trap 'echo "SIGINT traped"' INT

    while ! res=$(zenity --question --text="Close the NFSbootserver?" --extra-button="Save img" --extra-button="KeepRun" --display=${DISPLAY})
    do
        echo $res
        if [ "${res}" == "Save img" ];then
            if res=$(zenity --entry --text="Save img to different name" --entry-text=${IMG} --display=${DISPLAY}); then
                echo "Save ${IMG} at different name: ${res}..."
                ${SUDO} mv -v ${IMG} ${res}
            fi
            exit
        elif [ "${res}" == "KeepRun" ];then
            export -f cleanUp
            trap 'echo "EXITED NORMAL"' EXIT
            echo "Type 'cleanUp' to cleanUp!!!"
            break
        elif [ "${res}" == "ok" ];then
            echo "Type 'OK!!!!!!!!!!!!!!!!' to ${res}!!!"
        else cleanUp
        fi    
        echo "sleeping..."
        sleep 10
    done
}
#fi

check_root
[ "${BASH_SOURCE}" == "${0}" ] && runNfsBoot
exit

unmount_image(){
	sync
	sleep 1
	local LOOP_DEVICES
	LOOP_DEVICES=$(losetup --list | grep "$(basename "${1}")" | cut -f1 -d' ')
	for LOOP_DEV in ${LOOP_DEVICES}; do
		if [ -n "${LOOP_DEV}" ]; then
			local MOUNTED_DIR
			MOUNTED_DIR=$(mount | grep "$(basename "${LOOP_DEV}")" | head -n 1 | cut -f 3 -d ' ')
			if [ -n "${MOUNTED_DIR}" ] && [ "${MOUNTED_DIR}" != "/" ]; then
				unmount "$(dirname "${MOUNTED_DIR}")"
			fi
			sleep 1
			losetup -d "${LOOP_DEV}"
		fi
	done
}
export -f unmount_image

# export DISPLAY=192.168.1.10:0
    # export LIBGL_ALWAYS_INDIRECT=1

    #:
    #tail -F /nfs/root/var/log/syslog | grep "unsafe path transition"
    # sudo apt install ttf-mscorefonts-installer && sudo fc-cache -fv
    # /sys/fs/cgroup/systemd/system.slice/triggerhappy.socket
    # rc2-5 /nfs/root/etc/rc3.d/S01dphys-swapfile -> ../init.d/dphys-swapfile
    # sudo rm /nfs/root/etc/systemd/system/multi-user.target.wants/dphys-swapfile.service
    # sudo ln -s /dev/null /nfs/root/etc/systemd/system/multi-user.target.wants/dphys-swapfile.service
    # sudo ln -s  /lib/systemd/system/dphys-swapfile.service /nfs/root/etc/systemd/system/multi-user.target.wants/dphys-swapfile.service
    # sudo ln -s /lib/systemd/system/ssh.service /nfs/root/etc/systemd/system/multi-user.target.wants/ssh.service
    # sudo ln -s /usr/share/zoneinfo/America/New_York /etc/localtime

    # /nfs/boot/config.txt
    # /nfs/boot/start.elf
    # /nfs/boot/fixup.dat
    # /nfs/boot/cmdline.txt
    # /nfs/boot/bcm2710-rpi-3-b.dtb
    # /nfs/boot/kernel7.img

    #sudo curl https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/start.elf -o /nfs/boot/start.elf

    ## To find out which processes are accessing the NFS share, use the fuser command:
    # fuser -m MOUNT_POINT

    ## piserver dnsmasq
    ### This is an auto-generated file. DO NOT EDIT

    #bind-dynamic
    #log-dhcp
    #enable-tftp
    #tftp-root=/var/lib/piserver/tftproot
    #tftp-unique-root=mac
    #local-service
    #host-record=piserver,192.168.0.53
    #dhcp-range=tag:piserver,192.168.0.53,proxy
    #pxe-service=tag:piserver,0,"Raspberry Pi Boot"
    #dhcp-reply-delay=tag:piserver,1

    #dhcp-host=b8:27:eb:c7:e3:28,set:piserver
    #dhcp-host=b8:27:eb:d0:2e:74,set:piserver

    ## sudo apt install libfreeimage3 libboost-filesystem1.67.0 libpugixml1v5 liburiparser1

    #wget https://github.com/raspberrypi/rpi-eeprom/raw/master/firmware/beta/pieeprom-2019-12-03.bin
    #rpi-eeprom-config pieeprom-2019-12-03.bin > bootconf.txt
    #sed -i s/0x1/0x21/g bootconf.txt
    #rpi-eeprom-config --out pieeprom-2019-12-03-netboot.bin --config bootconf.txt pieeprom-2019-12-03.bin
    #sudo rpi-eeprom-update -d -f ./pieeprom-2019-12-03-netboot.bin
    #cat /proc/cpuinfo

    # ROOT_FS=/nfs/root sed -i 's/^exit 0/service ssh start || printf "Could not start ssh service"\n\nexit 0/' ${ROOT_FS}/etc/rc.local

    # piserver:: /var/lib/piserver/os/Raspbian_Full-2019-09-26/etc/fstab

    # curl https://gist.githubusercontent.com/paul-ridgway/d39cbb30530442dca416734c3ee70162/raw/c490df8be1976dd062a8b5f429ef42ed1b393ecb/ro-root.sh -o ${ROOT_FS}/bin/ro-root.sh

    # service systemd-timesyncd status systemd-remount-fs.service
    # 


    # ssh pwd warning: /run/sshwarn + /etc/xdg/lxsession/LXDE-pi/sshpwd.sh  remove with sudo apt purge ppromt

pepe() {
    # remove previous modifications
    ${SUDO} sed -i '/PxeServer/d' ${BOOT_FS}/config.txt
    # delete all trailing blank lines at end of file
    ${SUDO} sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' ${BOOT_FS}/config.txt
    echo "cmdline=netboot.txt   # PxeServer" | ${SUDO} tee -a ${BOOT_FS}/config.txt
}

remove_unused() {
    ${SUDO} apt -q update
    # BusterFull all:
    ${SUDO} apt purge -y python-games mu-editor minecraft-pi piwiz scratch* wolfram* claws-mail libreoffice* \
    geany* greenfoot-unbundled nodered bluej realvnc-vnc-viewer thonny sonic-pi*
    ## Hold or Exclude Packages:
    ${SUDO} apt-mark hold raspberrypi-ui-mods
    ${SUDO} apt-mark manual fonts-piboto # prevent autoremove
    ## List Packages on Hold
    # sudo dpkg --get-selections | grep "hold"
    ## Unhold or Include Package in Install
    # sudo apt-mark unhold package_name
    ${SUDO} apt upgrade -y && ${SUDO} apt autoremove -y && ${SUDO} apt autoclean && ${SUDO} apt clean
    ## BorsiNew
    ${SUDO} apt purge -y pi-bluetooth rp-prefapps thonny rp-bookshelf
}

prepare_wpa_supplicant() {
    ${SUDO} bash -c "cat > ${ROOT_FS}/etc/wpa_supplicant/wpa_supplicant.conf" << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=HU

network={
    ssid="Telekom-rFqy6B"
    psk="5u1jm7eh2d8g"
}
EOF
# start new settings
}

#${ROOT_FS}/usr/share/initramfs-tools
# ${ROOT_FS}/etc/initramfs-tools/scripts/overlay
## /etc/initramfs-tools/initramfs.conf: DEVICE=usb0 NFSROOT=10.42.0.1:/nfs/root MODULES=netboot
prepare_initramfs() {
    # add the overlay(fs) to the list of modules
    local modules='overlay'
    ## modules needed by usb-boot
    modules+='  g_ether libcomposite u_ether udc-core usb_f_rndis usb_f_ecm'
    for m in $modules
        do
            if ! grep $m /etc/initramfs-tools/modules > /dev/null; then
                echo $m |  ${SUDO} tee -a ${ROOT_FS}/etc/initramfs-tools/modules
                echo "added $m to modules"
            fi
        done
    ${SUDO} update-initramfs -c -k $(echo $(uname -r) | sed 's/-v7//')
}

usbboot() {
    ${SUDO} /mnt/LinuxData/OF/usbboot/rpiboot -l -o -d ${BOOT_FS}
}

## kali fstab
# mount -t tmpfs tmpfs /var/log/journal -o defaults,mode=755
# echo dtoverlay=dwc2,dr_mode=host | sudo tee /boot/config.txt # RaspberryPi IO board !!!

installUbuntu() {
    #IMG=/mnt/LinuxData/OF/ubuntu-20.04.2-preinstalled-server-arm64+raspi.img
    if ! IMG=$(zenity --file-selection --file-filter="*.img *.zip *.ISO *.gz" --filename="${IMG_FOLDER}/ubuntu-20.04.2-preinstalled-server-arm64+raspi.img" 2>/dev/null); then
    # sudo dd if=${IMG} bs=4M of=/dev/mmcblk0 bs=10MB
    xzcat ${IMG} | pv -s 2G  | ${SUDO} dd bs=4M of=/dev/mmcblk0
    # xzcat ${IMG} | ${SUDO} dd bs=4M of=/dev/mmcblk0
    fi
}
    # rasbian bootorder:
    # sed -i '/CM4_ENABLE_RPI_EEPROM_UPDATE=1/!d' /etc/default/rpi-eeprom-update
    # echo "CM4_ENABLE_RPI_EEPROM_UPDATE=1" | sudo tee -a /etc/default/rpi-eeprom-update

    # CM4_ENABLE_RPI_EEPROM_UPDATE=1 sudo -E rpi-eeprom-config --edit

hack() {
    # ${SUDO} mkdir -m 755 boot.bak
    files="bootcode.bin \
           start.elf \
           bcm2710-rpi-3-b.dtb \
           fixup.dat"

    files4="bootcode.bin \
            start4.elf \
            bcm2711-rpi-4-b.dtb \
            fixup4.dat"
    for file in  $files #$files4
    do
        ${SUDO} curl https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/${file} -o ${BOOT_FS}/${file} 2>/dev/null
    done

}
