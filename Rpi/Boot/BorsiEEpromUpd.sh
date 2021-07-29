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


## Server fb59ee8e
LAN	192.168.10.167	e4:5f:01:1f:b7:27 
WLAN	10.0.10.40	e4:5f:01:1f:b7:28

## Kodi

dd257d82    e4:5f:01:1f:b7:2a   192.168.10.116  F1-Teremhang                192.168.10.2    ether9 
d3cb90f9    e4:5f:01:1f:b9:df   192.168.10.144	F3-7.3_WindowToPast(Right)  192.168.10.2    ether21
9e959b9a    e4:5f:01:1f:b6:e5   192.168.10.137  F3-8.3_WindowToPast(Center) 192.168.10.2    ether19
0498982a    e4:5f:01:1f:bb:4d   192.168.10.143  F3-9.3_WindowToPast(Left)   192.168.10.2    ether17

c15e7df5    e4:5f:01:1f:b7:4b   192.168.10.147  E4-Bolcso                   192.168.10.1
527bf3bd	e4:5f:01:1f:b8:b3   192.168.10.161  E8-Fire                     192.168.10.110  ether5        
6b8e0a56    e4:5f:01:1f:b7:3f   192.168.10.149  E9-5.3b_SZOBROK             192.168.10.112
38ddc958    e4:5f:01:1f:b7:21   192.168.10.153  E9-5.13b_OnPaints           192.168.10.111  
79fee1e9    e4:5f:01:1f:b8:d7   192.168.10.155  E9-5.15b_MemoryTrees        192.168.10.111

# UnKnonw state or other problem
ac4939a9    e4:5f:01:1f:b7:15   192.168.10.102  E2-Piocák                   192.168.10.1                ??????????
e70761a7    e4:5f:01:1f:b6:f4   192.168.10.146  E2-Teremhang                192.168.10.110  ether1
                                                E4-Mese                     192.168.10.1
a3b621da    e4:5f:01:1f:b7:54
d3eadbbe    e4:5f:01:1f:b6:df

## Msys
            dc:a6:32:da:04:2d   192.168.10.194  E9-5.5b_TenkesKapitánya     192.168.10.112

dbfc9ec4    e4:5f:01:1f:b6:ee   192.168.10.130  E9-FundationFilm            192.168.10.112
            e4:5f:01:1f:b6:e8   192.168.10.128  F5-Teremhang                192.168.10.2    ether13
            e4:5f:01:1f:b6:f1   192.168.10.114  F6-Teremhang                192.168.10.2    ether3
308e7856    e4:5f:01:1f:b6:fa   192.168.10.196  E9-5,6a_Indulók             192.168.10.112
            e4:5f:01:1f:b6:fd   192.168.10.159  E7-Mikes                    192.168.10.110  ether1


            e4:5f:01:1f:b7:00   192.168.10.187  E9-Szalagos                 192.168.10.112
            e4:5f:01:1f:b7:03   192.168.10.123  E7-Animatik                 192.168.10.1
22537658    e4:5f:01:1f:b7:06   192.168.10.119  E7-Hadászat                 192.168.10.1
fed64f9e    e4:5f:01:1f:b7:0f   192.168.10.141  E6-Animatik                 192.168.10.1
3c50280a    e4:5f:01:1f:b7:12   192.168.10.127  E6-Clouds_FL                192.168.10.1
633a808b    e4:5f:01:1f:b7:2d   192.168.10.118  E9-5.16b_KurucnotaTarogato  192.168.10.111
c8213b42    e4:5f:01:1f:b7:42   192.168.10.108  E3-Latin                    192.168.10.1
            e4:5f:01:1f:b7:4e   192.168.10.131  F6-Animatik                 192.168.10.2    ether2
f6c82acf    e4:5f:01:1f:b7:51                   E6-Clouds_FR                192.168.10.1
            e4:5f:01:1f:b7:a8   192.168.10.166  E7-Tenger                   192.168.10.110  ether8
            e4:5f:01:1f:b7:b7   192.168.10.135  E9-5.20ab_SK_Ruszin         192.168.10.111                    
            e4:5f:01:1f:b7:78   192.168.10.101  E6-Clouds_RR

6cbcac49    e4:5f:01:1f:b8:5f   192.168.10.124  E1-Heraldika                --------------  ------
1f8638a0    e4:5f:01:1f:b8:89   192.168.10.120  E9-5.2a_Rémisztő            192.168.10.112
7db7a8e2    e4:5f:01:1f:b8:92   192.168.10.106  E9-5.6b_Könnyűzene          192.168.10.112

ab276eca    e4:5f:01:1f:b9:d6   192.168.10.164  E9-ReBurial                 192.168.10.111
2d3b5794    e4:5f:01:1f:b9:f1   192.168.10.117  E8-MyHero                   192.168.10.1
            e4:5f:01:1f:b9:1c   192.168.10.103  E9-5.16a_Radio              192.168.10.111
ab8aa887    e4:5f:01:1f:b9:1f   192.168.10.129  E2-Vizelet                  192.168.10.1
            e4:5f:01:1f:b9:8e   192.168.10.139  F2-Priodizáció              192.168.10.2    ether1

a35a7fdb    e4:5f:01:1f:ba:3f   192.168.10.132  E6-Clouds_RL                192.168.10.1

# poe-out status: short_circuit
192.168.10.2    ether5

"