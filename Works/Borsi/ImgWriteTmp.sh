# ls /media/pi
# sudo apt autoremove
# sudo apt autoclean
# sudo apt clean
# sudo apt purge -y pi-bluetooth rp-prefapps thonny rp-bookshelf


# PiMaker

# REMOTE_HOST=192.168.10.142
REMOTE_HOST=$(set | sed '/SSH_CONNECTION/!d; s/^.*=.//;s/ .*//')
mount -oremount,rw /flash

mkdir -pv /media/OF
if  ! (mountpoint /media/OF); then
        mount ${REMOTE_HOST}:/mnt/LinuxData/OF /media/OF
else
        echo "Already Mounted"
fi
ls /media/OF/*

eepromUpdate() {
        CM4_ENABLE_RPI_EEPROM_UPDATE=1 rpi-eeprom-config --edit
}

ddImg() {
        mkdir -pv /media/bs
        if  ! (mountpoint /media/bs); then
            mount ${REMOTE_HOST}:/home/pi /media/bs
        fi
        ls /media/bs
        df -h
        if (mountpoint /dev/mmcblk0p1); then
            umount /dev/mmcblk0p1
            echo "::/dev/mmcblk0p1 unmounted"
        fi
        if (mountpoint /dev/mmcblk0p1); then
                umount /dev/mmcblk0p2
                echo "::/dev/mmcblk0p2 unmounted"
        fi

        gunzip -kc /media/bs/BorsiBase.img.gz | dd of=/dev/mmcblk0 bs=4M
        sync
        fsResize
        df -h
        mkdir -pv /media/STORAGE
        mount /dev/mmcblk0p2 /var/media/STORAGE
        echo "F2-Periodizacio"  > c
        #cp /media/OF/Borsi/Scripts/E3-Latin.py /media/STORAGE/.kodi/addons/service.autoexec/autoexec.py
        echo "import xbmc" > /media/STORAGE/.kodi/addons/service.autoexec/autoexec.py
        echo 'xbmc.executebuiltin( "RunAddon(script.period)" )'  >> /media/STORAGE/.kodi/addons/service.autoexec/autoexec.py
        ls /media/OF/Borsi/Videos/F2-Periodizacio
        cp -r /media/OF/Borsi/Videos/F2-Periodizacio /media/STORAGE/videos
        echo "# Borsi F2-Periodizacio" > /media/STORAGE/.kodi/userdata/playlists/video/Borsi.m3u
        echo `ls /media/STORAGE/videos/*` >> /media/STORAGE/.kodi/userdata/playlists/video/Borsi.m3u
        sed -i 's/media\/STORAGE/storage/g' /media/STORAGE/.kodi/userdata/playlists/video/Borsi.m3u
        # 14, 15, 18, 23, 24, 25, 8
}

fsResize() {
    DISK=/dev/mmcblk0
    umount ${DISK}p1 || true
    umount ${DISK}p2 || echo "NOT MONTED!!"
    parted -s -m ${DISK} resizepart 2 100%
    e2fsck -f -p ${DISK}p2
    resize2fs ${DISK}p2
}