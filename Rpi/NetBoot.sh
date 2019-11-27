OnExportedFS:
cmdline.txt:

dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=192.168.0.14:/rootfs,vers=4.1,proto=tcp,port=2049 rw ip=dhcp elevator=deadline rootwait plymouth.ignore-serial-consoles

fstab:

192.168.0.14:/tftpboot /boot nfs4 defaults 0 2

Server:
# /etc/exports
/nfs 192.168.0.0/24(rw,fsid=0,sync,no_subtree_check,no_auth_nlm,insecure,no_root_squash)

#/etc/dnsmasq.d/bootserver.conf:
port=0
interface=eth0
dhcp-range=192.168.0.0,proxy,255.255.255.0
dhcp-script=/bin/echo
#pxe-service=x86PC, "PXE Boot Menu", pxelinux
dhcp-boot=pxelinux.0
enable-tftp
#tftp-root=/var/lib/tftpboot


log-dhcp
#enable-tftp
tftp-root=/nfs/tftpboot
pxe-service=0,"Raspberry Pi Boot"