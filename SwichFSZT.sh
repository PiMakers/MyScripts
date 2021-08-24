#!/bin/bash

fsz="1 2 3 9 13 17 19 21"

swichOn(){
    for port in ${fsz}
        do
            echo "Switching on ROUTER 2 port: ${port}"
            /home/pi/MyScripts/MikroTik.sh ON 143 2 ${port}
        done
}

swichQOff(){
    for port in ${fsz}
        do
            echo "Switching qOFF ROUTER 2 port: ${port}"
            /home/pi/MyScripts/MikroTik.sh QOFF 143 2 ${port}
        done
}

if [ "x$1" == "xON" ]; then
    swichOn
elif [ "x$1" == "xOFF" ]; then
    swichOff
elif [ "x$1" == "xQOFF" ]; then
    swichQOff
else
    swichOn
fi