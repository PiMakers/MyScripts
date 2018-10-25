# https://github.com/Pulse-Eight/libcec/blob/master/docs/README.raspberrypi.md

#!/bin/bash
set -e


# CrossComplie:
# cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/CrossCompile.cmake \
#      -DXCOMPILE_BASE_PATH=/path/to/tools/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi \
#      -DXCOMPILE_LIB_PATH="$RPI_ROOT"/opt/vc/lib \
#      -DRPI_INCLUDE_DIR="$RPI_ROOT"/opt/vc/include \
#      -DRPI_LIB_DIR="$RPI_ROOT/opt/vc/lib" \

#TODO
# Check Rpi or Cross

function cecInstall() {
sudo apt-get -y update
sudo apt-get install -y cmake libudev-dev libxrandr-dev python-dev swig
cd
[ ! -d "platform" ] || rm -Rf "platform" && git clone https://github.com/Pulse-Eight/platform.git
mkdir platform/build
cd platform/build
cmake ..
make -j4
sudo make -j4 install
cd
[ ! -d "libcec" ] || rm -Rf "libcec" && git clone https://github.com/Pulse-Eight/libcec.git
mkdir libcec/build
cd libcec/build
cmake -DRPI_INCLUDE_DIR=/opt/vc/include -DRPI_LIB_DIR=/opt/vc/lib ..
make -j4
sudo make -j4 install
sudo ldconfig
}

cecInstall