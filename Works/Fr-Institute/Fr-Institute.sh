#!/bin/bash

remove_unused() {
sudo apt purge -y mu-editor minecraft-pi libreoffice-pi scratch* wolfram* claws-mail nodered piwiz \
                    greenfoot* \
                    bluej  \
                    geany* \
                    smartsim*
sudo apt autoremove -y && sudo apt update && sudo apt upgrade -y && sudo apt autoclean && sudo apt clean
}

# samba
sudo apt install samba samba-common-bin smbclient cifs-utils

# pip install python-vlc
pip3 install python-vlc 

mkdir /home/pi/SMBmounts




echo "python3 /home/pi/Slideshow.py" | sudo tee -a /home/pi/.profile

#username=administrator
#password=1sti3Fr16

username=highd
password=ZZSJR5qWs
mount_SMBshare() {
    ## create credentials
    cat << EOF | sudo tee /root/.SMBcreds
#slideShow
username=${username}
password=${password}
EOF
    sudo chmod 600 /root/.SMBcreds
    ## remove previous settings if any
    ${SUDO} sed -i '/#slideShow/d' /etc/fstab
    ## prepare fstab for samba share
    cat << EOF | ${SUDO} tee -a /etc/fstab
#slideShow mount point for images/videos share :
//192.168.1.69/tmpShare   /home/pi/SMBmount   cifs  credentials=/root/.SMBcreds,uid=1000,gid=1000 0 0   #slideShow
EOF
## mount
${SUDO} mount -oremount -a
}


create_slideshow(){
    cat > /home/pi/Slideshow.py << EOF
import pygame
import sys
import vlc
import os
import re
from PIL import Image


filesdir = '/home/pi/SMBmount/'

imgexts = ['png', 'jpg', 'jpeg']
videxts = ['mp4', 'mkv', 'avi']

time = 5  # Time to display every img

#filtering out non video and non image files in the directory using regex
showlist = [filename for filename in os.listdir(filesdir) if re.search('[' + '|'.join(imgexts + videxts) + ']$', filename.lower())]

pygame.init()

size = (pygame.display.Info().current_w, pygame.display.Info().current_h)

screen = pygame.display.set_mode(size)

clock = pygame.time.Clock()

while True:
    try:
        # For every file in filesdir :
        for filename in showlist:
            filenamelower = filename.lower()

            # If image:
            if filenamelower.endswith('.png') or filenamelower.endswith('.jpg') or filenamelower.endswith('.jpeg'):
                fullname = filesdir + filename
                img = pygame.image.load(fullname).convert()
                imgrect = img.get_rect()

                # If image is not same dimensions
                if imgrect.size != size:
                    img = Image.open(fullname)
                    img = img.resize(size, Image.ANTIALIAS)  # Resize to fit the screen
                    if filenamelower.endswith('.png'):
                        img =img.convert(mode='P', palette=Image.ADAPTIVE)  # Convert the image to 8bits (256 colors) to optimize file size.
                    img.save(fullname, optimize=True, quality=95)
                    img = pygame.image.load(fullname).convert()
                    imgrect = img.get_rect()

                screen.blit(img, imgrect)
                pygame.mouse.set_visible(False)
                pygame.display.flip()

            # Elif video:
            elif filenamelower.endswith('.mp4') or filenamelower.endswith('.mkv') or filenamelower.endswith('.avi'):
                fullname = filesdir + filename
                # Create instane of VLC and create reference to movie.
                vlcInstance = vlc.Instance("--aout=adummy")
                media = vlcInstance.media_new(fullname)

                # Create new instance of vlc player
                player = vlcInstance.media_player_new()

                # Load movie into vlc player instance
                player.set_media(media)

                # Start movie playback
                player.play()

                # Do not continue if video not finished
                while player.get_state() != vlc.State.Ended:
                    # Quit if keyboard pressed during video
                    for event in pygame.event.get():
                        if event.type == pygame.KEYDOWN:
                            pygame.display.quit()
                            pygame.quit()
                            sys.exit()
                player.stop()

            clock.tick(1 / time)  # framerate = 0.25 means 1 frame each 4 seconds

            # Quit if keyboard pressed during video
            for event in pygame.event.get():
                if event.type == pygame.KEYDOWN:
                    pygame.display.quit()
                    pygame.quit()
                    sys.exit()
    except:
        pass
EOF

}