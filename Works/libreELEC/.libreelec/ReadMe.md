# https://wiki.libreelec.tv/

# https://archive.libreelec.tv/releases.json
# https://archive.libreelec.tv/?C=M;O=D


# https://test.libreelec.tv/
# https://test.libreelec.tv/releases.json

/home/pimaker/McELEC/build.LibreELEC-RPi4.arm-10.0.2/image/system/usr/lib/kodi/kodi-config
/storage/.kodi/temp/done


ROOT=/home/pimaker/McELEC
# create " /storage/.cache/services/sshd.conf" to enable sshd service at startup
sed '/services/d' ${ROOT}/packages/network/openssh/tmpfiles.d/z_04_openssh.conf
cat << EOF >> ${ROOT}/packages/network/openssh/tmpfiles.d/z_04_openssh.conf
# create " /storage/.cache/services/sshd.conf" to enable sshd service at startup
d    /storage/.cache/services            0600 root root - -
f    /storage/.cache/services/sshd.conf  0600 root root - -
EOF

cat << EOF > sudo tee /etc/wsl.conf
[interop]
  enabled=false # enable launch of Windows binaries appendWindowsPath=false # append Windows path to $PATH variable
EOF

# disable kodisplash:
# add to <splash>true</splash> to projects/RPi/kodi/advancedsettings.xml

## add /storage/.config/autostart.sh
disableAutoUpd() {
    echo "# Disable autoUpdate:" > /storage/.config/autostart.sh
    echo "touch > /dev/.update_disabled" >> /storage/.config/autostart.sh
}

## Disable startup wizzard
## Hack or change Estuary or default skin
## add autoexec.py addon
## add rpi-tools addon
## add external player to OS (for sync & multiplay)


# Maps:
special://xbmc/ is mapped to: /usr/share/kodi/
special://xbmcbin/ is mapped to: /usr/lib/kodi
special://xbmcbinaddons/ is mapped to: /usr/lib/kodi/addons
special://masterprofile/ is mapped to: /storage/.kodi/userdata
special://envhome/ is mapped to: /storage
special://home/ is mapped to: /storage/.kodi
special://temp/ is mapped to: /storage/.kodi/temp
special://logpath/ is mapped to: /storage/.kodi/temp
special://xbmc/system/advancedsettings.xml ->  /usr/share/kodi/system/advancedsettings.xml
special://masterprofile/advancedsettings.xml -> /storage/.kodi/userdata/advancedsettings.xml
GUI settings?
special://masterprofile/sources.xml
## Running database version Addons33
## Error getting /usr/lib/kodi/addons
## Error getting special://xbmcbin/addons
## CAddonMgr::FindAddons: game.controller.default v1.0.20 installed
...
## screensaver.xbmc.builtin.black v1.0.34 installed
## screensaver.xbmc.builtin.dim v1.0.64 installed
...
special://xbmc/system/Lircmap.xml
special://xbmc/system/keymaps/appcommand.xml
special://xbmc/system/keymaps/customcontroller.AppleRemote.xml
special://xbmc/system/keymaps/customcontroller.Harmony.xml
special://xbmc/system/keymaps/customcontroller.SiriRemote.xml
special://xbmc/system/keymaps/gamepad.xml
special://xbmc/system/keymaps/joystick.xml
special://xbmc/system/keymaps/keyboard.xml
special://xbmc/system/keymaps/mouse.xml
special://xbmc/system/keymaps/remote.xml
special://xbmc/system/keymaps/touchscreen.xml

=== load skin from: /usr/share/kodi/addons/skin.estuary-modded
colors from /usr/share/kodi/addons/skin.estuary-modded/colors/black.xml
skin includes from /usr/share/kodi/addons/skin.estuary-modded/xml/Includes.xml
fonts from /usr/share/kodi/addons/skin.estuary-modded/xml/Font.xml
custom window XMLs from skin path /usr/share/kodi/addons/skin.estuary-modded/xml:
# skin xml-s to change?:
Custom_1109_TopBarOverlay.xml, load type: LOAD_ON_GUI_INIT
DialogVolumeBar.xml, load type: LOAD_ON_GUI_INIT
DialogBusy.xml, load type: LOAD_ON_GUI_INIT
Pointer.xml, load type: LOAD_ON_GUI_INIT
DialogExtendedProgressBar.xml, load type: LOAD_ON_GUI_INIT
DialogSeekBar.xml, load type: LOAD_ON_GUI_INIT
DialogNotification.xml, load type: LOAD_ON_GUI_INIT
DialogBusy.xml, load type: LOAD_ON_GUI_INIT
resource://resource.uisounds.kodi/sounds.xml
=== skin loaded...

Startup.xml, load type: LOAD_EVERY_TIME
MyVideoNav.xml, load type: KEEP_IN_MEMORY
## ERROR <general>: GetDirectory - Error getting replace
## ERROR <general>: CGUIMediaWindow::GetDirectory(replace) failed
## WARNING <general>: JSONRPC: Could not parse type "Setting.Details.SettingList"
## INFO <general>: JSONRPC: Adding type "Setting.Details.SettingList" to list of incomplete definitions (waiting for "Setting.Details.Setting")
## INFO <general>: JSONRPC: Resolving incomplete types/methods referencing Setting.Details.Setting

special://xbmc/system/playercorefactory.xml
special://masterprofile/playercorefactory.xml
Home.xml