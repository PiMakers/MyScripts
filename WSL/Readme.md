# https://seanthegeek.net/234/graphical-linux-applications-bash-ubuntu-windows/
# https://docs.microsoft.com/hu-hu/windows/wsl/install-win10

## Enable the Windows Subsystem for Linux feature
# Open a PowerShell prompt as administrator and run:

Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

## Install Bash on Ubuntu on Windows
# Open a command prompt as your normal user
# Run bash
# After you have accepted the license, the Ubuntu user mode image will be downloaded, and a “Bash on Ubuntu on Windows” shortcut will be added to your Start Menu.
# After you have accepted the license, the Ubuntu user mode image will be downloaded, and a “Bash on Ubuntu on Windows” shortcut will be added to your Start Menu.

# After installation your Linux distribution will be located at: %localappdata%\lxss\ This directory is marked as a hidden system folder.

# The first time you install Bash on Ubuntu on Windows, you will be prompted to create a UNIX username and password.

# This UNIX username and password has no relationship to your Windows username and password, and it can be different. 

# After you have set up your user, update Ubuntu:
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y && sudo apt-get autoremove -y

## Graphical Applications

# In order to run Linux GUI applications on Bash On Ubuntu on Windows, you must:

# Install a X server for Windows
# Configure bash to tell GUIs to use the local X server
# Install VcXsrv
# In order to run graphical Linux applications, you’ll need an X server.

# VcXsrv is the only fully open source and up-do-date native X server for windows.

# Download and run the latest installer: https://sourceforge.net/projects/vcxsrv/
Locate the VcXsrv shortcut in the Start Menu
Right click on it
Select More>Open file location
Copy the VcXsrv shortcut file
Paste the shortcut in %appdata%\Microsoft\Windows\Start Menu\Programs\Startup
Launch VcXsrv for the first time
You may receive a prompt to allow it through your firewall. Cancel/deny this request! Otherwise, other computers on your network could access the server.

A X icon will appear in your system tray.

Configure bash to use the local X server
In bash run:
echo "export DISPLAY=localhost:0.0" >> ~/.bashrc
To have the configuration changes take effect, restart bash, or run:
. ~/.bashrc
Test a graphical application
Install x11-apps
sudo apt-get install x11-apps
Run xeyes
A new window will open, containing a pair of eyes that will follow your mouse movements.

ADD TO userconfig

{
    "terminal.integrated.shell.windows": "C:\\msys64\\usr\\bin\\bash.exe",
    "terminal.integrated.shellArgs.windows": [
        "--login",
    ],
    "terminal.integrated.env.windows": {
        "CHERE_INVOKING": "1",
        "MSYSTEM": "MINGW32",
    },
}

# https://www.reddit.com/r/bashonubuntuonwindows/comments/6ysgn4/guide_to_xfce4_install_in_wsl_for_advanced_noobs/

# ssh -X highd@192.168.0.3 "wsl.exe bash --login -c 'DISPLAY=:0 make -C /mnt/i/DataNTFS/OF/openFrameworks/examples/3d/3DModelLoaderExample'"

## How to run the native Ubuntu desktop on Windows 10
#https://www.zdnet.com/article/how-to-run-run-the-native-ubuntu-desktop-on-windows-10/
sudo sed -i 's/<listen>.*<\/listen>/<listen>tcp:host=localhost,port=0<\/listen>/' /etc/dbus-1/session.conf

##Ubuntu 18.04, DBUS Fix Instructions with Troubleshooting
https://www.reddit.com/r/bashonubuntuonwindows/comments/9lpc0o/ubuntu_1804_dbus_fix_instructions_with/s

