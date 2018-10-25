#! /bin/bash

# change these to suit
HOSTNAME=MESH
THISSSID=Pi-Mesh
THISKEY=0000000000
MAINSSID=XXXXXXXXXXXXXXXXXXXXX
MAINKEY=XXXXXXXXXX
# this must be full path - change to suit
SHAREDDRIVE=/srv/http

if [ ! -f /boot/firststage ]; then
  # this section overclocks the Pi and sets gpu_mem for 16 - may not be needed for other applications
  sed -i 's/#arm_freq=900/arm_freq=900/' /boot/config.txt
  sed -i 's/#core_freq=333/core_freq=333/' /boot/config.txt
  sed -i 's/#sdram_freq=450/sdram_freq=450/' /boot/config.txt
  sed -i 's/#over_voltage=2/over_voltage=2/' /boot/config.txt
  sed -i 's/gpu_mem/#gpu_mem/g' /boot/config.txt
  sed -i 's/cma_/#cma_/g' /boot/config.txt
  echo -e "gpu_mem=16\n" >> /boot/config.txt

  cp /etc/netctl/examples/wireless-wpa /etc/netctl/ || { echo "Unable to copy default netctl wireless file. Exiting"; exit 1; }
  sed -i "s/MyNetwork/$MAINSSID/" /etc/netctl/wireless-wpa || { echo "Unable to sed SSID for main network (slash in SSID?). Exiting"; exit 1; }
  sed -i "s/'WirelessKey'/$MAINKEY/" /etc/netctl/wireless-wpa || { echo "Unable to sed key for main network. Exiting"; exit 1; }
  # this line sets up ntp - something your application may not need
  echo -e "\nExecUpPost='/usr/bin/ntpd -gq || true'\n" | tee -a /etc/netctl/wireless-wpa
  # this line sets GMT timezone - change to suit
  timedatectl set-timezone GMT
  
  netctl enable wireless-wpa

  hostnamectl set-hostname ${HOSTNAME}
  
  fdisk /dev/mmcblk0 <<HDHD
d
2
n
e



n
l


w
HDHD
  touch /boot/firststage
  reboot
fi

if [ -f /boot/secondstage ]; then
  echo "It appears that the first and second stages have already been run - exiting"
  exit
fi

if [ ! -f /boot/secondstage ]; then
  resize2fs /dev/mmcblk0p5 || { echo "Unable to resize SD card. Exiting"; exit 1; }
  pacman-key --init || echo "Unable to init pacman.  Proceeding anyway" 
  pacman -Syu --noconfirm || echo "Unable to update system.  Proceeding anyway"
  sync
  pacman -S --noconfirm --needed screen samba smbclient base-devel unzip iptables dhcp libnl1 || { echo "Unable to download files from AUR. Are we connected to the internet?  Exiting"; exit 1; }
  mv /etc/dhcpd.conf /etc/dhcpd.conf.example 
  tee /etc/dhcpd.conf << HDHD || { echo "Unable to change dhcpd.conf.  Exiting"; exit 1; }
ddns-update-style none;
default-lease-time 600;
max-lease-time 7200;
authoritative;
subnet 192.168.42.0 netmask 255.255.255.0 {
range 192.168.42.10 192.168.42.50;
option broadcast-address 192.168.42.255;
option routers 192.168.42.1;
default-lease-time 600;
max-lease-time 7200;
option domain-name "local";
option domain-name-servers 8.8.8.8, 8.8.4.4;
}
HDHD
  cd /root/
#  wget --no-check-certificate http://www.dropbox.com/s/rcxkbidv7a3t9kk/hostapd-rtl8192cu-0.8-1.src.tar.gz
  wget http://www.dropbox.com/s/rcxkbidv7a3t9kk/hostapd-rtl8192cu-0.8-1.src.tar.gz || { echo "Unable to fetch patched hostapd - exiting"; exit 1; }
  tar -zxvf hostapd*
  cd hostapd*
  makepkg --asroot || { echo "Unable to make hostapd package - exiting"; exit 1; }
  pacman -U --noconfirm *.xz || { echo "Unable to install hostapd package - exiting"; exit 1; }
  mv /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.example
  tee /etc/hostapd/hostapd.conf << HDHD || { echo "Unable to write hostapd config - exiting"; exit 1; }
interface=wlan1
driver=rtl871xdrv
ssid=$THISSSID
hw_mode=g
channel=6
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$THISKEY
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP  
HDHD

  tee /etc/systemd/system/mesh.service << HDHD || { echo "Unable to write systemd file - exiting"; exit 1; }
[Unit]
Description= mesh setup service
After=network.target
[Service]
Type=oneshot
RemainAfterExit=yes
# reset static IP
ExecStart=/usr/bin/sh -c "/usr/bin/ip addr del 192.168.42.1/24 dev wlan1; exit 0"
ExecStart=/usr/bin/ip link set up dev wlan1
ExecStart=/usr/bin/ip addr add 192.168.42.1/24 dev wlan1
# start ip forwarding
ExecStart=/usr/bin/sysctl -w net.ipv4.ip_forward=1
# clear IP table rules
ExecStart=/usr/bin/iptables -F
ExecStart=/usr/bin/iptables -t nat -F
# use IP tables to route internet forwarding
ExecStart=/usr/bin/iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
ExecStart=/usr/bin/iptables -A FORWARD -i wlan0 -o wlan1 -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStart=/usr/bin/iptables -A FORWARD -i wlan1 -o wlan0 -j ACCEPT
# start dhcpd and hostapd
ExecStart=/usr/bin/systemctl restart dhcpd4
ExecStart=/usr/bin/systemctl restart hostapd

ExecStop=/usr/bin/systemctl stop dhcpd4
ExecStop=/usr/bin/systemctl stop hostapd
ExecStop=/usr/bin/iptables -F
ExecStop=/usr/bin/iptables -t nat -F
[Install]
WantedBy=multi-user.target
HDHD

  if [ ! -f /etc/samba/smb.conf ]; then
    cp /etc/samba/smb.conf.default /etc/samba/smb.conf
  fi

  mkdir -p ${SHAREDDRIVE}

  comp=`cat /etc/samba/smb.conf | grep '\[MESHDrive\]'`
  if [ ! "$comp" = "MESHDrive" ]; then
    tee -a /etc/samba/smb.conf << HDHD || { echo "Unable to update samba config. Exiting"; exit 1; }
[MESHDrive]
comment = MESHDrive
path = $SHAREDDRIVE
writeable = yes
guest ok = yes
create mask = 0777
directory mask = 0777
read only = no
browseable = yes
force user = root
public = yes
HDHD
    sed -i '
/security = user/ i\
    map to guest = Bad User
' /etc/samba/smb.conf || { echo "Unable to update samba config. Exiting"; exit 1; }
    sed -i 's/MYGROUP/WORKGROUP/' /etc/samba/smb.conf || { echo "Unable to update samba config. Exiting"; exit 1; }
  fi
  
  systemctl enable smbd
  systemctl enable nmbd
  ststemctl enable ntpd
  systemctl enable mesh.service
  touch /boot/secondstage
  sync && reboot
fi
  


