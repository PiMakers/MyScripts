#!/bin/bash

# tput cvvis
exit() {
    echo "HUP"
    kill $$
}

trap exit HUP
trap 'echo EXIT' EXIT
trap 'echo RETURN' RETURN
trap 'echo INT $$ && exit' INT

while :
do
    echo $$ $BASHPID
    echo -ne "\r          \r"
    for  ((i=0; i<=10; i++))
    do
        sleep 1
        echo -ne "."
    done
    echo -ne "\r           "
    echo --------------
    sudo pkill -2 $$
    #break
done