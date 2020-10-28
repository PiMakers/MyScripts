#!/bin/bash
#20.04 focal:

depInstall() {
sudo apt -qqq install curl git-core fonts-noto-cjk-extra

git config --global user.email "PiMakers@gmail.com"
git config --global user.name "pimaker"

sudo snap install code
}

noPwd() {
    echo "FUNCNAME = ${FUNCNAME[0]}   ${BASH_SOURCE[0]}"
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/010_${USER}-nopasswd
    sudo chmod 440 /etc/sudoers.d/010_${USER}-nopasswd
}
