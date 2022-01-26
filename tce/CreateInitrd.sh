#!/bin/ash

# cd /tmp
BASE_DIR='/tmp/initrd'
MASTER_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD4N+X1pLa63SD67I4uKkQl2xvnNbO5SLtSbh1iIL9ktGRMVGOfvbX6dtCbMTvZQa40zLnaT5M5BAgFEPjgecfeg8VmwHvweeHzLPdx8u9yA+jVB+8Ogc3LzfpULCult+i78Xl67sn7rIftcsBlCE/D8+6ks1e7TRSeQrs4sbfbaziTzVlDkOZAHYD5J1+/uuViWQ7QcdJ5WirH9GT4DYa504wgjg/nqlvsh736tdtt7HVnGBkpMmgpu98Rbfy9E0+bW8FdvxhNTZQY2vnstE4q62xE20s3ICOwrL9y4DmTRjIA01ef8tJhUuIh9AyqEtPVO9+QrPpc4L9XIYdHs2up masterKey@BorsiServer'

createStartUpScript() {
    mkdir -p ${BASE_DIR}/opt
    cat /opt/bootsync.sh | /bin/sed '/box/d;/#PiM@ker/d' > ${BASE_DIR}/opt/bootsync.sh
    echo 
    cat << 'EOF' | sed 's/^.\{8\}//' >> /tmp/initrd/opt/bootsync.sh
        echo "======================================"   #PiM@ker
        /usr/local/etc/init.d/openssh start &           #PiM@ker
        echo restore:Borsi@2021 | /usr/sbin/chpasswd    #PiM@ker
        count=0                                         #PiM@ker
        echo -n Waiting for the network...              #PiM@ker
        while [ "$count" -lt 60 ]; do                   #PiM@ker
        ifconfig eth0 | grep -q inet && break           #PiM@ker
        sleep 1                                         #PiM@ker
        count=$((count + 1))                            #PiM@ker
        echo -n .                                       #PiM@ker
        done                                            #PiM@ker
        /opt/installer.sh                               #PiM@ker
EOF
    # startUpscript
    cat << 'EOF' | /bin/sed 's/^.\{8\}//' > ${BASE_DIR}/opt/installer.sh
        #!/bin/ash
        mountOF() {
            if (ping -c 1 -w 1 NUC 2>/dev/null 1>&2) ;then
                REMOTE_HOST=NUC
                BACKUP_ROOT_DIR=/mnt/LinuxData/OF
            elif (ping -c 1 -w 1 BorsiServer 2>/dev/null 1>&2);then
                REMOTE_HOST=BorsiServer
                BACKUP_ROOT_DIR=/mnt/deb-b
            else
                echo ":: ERROR:BACKUPSERVER NOT FOUND!"
                exit 1
            fi

            BACKUP_DIR=${BACKUP_ROOT_DIR}/BorsiBackUp/BackUpImages

            if ( df | grep -q ${BACKUP_ROOT_DIR} ); then
                echo ":: ${REMOTE_HOST}:${BACKUP_ROOT_DIR} ALREADY MOUNTED."
            else 
                sudo mkdir -pv ${BACKUP_ROOT_DIR}
                sudo mount -onolock ${REMOTE_HOST}:${BACKUP_ROOT_DIR} ${BACKUP_ROOT_DIR} || echo ":: ERROR MOUNTING BACKUP DIR!"
            fi
        }
        mountOF
EOF

    cp ${BACKUP_ROOT_DIR}/myGitHub/Borsi-Scripts/restoreImg.sh ${BASE_DIR}/opt
    chmod +x ${BASE_DIR}/opt/installer.sh ${BASE_DIR}/opt/bootsync.sh
}

installOpenSSH() {
    # load openssh extension if it not already loaded
    tce-load -wi openssh parted

    # make all loaded extension persistent
    mkdir -pv ${BASE_DIR}/usr/local -m 700 ${BASE_DIR}/home/restore/.ssh
    sudo chown -R 1000:50 ${BASE_DIR}/home/restore/.ssh \
        && sudo chmod  744 ${BASE_DIR}/home/restore/.ssh \
        && echo "${MASTER_KEY}" > ${BASE_DIR}/home/restore/.ssh/authorized_keys \
        && sudo chmod  600 ${BASE_DIR}/home/restore/.ssh/authorized_keys

    sudo cp -vr /usr/local/etc ${BASE_DIR}/usr/local 
    sudo cp -vr  /tmp/tcloop/openssl/* \
                /tmp/tcloop/openssh/* \
                /tmp/tcloop/parted/* \
                /tmp/tcloop/readline/* \
                /tmp/tcloop/ncurses/* \
                ${BASE_DIR}
    echo "---------------------------------------------" | sudo tee ${BASE_DIR}/etc/motd
    echo "--- RECOVERY ENVIROMENT for Borsi restore ---" | sudo tee -a ${BASE_DIR}/etc/motd
    echo "---------------------------------------------" | sudo tee -a ${BASE_DIR}/etc/motd
}

createInitrd() {
    cd ${BASE_DIR}
    INITRD='recovery1.gz'
    DST='/mnt/LinuxData/OF'
    sudo find | sudo cpio -o -H newc | gzip -9 > ../${INITRD}
    #advdef -z4 ../ssh.gz
    # cat core.gz myimg.gz > new.gz
    cp -v /tmp/${INITRD} /mnt/LinuxData/OF/recovery.gz
    # sudo cp ../recovery.gz 
    # sudo cp /mnt/LinuxData/OF/recovery.gz /tftpLE/recovery.gz
}

mountOF() {
    if (ping -c 1 -w 1 NUC 2>/dev/null 1>&2) ;then
        REMOTE_HOST=NUC
        BASE_DIR='/mnt/LinuxData/OF'
        BACKUP_ROOT_DIR="${BASE_DIR}/BorsiBackUp"
        IMG_DIR="${BACKUP_ROOT_DIR}/BackUpImages"
        SCRIPT_DIR="${BASE_DIR}/myGitHub/Borsi-Scripts"
    elif (ping -c 1 -w 1 BorsiServer 2>/dev/null 1>&2);then
        REMOTE_HOST=BorsiServer
        BASE_DIR==/mnt/deb-b
    else
        echo ":: ERROR:BACKUPSERVER NOT FOUND!"
        exit 1
    fi

    BACKUP_DIR=${BACKUP_ROOT_DIR}/BorsiBackUp/BackUpImages

    if ( df | grep -q ${BACKUP_ROOT_DIR} ); then
        echo ":: ${REMOTE_HOST}:${BACKUP_ROOT_DIR} ALREADY MOUNTED."
    else 
        sudo mkdir -pv ${BACKUP_ROOT_DIR}
        sudo mount -onolock ${REMOTE_HOST}:${BACKUP_ROOT_DIR} ${BACKUP_ROOT_DIR} || echo ":: ERROR MOUNTING BACKUP DIR!"
    fi
}

runCreateInitrd() {
    mountOF
    createStartUpScript
    installOpenSSH
    createInitrd
}

fsResize() {
    DISK=/dev/mmcblk0
    df | grep -q ${DISK} && sudo umount $(df |sed "/${DISK##*/}/!d;s/ .*//")
    sudo parted -s -m ${DISK} resizepart 2 100%
    sudo e2fsck -f -p ${DISK}p2
    sudo resize2fs ${DISK}p2
}

restoreImgGZ() {
    DISK='/dev/mmcblk0'
    #BACKUP_DIR='/mnt/LinuxData/OF/zacc' #!!!!!!!!!!!!!!!!!!!!!!
    HOSTNAME='f2-periodizacio'
    #HOSTNAME='LibreELEC-RPi4.arm-10.0.1'
    IMG="${BACKUP_DIR}/${HOSTNAME}.img.gz"

    mountOF
    [ -f $IMG ] || ( echo $IMG NOT FOUND && exit 1 )
    #gunzip -kc $IMG 
    df | grep -q ${DISK} && sudo umount $(df |sed "/${DISK##*/}/!d;s/ .*//")
    gunzip -fk $IMG #| sudo -E dd of=${DISK} bs=4M conv=sync,noerror
    sudo dd if=${IMG%.*} of=${DISK} bs=4M conv=sync,noerror
    #gunzip -fkc $IMG | sudo dd of=/dev/mmcblk0 bs=4M conv=sync,noerror
    read -p "PRESS A KEY!"
    sudo rm ${IMG%.*}
    fsResize
}

echo ":: BASH_SOURCE = ${BASH_SOURCE} s0 = $0"
[ '-sh' != "${0}" ] && runCreateInitrd
