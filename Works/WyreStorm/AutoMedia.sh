# https://stackoverflow.com/questions/21580750/disconnect-and-reconnect-ttyusb0-programmatically-in-linux
# https://unix.stackexchange.com/questions/234581/disconnect-and-reconnect-usb-port-via-cli
## https://sites.google.com/site/brendanrobert/projects/bits-and-pieces/lg-tv-hacks

#!/bin/bash

DRIVER=$(lsmod | sed '/^usbserial/!d;s/.* //')
#[Bus Nr.]- [Port Nr.]:
USB_TAG=$(ls /sys/bus/usb/drivers/${DRIVER} | head -n 1)

checkUsbTag() {
    OS=$(lsb_release -i)

    if [ ${OS##*:} == "Ubuntu" ]; then
    ##ubuntu:
        [[ $USB_TAG =~ ^[0-9]-[0-9]:[0-9].[0-9]$ ]] && echo "OK!!!" || ( echo "FAIcccLED!!!" && exit )&& echo $USB_TAG
    fi
    if [ ${OS##*:} == "Raspbian" ]; then
    ## raspberryPi:
        [[ $USB_TAG =~ ^[0-9]-[0-9].[0-9]:[0-9].[0-9]$ ]] && echo "OK!!! " || ( echo "FAILED!!!" && exit )&& echo $USB_TAG
    else
        echo "OS=${OS##*:} not supported USB_TAG=$USB_TAG"
    fi
}

addUdevRule() {
    cat << EOF | sed 's/^.\{4\}//'| sudo tee /etc/udev/rules.d/99-usb-serial.rules
    SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{idModel}=="2303", MODE="0666"
EOF
}

eject_USB() {
    echo ${USB_TAG} | sudo tee /sys/bus/usb/drivers/${DRIVER}/unbind
    if [ $? = 1 ]; then
        echo Cannot disconnect $DRIVER
        return 1
    fi
    return 0
}

connect_USB() {
    echo ${USB_TAG} | sudo tee /sys/bus/usb/drivers/${DRIVER}/bind
}

# HEX (Kramer) echo -en "\x00\x80\x80\x81" >/dev/ttyUSB0 # send reset use "protocol 2000" for available codes
# 
#$1=inport num (1-4) $2=outport num (1-2)
swichInToOut() {
    stty -F /dev/ttyUSB0 115200 raw
    echo "SET SW in$1 out$2" | sudo tee /dev/ttyUSB0 >/dev/null
    while read -t 5 -r line < /dev/ttyUSB0; do
        if [[ "$line" == "" ]];then
            echo emptyLine
            continue
        else
            if [[ "$line" == "SW in$1 out$2" ]];then
                echo "Set input: $1 to output: $2 done!"
                return
            else
                echo "LINE=$line"
                echo -e "$(tail -9 log.log)\n$line" > log.log
            fi
        fi
    done
}

funscreen() {
    stty -F /dev/ttyUSB0 2400 raw
    cmd="\xFF\xEE\xEE\xEE"
    case "$1" in
            up)
                cmd="$cmd\xDD"
                ;;
            
            down)
                cmd="$cmd\xEE"
                ;;
            
            stop)
                cmd="$cmd\xCC"
                ;;
            reset_karamer)
                stty -F /dev/ttyUSB0 9600 raw
                cmd="\x00\x80\x80\x81"
                ;;
            *)
                echo $"Usage: $0 {up|down|stop}"
                exit 1
    esac
    echo -en $cmd >/dev/ttyUSB0
}