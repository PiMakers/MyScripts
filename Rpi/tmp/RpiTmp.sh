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


iSCSI_add() {
    
    local DRIVER=iscsi
    local ID=3
    local LUN=1 #!!! get next available
    local TGT_PATH=$1
    TGT_PATH=${TGT_PATH:-"/mnt/LinuxData/iscsi/blocks/2020-08-20-raspios-buster-armhf-lite.img"}  # path to img
    local BSTYPE=                                                                    # bstype option is optional.
    local BSOPTS=                                                                    # bsopts are specific to the bstype.
    local BSOFLAGS=        #bsoflags supported options are sync and direct (sync:direct for both).

    [ -z ${BSTYPE} ] || local BSTYPE="--bstype ${BSTYPE}"
    [ -z ${BSOPTS} ] || local BSTYPE="--bstype ${BSOPTS}"
    [ -z ${BSOPTS} ] || local BSTYPE="--bstype ${BSOPTS}"

    CMD="tgtadm --lld ${DRIVER} --mode logicalunit --op new --tid ${ID} --lun ${LUN} --backing-store ${TGT_PATH} ${BSTYPE} ${BSOPTS} ${BSOFLAGS}"
    # --lld ${DRIVER} --mode logicalunit --op new --tid ${ID} --lun ${LUN} --backing-store ${TGT_PATH} --bstype ${BSTYPE} --bsopts ${BSOPTS} --bsoflags ${BSOFLAGS}
    #sudo tgtadm --lld ${DRIVER} --mode logicalunit --op new --tid ${ID} --lun ${LUN} --backing-store ${TGT_PATH} ${BSTYPE} ${BSOPTS} ${BSOFLAGS}
    # CMD="tgtadm --lld ${DRIVER} --mode target --op update --tid ${ID} --name backing-store" #--value /mnt/LinuxData/iscsi/blocks/T.I.2020-armhf_test.img"
    # CMD=sudo tgtadm --lld isci --op update --mode target --tid ${ID} --params parameter=value<,...>
    echo "$CMD"
    sudo ${CMD}
    # sudo tgtadm --lld iscsi --mode target --op show
}

iSCSI_iser() {
    for m in mlx4_core mlx4_ib mlx4_en ib_core ib_addr ib_sa ib_cm rdma_cm rdma_ucm ib_iser ib_isert
        do
            sudo modprobe $m
            echo "added module $m "
        done
}

#Server configuration example (with null device):
serverConf() {
    sudo apt install infiniband-diags ibutils ibverbs-utils rdmacm-utils perftest libmlx4-1 tgt
    sudo tgtd
    sudo tgt-setup-lun -n tgt-2 -d /tmp/null -b null -t iser
    ## To verify that the target exist run:
    sudo tgtadm -m target -o show | grep -i target | sed 's/^.* //'
}

getTargets() {
    sudo tgtadm -m target -o show | grep -i target | sed 's/^.* //'
}

SUDO=sudo
TFTPBOOT_DIR=/tftpboot
PI3B_SERIAL=b0c7e328
TARGET_IQN=iqn.1961-06.NUC.local:Piarmhf
INITIATOR_IQN=iqn.1961-06.NUC.local.initiator:armhf
ISCSI_TARGET_IP=192.168.1.18
ISCSI_TARGET_PORT=3260

    sed "s/quiet .*//;s/$/ip=dhcp ISCSI_INITIATOR=${INITIATOR_IQN} ISCSI_TARGET_NAME=$TARGET_IQN ISCSI_TARGET_IP=$ISCSI_TARGET_IP ISCSI_TARGET_PORT=${ISCSI_TARGET_PORT} rw/" \
    ${TFTPBOOT_DIR}/${PI3B_SERIAL}/cmdline.txt | ${SUDO} tee ${TFTPBOOT_DIR}/${PI3B_SERIAL}/cmdline.iscsi.pi3.${IMG_ARCH} 1>/dev/null

bootDir() {
    VERBOSE=1
    local TFTPBOOT_DIR=/tftpboot
    #sudo rm -rv ${TFTPBOOT_DIR}
    local PI3B_SERIAL=b0c7e328
    local PI4_SERIAL=177b3502
    local RPI_FIRMWARE_DIR=/nfs/root/boot
    # /mnt/LinuxData/OF/GitHub/RpiFirmware/boot

    sudo mkdir -pv -m 770 ${TFTPBOOT_DIR}/${PI3B_SERIAL}
    sudo mkdir -pv -m 770 ${TFTPBOOT_DIR}/${PI4_SERIAL}
    sudo chown -R ${USER}:${USER} ${TFTPBOOT_DIR}
    sudo chmod -R +x ${TFTPBOOT_DIR}
    for m in $(ls ${RPI_FIRMWARE_DIR})
        do
            echo "$m"
            if [ $m == "bootcode.bin" ]; then
                # sudo ln -s ${RPI_FIRMWARE_DIR}/bootcode.bin ${TFTPBOOT_DIR}/bootcode.bin
                sudo cp -v ${RPI_FIRMWARE_DIR}/bootcode.bin ${TFTPBOOT_DIR}/bootcode.bin
                continue
            fi
            sudo cp -rv ${RPI_FIRMWARE_DIR}/$m ${TFTPBOOT_DIR}
            # /${PI4_SERIAL}/$m
            sudo unlink ${TFTPBOOT_DIR}/${PI3B_SERIAL}/$m
            sudo ln -s ${TFTPBOOT_DIR}/$m ${TFTPBOOT_DIR}/${PI3B_SERIAL}/$m
            # echo "***********************"
        done

    [ -n ${VERBOSE} ] && ls -la ${TFTPBOOT_DIR}/${PI4_SERIAL}
}

iscsi_QuickStart() {
    local IMG_ARCH=aarch64
    
    local TGT_ID=2
    local IQN=iqn.1961-06.$(uname -n).local
    local TARGET_IQN="${IQN}:Pi${IMG_ARCH}"
    local INITIATOR_IQN="${IQN}.initiator:${IMG_ARCH}"
	
    sudo tgtadm --lld iscsi --mode target --op new --tid ${TGT_ID} --targetname ${TARGET_IQN}
	sudo tgtadm --lld iscsi --mode target --op bind --tid ${TGT_ID} --initiator-address ALL
    sudo tgtadm --lld iscsi --mode target --op unbind --tid ${TGT_ID} --initiator-name nameX
    sudo tgtadm --lld iscsi --mode target --op bind --tid ${TGT_ID} --initiator-name nameX
    sudo tgtadm --lld iscsi --mode target --op bind --tid ${TGT_ID} --initiator-name nameY
	sudo tgtadm --lld iscsi --mode logicalunit --op new --tid ${TGT_ID} --lun 1 --backing-store /mnt/LinuxData/iscsi/blocks/2020-08-20-raspios-buster-armhf.img --bstype rdwr
    sudo tgtadm --lld iscsi --mode target --op show
}

# pharseCmdline
# iSCSI_add
# iSCSI_iser
# serverConf
bootDir