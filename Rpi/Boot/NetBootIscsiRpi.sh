## https://tech.xlab.si/blog/pxe-bsudo nano oot-raspberry-pi-iscsi/#fnref:1
################ Diskless Boot for a Raspberry Pi over PXE and iSCSI ################

## Pi
ssh() {
  ssh-keygen -t ed25519 -C raspi-mgmt -N "" -f raspi-mgmt
  ROOT_PUBKEY="$(cat raspi-mgmt.pub)"

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

GetSerialNo() {
  grep '^Serial' /proc/cpuinfo | cut -d ':' -f 2 | sed -E 's/ +0+(.*)/\1/'
}

  PXEDHCPproxyAndTFTPserver() {
    
    NETWORK_SUBNET=${NETWORK_SUBNET:-"192.168.1.18"}
    TFTP_ROOT=${TFTP_ROOT:-"/tftpboot"}
    #${SUDO} apt install targetcli-fb dnsmasq
    #${SUDO} targetcli /iscsi create "$TARGET_IQN"
    #${SUDO} targetcli saveconfig
    #mkdir -p /tftpboot/

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

  sudo systemctl enable dnsmasq
  sudo service dnsmasq restart
  
  zenity --question #--display=192.168.1.10:0
  sudo service dnsmasq stop
  sudo rm /etc/dnsmasq.d/proxydhcp.conf

}


########################################
# https://www.howtoforge.com/how-to-setup-iscsi-storage-server-on-ubuntu-1804/

setvars() {
  ISCSI_TARGET_IP=192.168.1.10
  ISCSI_INITIATOR_IP=192.168.1.18
  INCOMING_USER_NAME=iscsi-user
  INCOMING_USER_PWD=password
  OUTGOING_USER_NAME=iscsi-target
  OUTGOING_USER_PWD=secretpass
  SUDO=sudo
}

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