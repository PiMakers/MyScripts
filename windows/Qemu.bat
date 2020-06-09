cls
@echo off
set "xPATH=C:\Program Files\qemu"

set "RPI_BOOT=RPI\rpi-boot"
set "IMG_PATH=RPI\img"

"%xPATH%\qemu-system-arm" -M raspi2 -m 1024 ^
    -serial stdio^
    -drive file="%xPATH%\%IMG_PATH%\2020-02-13-raspbian-buster-full.img",format=raw,if=sd ^
    -no-reboot

: %RPI_BOOT%\initrd.img-4.14.0-3-arm64