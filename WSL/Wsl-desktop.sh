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

## Expanding the size of your WSL 2 Virtual Hardware Disk
## https://docs.microsoft.com/en-us/windows/wsl/compare-versions#wsl-2-architecture
wsl --shutdown
Terminate all WSL instances using the command: wsl --shutdown

Find your distribution installation package name ('PackageFamilyName')

Using PowerShell (where 'distro' is your distribution name) enter the command:
Get-AppxPackage -Name "*<distro>*" | Select PackageFamilyName
Locate the VHD file fullpath used by your WSL 2 installation, this will be your pathToVHD:

%LOCALAPPDATA%\Packages\<PackageFamilyName>\LocalState\<disk>.vhdx
Resize your WSL 2 VHD by completing the following commands:

Open Windows Command Prompt with admin privileges and enter:
diskpart
Select vdisk file="<pathToVHD>"
expand vdisk maximum="<sizeInMegaBytes>"
Launch your WSL distribution (Ubuntu, for example).

## 6. Make WSL aware that it can expand its file system's size by running these commands from your Linux distribution command line:

sudo mount -t devtmpfs none /dev
mount | grep ext4
Copy the name of this entry, which will look like: /dev/sdXX (with the X representing any other character)
sudo resize2fs /dev/sdXX
Use the value you copied earlier. You may also need to install resize2fs: apt install resize2fs

## WSL2 script
echo export DISPLAY=$(ipconfig.exe | grep IPv4 | cut -d: -f2 | sed -n -e '/^ 172/d' -e 's/ \([0-9\.]*\).*/\1:0.0/p') >> ~/.profile
sudo mkdir -p /run/user/1000
echo export XDG_RUNTIME_DIR=/run/user/1000 >> ~/.profile
echo export RUNLEVEL=3 >> ~/.profile

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
## https://medium.com/@gulfsteve/hacking-with-wsl2-ede3e649e08d
# NAT WSL 
sed '/nameserver/!d;s/[^ ]* //'  /etc/resolv.conf
# wsl ip
ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
hostname -I