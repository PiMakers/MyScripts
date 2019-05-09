#!/bin/bash
set -e

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
${SUDO} apt -y autoremove
${SUDO} apt autoclean
${SUDO} apt clean
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
( [ -f /etc/exports ] && \
${SUDO} sed -i '/NUC.local/d' /etc/exports && \
${SUDO} bash -c 'echo -e "/\t\t\tNUC.local(rw,sync,no_subtree_check,no_root_squash,insecure)" >> /etc/exports' ) || echo "error writing exports" 
${SUDO} service nfs-kernel-server restart
# sudo exportfs
}

mount_nfs() {
# manual:
${SUDO} mount -o hard,nolock  NUC.local:/mnt/LinuxData /mnt/LinuxData
# auto (fstab)
# showmount -e ${HOST}
# ${SUDO} bash -c 'echo NUC.local:/mnt/LinuxData /mnt/LinuxData nfs   _netdev,auto   0   0'

}

relativeSoftLinks(){
    for link in $(ls -la | grep "\-> /" | sed "s/.* \([^ ]*\) \-> \/\(.*\)/\1->\/\2/g"); do 
        lib=$(echo $link | sed "s/\(.*\)\->\(.*\)/\1/g"); 
        link=$(echo $link | sed "s/\(.*\)\->\(.*\)/\2/g"); 
        rm $lib
        ln -s ../../..$link $lib 
    done

    for f in *; do 
        error=$(grep " \/lib/" $f > /dev/null 2>&1; echo $?) 
        if [ $error -eq 0 ]; then 
            sed -i "s/ \/lib/ ..\/..\/..\/lib/g" $f
            sed -i "s/ \/usr/ ..\/..\/..\/usr/g" $f
        fi
    done
}

check_root
install_dependencies
export_rootfs
mount_nfs
