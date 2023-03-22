#! /bin/bash

###################################
# A táphoz közelebbi a touchscreen.
# A scriptben az útvonalakat cseréld ki a megfelelőekre.
# A touch input id-ját megtalálja, de csekkold le terminálban:
# xinput --list | grep -F ILITEK | grep -Po '(?<=id=)\d\d?' | head -n 1
###################################


pathToVideo=~/Videos/vid_FHD_H264.mp4
pathToApp=~/Documents/Video_control_app

pathToVideo=~/VXII-Kivetito-HD.mp4
pathToApp=~/Video_control_app

one=$(xinput --list | grep -F ILITEK | grep -Po '(?<=id=)\d\d?' | head -n 1)
two=$(xinput --list | grep -F ILITEK | grep -Po '(?<=id=)\d\d?' | tail -n 1)

xinput map-to-output $one HDMI-2
xinput map-to-output $two HDMI-2

# cd ~/Documents/Video_control_app && npm start &
# cd ~/Videos && mpv vid_FHD_H264.mp4 -screen=1 --fs --idle --loop --no-osc --no-audio --input-ipc-server=/tmp/mpvsocket &
mpv $pathToVideo --screen=1 --fs --idle --loop --no-osc --no-audio --input-ipc-server=/tmp/mpvsocket &
# npm start --prefix=$pathToApp

DISPLAY=:0 firefox --kiosk http://127.0.0.1:8080


mpvconf() {
sudo killall mpv
sudo raspi-config
rm  Videos*/*
ls /med*/$USER/PEN*/*/*ls /med*/$USER/PEN*/*/*

echo "
fullscreen
loop
no-osc
" | sudo tee  /etc/mpv/mpv.conf
sudo nano mpv-autostart
sudo reboot
}

# https://raspberrypi.stackexchange.com/questions/53127/how-to-permanently-hide-mouse-pointer-or-cursor-on-raspberry-pi
# disable mose cursor: Edit the /usr/bin/startx file and change the defaultserverargs line to: defaultserverargs="-nocursor"