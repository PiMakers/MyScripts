## https://tech.xlab.si/blog/pxe-boot-raspberry-pi-iscsi/#fnref:1
################ Diskless Boot for a Raspberry Pi over PXE and iSCSI ################

CustomisingRaspbian() {
  unzip "2019-04-08-raspbian-stretch-lite.zip"
  ssh-keygen -t ed25519 -C raspi-mgmt -N "" -f raspi-mgmt

  ROOT_PUBKEY="$(cat raspi-mgmt.pub)"
  IMAGE_FILE="2019-04-08-raspbian-stretch-lite.img"

  apt install kpartx
  creation_output="$(kpartx -asv "$IMAGE_FILE")"
  loop_device="$(echo "$creation_output" \
      | head -n 1 \
      | sed -E 's/add map (loop[0-9]+)p.*/\1/')"
  temp_dir="$(mktemp -d)"
  mount "/dev/mapper/${loop_device}p2" "$temp_dir"
  mount "/dev/mapper/${loop_device}p1" "$temp_dir/boot/"

  touch "$temp_dir/boot/ssh"
  mkdir -p "$temp_dir/root/.ssh/"
  echo "$ROOT_PUBKEY" >>"$temp_dir/root/.ssh/authorized_keys"
  sed -r -i \
      's/#?.*?PermitRootLogin.*?$/PermitRootLogin without-password/g' \
      "$temp_dir/etc/ssh/sshd_config"

  umount "$temp_dir/boot/"
  umount "$temp_dir"
  rmdir "$temp_dir"
  kpartx -dv "$IMAGE_FILE"
}

PreparingTheRaspberryPi() {
  IMAGE_FILE="2019-04-08-raspbian-stretch-lite.img"
  SD_CARD_DEVICE="/dev/sdX"
  pv "$IMAGE_FILE" | dd of="$SD_CARD_DEVICE" bs=4M conv=noerror,notrunc
}

GetSerialNo() {
  grep '^Serial' /proc/cpuinfo | cut -d ':' -f 2 | sed -E 's/ +0+(.*)/\1/'
}
CreatingTheISCSItarget() {

  PXEDHCPproxyAndTFTPserver() {
    TARGET_IQN="iqn.2019-08.si.xlab.blog:rpis"
    NETWORK_SUBNET="192.0.2.255"

    ${SUDO} apt install targetcli-fb dnsmasq
    ${SUDO} targetcli /iscsi create "$TARGET_IQN"
    ${SUDO} targetcli saveconfig
    mkdir -p /tftpboot/

    cat >/etc/dnsmasq.d/proxydhcp.conf << EOF
    port=0
    dhcp-range=$NETWORK_SUBNET,proxy
    log-dhcp
    log-queries
    enable-tftp
    tftp-root=/tftpboot
    pxe-service=0,"Raspberry Pi Boot   "
    pxe-prompt="Boot Raspberry Pi", 1
    dhcp-no-override
    dhcp-reply-delay=1
EOF

    systemctl enable dnsmasq
    systemctl restart dnsmasq
  }
}

# on Pi
ModifyingTheRaspbianInitrdForiSCSI() {
  STORAGE_MACHINE="192.168.1.18"

  apt install open-iscsi initramfs-tools
  touch /etc/iscsi/iscsi.initramfs
  update-initramfs -v -k "$(uname -r)" -c

  ssh "$STORAGE_MACHINE" mkdir -p /tmp/bootpart/
  scp -r /boot/ "$STORAGE_MACHINE:/tmp/bootpart/$(uname -r)/"
}

# on Storage Machine
MakingThePiBootFromTheNetwork() {
  RPI_SERIAL="b0c7e328"
  RPI_KERNEL_VERSION="4.19.97-v7+"
  TARGET_IQN="iqn.2019-08.si.xlab.blog:rpis"
  INITIATOR_IQN="iqn.2019-08.si.xlab.blog.initiator:rpi-blog"
  BACKSTORE_SIZE="16G"
  IMAGE_FILE="2019-04-08-raspbian-stretch-lite.img"
  STORAGE_MACHINE_IP="192.168.1.18"
  SUDO=sudo

  ${SUDO} apt install -y  kpartx pv
  ${SUDO} apt install targetcli-fb dnsmasq
  ${SUDO} targetcli /iscsi create "$TARGET_IQN"
  ${SUDO} targetcli saveconfig

  ${SUDO} mkdir -p "/tftpboot/$RPI_SERIAL/"
  ${SUDO} cp -r "/tmp/bootpart/$RPI_KERNEL_VERSION/"* "/tftpboot/$RPI_SERIAL/"
  ${SUDO} cp /tftpboot/$RPI_SERIAL/bootcode.bin /tftpboot/bootcode.bin
  # echo "initramfs initrd.img-$RPI_KERNEL_VERSION followkernel" | ${SUDO} tee -a \
  #  "/tftpboot/$RPI_SERIAL/config.txt"

  ${SUDO} targetcli /backstores/fileio create \
    "backstore-$RPI_SERIAL" \
    "/srv/backing-file-$RPI_SERIAL" \
    "$BACKSTORE_SIZE" \
    true \
    true
  ${SUDO} targetcli "/iscsi/${TARGET_IQN}/tpg1/luns" create \
    "/backstores/fileio/backstore-$RPI_SERIAL"
  ${SUDO} targetcli "/iscsi/${TARGET_IQN}/tpg1/acls" create \
    "$INITIATOR_IQN" \
    false
  ${SUDO} targetcli "/iscsi/$TARGET_IQN/tpg1/acls/${INITIATOR_IQN}" create \
    0 \
    "/backstores/fileio/backstore-$RPI_SERIAL"
  ${SUDO} targetcli saveconfig

  pv "$IMAGE_FILE" \
    | ${SUDO} dd of="" bs=4M conv=noerror,notrunc
}

create_cmdline.txt() {
  echo \
    dwc_otg.lpm_enable=0 \
    console=tty1 \
    rootfstype=ext4 \
    elevator=deadline \
    fsck.repair=yes \
    rootwait \
    ip=::::rpi-blog:eth0:dhcp \
    root=UUID=$root_part_uuid \
    ISCSI_INITIATOR=$INITIATOR_IQN \
    "ISCSI_TARGET_NAME=$TARGET_IQN" \
    "ISCSI_TARGET_IP=$STORAGE_MACHINE_IP" \
    ISCSI_TARGET_PORT=3260 \
    rw \
>"/tftpboot/$RPI_SERIAL/iscsi_cmdline.txt"
}

########################################
########################################
# https://www.howtoforge.com/how-to-setup-iscsi-storage-server-on-ubuntu-1804/

ISCSI_TARGET_IP=192.168.1.10
ISCSI_INITIATOR_IP=192.168.1.18
INCOMING_USER_NAME=iscsi-user
INCOMING_USER_PWD=password
OUTGOING_USER_NAME=iscsi-target
OUTGOING_USER_PWD=secretpass
SUDO=sudo


Configure_iSCSI_Target() {
  echo \
  "<target iqn.2019-11.example.com:lun1>
    # Provided device as an iSCSI target
    backing-store /dev/sdb1                             
    initiator-address ${ISCSI_INITIATOR_IP}
    initiator-name iqn.2019-11.example.com:initiator01
    incominguser  ${INCOMING_USER_NAME} ${INCOMING_USER_PWD}
    outgoinguser ${OUTGOING_USER_NAME} ${OUTGOING_USER_PWD}
  </target>" | ${SUDO} tee  /etc/tgt/conf.d/iscsi.conf
  ${SUDO} service tgt restart
}

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