##############################################
# https://github.com/sdesalas/node-pi-zero.git
# https://github.com/audstanley/Node-MongoDb-Pi/
##############################################


# linux 18.04.
# sudo apt update && # sudo apt upgrade
# sudo apt install npm node-gyp nodejs-dev libssl1.0-dev
# sudo apt autoclean && sudo apt clean && sudo apt autoremove

#!/bin/bash
set -e

detectSyystem () {
    uname -a
}

tmp=$(sed '/^ID=/!d; s/^ID=//'  /etc/os-release) && [ "$tmp" = "raspbian" ] || ( echo -e "RunThisScript on raspbian" && exit 111 )

BASE_URL=https://nodejs.org/dist
ARCH=armv6l # linux: armv6l | armv7l | arm64 | x64 | x86 | ppc64le | s390x
VERSION=latest-v8.x ## should be etc: latest,  v7.2.1, or latest-v7.x
#SUBVERSION=8.x
#DL_URL=${BASE_URL}/${VERSION}${SUBVERSION#^*/-}

NODE_JS=$(curl -sL https://nodejs.org/dist/${VERSION} | grep "${ARCH}.tar.xz" | cut -d'"' -f2)

wget ${BASE_URL}/${VERSION}/${NODE_JS} -O /tmp/${NODE_JS}

sudo tar -xvf /tmp/${NODE_JS} -C /tmp/

([ -f /opt/nodejs ] && sudo rm -r /opt/nodejs && echo "removing old nodejs...") || \

sudo mv /tmp/${NODE_JS:: -7} /opt/nodejs${VERSION/latest-/}

# Remove existing symlinks
sudo unlink /usr/bin/node || true
sudo unlink /usr/sbin/node || true
sudo unlink /sbin/node || true
sudo unlink /usr/local/bin/node || true
sudo unlink /usr/bin/npm || true
sudo unlink /usr/sbin/npm || true
sudo unlink /sbin/npm || true
sudo unlink /usr/local/bin/npm || true

# Create symlinks to node && npm
sudo ln -s /opt/nodejs${VERSION/latest-/}/bin/node /usr/bin/node;
sudo ln -s /opt/nodejs${VERSION/latest-/}/bin/node /usr/sbin/node;
sudo ln -s /opt/nodejs${VERSION/latest-/}/bin/node /sbin/node;
sudo ln -s /opt/nodejs${VERSION/latest-/}/bin/node /usr/local/bin/node;
sudo ln -s /opt/nodejs${VERSION/latest-/}/bin/npm /usr/bin/npm;
sudo ln -s /opt/nodejs${VERSION/latest-/}/bin/npm /usr/sbin/npm;
sudo ln -s /opt/nodejs${VERSION/latest-/}/bin/npm /sbin/npm;
sudo ln -s /opt/nodejs${VERSION/latest-/}/bin/npm /usr/local/bin/npm;

# curl https://raw.githubusercontent.com/PiMakers/MyScripts/edit/Rpi/setUp/setupTI.sh | bash -s