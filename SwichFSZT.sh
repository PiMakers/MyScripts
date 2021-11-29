#!/bin/bash



fsz="1 2 3 5 6 9 13 17 19 21"

fsz_hosts="f1-teremhang \
           f2-periodizacio \
           f3-windowtopast-left \
           f3-windowtopast-center \
           f3-windowtopast-right \
           f3-inventarium-a \
           f3-inventarium-b \
           f5-teremhang \
           f6-animatik \
           f6-teremhang"



swichOn(){
    for port in ${fsz}
        do
            echo "Switching on ROUTER 2 port: ${port}"
            /home/pi/MyScripts/MikroTik.sh ON 2 ${port}
        done
}

swichOff(){
    for host in ${fsz_hosts}
        do
            echo "Switching OFF: ${host}"
            ssh root@${host}.local 'shutdown now'
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
    ON|on) swichOn
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