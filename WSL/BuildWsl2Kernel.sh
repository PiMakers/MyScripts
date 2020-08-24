#!/bin/bash

##BUILD wsl kernel
# https://medium.com/@centerorbit/installing-wiwsl.exe --unregister  Ubuntu-20.04reguard-in-wsl-2-dd676520cb21
# https://tinkerboarding.co.uk/forum/archive/index.php/thread-1968.html
# The kernel is located at C:\Windows\System32\lxss\tools\kernel in Windows

installDependencies() {
    sudo apt install -y bison build-essential flex libssl-dev libelf-dev #1>/dev/null &
    #pids[0]=$!
}

open-iscsi.mod() {
    cat << EOF > PiMaker/open-iscsi.mod
##########*
#* PiMaker
##########*
#* Open iscsi
CONFIG_INET=y                   #* PiMaker
CONFIG_BLK_DEV_SD=y             #* PiMaker
CONFIG_SCSI_LOWLEVEL=y          #* PiMaker
CONFIG_ISCSI_TCP=m              #* PiMaker
CONFIG_SCSI_ISCSI_ATTRS=m       #* PiMaker
EOF
echo "Added $0"
}

cloneKernelSrc() {
    pwd=$PWD
    SRC_DIR=/mnt/LinuxData/OF/GitHub/
    cd ${SRC_DIR}
    [ -d WSL2-Linux-Kernel ] || \
    git clone --depth 1 https://github.com/microsoft/WSL2-Linux-Kernel.git #1>/dev/null &
    #pids[1]=$!
    cd WSL2-Linux-Kernel
    echo "# PiMaker\nPiMaker" > .gitignore
    git pull
    mkdir -pv PiMaker
    cp Microsoft/config-wsl PiMaker/PiMaker-config-wsl2
    open-iscsi.mod
    sed -i '/#\*/d' PiMaker/PiMaker-config-wsl2
    cat PiMaker/*.mod >> PiMaker/PiMaker-config-wsl2

    sudo make -j $(nproc) clean  
    #sudo make  -j $(nproc) KCONFIG_CONFIG=PiMaker/PiMaker-config-wsl2
    #sudo make  -j $(nproc) KCONFIG_CONFIG=Microsoft/config-wsl
    #cd /lib/modules
    #sudo ln -s 4.19.84-microsoft-standard+/ /lib/modules/4.19.84-microsoft-standard
    
    #sudo make -j $(nproc)
    sudo make -j $(nproc) modules_install
    sudo make -j $(nproc) install INSTALL_PATH="/mnt/i/wsl/Kernel"
    cd $pwd
    echo "Done!"
}

writeWslConf() {
    CONF_DIR='cmd.exe /c echo "%userprofile%"'
}

orig() {
    pwd=$PWD
    SRC_DIR=/mnt/LinuxData/OF/GitHub/
    cd ${SRC_DIR}
    [ -d WSL2-Linux-Kernel ] || \
        git clone --depth 1 https://github.com/microsoft/WSL2-Linux-Kernel.git
        git clone --depth 1 https://github.com/open-iscsi/open-iscsi.git
    
    cd WSL2-Linux-Kernel
    # git clone --depth 1 https://git.zx2c4.com/wireguard-linux-compat
    # git clone --depth 1 https://git.zx2c4.com/wireguard-tools
    sudo bash -c 'zcat /proc/config.gz > .config'
    sudo make -j $(nproc)
    sudo make -j $(nproc) modules_install
    sudo modprobe iscsi_tcp libiscsi libiscsi_tcp scsi_transport_iscsi

}
installDependencies
#cloneKernelSrc
orig

# wait for all pids
for pid in ${pids[*]}; do
    wait $pid
done