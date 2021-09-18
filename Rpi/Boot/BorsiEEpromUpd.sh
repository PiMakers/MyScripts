## https://onedrive.live.com/?cid=04E1AFAA94739671&id=4E1AFAA94739671%21330810&parId=4E1AFAA94739671%21307716&o=OneUp

#!/bin/bash
hopp() {
    mkdir -pv /var/media/OF
    mount 192.168.1.20:/mnt/LinuxData/OF /media/OF
    /media/OF/myGitHub/MyScripts/Rpi/Boot/BorsiEEpromUpd.sh
}

. /etc/os-release

if [ $ID == "libreelec" ]; then
    mount -oremount,rw /flash
    TMP_DIR=/storage/.kodi/temp
else
    SUDO=sudo
    SUDOE='sudo -E'
    TMP_DIR=/tmp
fi

echo "$ID detected"

TMP_DIR=/tmp

    cat << EOF | sed 's/^.\{8\}//' | ${SUDO} tee ${TMP_DIR}/boot.conf
        [all]
        BOOT_UART=0
        WAKE_ON_GPIO=1
        POWER_OFF_ON_HALT=1

        # Try  Network -> MSD/USB -> SD- > Loop
        BOOT_ORDER=0xf12

        # Set to 0 to prevent bootloader updates from USB/Network boot
        # For remote units EEPROM hardware write protection should be used.
        ENABLE_SELF_UPDATE=1

        # default=0 silent=1
        DISABLE_HDMI=1

        #DHCP_TIMEOUT=45000
        #DHCP_REQ_TIMEOUT=4000
        #TFTP_FILE_TIMEOUT=30000
        #TFTP_IP=
        #TFTP_PREFIX=0
        SD_BOOT_MAX_RETRIES=0
        NET_BOOT_MAX_RETRIES=0

        [none]
        FREEZE_VERSION=0
EOF

CM4_ENABLE_RPI_EEPROM_UPDATE=1 ${SUDOE} rpi-eeprom-config --apply ${TMP_DIR}/boot.conf && RES="$?"

echo "::RES = $RES ---------------------------------------------------------" 
if [ $RES ]; then

    echo "***************************************************************"
    echo "*                      SUCCSESS!!!!!!!                        *"
    echo "***************************************************************"

    PI_SERIAL=`cat /proc/cpuinfo | grep Serial | awk -F ': ' '{print $2}' | tail -c 8`
    PI_MAC=`ip addr show eth0 | grep ether | awk '{print $2}'`
    if [ ! -f /boot/BorsiSerials.txt ]; then
        echo -e "BORSI CM4\n serials:\tmac address:\n" | ${SUDO} tee -a /boot/BorsiSerials.txt
    fi
    #${SUDO} sed -i "/${PI_SERIAL}/d" /boot/BorsiSerials.txt
    #echo -e "${PI_SERIAL}\t${PI_MAC}" ${SUDO} tee -a /boot/BorsiSerials.txt || true
    #cat -n /boot/BorsiSerials.txt || true
    #sleep 10
    #${SUDO} shutdown now 
else
    echo "---------------------------------------------------------------"
    echo "-                       FAILED!!!!!!!!                        -"
    echo "---------------------------------------------------------------"
    sleep 5
    reboot
fi


echo " \
## Switchek:
192.168.10.1	08:55:31:ae:63:7b	(Emelet)


192.168.10.2	08:55:31:ae:8c:e9	(Fsz)
    ether1      F2-Periodizácio
    ether2      F6-Animatik
    ether3      F6-Teremhang
    ether 4-8   -
    ether9      F1-Teremhang
    ether 10-12 -
    ether13     F5-Teremhang
    ether17     F3-9.3_WindowToPast(Left)
    ether19     F3-8.3_WindowToPast(Center)
    ether21     F3-7.3_WindowToPast(Right)
                NUC
                NUC

192.168.10.11	08:55:31:ae:63:7b	(Unknown)
192.168.10.110	08:55:31:7b:8c:0a	(E7-E8-E2)
    ether1      E7-Mikes
    ether2      E2-Teremhang
    ether5      E8-Fire
    ether8      E7-Tenger
    ether 3;4;6;7   --- 
192.168.10.111  08:55:31:7b:8b:7f       (E9-Right)
    ether1      E9-5.16a_Radio
    ether2      ---
    ether3      E9-5.15b_MemoryTrees
    ether4      E9-5.20ab_SK_Ruszin
    ether5      E9-Szalagos
    ether6      E9-5.13b_OnPaints
    ether7      E9-ReBurial
    ether8      E9-5.16b_KurucnotaTarogato    
192.168.10.112  08:55:31:7b:84:42       (E9-Left)
    ether1      E9-FundationFilm
    ether3      E9-5.5b_TenkesKapitánya
    ether4      E9-5.6a_Indulók
    ether5      E9-5.6b_Könnyűzene
    ether6      E9-5.3b_SZOBROK
    ether7      E9-5.2a_Rémisztő
    ether 2;8      ---   

192.168.10.113  08:55:31:b8:94:07       (E6)
    ether2      E6-CloudsFR
    ether4      E6_Animatik
    ether 1;3;5-8      ---   

192.168.10.121	08:55:31:d4:f1:e5	(Unknown)
192.168.10.122	08:55:31:d4:f1:ce	(Unknown)
192.168.10.200	2c:f0:5d:15:ea:3e	(Unknown)


## Server fb59ee8e
LAN:
a3b621da    e4:5f:01:1f:b7:54   192.168.10.142

???:
WLAN	10.0.10.40	e4:5f:01:1f:b7:28

#########
## Kodi #
#########

# FSZ:
35b00be8    dc:a6:32:e4:ed:6a   192.168.10.162  f1-teremhang.local              F1-Teremhang                192.168.10.2    ether9  40
72d9e3f4    e4:5f:01:1f:b9:8e   192.168.10.118  f2-periodizacio.local           F2-Periodizáció             192.168.10.2    ether1
0498982a    e4:5f:01:1f:bb:4d   192.168.10.114  f3-windowtopast-left.local      F3-9.3_WindowToPast(Left)   192.168.10.2    ether17
9e959b9a    e4:5f:01:1f:b6:e5   192.168.10.137  f3-windowtopast-center.local    F3-8.3_WindowToPast(Center) 192.168.10.2    ether19
d3cb90f9    e4:5f:01:1f:b9:df   192.168.10.144	f3-windowtopast-right.local     F3-7.3_WindowToPast(Right)  192.168.10.2    ether21
e0814bfd    e4:5f:01:1f:b6:e8   192.168.10.128  f5-teremhang.local              F5-Teremhang                192.168.10.2    ether13
aabe2c95    e4:5f:01:1f:b7:4e   192.168.10.131  f6-animatik.local               F6-Animatik                 192.168.10.2    ether2
656e4acc    e4:5f:01:1f:b6:f1   192.168.10.148  f6-teremhang.local              F6-Teremhang                192.168.10.2    ether3


# EMELET:
fb59ee8e	e4:5f:01:1f:b7:27   192.168.10.167	e2-piocak.local                 E2-Piocák                   192.168.10.1
115ee8a1    dc:a6:32:e6:10:09   192.168.10.107  e2-teremhang.local              E2-Teremhang                192.168.10.110  ether2

c8213b42    e4:5f:01:1f:b7:42   192.168.10.108  e3-latin.local                  E3-Latin                    192.168.10.1

c15e7df5    e4:5f:01:1f:b7:4b   192.168.10.147  e4-bolcso.local                 E4-Bolcso                   192.168.10.1
580242cc    dc:a6:32:ea:c8:6d   192.168.10.152  e4-mese.local                   E4-Mese                     192.168.10.1


3c50280a    e4:5f:01:1f:b7:12   192.168.10.127  E6-CloudsFL                 192.168.10.1
f6c82acf    e4:5f:01:1f:b7:51   192.168.10.126  e6-cloudsfr.local               E6-Clouds_FR                192.168.10.113  ether2
a35a7fdb    e4:5f:01:1f:ba:3f   192.168.10.100  e6-cloudsrl.local               E6-Clouds_RL                192.168.10.1
49407160    e4:5f:01:1f:b7:78   192.168.10.101  e6-cloudsrr.local               E6-Clouds_RR                192.168.10.1
fed64f9e    e4:5f:01:1f:b7:0f   192.168.10.141  e6-animatik.local               E6-Animatik                 192.168.10.113  ether4

ac4939a9    e4:5f:01:1f:b7:15   192.168.10.104  e7-tenger.local                 E7-Tenger                   192.168.10.110  ether8
043ab7a6    e4:5f:01:1f:b7:03   192.168.10.123  e7-animatik.local               E7-Animatik                 192.168.10.1

527bf3bd	e4:5f:01:1f:b8:b3   192.168.10.161  e8-fire.local                   E8-Fire                     192.168.10.110  ether5

dbfc9ec4    e4:5f:01:1f:b6:ee   192.168.10.130  e9-fundationfilm.local              E9-FundationFilm            192.168.10.112  ether1
ab276eca    e4:5f:01:1f:b9:d6   192.168.10.164  e9-reburial.local                   E9-ReBurial                 192.168.10.111  ether7
1f8638a0    e4:5f:01:1f:b8:89   192.168.10.120  e9-5-2a-scary.local                 E9-5.2a_Scary               192.168.10.112  ether7
6b8e0a56    e4:5f:01:1f:b7:3f   192.168.10.149  e9-5-3b-szobrok.local               E9-5.3b_SZOBROK             192.168.10.112  ether6
717dca63    dc:a6:32:da:04:2d   192.168.10.194  e9-5-5b-tenkeskapitanya.local       E9-5.5b_TenkesKapitánya     192.168.10.112  ether3
308e7856    e4:5f:01:1f:b6:fa   192.168.10.196  e9-5-6a-marses.local                E9-5.6a_Indulók             192.168.10.112  ether4
38ddc958    e4:5f:01:1f:b7:21   192.168.10.153  e9-5-13b-onpaints.local             E9-5.13b_OnPaints           192.168.10.111  ether6
79fee1e9    e4:5f:01:1f:b8:d7   192.168.10.155  e9-5-15b-memorytrees.local          E9-5.15b_MemoryTrees        192.168.10.111  ether3
633a808b    e4:5f:01:1f:b7:2d   192.168.10.105  e9-5-16b-KurucnotaTarogato.local    E9-5.16b_KurucnotaTarogato  192.168.10.111  ether8
821e1006    e4:5f:01:1f:b7:b7   192.168.10.102  e9-5-20abszlovakruszin.local        E9-5.20ab_SK_Ruszin         192.168.10.111  ether4

## Msys
37c8c5c7    e4:5f:01:1f:b6:fd   192.168.10.159  E7-Mikes                    192.168.10.110  ether1

7db7a8e2    e4:5f:01:1f:b8:92   192.168.10.106  E9-5.6b_Könnyűzene          192.168.10.112  ether5
6a4fe60d    e4:5f:01:1f:b9:1c   192.168.10.103  E9-5.16a_Radio              192.168.10.111  ether1
 
96facade    e4:5f:01:1f:b7:00   192.168.10.187  E9-Szalagos                 192.168.10.111  ether5
22537658    e4:5f:01:1f:b7:06   192.168.10.119  E7-Hadászat                 192.168.10.1
6cbcac49    e4:5f:01:1f:b8:5f   192.168.10.124  E1-Heraldika                --------------  ------
2d3b5794    e4:5f:01:1f:b9:f1   192.168.10.117  E8-MyHero                   192.168.10.1
ab8aa887    e4:5f:01:1f:b9:1f   192.168.10.129  E2-Vizelet                  192.168.10.1

                                                E3-InventáriumA
                                                E3-InventáriumB
# poe-out status: short_circuit
192.168.10.2    ether5


New:
e809ea80    dc:a6:32:f3:8d:c1
94dbd852    e4:5f:01:1f:b7:a8


    STATION_NAME=F6-Animatik
    STATION_NAME=E9-5.5b_TenkesKapitánya
    . /flash/PiMaker.sh
    mkdir -pv /media/bs
    mount 192.168.10.142:/home/pi /media/bs
    ls /media/bs
    df -h
    umount /dev/mmcblk0p1 
    gunzip -kc /media/bs/BorsiBase.img.gz | dd of=/dev/mmcblk0 bs=4M
    sync
    df -h
    fsResize
    df -h
    mount /dev/mmcblk0p2 /var/media/STORAGE
    ls /var/media/STORAGE
 
    echo ${STATION_NAME}> /var/media/STORAGE/.cache/hostname
 
    mount /dev/mmcblk0p1 /media/LIBREELEC
    nano /media/STORAGE/.kodi/userdata/addon_data/service.libreelec.settings/oe_settings.xml
    nano /media/STORAGE/.kodi/addons/service.autoexec/autoexec.py
    nano /media/STORAGE/.kodi/userdata/playlists/video/Borsi.m3u
    cp -r /media/OF/Borsi/Videos/F6-Animatik /media/STORAGE/videos/



" >/dev/null