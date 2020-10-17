#!/bin/bash

pharseCmdline() {
    local BOOT_FS=/nfs/root/boot
    CMDLINE=`cat ${BOOT_FS}/cmdline.txt`
    NEW_CMDLINE=
    for m in ${CMDLINE[@]}
        do
            case $m in
                root=*)
                    if [ $m != "root=/dev/nfs" ]; then 
                        m='root=/dev/nfs nfsroot=192.168.1.18:/root rw ip=:::255.255.255.0:pi::dhcp'
                    fi
                    ;;
                *)
                    echo "Other founds: $m" 
                    ;;
            esac
            NEW_CMDLINE+=" $m"
            echo "NEW_CMDLINE = ${NEW_CMDLINE[@]}"
        done
    # echo "NEW_CMDLINE =${NEW_CMDLINE[@]# }"
    echo "${NEW_CMDLINE[@]# }" | sudo tee ${BOOT_FS}/cmdline.nfsboot.eth0
}

pharseCmdline