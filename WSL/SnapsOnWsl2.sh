## https://forum.snapcraft.io/t/running-snaps-on-wsl2-insiders-only-for-now/13033
## https://github.com/damionGans/ubuntu-wsl2-systemd-script

install_deps() {
    #sudo apt-get update && \
    sudo apt install -yqq daemonize dbus-user-session fontconfig
}

create_start_namespace() {
    cat << EOF | sed 's/^.\{4\}//' | sudo tee /usr/sbin/start-systemd-namespace
    #!/bin/sh

    SYSTEMD_EXE="/lib/systemd/systemd --system-unit=basic.target"
    SYSTEMD_PID="\$(ps -eo pid=,args= | awk '$2" "\$3=="'"\$SYSTEMD_EXE"'" {print $1}')"
    if [ "\$LOGNAME" != "root" ] && ( [ -z "\$SYSTEMD_PID" ] || [ "\$SYSTEMD_PID" != "1" ] ); then
        export | sed -e 's/^declare -x //;/^IFS=".*[^"]$/{N;s/\n//}' |\\
            grep -E -v "^(BASH|BASH_ENV|DIRSTACK|EUID|GROUPS|HOME|HOSTNAME|\\
                        IFS|LANG|LOGNAME|MACHTYPE|MAIL|NAME|OLDPWD|OPTERR|\\
                        OSTYPE|PATH|PIPESTATUS|POSIXLY_CORRECT|PPID|PS1|PS4|\\
                        SHELL|SHELLOPTS|SHLVL|SYSTEMD_PID|UID|USER|_)(=|\$)" \\
                        > "\$HOME/.systemd-env"
        export PRE_NAMESPACE_PATH="\$PATH"
        export PRE_NAMESPACE_PWD="\$(pwd)"
        exec sudo /usr/sbin/enter-systemd-namespace "\$BASH_EXECUTION_STRING"
    fi
    if [ -n "\$PRE_NAMESPACE_PATH" ]; then
        export PATH="\$PRE_NAMESPACE_PATH"
        unset PRE_NAMESPACE_PATH
    fi
    if [ -n "\$PRE_NAMESPACE_PWD" ]; then
        cd "\$PRE_NAMESPACE_PWD"
        unset PRE_NAMESPACE_PWD
    fi
EOF
}

create_enter_namespace() {
    cat << EOF | sed 's/^.\{4\}//' | sudo tee /usr/sbin/enter-systemd-namespace
    #!/bin/bash
    
    if [ "\$UID" != 0 ]; then
        echo "You need to run \$0 through sudo"
        exit 1
    fi

    export SUDO_USER=\$USER

    SYSTEMD_PID="\$(ps -ef | grep '/lib/systemd/systemd --system-unit=basic.target$' | grep -v unshare | awk '{print $2}')"
    if [ -z "\$SYSTEMD_PID" ]; then
        /usr/bin/daemonize /usr/bin/unshare --fork --pid --mount-proc /lib/systemd/systemd --system-unit=basic.target
        while [ -z "\$SYSTEMD_PID" ]; do
            SYSTEMD_PID="\$(ps -ef | grep '/lib/systemd/systemd --system-unit=basic.target$' | grep -v unshare | awk '{print \$2}')"
        done
    fi

    if [ -n "\$SYSTEMD_PID" ] && [ "\$SYSTEMD_PID" != "1" ]; then
        if [ -n "\$1" ] && [ "\$1" != "bash --login" ] && [ "\$1" != "/bin/bash --login" ]; then
            exec /usr/bin/nsenter -t "\$SYSTEMD_PID" -a \\
                /usr/bin/sudo -H -u "\$SUDO_USER" \\
                /bin/bash -c 'set -a; source "\$HOME/.systemd-env"; set +a; exec bash -c '"\$(printf "%q" "\$@")"
        else
            exec /usr/bin/nsenter -t "\$SYSTEMD_PID" -a \\
                /bin/login -p -f "\$SUDO_USER" \\
                \$(/bin/cat "\$HOME/.systemd-env" | grep -v "^PATH=")
        fi
        echo "Existential crisis"
    fi
EOF
sudo chmod +x /usr/sbin/enter-systemd-namespace
}

add_sudoers_rule() {
    cat << EOF | sed 's/^.\{4\}//' | sudo tee /etc/sudoers.d/01-systemd-namespace
    Defaults        env_keep += WSLPATH
    Defaults        env_keep += WSLENV
    Defaults        env_keep += WSL_INTEROP
    Defaults        env_keep += WSL_DISTRO_NAME
    Defaults        env_keep += PRE_NAMESPACE_PATH
    %sudo ALL=(ALL) NOPASSWD: /usr/sbin/enter-systemd-namespace
EOF
}

other() {
    # Put this in the 2nd line
    #sudo sed '/PiMaker/d'
    #sudo sed -i '/PiMaker/d;2a# Start or enter a PID namespace in WSL2 #PiMaker\nsource /usr/sbin/start-systemd-namespace #PiMaker\n' /etc/bash.bashrc
    # remove duplicated empty lines
    #sudo sed -i 'N;/^\n$/D;P;D;' /etc/bash.bashrc
    # Visual Studio Code should now correctly enter the namespace when using the WSL Remote extension
    #orig: WSLENV=VSCODE_WSL_EXT_LOCATION/up:VSCODE_SERVER_TAR/up
    cmd.exe /C "setx WSLENV BASH_ENV/u && cmd.exe /C set WSLENV=BASH_ENV/u"
    
    cmd.exe /C  "setx BASH_ENV /etc/bash.bashrc && set BASH_ENV=/etc/bash.bashrc"
}

install() {
    install_deps
    create_start_namespace
    create_enter_namespace
    add_sudoers_rule
    other
}

uninstall() {
    #sudo sed -i '/PiMaker/d;N;/^\n$/D;P;D;' /etc/bash.bashrc
    sudo rm /usr/sbin/start-systemd-namespace \\
            /usr/sbin/enter-systemd-namespace \\
            /etc/sudoers.d/01-systemd-namespace
    cmd.exe /c "setx WSLENV VSCODE_WSL_EXT_LOCATION/up:VSCODE_SERVER_TAR/up && set WSLENV=VSCODE_WSL_EXT_LOCATION/up:VSCODE_SERVER_TAR/up"
    cmd.exe /c "reg DELETE HKCU\Environment /f /v BASH_ENV && set BASH_ENV="
}

#uninstall