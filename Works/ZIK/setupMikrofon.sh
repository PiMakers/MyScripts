#!/bin/bash

## Tested onBuster x64
# https://forum.raspiaudio.com/t/ultra-installation-get-it-working-with-external-mic/532/19
# // Definitions for Waveshare WM8960 https://github.com/waveshare/WM8960-Audio-HAT
# https://forum.raspiaudio.com/t/installing-drivers-on-ultra-on-arch-linux-resolved/152/3
# Driver:

git clone https://github.com/RASPIAUDIO/WM8960-Audio-HAT.git
#git clone https://github.com/RASPIAUDIO/ultra2.git
cd WM8960-Audio-HAT
sudo ./install.sh
# External microphone input and headphones output:
wget https://raw.githubusercontent.com/RASPIAUDIO/WM8960-Audio-HAT/master/preset_external_jack_microphone_input2
alsactl --file preset_external_jack_microphone_input2 restore 0
# sudo arecord -f cd -Dhw:0


## Reaper:
sudo chown -R 1000:1000 /opt
cd /opt
wget https://www.reaper.fm/files/6.x/reaper673_linux_aarch64.tar.xz
tar -xvf reaper673_linux_aarch64.tar.xz
reaper_linux_aarch64/REAPER/reaper

dtoverlay=i2s-mmap

dtparam=i2s=on
dtoverlay=wm8960-soundcard

dtparam i2c_arm=on
modprobe i2c-dev
dtoverlay wm8960-soundcard

/etc/wm8960-soundcard/