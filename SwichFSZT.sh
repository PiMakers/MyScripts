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

swichMon(){
    for port in ${fsz}
        do
            echo "Monitoring ROUTER 2 port: ${port}"
            /home/pi/MyScripts/MikroTik.sh MON 143 2 ${port} &
            PID="$!"
            echo $PID >> /tmp/PIDS.txt
        done
        sleep 8
        sudo killall sshpass
        #cat /tmp/PIDS.txt
        rm /tmp/PIDS.txt
}


case "$1" in
    ON|on) swichOff
            ;;

    OFF|off)
            swichOff
            ;;
    QOFF|qoff)
            swichQOff
            ;;
    MON|mon)
            swichMon
            ;;

    *)
        swichOn
        ;;
esac        