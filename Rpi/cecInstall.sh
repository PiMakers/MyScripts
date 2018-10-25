#!/bin/bash


cecInstall {
sudo apt-get -y update
sudo apt-get install -y cmake libudev-dev libxrandr-dev python-dev swig
cd
git clone https://github.com/Pulse-Eight/platform.git
mkdir platform/build
cd platform/build
cmake ..
make -j4
sudo make -j4 install
cd
git clone https://github.com/Pulse-Eight/libcec.git
mkdir libcec/build
cd libcec/build
cmake -DRPI_INCLUDE_DIR=/opt/vc/include -DRPI_LIB_DIR=/opt/vc/lib ..
make -j4
sudo make -j4 install
sudo ldcon
}

cecInstall
