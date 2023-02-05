# sudo cp /mnt/LinuxData/OF/myGitHub/MyScripts/Works/ZIK/autostart.sh /tftpLE
SERVEDR_IP=192.168.1.20

mkdir -p /media/OF && mount -onolock ${SERVEDR_IP}:/mnt/LinuxData/OF /media/OF
mkdir /storage/script
cp /media/OF/myGitHub/MyScripts/Works/ZIK/magnofal.py /storage/script/autoexec.py

# cp /media/OF/ZIK/ /var/media/STORAGE/videos
ls /var/media/STORAGE/videos/* > /storage/.kodi/userdata/playlists/video/zik.m3u
# systemctl restart kodi
# cat .kodi/temp/kodi.log