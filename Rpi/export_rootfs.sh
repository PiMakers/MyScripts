#!/bin/bash
set -e

check_root() {
if [ $EUID != 0 ]; then
	echo "this script must be run as root"
	echo ""
	echo "usage:"
	echo "sudo "$0
#	exit $exit_code
   exit 1
fi
}

install_dependencies() {
apt install nfs-kernel-server
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

do_exports() {
( [ -f /etc/exports ] && \
sudo sed -i '/192.168.0.13/d' /etc/exports
sudo bash -c 'echo -e "/\t\t\t192.168.0.13(rw,sync,no_subtree_check,no_root_squash,insecure)" >> /etc/exports' ) || echo "error writing exports" 
sudo service nfs-kernel-server restart
# sudo exportfs
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
do_exports
