## https://onedrive.live.com/?cid=04E1AFAA94739671&id=4E1AFAA94739671%21330810&parId=4E1AFAA94739671%21307716&o=OneUp

#!/bin/bash

TMP_DIR=/tmp

    cat << EOF | sed 's/^.\{4\}//' | ${SUDO} tee ${TMP_DIR}/boot.conf
        [all]
        BOOT_UART=0
        WAKE_ON_GPIO=1
        POWER_OFF_ON_HALT=0

        # Try  Network -> SD- > Loop
        BOOT_ORDER=0xf12

        # Set to 0 to prevent bootloader updates from USB/Network boot
        # For remote units EEPROM hardware write protection should be used.
        ENABLE_SELF_UPDATE=1

        # default=0 silent=1
        DISABLE_HDMI=1
EOF

CM4_ENABLE_RPI_EEPROM_UPDATE=1 sudo -E rpi-eeprom-config --apply ${TMP_DIR}/boot.conf && RES="$?"

echo "::RES = $RES ---------------------------------------------------------" 
if [ $RES ]; then

    echo "***************************************************************"
    echo "*                      SUCCSESS!!!!!!!                        *"
    echo "***************************************************************"

    PI_SERIAL=`cat /proc/cpuinfo | grep Serial | awk -F ': ' '{print $2}' | tail -c 8`
    PI_MAC=`ip addr show eth0 | grep ether | awk '{print $2}'`
    if [ ! -f /boot/BorsiSerials.txt ]; then
        echo "BORSI CM4 serials\tmac address:\n" > /boot/BorsiSerials.txt
    fi
    sed -i "/${PI_SERIAL}/d" /boot/BorsiSerials.txt
    echo "${PI_SERIAL}\t${PI_MAC}" >> /boot/BorsiSerials.txt || true
    cat -n /boot/BorsiSerials.txt || true
    sleep 10
    shutdown now 
else
    echo "---------------------------------------------------------------"
    echo "-                       FAILED!!!!!!!!                        -"
    echo "---------------------------------------------------------------"
    sleep 5
    reboot
fi


echo " \
## Switchek:
192.168.10.1	08:55:31:ae:63:7b	(Unknown)
192.168.10.2	08:55:31:ae:8c:e9	(Unknown)
192.168.10.11	08:55:31:ae:63:7b	(Unknown)
192.168.10.121	08:55:31:d4:f1:e5	(Unknown)
192.168.10.122	08:55:31:d4:f1:ce	(Unknown)
192.168.10.200	2c:f0:5d:15:ea:3e	(Unknown)

## NotShure
192.168.10.102	e4:5f:01:1f:b7:15	(E2-Pioca?)

## Server fb59ee8e
LAN	192.168.10.167	e4:5f:01:1f:b7:27 
WLAN	10.0.10.40	e4:5f:01:1f:b7:28

## Kodi

d3cb90f9    e4:5f:01:1f:b9:df   192.168.10.144	F3-7.3_WindowToPast(Right)
9e959b9a    e4:5f:01:1f:b6:e5   192.168.10.137  F3-8.3_WindowToPast(Center)
0498982a    e4:5f:01:1f:bb:4d   192.168.10.143  F3-9.3_WindowToPast(Left)
c15e7df5    e4:5f:01:1f:b7:4b   192.168.10.147  E4-Bolcso
527bf3bd	e4:5f:01:1f:b8:b3   192.168.10.161  E8_Fire
38ddc958    e4:5f:01:1f:b7:21   192.168.10.153  E9-5.13b_OnPaints
79fee1e9    e4:5f:01:1f:b8:d7   192.168.10.155  E9-5.15b_MemoryTrees
6b8e0a56    e4:5f:01:1f:b7:3f   192.168.10.149  E9-5.3b_SZOBROK


## Msys
dbfc9ec4    e4:5f:01:1f:b6:ee
e70761a7    e4:5f:01:1f:b6:f4
308e7856    e4:5f:01:1f:b6:fa
d3eadbbe    e4:5f:01:1f:b6:df

22537658    e4:5f:01:1f:b7:06
fed64f9e    e4:5f:01:1f:b7:0f   192.168.10.141  E6-Animatik
            e4:5f:01:1f:b7:2a   192.168.10.116 F1-Teremhang
633a808b    e4:5f:01:1f:b7:2d
3c50280a    e4:5f:01:1f:b7:12
ac4939a9    e4:5f:01:1f:b7:15
c8213b42    e4:5f:01:1f:b7:42
f6c82acf    e4:5f:01:1f:b7:51
a3b621da    e4:5f:01:1f:b7:54

1f8638a0    e4:5f:01:1f:b8:89
6cbcac49    e4:5f:01:1f:b8:5f
7db7a8e2    e4:5f:01:1f:b8:92
79fee1e9    e4:5f:01:1f:b8:d7

ab276eca    e4:5f:01:1f:b9:d6
2d3b5794    e4:5f:01:1f:b9:f1
ab8aa887    e4:5f:01:1f:b9:1f

a35a7fdb    e4:5f:01:1f:ba:3f
"