#!/usr/bin/env bash
set -e
# silent_boot https://scribles.net/silent-boot-on-raspbian-stretch-in-console-mode/

check_root() {
    # Must be root to run this script
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
            exit 1
        fi
    fi
}

# Part of raspi-config https://github.com/RPi-Distro/raspi-config
CONFIG=/boot/config.txt

is_raspbian_strech() {
grep 'Raspbian GNU/Linux 9 (stretch)' /etc/os-release || \
(echo -e "This program works only on Raspbian 9 (stretch) OS \nExiting Now...\nBye-bye!" && exit 1)
}

is_pi () {
  ARCH=$(dpkg --print-architecture)
  if [ "$ARCH" = "armhf" ] ; then
    return 0
  else
    return 1
  fi
}


if is_pi ; then
  CMDLINE=/boot/cmdline.txt
else
  CMDLINE=/proc/cmdline
fi

is_pione() {
   if grep -q "^Revision\s*:\s*00[0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo; then
      return 0
   elif grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]0[0-36][0-9a-fA-F]$" /proc/cpuinfo ; then
      return 0
   else
      return 1
   fi
}

is_pitwo() {
   grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]04[0-9a-fA-F]$" /proc/cpuinfo
   return $?
}

is_pizero() {
   grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]0[9cC][0-9a-fA-F]$" /proc/cpuinfo
   return $?
}

get_pi_type() {
   if is_pione; then
      return 1
   elif is_pitwo; then
      return 2
   elif is_pizero; then
	return 0
   else
	return 3
   fi
}

is_live() {
    grep -q "boot=live" $CMDLINE
    return $?
}

is_ssh() {
  if pstree -p | egrep --quiet --extended-regexp ".*sshd.*\($$\)"; then
    return 0
  else
    return 1
  fi
}

# silent_boot https://scribles.net/silent-boot-on-raspbian-stretch-in-console-mode/
silent_boot_to_CLI () {
    echo "Creating backup dirs..."
    echo "PROGNAME= $0"
    BACKUP_DIR=/etc/PiMaker®/BackUp
    ${SUDO} mkdir -p ${BACKUP_DIR} 2>/dev/null
    
    echo -e "1. Set boot to console mode (vs. grafical.target)\n"
    ${SUDO} systemctl set-default multi-user.target
#    ${SUDO} sed -i '/^ExecStart=/ s/--no clear/--skip-login --noclear --noissue --login-options "-f pi"/' /lib/systemd/system/getty@.service
    echo "2. Remove autologin message by modify autologin service\n"
#    ${SUDO} raspi-config nonint do_boot_behaviour B2
   
   # sudo rm /etc/systemd/system/getty.target.wants/getty@tty1.service
      ${SUDO} ln -fs /etc/systemd/system/autologin@.service /lib/systemd/system/getty.target.wants/getty@tty1.service
      AUTO_LOGIN_USER=pi
      ${SUDO} bash -c 'cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf' << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --noclear --skip-login --login-options "-f ${AUTO_LOGIN_USER}" %I ${TERM}
EOF

    echo "3. Disabling \“Welcome to PIXEL” splash...\"\n"
    ${SUDO} systemctl mask plymouth-start.service

    echo "4. Removing Rainbow Screen...\n"

    ${SUDO} grep '^disable_splash' /boot/config.txt || \
    ${SUDO} grep '# disable_splash' /boot/config.txt && \
    ${SUDO} sed -i '/^# disable_splash/ s/# //' /boot/config.txt || \
        ( ${SUDO}  bash -c 'echo -e "\n# Disable rainbow image at boot\t\t#PubHub" >> /boot/config.txt' && \
        ${SUDO}  bash -c 'echo -e "disable_splash=1\t\t\t#PubHub" >> /boot/config.txt' )

    echo "5. Removing: Raspberry Pi logo and blinking cursor\n Adding: 'loglevel=3' from/to /boot/cmdline.txt"
    echo -e "by adding \"logo.nologo vt.global_cursor_default=0\" at the end of the line in \"/boot/cmdline.txt\".\n"
	   ${SUDO} grep 'logo.nologo' /boot/cmdline.txt || ${SUDO} sed -i 's/$/ logo.nologo/' /boot/cmdline.txt
      ${SUDO} sed -i 's/ vt.global_cursor_default=0//' /boot/cmdline.txt
      ${SUDO} sed -i 's/$/ vt.global_cursor_default=0/' /boot/cmdline.txt
    # remove boot messages:
      ${SUDO} sed -i 's/ loglevel=[01245]//; s/$/ loglevel=3/' /boot/cmdline.txt
    
    echo "6. Removing login message\n"
    ${SUDO} touch ~/.hushlogin
}


silent_boot_to_CLIXXX () {
   echo "backUp"
   BACKUP_DIR=/etc/PiMaker®/BackUp
   [ -d $BACKUP_DIR ] || ${SUDO} mkdir -p ${BACKUP_DIR} 2>/dev/null   

   echo -e "1. Set autologin to CLI without any message\n"
      #${SUDO} sed -i '/^ExecStart=/ s/--autologin pi --noclear/--skip-login --noclear --noissue --login-options "-f pi"/' /etc/systemd/system/autologin@.service
      # /etc/systemd/system/getty@tty1.service.d/autologin.conf ExecStart=-/sbin/agetty --autologin pi --noclear %I xterm-256color
      #${SUDO} sed -i '/^ExecStart=/ s/--autologin pi --noclear/--skip-login --noclear --noissue --login-options "-f pi"/' /etc/systemd/system/getty@tty1.service.d/autologin.conf
      # Login to CLI
      ${SUDO} raspi-config nonint do_boot_behaviour B2 # boot to: B1 console; B2 console autologin B3 desktop B4 desktop autologin 
      ${SUDO} bash -c 'cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf' << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $SUDO_USER --noclear %I $TERM
EOF

   echo "2. Disabling \“Welcome to PIXEL” splash...\"\n"
      ${SUDO} systemctl mask plymouth-start.service

   echo "3. Removing Rainbow Screen...\n"
      ${SUDO} sed -i '/disable_splash/!d s/# //' /boot/config.txt || \
      ${SUDO} sudo sed -i '/disable_splash/d' /boot/config.txt
      ${SUDO} sudo sed -i '$ a \\ndisable_splash=1' /boot/config.txt

   echo "4. Removing: Raspberry Pi logo and blinking cursor\n Adding: 'loglevel=3' from/to /boot/cmdline.txt"
   echo "by adding \"logo.nologo vt.global_cursor_default=0\" at the end of the line in \"/boot/cmdline.txt\".\n"
      ${SUDO} grep 'logo.nologo' /boot/cmdline.txt || ${SUDO} sed -i 's/$/ logo.nologo/' /boot/cmdline.txt
      ${SUDO} grep 'vt.global_cursor_default=0' /boot/cmdline.txt || ${SUDO} sed -i 's/$/ vt.global_cursor_default=0/' /boot/cmdline.txt
     (${SUDO} grep 'loglevel=[012345]' /boot/cmdline.txt || ${SUDO} sed -i 's/$/ loglevel=3/' /boot/cmdline.txt) || echo "Raspbian Lite Not Detected!!\n"

   echo "5. Removing login message\n"
      ${SUDO} touch ~/.hushlogin
}

do_about() {
  whiptail --msgbox "\
This tool provides a straight-forward way of doing initial
configuration of the Raspberry Pi. Although it can be run
at any time, some of the options may have difficulties if
you have heavily customised your installation.\
" 20 70 1
}



#is_raspbian_strech
check_root
#do_about
silent_boot_to_CLI
#silent_boot_to_CLIXXX
