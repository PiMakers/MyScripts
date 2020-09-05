#!/bin/bash


username=administrator
password=1sti3Fr16

check_root() {
    # Must be root to install the hotspot
    echo ":::"
    if [[ $EUID -eq 0 ]];then
        echo "::: You are root - OK"
    else
        echo "::: sudo will be used for the install."
        # Check if it is actually installed
        # If it isn't, exit because the install cannot complete
        if [[ $(dpkg-query -s sudo) ]];then
            export SUDO="sudo"
            export SUDOE="sudo -E"
        else
            echo "::: Please install sudo or run this as root."
            exit
        fi
    fi
}

# not used
remove_unused() {
    sudo apt purge -y mu-editor minecraft-pi libreoffice-pi scratch* wolfram* claws-mail nodered piwiz \
                        greenfoot* \
                        bluej  \
                        geany* \
                        smartsim*
    sudo apt autoremove -y && sudo apt update && sudo apt upgrade -y && sudo apt autoclean && sudo apt clean
}

installDependencies() {
    # make dirs
    ${SUDO} mkdir -pv ~/SMBmounts
    # update img
    ${SUDO} apt update && apt -y upgrade
    # samba
    ${SUDO} apt install samba samba-common-bin smbclient cifs-utils
    # pip install python-vlc
    ${SUDO} pip3 install python-vlc
}

mount_SMBshare() {
    ## create credentials
    cat << EOF | sed 's/^.\{8\}//' | ${SUDO} tee /root/.SMBcreds >/dev/null
        #slideShow
        username=${username}
        password=${password}
EOF
    ${SUDO} chmod 600 /root/.SMBcreds
    ## remove previous settings if any
    ${SUDO} sed -i '/#slideShow/d' /etc/fstab
    ## prepare fstab for samba share
    cat << EOF | sed 's/^.\{8\}//' | ${SUDO} tee -a /etc/fstab 1>/dev/null
        #slideShow mount point for images/videos share :
        //192.168.1.1/Cellule_de_communication/Projecteur/Actif     /home/pi/SMBmount    cifs    credentials=/root/.SMBcreds,uid=1000,gid=1000 0 0  #slideShow
EOF
    ## mount
    ${SUDO} mount -a
}

create_slideshowPlayer(){
    cat << EOF | sed 's/^.\{8\}//' | ${SUDO} tee ~/Slideshow.py
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

autoStart() {
    ${SUDO} sed -i '/#slideShow/d' ~/home/pi/.profile
    echo "python3 /home/pi/Slideshow.py         #slideShow" | sudo tee -a /home/pi/.profile 1>/dev/null
}

run() {
    check_root
}

[ "${BASH_SOURCE}" == "${0}" ] && run

exit