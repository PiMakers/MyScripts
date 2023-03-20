#!/bin/bash

## Tested onBuster x64
# https://forum.raspiaudio.com/t/ultra-installation-get-it-working-with-external-mic/532/19
# // Definitions for Waveshare WM8960 https://github.com/waveshare/WM8960-Audio-HAT
# https://forum.raspiaudio.com/t/installing-drivers-on-ultra-on-arch-linux-resolved/152/3
# Driver:

git clone https://github.com/RASPIAUDIO/WM8960-Audio-HAT.git
# git clone https://github.com/HinTak/seeed-voicecard.git
#cd seeed-voicecard
#git clone https://github.com/RASPIAUDIO/ultra2.git
#cd ultra2
# git clone https://github.com/waveshare/WM8960-Audio-HAT
cd WM8960-Audio-HAT
sudo ./install.sh
# External microphone input and headphones output:
# wget https://raspiaudio.com/s/MicUltra_Input_JackMicrophone_Input2
# wget https://raw.githubusercontent.com/RASPIAUDIO/WM8960-Audio-HAT/master/preset_external_jack_microphone_input2
# alsactl --file preset_external_jack_microphone_input2 restore 0
# sudo arecord -f cd -Dhw:0


## Reaper:
sudo chown -R 1000:1000 /opt
cd /opt
ARCH=`uname -m`
wget https://www.reaper.fm/files/6.x/reaper675_linux_${ARCH}.tar.xz
tar -xvf reaper675_linux_${ARCH}.tar.xz
/opt/reaper_linux_${ARCH}/REAPER/reaper


montOF(){
    mountpoint /mnt/LinuxData/OF || sudo mkdir -pv /mnt/LinuxData/OF && sudo mount -onolock nuc:/mnt/LinuxData/OF /mnt/LinuxData/OF
    mountpoint /media/OF || sudo mkdir -pv /media/OF && sudo mount -onolock nuc:/mnt/LinuxData/OF /media/OF
    aplay -f cd /mnt/LinuxData/OF/ZIK/ContentsX/4152-Lemezjatszo.wav
}

ttt() {
dtparam=i2s=on
dtoverlay=wm8960-soundcard

dtparam i2c_arm=on
modprobe i2c-dev
dtoverlay wm8960-soundcard

/etc/wm8960-soundcard/
}