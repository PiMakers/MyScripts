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
ac4939a9    e4:5f:01:1f:b7:15
527bf3bd    e4:5f:01:1f:b8:b3
38ddc958    e4:5f:01:1f:b7:21
9e959b9a    e4:5f:01:1f:b6:e5
22537658    e4:5f:01:1f:b7:06
dbfc9ec4    e4:5f:01:1f:b6:ee
1f8638a0    e4:5f:01:1f:b8:89
d3eadbbe    e4:5f:01:1f:b6:df
fb59ee8e    e4:5f:01:1f:b7:27

f6c82acf    e4:5f:01:1f:b7:51
2d3b5794    e4:5f:01:1f:b9:f1
ab8aa887    e4:5f:01:1f:b9:1f
ac4939a9    e4:5f:01:1f:b7:15
6cbcac49    e4:5f:01:1f:b8:5f
a3b621da    e4:5f:01:1f:b7:54
ab276eca    e4:5f:01:1f:b9:d6
e70761a7    e4:5f:01:1f:b6:f4
633a808b    e4:5f:01:1f:b7:2d
79fee1e9    e4:5f:01:1f:b8:d7

633a808b    e4:5f:01:1f:b7:2d
3c50280a    e4:5f:01:1f:b7:12
a35a7fdb    e4:5f:01:1f:ba:3f
79fee1e9    e4:5f:01:1f:b8:d7
c15e7df5    e4:5f:01:1f:b7:4b
fed64f9e    e4:5f:01:1f:b7:0f
3c50280a    e4:5f:01:1f:b7:12
7db7a8e2    e4:5f:01:1f:b8:92
6b8e0a56    e4:5f:01:1f:b7:3f
c8213b42    e4:5f:01:1f:b7:42

308e7856    e4:5f:01:1f:b6:fa

"