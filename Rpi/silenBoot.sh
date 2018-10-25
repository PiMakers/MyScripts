#!/usr/bin/env bash
set -e
# silent_boot https://scribles.net/silent-boot-on-raspbian-stretch-in-console-mode/

if [ $EUID != 0 ]; then
	echo "this script must be run as root"
	echo ""
	echo "usage:"
	echo "sudo "$0
	exit $exit_code
   exit 1
fi
# Part of raspi-config https://github.com/RPi-Distro/raspi-config
CONFIG=/boot/config.txt

is_raspbian_strech() {
grep -q raspbian /etc/os-release && grep 'Raspbian GNU/Linux 9 (stretch)' /etc/os-release || \
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

silent_boot(){
echo -e "1. Disabling \“Welcome to PIXEL” splash...\"\n"
systemctl mask plymouth-start.service

echo "2. Removing Rainbow Screen...\n"

grep -q '^disable_splash' /boot/config.txt || \
grep -q '# disable_splash' /boot/config.txt && \
sed -i '/^# disable_splash/ s/# //' /boot/config.txt || \
( echo -e "\n# Disable rainbow image at boot\t\t#PubHub" >> /boot/config.txt && \
echo -e "disable_splash=1\t\t\t#PubHub" >> /boot/config.txt )

echo -e "3. Removing Raspberry Pi logo and blinking cursor\n"
echo -e "by adding \"logo.nologo vt.global_cursor_default=0\" at the end of the line in \"/boot/cmdline.txt\".\n"
	grep -q 'logo.nologo' /boot/cmdline.txt || sed -i 's/$/ logo.nologo/' /boot/cmdline.txt
	grep -q 'vt.global_cursor_default=0' /boot/cmdline.txt || sed -i 's/$/ vt.global_cursor_default=0/' /boot/cmdline.txt

echo -e "4. Removing login message\n"
touch ~/.hushlogin

echo -e "5. Remove autologin message by modify autologin service\n"
sed -i '/^ExecStart=/ s/--autologin pi --noclear/--skip-login --noclear --noissue --login-options "-f pi"/' /etc/systemd/system/autologin\@.service
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
do_about
silent_boot
