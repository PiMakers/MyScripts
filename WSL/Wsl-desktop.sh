## https://dev.to/darksmile92/linux-on-windows-wsl-with-desktop-environment-via-rdp-522g

sudo apt update && sudo apt -y upgrade
sudo apt -y install xfce4
## WSL with Desktop Environment via RDP
sudo apt-get install xrdp
sudo cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.bak
sudo sed -i 's/3389/3390/g' /etc/xrdp/xrdp.ini
sudo sed -i 's/max_bpp=32/#max_bpp=32\nmax_bpp=128/g' /etc/xrdp/xrdp.ini
sudo sed -i 's/xserverbpp=24/#xserverbpp=24\nxserverbpp=128/g' /etc/xrdp/xrdp.ini
sudo /etc/init.d/xrdp start

## https://www.makeuseof.com/tag/linux-desktop-windows-subsystem/
## https://askubuntu.com/questions/1162808/run-ubuntu-desktop-on-wsl-ubuntu-18-04-lts
# VcXsrv - https://sourceforge.net/projects/vcxsrv/files/latest/download
# Xming - https://sourceforge.net/projects/xming/files/latest/download

export DISPLAY=:0
export LIBGL_ALWAYS_INDIRECT=1

# extra ?? mount usb drive: sudo mount -t drvfs D: /mnt/d

# https://www.reddit.com/r/bashonubuntuonwindows/comments/6ysgn4/guide_to_xfce4_install_in_wsl_for_advanced_noobs/
# https://www.zdnet.com/article/how-to-run-run-the-native-ubuntu-desktop-on-windows-10/

# The basic Display variable required for graphical programs to work with the windows Xserver

export DISPLAY=:0
export XDG_RUNTIME_DIR=your dir of choice. # This isn't set by default i made a temporary dir in my home folder and it exports there. 
export RUNLEVEL=3 # System Runlevel required for some apps to install without warnings. 
sudo /etc/init.d/dbus start # A way to almost perfectly start dbus with far less error's this auto creates the missing dbus folder as well

## https://github.com/famelis/wsl2-x11/tree/master/VcXsrv
## wsl2:
# Install VcXsrv:
# Install WSL:
## https://www.tenforums.com/tutorials/3436-run-administrator-windows-10-a.html#option1
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
# Install Ubuntu from the store:
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install ubuntu-desktop # sudo apt install lxde && startlxde
sudo service dbus start
sudo service x11-common start
gnome-shell --x11 -r
export DISPLAY=$(ipconfig.exe | grep IPv4 | cut -d: -f2 | sed -n -e '/^ 172/d' -e 's/ \([0-9\.]*\).*/\1:0.0/p') #export DISPLAY=192.168.1.10:0