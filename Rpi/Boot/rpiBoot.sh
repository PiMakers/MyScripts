## 

DEV_DIR=/mnt/LinuxData/OF
GIT_DIR=GitHub
mkdir -pv ${DEV_DIR}/${GIT_DIR}
cd ${DEV_DIR}/${GIT_DIR}

git clone --depth=1 https://github.com/raspberrypi/usbboot
cd usbboot

sudo apt install libusb-1.0-0-dev

make -j

sudo ./rpiboot -v