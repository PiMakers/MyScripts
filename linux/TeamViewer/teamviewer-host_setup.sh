#x https://pimylifeup.com/raspberry-pi-teamviewer/
#!/bin/bash



PWD=Borsi@2021

#curl https://download.teamviewer.com/download/linux/teamviewer-host_armhf.deb -O

sudo apt update
[ -f teamviewer-host_armhf.deb ] || wget https://download.teamviewer.com/download/linux/teamviewer-host_armhf.deb
sudo dpkg -i teamviewer-host_armhf.deb
sudo apt -y --fix-broken install
# accept license
teamviewer license accept
sudo teamviewer passwd ${PWD}
# sudo teamviewer info
# get ID
TeamViewerID=$(teamviewer info | sudo sed '/TeamViewer ID:/!d; s/.*  //')
sudo teamviewer setup
sleep 5

exit

tmp() {
[ -z TEAMVIEWER_PASSWD ] && TEAMVIEWER_PASSWD=passwd
echo "TEAMVIEWER_PASSWDs=$TEAMVIEWER_PASSWD"

sudo cp src/teamviewer.list /etc/apt/sources.list.d/teamviewer.list
sudo apt-key add src/TeamViewer2017.asc
sudo apt update
sudo apt install teamviewer-host -y

teamviewer --daemon restart

#get teamviewer id
teamviewer info

#set a password 
sudo teamviewer passwd ${TEAMVIEWER_PASSWD}   # any

# get ID
TeamViewerID=$(teamviewer info | sed '/TeamViewer ID:/!d; s/.*  //')

# teamviewer                           Start TeamViewer user interface (if not running). 

 # teamviewer help                      Print this help screen. 
 # teamviewer version                   Print version information. 
 # teamviewer info                      Print version, status, id. 
 # teamviewer ziplog                    Create a zip containing all teamviewer logs (useful when contacting support). 

 # teamviewer license [show|accept]     Interactively agree or show/agree to End User License Agreement. 
 # teamviewer setup                     Configure headless modes (non-gui/console) 

 # teamviewer passwd [PASSWD]           Set a password (useful when installing remote (ssh). 

 # teamviewer daemon status             Show current status of the TeamViewer daemon. 
 # teamviewer daemon start              Start		TeamViewer daemon. 
 # teamviewer daemon stop               Stop		TeamViewer daemon. 
 # teamviewer daemon restart            Stop/Start	TeamViewer daemon. 
 # teamviewer daemon disable            Disable	TeamViewer daemon - don't start daemon on system startup. 
 # teamviewer daemon enable             Enable		TeamViewer daemon - start daemon on system startup (default). 

 # teamviewer repo                      show current repository configuration 
 # teamviewer repo list                 list available packages 
 # teamviewer repo default              restore default configuration 
 # teamviewer repo disable              disable repository updates 
 # teamviewer repo main [stable]        make all TeamViewer packages available (default) 
 # teamviewer repo tv14 [stable]        make TeamViewer 14 packages available stable omit preview and beta releases 
}