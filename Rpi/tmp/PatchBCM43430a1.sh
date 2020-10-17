# https://github.com/seemoo-lab/nexmon

# Build patches for bcm43430a1 on the RPI3/Zero W or bcm434355c0 on the RPI3+ using Raspbian (recommended)
# Note: We currently support Kernel Version 4.4 (depricated), 4.9 and 4.14

#!/bin/bash
set -e

# Make sure the following commands are executed as root: 
#TODO 
#sudo su

# Upgrade your Raspbian installation: 
apt-get update && apt-get -y upgrade

# Install the kernel headers to build the driver and some dependencies: 
apt install -y raspberrypi-kernel-headers git libgmp3-dev gawk qpdf bison flex make

#Clone our repository: 
git clone https://github.com/seemoo-lab/nexmon.git

#Go into the root directory of our repository: 
cd nexmon

# Check if /usr/lib/arm-linux-gnueabihf/libisl.so.10 exists, if not, compile it from source:
if [ -z "/usr/lib/arm-linux-gnueabihf/libisl.so.10" ]
	then echo "hurrá"
else
	ROOT="$PWD"
	echo "$ROOT"
	cd buildtools/isl-0.10
	./configure
	make
	make install
	ln -s /usr/local/lib/libisl.so /usr/lib/arm-linux-gnueabihf/libisl.so.10
	cd ../..
	echo "$PWD"	
fi

## Then you can setup the build environment for compiling firmware patches

#Setup the build environment: 
source setup_env.sh

# Compile some build tools and extract the ucode and flashpatches from the original firmware files:
make

# Go to the patches folder for the bcm43430a1/bcm43455c0 chipset:
cd patches/bcm43430a1/7_45_41_46/nexmon/ / patches/bcm43455c0/7_45_154/nexmon/

# Compile a patched firmware:
make

# Generate a backup of your original firmware file:
make backup-firmware

# Install the patched firmware on your RPI3:
make install-firmware

# Install nexutil: from the root directory of our repository switch to the nexutil folder:
cd utilities/nexutil
# Compile and install nexutil:
make && make install
# Optional: remove wpa_supplicant for better control over the WiFi interface:
apt-get remove wpasupplicant

##################################################################################
## Note: To connect to regular access points you have to execute nexutil -m0 first
##################################################################################
