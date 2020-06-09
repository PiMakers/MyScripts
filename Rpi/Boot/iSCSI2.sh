## https://$(uname -n).com/iscsi_storage_server_ubuntu/
## https://www.howtoforge.com/how-to-setup-iscsi-storage-server-on-ubuntu-1804/
## iSCSI Naming and Discovery: https://tools.ietf.org/html/rfc3721

set +e
trap 'KILL -HUP ($jobs -p)' HUP

# if sourced, exit with "return"
exit() {
    trap "echo FuckYou!!!" EXIT
    trap "echo FuckYouToo" RETURN
    [ "${BASH_SOURCE}" == "${0}" ] || EXIT_CMD=return && echo "EXIT_CMD=${EXIT_CMD}" 
    cleanUp
    kill -2 $$
}

install_dependencies() {
    sudo apt update
    sudo apt install -y \
        tgt \
        binfmt-support \
        qemu-user-static \
        zenity
}

SUDO=sudo
iSCSI_ROOT=/iscsi
RPI_IMG_DIR=$iSCSI_ROOT
RPI_ROOT_FS=/tmp/rpi/root
RPI_BOOT_FS=${RPI_ROOT_FS}/boot
IMG=/mnt/LinuxData/OF/img/2020-05-27-raspios-buster-full-armhf.img

sudo mkdir -p ${iSCSI_ROOT}/blocks

get_img(){
    export DISPLAY=:0
    if ! IMG=$(zenity --file-selection --file-filter="*.img *.zip" --filename=${RPI_IMG_DIR}/2019-09-26-raspbian-buster-full-netboot.img 2>/dev/null); then
        # TODO download script
        echo $IMG
        if [ $(zenity --question --text="Download latest image?") ];then
            echo "Downloding latest image... (not implemented yet)"
            #RASPBIAN_TYPE=lite
        fi
        echo "No img selected. Exit"; exit 1
    else
        if [ ${IMG##*.}=="zip" ];then
            if [ ! -f ${IMG%.*}.img ];then
                sudo unzip $IMG -d ${iSCSI_ROOT}/blocks
            else
                sudo cp -v ${IMG%.*}.img ${iSCSI_ROOT}/blocks/
            fi
            IMG=${IMG%.*}.img
        else
            sudo mkdir -pv ${iSCSI_ROOT}/blocks
            sudo cp $IMG ${iSCSI_ROOT}/blocks/
        fi
    fi
}

mount_img() {
    sudo mkdir -pv ${RPI_BOOT_FS}
    export LOOP_DEVICE=$(sudo losetup --show -f -P ${iSCSI_ROOT}/blocks/${IMG##*/})
    sudo mount ${LOOP_DEVICE}p2 ${RPI_ROOT_FS}
    sudo mount ${LOOP_DEVICE}p1 ${RPI_BOOT_FS} 
}

#echo ${IMG##*/}
TARGET_IQN="iqn.$(date +%Y-%m).com.$(uname -n):rpis"
INITIATOR_IQN="iqn.$(date +%Y-%m).com.$(uname -n).initiator:rpi-blog"
ISCSI_TARGET_IP=$(echo $(hostname -I) | sed 's/ .*//')
ISCSI_TARGET_PORT=3260
PI_SERIAL=
CMD=/boot/sh.sh

chroot_sh() {
    cat << EOF | ${SUDO} tee ${RPI_ROOT_FS}${CMD}
    #!/bin/bash
    export LC_ALL=C
    apt update
    apt upgrade -y
    apt autoremove
    apt autoclean
    apt clean
    apt install -y open-iscsi
    PI_KERNEL_VERSION=\$(echo "\$(ls /lib/modules)" | sed '/v8+.*/!d')
    echo PI_KERNEL_VERSION=\${PI_KERNEL_VERSION}
    update-initramfs -v -k \${PI_KERNEL_VERSION} -c
    touch /boot/iscsi_cmdline.txt
    sed "s/quiet .*//;s/$/ip=::::raspi:eth0:dhcp ISCSI_INITIATOR=${INITIATOR_IQN} ISCSI_TARGET_NAME=$TARGET_IQN ISCSI_TARGET_IP=$ISCSI_TARGET_IP ISCSI_TARGET_PORT=${ISCSI_TARGET_PORT} rw/" \
    /boot/cmdline.txt | tee /boot/iscsi_cmdline.txt
    
    sed -i '/cmdline/d;/initramfs/d' /boot/iscsi_config.txt
    echo "initramfs initrd.img-\${PI_KERNEL_VERSION} followkernel" >> /boot/iscsi_config.txt
          
    echo "cmdline=iscsi_cmdline.txt" >> /boot/iscsi_config.txt

    sed -i '/include iscsi_config.txt/d' /boot/config.txt    
    echo "include iscsi_config.txt" >> /boot/config.txt
EOF
    sudo chmod +x ${RPI_ROOT_FS}${CMD}
}

# ip=<rpi ip>:<iscsi server ip>:<your router ip>:<rpi netmask>:<rpi hostname>:eth0:off
# iscsi_t_ip=<your iscsi server ip> iscsi_i=iqn.2016.03.localdomain.raspberrypi:openiscsi-initiator iscsi_t=iqn.2016.03.localdomain.myservername:raspberrypi rw root=/dev/ram0 init=/linuxrc rootfs=ext4 rootdev=UUID=aaaaa-bbbbb-ccccc-ddddd-eeeee-fffff elevator=deadline rootwait panic=15
prepare_img() {
    ARCH=$(dpkg --print-architecture)

    if [ -n "$XAUTHORITY" ]; then
    sudo cp "$XAUTHORITY" ${RPI_ROOT_FS}/root/Xauthority
    export XAUTHORITY=/root/Xauthority
    fi
    #sudo mount --bind /dev RPI_ROOT_FS/dev
    #sudo mount --bind /dev/devpts ${RPI_ROOT_FS}/dev/pts
    sudo mount --bind /proc ${RPI_ROOT_FS}/proc
    sudo mount --bind /sys ${RPI_ROOT_FS}/sys

    if [ "$ARCH" != "armhf" ]; then
        sudo which qemu-arm-static > /dev/null || { echo "qemu-arm-static command not found. Try: sudo apt-get install binfmt-support qemu-user-static"; exit 1; }                                                                                                                                                    
        sudo install -m 0755 /usr/bin/qemu-arm-static ${RPI_ROOT_FS}/usr/bin/qemu-arm-static
    fi    
    
    sudo chroot ${RPI_ROOT_FS} $CMD
    
    #sudo umount ${RPI_ROOT_FS}/dev/pts
    #sudo umount ${RPI_ROOT_FS}/dev
    sudo umount ${RPI_ROOT_FS}/proc
    sudo umount ${RPI_ROOT_FS}/sys

    sudo mv ${RPI_ROOT_FS}/etc/ld.so.preload.disabled ${RPI_ROOT_FS}/etc/ld.so.preload

    if [ -n "$XAUTHORITY" ]; then
        sudo rm -f "${RPI_ROOT_FS}/root/Xauthority"
    fi
}

create_iscsi_conf() {
    cat << EOF | sudo tee  /etc/tgt/conf.d/${TARGET_IQN}.conf
 <target ${TARGET_IQN}>
    backing-store ${iSCSI_ROOT}/blocks/${IMG##*/}
    # initiator-address ${ISCSI_INITIATOR_IP}
    initiator-address 192.168.1.3
    initiator-name ${INITIATOR_IQN}
    # incominguser $(uname -n) secret
    # outgoinguser
 </target>
EOF
    #sudo systemctl restart tgt
    sudo service tgt restart
    sudo tgtadm --lld iscsi --mode target --op show
}

PXEDHCPproxyAndTFTPserver() {
    export DISPLAY=:0
    #$ssh_cmd "sudo shutdown -now"
    sudo service dnsmasq stop
    #sudo rm /etc/dnsmasq.d/bootserver.conf

    NETWORK_SUBNET=${NETWORK_SUBNET:-"192.168.1.18"}
    TFTP_ROOT=${TFTP_ROOT:-"/tftpboot"}
    
    sudo rm -r ${TFTP_ROOT}
    sudo mkdir -p ${TFTP_ROOT}/${PI_SERIAL}
    sudo cp -r ${RPI_BOOT_FS}/* ${TFTP_ROOT} #/${PI_SERIAL}

    #sudo cp ${IMG} ${iSCSI_ROOT}/blocks/${IMG##*/}
    
    cat << EOF | sudo tee /etc/dnsmasq.d/proxydhcp.conf 
    port=0
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
  sudo service dnsmasq start
  
  if [ $(zenity --question --text="Close iSCSI server?") ];then # --display=:0
    sudo service dnsmasq stop
    sudo rm /etc/dnsmasq.d/proxydhcp.conf
  fi
}

# remove open-iscsi unloaded module
## sed 's/^ib_iser/#ib_iser/' /lib/modules-load.d/open-iscsi.conf

run() {
install_dependencies
get_img
mount_img
chroot_sh
prepare_img
create_iscsi_conf
PXEDHCPproxyAndTFTPserver
}