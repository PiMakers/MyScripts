#!/bin/bash

SUDO=sudo
RPI_ROOT_FS=/nfs/root
# ${SUDO} mkdir -pv ${${RPI_ROOT_FS}}

export LC_ALL=C

xxX() {
VERBOSE=1
# PI_SERIAL=b0c7e328          # Raspberry Pi 3 Model B Rev 1.2 Main Dev:192.168.1.3
DEV_DIR=/mnt/LinuxData/OF
MYSCRIPTS_DIR=${DEV_DIR}/myGitHub/MyScripts
SCRIPT_NAME=${BASH_SOURCE[0]##*/}
SCRIPT_PATH=${BASH_SOURCE[0]%/*}
cd ${SCRIPT_PATH}
    SCRIPTS_LIST+=(
        ${MYSCRIPTS_DIR}/Rpi/Boot/nfsBoot.sh
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
}

makeOverlay() {
    cat << 'EOF' | ${SUDO} tee ${RPI_ROOT_FS}/usr/share/initramfs-tools/scripts/overlay >/dev/null
    # nfs filesystem mounting			-*- shell-script -*-

    #
    # This script overrides nfs_mount_root() in /scripts/nfs
    # and mounts root as a read-only filesystem with a temporary (rw) overlay filesystem.
    #

    if [ "$ROOT" == "/dev/nfs" ]; then
        BOOT=nfs   
        . /scripts/nfs

        nfs_mount_root() {
            log_begin_msg "================= Pepe nfs mount ================="

            nfs_top

            # For DHCP
            modprobe af_packet

            wait_for_udev 10

            # Default delay is around 180s
            delay=${ROOTDELAY:-180}

            # CHANGES TO THE ORIGINAL FUNCTION BEGIN HERE
            # N.B. this code still lacks error checking

            # Create directories for root and the overlay
            mkdir /lower /upper
    log_failure_msg "***************************************************** NFS4 start HERE:"
            
            modprobe sunrpc
            modprobe nfs
            modprobe nfsd
            modprobe nfsv4 || log_failure_msg "**************************************nfsv4"
            modprobe nfs_layout_nfsv41_files || log_failure_msg "********** nfs_layout_nfsv41_files"
            modprobe blocklayoutdriver || log_failure_msg "*****************nfsv4"
            modprobe nfs_layout_flexfiles || log_failure_msg "*****************nfsv4"
            modprobe nfs_acl
            modprobe grace
            
            # See if rpcbind is running
            if [ -x /usr/sbin/rpcinfo ]; then
                /usr/sbin/rpcinfo -p >/dev/null 2>&1
                RET=$?
                if [ $RET != 0 ]; then
                   echo
                   log_warning_msg "Not starting: portmapper is not running"
                   exit 0
                fi
            fi
            /sbin/rpc.statd || log_failure_msg "rpc.statd"
            [ -x /usr/sbin/rpc.idmapd ] ||  log_failure_msg "NEED_IDMAPD=no"
            [ -x /usr/sbin/rpc.gssd   ] ||  log_failure_msg "NEED_GSSD=no"

            mkdir -pv /run/rpc_pipefs
            
    log_failure_msg "***************************************************** NFS4 ended HERE:"
            
            # Mount read-only root to /lower
            orig_rootmnt=${rootmnt}
            rootmnt=/lower
            # loop until nfsmount succeeds
            nfs_mount_root_impl
            ret=$?
            echo "ret=$ret"
            nfs_retry_count=0
            while [ ${nfs_retry_count} -lt "${delay}" ] \
                && [ $ret -ne 0 ] ; do
                [ "$quiet" != "y" ] log_begin_msg "Retrying nfs mount"
                sleep 1 || log_begin_msg "could not sleep"
                nfs_mount_root_impl
                ret=$?
                nfs_retry_count=$(( nfs_retry_count + 1 ))
                [ "$quiet" != "y" ] && log_end_msg
            done
                
            modprobe overlay || insmod "/lower/lib/modules/$(uname -r)/kernel/fs/overlayfs/overlay.ko" \
            || _log_msg " ================= CANNOT MODPROBE OVERLAY ================= "
                
            # Mount a tmpfs for the overlay in /upper
            mount -t tmpfs tmpfs /upper
            mkdir /upper/data /upper/work
                
            # Mount the final overlay-root in $rootmnt
            rootmnt=${orig_rootmnt}
            mount -t overlay \
                -olowerdir=/lower,upperdir=/upper/data,workdir=/upper/work \
                overlay ${rootmnt}
            log_end_msg "================= Booted with overlayfs =========================="
        }

    elif [ $BOOT == "overlay" ]; then
        BOOT=local    
    
        # Local filesystem mounting			-*- shell-script -*-

        #
        # This script overrides local_mount_root() in /scripts/local
        # and mounts root as a read-only filesystem with a temporary (rw)
        # overlay filesystem.
        #

        . /scripts/local

        local_mount_root() {
            local_top
            local_device_setup "${ROOT}" "root file system"
            ROOT="${DEV}"

            # Get the root filesystem type if not set
            if [ -z "${ROOTFSTYPE}" ]; then
                FSTYPE=$(get_fstype "${ROOT}")
            else
                FSTYPE=${ROOTFSTYPE}
            fi

            local_premount

            # CHANGES TO THE ORIGINAL FUNCTION BEGIN HERE
            # N.B. this code still lacks error checking

            modprobe ${FSTYPE}
            checkfs ${ROOT} root "${FSTYPE}"

            # Create directories for root and the overlay
            mkdir /lower /upper

            # Mount read-only root to /lower
            if [ "${FSTYPE}" != "unknown" ]; then
                mount -r -t ${FSTYPE} ${ROOTFLAGS} ${ROOT} /lower
            else
                mount -r ${ROOTFLAGS} ${ROOT} /lower
            fi

            modprobe overlay || insmod "/lower/lib/modules/$(uname -r)/kernel/fs/overlayfs/overlay.ko"

            # Mount a tmpfs for the overlay in /upper
            mount -t tmpfs tmpfs /upper
            mkdir /upper/data /upper/work

            # Mount the final overlay-root in $rootmnt
            mount -t overlay \
                -olowerdir=/lower,upperdir=/upper/data,workdir=/upper/work \
                overlay ${rootmnt}
        }

        [ "$ROOT" == "/dev/nfs" ] && BOOT=nfs || BOOT=local
        log_end_msg "================= BOOT = ${BOOT} =========================="
    fi

    log_end_msg "================= BOOT = ${BOOT} =========================="
EOF
}

createInitramfs() {
        
        cat << EOF | ${SUDO} tee /usr/share/initramfs-tools/conf-hooks.d/netboot.conf
            MODULES=netboot
EOF


        ## modules needed by overlayfs, usb-boot (open-iscsi added while installed) 13463858
        modules=(overlay)
        ## modules needed by usb-boot:
        modules+=(g_ether)
        modules+=(libcomposite)
        modules+=(u_ether)
        modules+=(udc-core)
        modules+=(usb_f_rndis)
        modules+=(usb_f_ecm)
        #nfsv4
        modules+=(rpcsec_gss_krb5)
        modules+=(blocklayoutdriver)
        modules+=(nfs_layout_flexfiles)

        for m in ${modules[@]}
            do
                if ! $(grep -q $m ${RPI_ROOT_FS}/etc/initramfs-tools/modules); then
                    echo $m | ${SUDO} tee -a ${RPI_ROOT_FS}/etc/initramfs-tools/modules 1>/dev/null
                    echo "added $m to modules"
                fi
            done        

        ${SUDO} chroot ${RPI_ROOT_FS} update-initramfs -v -c -k 5.4.51+
}

runOverlayNfs() {
    makeOverlay
    createInitramfs
    CMDLINE=$(sed '/include /!d; s/include //' ${RPI_ROOT_FS}/boot/config.txt)
    #sed '/cmdline=/!d' ${RPI_ROOT_FS}/boot/${CMDLINE}
    CMDLINE=$(sed '/cmdline=/!d; s/cmdline=//' ${RPI_ROOT_FS}/boot/${CMDLINE})
    # echo "${CMDLINE##* }" 
    sudo mkdir -pv ${RPI_ROOT_FS}/run
    sed '/^[a-z]/!d' ${RPI_ROOT_FS}/boot/${CMDLINE##* } | sudo tee ${RPI_ROOT_FS}/run/cmdline
    [ "x$1" == "x1" ] && sed 's/^boot=overlay //' ${RPI_ROOT_FS}/boot/${CMDLINE##* } || sed 's/^/boot=overlay /' ${RPI_ROOT_FS}/boot/${CMDLINE##* }

}

[ "${BASH_SOURCE}" == "${0}" ] && runOverlayNfs