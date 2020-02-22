## https://www.domoticz.com/wiki/Setting_up_overlayFS_on_Raspberry_Pi
## https://www.kernel.org/doc/Documentation/filesystems/overlayfs.txt
#!/bin/bash

cd /tmp
wget https://github.com/hansrune/domoticz-contrib/raw/master/utils/mount_overlay
## wget https://github.com/hansrune/domoticz-contrib/raw/master/init.d/saveoverlays-stretch
wget https://raw.githubusercontent.com/hansrune/domoticz-contrib/master/services/saveoverlays
wget https://github.com/hansrune/domoticz-contrib/raw/master/utils/rootro
## wget https://github.com/hansrune/domoticz-contrib/raw/master/init.d/syncoverlayfs.service
wget https://raw.githubusercontent.com/hansrune/domoticz-contrib/master/services/syncoverlayfs.service
## mv saveoverlays-stretch saveoverlays
sudo chmod a+rx saveoverlays mount_overlay rootro
sudo cp mount_overlay /usr/local/bin/
sudo cp saveoverlays /etc/init.d/
sudo cp rootro /usr/local/bin/
sudo ln -s rootro /usr/local/bin/rootrw
sudo cp syncoverlayfs.service /lib/systemd/system/

## Configuration
# In /lib/systemd/system/syncoverlayfs.service, make sure that RequiresMountsFor contains all overlayfs mounts

# Optionally, create /etc/default/saveoverlays with parameters like these defaults:

 KILLPROCS="domoticz mosquitto" # processes to kill before sync, just in case still running
 PRIORITYFILES="/var/log/fake-hwclock.data /var/lib/domoticz/domoticz.db" # files to sync before everything else

## Backup and recovery
# In case of errors, it is a good idea to backup the below. You can then mount the modified SD card on another machine.

sudo cp -v /boot/cmdline.txt /boot/cmdline.txt-orig
sudo cp -v /etc/fstab /etc/fstab-orig
cd /var
sudo tar --exclude=swap -cf /var-orig.tar

# Stop using swap

sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall 
sudo update-rc.d dphys-swapfile disable
# For raspian Jessie and later, also do
sudo systemctl disable dphys-swapfile

## Move files you need to be able to update with a read-only root
## Some files may need to be continously updated after all changes are done. For example, if you use the fake-hwclock service, the data file for that service need to be moved:

## sudo systemctl disable fake-hwclock.service
sudo systemctl stop fake-hwclock.service
sudo mv /etc/fake-hwclock.data /var/log/fake-hwclock.data
sudo ln -s /var/log/fake-hwclock.data /etc/fake-hwclock.data

## Set up the syncoverlayfs service
#This syncoverlayfs service will take care of saving changes from the overlays back to the underlying SD card storage (now the _org part of the overlay). It also contains some logic to check if the fake clock data should be loaded. If you are not using the fake-hwclock service, you should comment that out (two places).
#The overlays are automatically detected, so you should not need to change any of that.
#Enable the service as follows:
sudo systemctl daemon-reload
sudo systemctl enable syncoverlayfs.service
#/etc/systemd/system/multi-user.target.wants/syncoverlayfs.service -> /lib/systemd/system/syncoverlayfs.service

## Change boot command line
#Change /boot/cmdline.txt similar to this, i.e. add noswap fastboot ro.
#In Raspbian Stretch root=/dev/mmcblk0p2 is different and looks like: root=PARTUUID=badee776-02

dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait noswap fastboot ro

## Update /etc/fstab for read-only SD card
# /etc/fstab need to be updated similar to this:

proc            /proc           proc    defaults    0 0
/dev/mmcblk0p1  /boot           vfat    ro          0 2
/dev/mmcblk0p2  /               ext4    ro,noatime  0 1
mount_overlay   /var            fuse    nofail,defaults 0 0
mount_overlay   /home           fuse    nofail,defaults 0 0
none            /tmp            tmpfs   defaults    0 0

## Stop services These services may have files open or may otherwise disturb the changes to be made
for S in nginx domoticz fail2ban shellinabox mosquitto cron ntp nodered rsyslog influxdb; do sudo systemctl stop $S; done

## Prepare the overlay directories
# Then change into layered mount setups as follows (as user root):

sudo su - 
for D in /etc
do
  mv -v ${D} ${D}_org
  cd ${D}_org
  find . | cpio -pdum ${D}_stage
  mkdir -v ${D} ${D}_rw ${D}/.overlaysync ${D}_org/.overlaysync
done
exit

## Loopback mount /home and /var before boot
# This is to make sure the next reboot does not run into trouble due to moved data (rsync with delete). When root is not read-only, this will result in /var_org being loopback mounted to /var, and /home_orig loopback mounted to /home

sudo mount /home
sudo mount /var


# Testing hints:
#       sudo mount -o remount,ro / 
#       sudo env INIT_VERBOSE=yes /etc/init.d/saveoverlays stop
#       cat /var/log/saveoverlays.log  