# https://github.com/shayne/wsl2-hacks
## Auto-start/services (systemd and snap support)
LC_ALL=C
SUDO=sudo
# 1. 
install_deps() {
    ${SUDO} apt update
    ${SUDO} apt install dbus policykit-1 daemonize
}
# 2.
create_fake_bash() {
    #cat << EOF | ${SUDO} tee /usr/bin/Bash
    ${SUDO} bash -c "cat > /usr/bin/bash" << EOF
    #!/bin/bash
    # your WSL2 username
    UNAME=${USER}

    UUID=\$(id -u "\${UNAME}")
    UGID=\$(id -g "\${UNAME}")
    UHOME=\$(getent passwd "\${UNAME}" | cut -d: -f6)
    USHELL=\$(getent passwd "\${UNAME}" | cut -d: -f7)

    if [[ -p /dev/stdin || "\${BASH_ARGC}" > 0 && "\${BASH_ARGV[1]}" != "-c" ]]; then
        USHELL=/bin/bash
    fi

    if [[ "\${PWD}" = "/root" ]]; then
        cd "\${UHOME}"
    fi

    # get pid of systemd
    SYSTEMD_PID=\$(pgrep -xo systemd)

    # if we're already in the systemd environment
    if [[ "\${SYSTEMD_PID}" -eq "1" ]]; then
        exec "\${USHELL}" "\$@"
    fi

    # start systemd if not started
    /usr/sbin/daemonize -l "\${HOME}/.systemd.lock" /usr/bin/unshare -fp --mount-proc /lib/systemd/systemd --system-unit=basic.target 2>/dev/null
    # wait for systemd to start
    while [[ "\${SYSTEMD_PID}" = "" ]]; do
        sleep 0.05
        SYSTEMD_PID=\$(pgrep -xo systemd)
    done

    # enter systemd namespace
    exec /usr/bin/nsenter -t "\${SYSTEMD_PID}" -m -p --wd="\${PWD}" /sbin/runuser -s "\${USHELL}" "\${UNAME}" -- "\${@}"
EOF
    ${SUDO} chmod +x /bin/Bash
}

# 3. Set the fake-bash as our root user's shell
set_user_shell() {
    [ -f /usr/bin/Bash ] && sudo sed -i '/^root/ s/bash/Bash/' /etc/passwd
    ## 4. Exit out of / close the WSL2 shell
    
    #cmd.exe /c "wsl.exe --default-user root"
    cmd.exe /c "wsl.exe --shutdown"
}

other() {
    "##5. Re-open WSL2

    #Everything should be in place. Fire up WSL via the MS Terminal or just wsl.exe. You should be logged in as your normal user and systemd should be running

    #You can test by running the following in WSL2:

    # systemctl is-active dbus
    #active

    ##6.Create /etc/rc.local (optional)

    #If you want to run certain commands when the WSL2 VM starts up, this is a useful file that's automatically ran by systemd.

    #sudo touch /etc/rc.local
    #sudo chmod +x /etc/rc.local
    #sudo editor /etc/rc.local
    #Add the following:

    #!/bin/sh -e

    # your commands here...

    #exit 0
    #/etc/rc.local is only run on "boot", so only when you first access WSL2 (or it's shutdown due to inactivity/no-processes). To test you can shutdown WSL via PowerShell/CMD wsl --shutdown then start it back up with wsl
    "
}

install() {
    install_deps
    create_fake_bash
    set_user_shell
}