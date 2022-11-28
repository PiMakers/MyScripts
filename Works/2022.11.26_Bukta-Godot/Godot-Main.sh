#!/bin/bash

HAUS="01-PopCorn \
      02-Kredenc-Window \
      02-Kredenc \
      03-Tomato \
      04-Kitchen"

FSZT="05-Vasalo \
      06-OkosKapa \
      07-Fa"

HOSTS="${FSZT} ${HAUS}"

comamnds="check \
          ping \
          shutdown \
          reboot \
          refresh"

for m in  $comamnds
do
   case $m in
    ${2}) command='echo "echoing from $HOST \${2}"'
          echo "command = ${2}"
          break
          ;;
    *)    echo "command not found"
          ;; 
    esac
done

[ -n $1 ] && HOST=${1}.local

sendCommandByName() {
    ssh "pimaker@${HOST}" ${command}
}

case ${command} in
    shutdown) command='echo "OK..."'

sendCommandByName

echo ${1}