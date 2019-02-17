##############################################
# https://github.com/sdesalas/node-pi-zero.git
# https://github.com/audstanley/Node-MongoDb-Pi/
##############################################


#!/bin/bash
set -e

detectSyystem () {
    uname -a
}

tmp=$(sed '/^ID=/!d; s/^ID=//'  /etc/os-release) && [ "$tmp" = "raspbian" ] || ( echo -e "RunThisScript on raspbian" && exit 111 )

ARCH=armv6l
VERSION=latest ## should be etc: latest,  v7.2.1, or latest-v7.x

NODE_JS=$(curl -sL https://nodejs.org/dist/${VERSION} | grep "${ARCH}.tar.xz" | cut -d'"' -f2)

wget https://nodejs.org/dist/${VERSION}/${NODE_JS} -O /tmp/${NODE_JS}

sudo tar -xvf /tmp/${NODE_JS} -C /tmp/

([ -f /opt/nodejs ] && sudo rm -r /opt/nodejs && echo "removing old nodejs...") || \

sudo mv /tmp/${NODE_JS:: -7} /opt/nodejs

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
sudo ln -s /opt/nodejs/bin/node /usr/bin/node;
sudo ln -s /opt/nodejs/bin/node /usr/sbin/node;
sudo ln -s /opt/nodejs/bin/node /sbin/node;
sudo ln -s /opt/nodejs/bin/node /usr/local/bin/node;
sudo ln -s /opt/nodejs/bin/npm /usr/bin/npm;
sudo ln -s /opt/nodejs/bin/npm /usr/sbin/npm;
sudo ln -s /opt/nodejs/bin/npm /sbin/npm;
sudo ln -s /opt/nodejs/bin/npm /usr/local/bin/npm;
