# parse-vt-settings-dev-tty0-permission-denied
gpasswd -a dietpi tty


arm_64bit=1
initial_turbo=60
hdmi_enable_4kp60=1
over_voltage=15
arm_freq_min=100
arm_freq=2350
gpu_freq=750
gpu_mem=512

# /etc/lightdm/lightdm.conf
xserver-command=X -nocursor
# xf86OpenConsole: Cannot open virtual console NOT WORKS!!!
sudo sed '/needs_root_rights=yes/!d' /etc/X11/Xwrapper.config
echo "needs_root_rights=yes" |sudo tee -a /etc/X11/Xwrapper.config


# login as root lsb-release comand not found
apt install lsb-release
apt purge --autoremove chromium-browser
apt install chromium

sudo apt install libnss3 libatk1.0-0 libatk-bridge2.0-0 libgtk3.0

echo "$export_options" > /etc/chromium.d/custom_flags

# Chromium 60+
G_EXEC cp /etc/chromium.d/custom_flags /root/.chromium-browser.init

"--start-fullscreen \
--kiosk --incognito \
--noerrdialogs \
--disable-translate \
--no-first-run \
--fast \
--fast-start \
--disable-infobars \
--disable-features=TranslateUI \
--disk-cache-dir=/dev/null \
--password-store=basic \
--disable-pinch \
--overscroll-history-navigation=disabled \
--disable-features=TouchpadOverscrollHistoryNavigation"

	# Autostart run script for Kiosk mode, based on @AYapejian https://github.com/MichaIng/DietPi/issues/1737#issue-318697621
	cat << '_EOF_' > /var/lib/dietpi/dietpi-software/installed/chromium-autostart.sh
#!/bin/bash
# Autostart run script for Kiosk mode, based on @AYapejian https://github.com/MichaIng/DietPi/issues/1737#issue-318697621
# - Please see /root/.chromium-browser.init (and /etc/chromium.d/custom_flags) for additional egl/gl init options

# Command line switches https://peter.sh/experiments/chromium-command-line-switches/
# --test-type gets rid of some of the chromium warnings that you may or may not care about in kiosk on a LAN
# --pull-to-refresh=1
# --ash-host-window-bounds="400,300"

# Resolution to use for kiosk mode, should ideally match current system resolution
RES_X=$(sed -n '/^[[:blank:]]*SOFTWARE_CHROMIUM_RES_X=/{s/^[^=]*=//p;q}' /boot/dietpi.txt)
RES_Y=$(sed -n '/^[[:blank:]]*SOFTWARE_CHROMIUM_RES_Y=/{s/^[^=]*=//p;q}' /boot/dietpi.txt)

CHROMIUM_OPTS="--kiosk --test-type --window-size=$RES_X,$RES_Y --start-fullscreen --start-maximized --window-position=0,0"
# If you want tablet mode, uncomment the next line.
#CHROMIUM_OPTS+=' --force-tablet-mode --tablet-ui'

# Add URL for first run:
URL=$(sed -n '/^[[:blank:]]*SOFTWARE_CHROMIUM_AUTOSTART_URL=/{s/^[^=]*=//p;q}' /boot/dietpi.txt)
CHROMIUM_OPTS+=" --homepage $URL"

# Find absolute filepath location of Chromium binary.
FP_CHROMIUM=$(command -v chromium)
if [[ ! $FP_CHROMIUM ]]; then

	# Assume RPi
	FP_CHROMIUM="$(command -v chromium-browser)"

fi

xinit $FP_CHROMIUM $CHROMIUM_OPTS
_EOF_