#!/bin/bash
# set -e

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
            exit 1
        fi
    fi
}

install_dependencies() {
  ${SUDO} apt install -y nfs-kernel-server nfs-common
}

is_ssh() {
  if pstree -p | egrep --quiet --extended-regexp ".*sshd.*\($$\)"; then
	echo "throught_ssh"    
	return 0
  else
	echo "live (no_ssh)"
	return 1
  fi
}

export_rootfs() {
  [ -z "$1" ] && NFS_CIENT="*" ||  NFS_CIENT="$1" # "192.168.0.87" # PiTopDev.local
  if [ -f /etc/exports ]; then 
    ${SUDOE} sed -i "/${NFS_CIENT}/d" /etc/exports
    ${SUDOE} bash -c 'echo -e "/\t\t\t${NFS_CIENT}(rw,sync,no_subtree_check,no_root_squash,insecure)" >> /etc/exports'
  else  
    echo "error writing exports" 
  fi
  #${SUDO} service nfs-kernel-server restart
  # sudo exportfs
}

mount_nfs() {
  [ -z "$1" ] && NFS_HOST="NUC.local" ||  NFS_HOST="$1" # "192.168.0.87" # PiTopDev.local
  # manual:
  # ${SUDO} mount -o hard,nolock  ${NFS_HOST}:/mnt/LinuxData /mnt/LinuxData
  # auto (fstab)
  # showmount -e ${HOST}
  ${SUDOE} bash -c 'echo -e "\n${NFS_HOST}:/mnt/LinuxData /mnt/LinuxData nfs   _netdev,auto   0   0   #PiMakers" >> /etc/fstab'
}


setup() {
  check_root
  install_dependencies
  export_rootfs ${NFS_CIENT}
  mount_nfs ${NFS_HOST}
}

setup