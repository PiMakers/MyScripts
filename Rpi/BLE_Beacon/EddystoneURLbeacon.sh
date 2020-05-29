## https://yamir.dev/update/tutorial/2016/03/16/raspberrypi-eddystone-url.html
## https://os.mbed.com/blog/entry/BLE-Beacons-URIBeacon-AltBeacons-iBeacon/

## BaconLayouts (https://beaconlayout.wordpress.com/):
#ALTBEACON	m:2-3=beac,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25
#EDDYSTONE  TLM	x,s:0-1=feaa,m:2-2=20,d:3-3,d:4-5,d:6-7,d:8-11,d:12-15
#EDDYSTONE  UID	s:0-1=feaa,m:2-2=00,p:3-3:-41,i:4-13,i:14-19
#EDDYSTONE  URL	s:0-1=feaa,m:2-2=10,p:3-3:-41,i:4-20v
#iBEACON	m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24

#!/bin/bash

check_root() {
    echo ":::"
    if [[ $EUID -eq 0 ]];then
        echo "::: You are root - OK"
    else
        echo "::: sudo will be used for the install."
        # Check if it is actually installed
        # If it isn't, exit because the install cannot complete
        if [[ $(dpkg-query -s sudo) ]];then
            export SUDO="sudo"
            export SUDOE="sudo -E"
        else
            echo "::: Please install sudo or run this as root."
            exit
        fi
    fi
}

check_root

# Ensure that the bluetooth adapter is running
if [[ ! $(${SUDO} hciconfig hci0 | grep "UP RUNNING") ]]; then
    ${SUDO} hciconfig hci0 up
fi

# Enable non connectable undirected advertising
${SUDO} hciconfig hci0 leadv 3

# Disable scanning
${SUDO} hciconfig hci0 noscan

## https://github.coventry.ac.uk/leej64/PIBeacon:
# ./PIBeacon.sh DCEF54A2-31EB-467F-AF8E-350FB641C97D 99 0
BLUETOOTH_DEVICE=hci0

UUID=$(python3 -c "import uuid; hexstring=uuid.UUID(\"DCEF54A2-31EB-467F-AF8E-350FB641C97D\").hex.upper(); print(' '.join([hexstring[i:i+2] for i in range(0, len(hexstring), 2)]))")
MAJOR=$(printf '%x' 1)
MINOR=$(printf '%x' 1)


# iBeacon	m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24

## Byte 0-2: Standard BLE Flags
# Byte 0: Length :  0x02
# Byte 1: Type: 0x01 (Flags)
# Byte 2: Value: 0x06 (Typical Flags)

## Byte 3-29: Apple Defined iBeacon Data
 #Byte 3: Length: 0x1a
 #Byte 4: Type: 0xff (Custom Manufacturer Packet)
 #Byte 5-6: Manufacturer ID : 0x4c00 (Apple)
 #Byte 7: SubType: 0x02 (iBeacon)
 #Byte 8: SubType Length: 0x15
 #Byte 9-24: Proximity UUID
 #Byte 25-26: Major
 #Byte 27-28: Minor
 #Byte 29: Signal Power
echo -e "Advertising iBeacon with the given \nuuid: $UUID, major: $MAJOR and minor: $MINOR"
${SUDO} hcitool -i hci0 cmd 0x08 0x0008 1E 02 01 1A 1A FF 4C 00 02 15 $UUID 00 $MAJOR 00 $MINOR C8
#s 00

read -p "press ENTER to stop Advertising!"
${SUDO} hciconfig $BLUETOOTH_DEVICE noleadv
${SUDO} hciconfig $BLUETOOTH_DEVICE leadv 0
sudo hcitool -i hci0 cmd 0x08 0x0008 1e 02 01 1a 1a ff 4c 00 02 15 $UUID $MAJOR $MINOR $POWER 00 00 00 00 00 00 00 00 00 00 00 00 00

read -p "press ENTER to continue!"
# EDDYSTONE  URL	s:0-1=feaa,m:2-2=10,p:3-3:-41,i:4-20v
echo "Advertising EddyStoneURL: http://webgazer.org"
#                                                                     s0 s1 m2 p3 i4 i5 i6 i7 i8 i9 10 11 12 13 14 15 16 17 18 19 20 v
${SUDO} hcitool -i hci0 cmd 0x08 0x0008 17 02 01 06 03 03 aa fe 0f 16 aa fe 10 00 03 77 65 62 67 61 7a 65 72 08 00 00 00 00 00 00 00 00

read -p "press ENTER to continue!"
echo "------------------- ( http://webgazer.org/ ) ---------------------"
echo "Advertising: http://pimylifeup"
 ${SUDO} hcitool -i hci0 cmd 0x08 0x0008 19 02 01 06 03 03 aa fe 11 16 aa fe 10 00 03 70 69 6d 79 6c 69 66 65 75 70 07 00 00 00 00 00 00
echo "------------------- http://pimylifeup ---------------------"

read -p "press ENTER to continue!"
# ${SUDO} hcitool -i hci0 cmd 0x08 0x0008 02 15 E2 0A 39 F4 73 F5 4B C4 A1 2F 17 D1 AD 07 A9 61 00 00 00 00 C8 00