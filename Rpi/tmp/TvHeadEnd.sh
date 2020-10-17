sudo apt update && sudo apt upgrade

sudo apt install gettext cmake

git clone https://github.com/tvheadend/tvheadend.git

cd tvheadend

./configure


sudo wget -qO- https://doozer.io/keys/tvheadend/tvheadend/pgp | sudo apt-key add

echo "deb http://apt.tvheadend.org/stable raspbian-stretch main" | sudo tee -a /etc/apt/sources.list.d/tvheadend.list
echo "deb http://apt.tvheadend.org/unstable raspbian-stretch main" | sudo tee -a /etc/apt/sources.list.d/tvheadend.list
## Ubuntu
#1. Pick a Build Type

#For the stable PPA containing daily builds from the latest stable branch:
sudo apt-add-repository ppa:mamarley/tvheadend-git-stable

# For the unstable PPA containing daily builds from master:
# sudo apt-add-repository ppa:mamarley/tvheadend-git

#2. Update Sources

sudo apt update
# 3. Install

sudo apt install tvheadend

sudo dpkg-reconfigure tvheadend
sudo service tvheadend restart