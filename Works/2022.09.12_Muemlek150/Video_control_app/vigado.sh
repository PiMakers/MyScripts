#! /bin/bash

###################################
# A táphoz közelebbi a touchscreen.
# A scriptben az útvonalakat cseréld ki a megfelelőekre.
# A touch input id-ját megtalálja, de csekkold le terminálban:
# xinput --list | grep -F ILITEK | grep -Po '(?<=id=)\d\d?' | head -n 1
###################################


pathToVideo=~/Videos/vid_FHD_H264.mp4
pathToApp=~/Documents/Video_control_app

one=$(xinput --list | grep -F ILITEK | grep -Po '(?<=id=)\d\d?' | head -n 1)
two=$(xinput --list | grep -F ILITEK | grep -Po '(?<=id=)\d\d?' | tail -n 1)

xinput map-to-output $one HDMI-2
xinput map-to-output $two HDMI-2

# cd ~/Documents/Video_control_app && npm start &
# cd ~/Videos && mpv vid_FHD_H264.mp4 -screen=1 --fs --idle --loop --no-osc --no-audio --input-ipc-server=/tmp/mpvsocket &
mpv $pathToVideo --screen=1 --fs --idle --loop --no-osc --no-audio --input-ipc-server=/tmp/mpvsocket &
npm start --prefix=$pathToApp