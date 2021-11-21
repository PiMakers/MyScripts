# parse-vt-settings-dev-tty0-permission-denied
gpasswd -a dietpi tty

# xf86OpenConsole: Cannot open virtual console NOT WORKS!!!
sudo sed '/needs_root_rights=yes/!d' /etc/X11/Xwrapper.config
echo "needs_root_rights=yes" |sudo tee -a /etc/X11/Xwrapper.config


# login as root lsb-release comand not found
apt install lsb-release
apt purge --autoremove chromium-browser
apt install chromium