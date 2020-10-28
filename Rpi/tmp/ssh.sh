#!/bin/bash
#set -e

set_var() {

	[ $(which zenity) ] && VAR=$(zenity --entry --text=${1//_/__} --entry-text=${2//_/__}) || \
	echo "zenity not installed"
	export ${1}=${VAR} || echo error
}

clear_vars() {
	for var in $var_list
	do
		export $var=""
	done
}

ssh_defaults () {
	local var_list	#="TARGET_HOST SSH_CLIENT_USER"

	[ -z $TARGET_HOST ] && var_list+=' TARGET_HOST'			#|| TARGET_HOST=raspberrypi.local 
	[ -z $SSH_CLIENT_USER ] && var_list+=' SSH_CLIENT_USER'	#|| && SSH_CLIENT_USER=${USER}
	[ -z $SSH_CLIENT_HOST ] && var_list+=' SSH_CLIENT_HOST'	#|| && SSH_CLIENT_HOST=$(hostname)
	[ -z $SSH_COMMENT ] && var_list+=' SSH_COMMENT'		#&& c="${SSH_CLIENT_USER}@${SSH_CLIENT_HOST}"

	echo $var_list
	for var in $var_list
	do
		echo $var
		set_var $var 

	done

	client_user=${SSH_CLIENT_USER} && echo "client_user = $client_user"	
	client_host=${SSH_CLIENT_HOST} && echo "client_host = $client_host"
	
	target_host=${TARGET_HOST} && echo "target_host = $target_host"
	# target_ip="192.168.0.102" && echo "target ip = $target_ip"
	target_ip="$target_host" && echo "target ip = $target_ip"
	login=${SSH_CLIENT_USER} && echo "login name = $login"
	passwd="raspi" && echo "password = $passwd"
	# ssh-keygen -c [-P passphrase] [-C comment] [-f keyfile]
	ssh_keyname="$USER@$target_host" && echo "default ssh_keyname = $ssh_keyname"
	ssh_key_path="$HOME/.ssh/" && echo "default ssh_key_path = $ssh_key_path"
	passphrase="Pepe374189" && echo "default passphrase = $passphrase"
	comment=${SSH_COMMENT} && echo "default comment = $comment"
#	default_port="22" && echo "default port = $default_port"
}

check_root() {
    # Must be root to install the hotspot
    echo ":::"
    if [[ $EUID -eq 0 ]];then
        echo "::: You are root - OK"
    else
        echo "::: sudo will be used for the install."
        # Check if it is actually installed
        # If it isn't, exit because the install cannot complete
        if [[ $(dpkg-query -s sudo) ]];then
            export SUDO="sudo"
            export SUDOE="sudo -E"
        else
            echo "::: Please install sudo or run this as root."
            exit 1
        fi
    fi
}

ssh_key_copy() {
# uncomit if any
# dryrun="-n"
force="-f"
options="-o IdentitiesOnly=yes $force $dryrun"
#
keyfile=$ssh_key_path$ssh_keyname
	ssh-keygen -f "$HOME/.ssh/known_hosts" -R ${target_ip}
	[ -f $keyfile ] || ssh-keygen -N $passphrase -C $comment -f $keyfile || echo "ERROR: ssh-keygen -N $passphrase -C $comment -f $keyfile!!!"
	ssh-copy-id $options -i $ssh_key_path$ssh_keyname $login@$target_ip || echo "copyKey error"
 	
#	ssh -o IdentitiesOnly=yes pi@raspberrypi.local || echo "ERROR"
	echo "test newly created key for ${login}@${target_ip}..."
	options=
	ssh $options $login@${target_ip} echo "success!!!!" || echo "$login@${target_ip} Bassza meg something went wrong!!!"
	unset TARGET_HOST SSH_CLIENT_USER SSH_CLIENT_HOST TARGET_HOST
}

others () {
	#remove/not working ones
	ssh-keygen -f "/home/pimaker/.ssh/known_hosts" -R $target_ip

	#On Host
	##!!!!! ssh-keygen -t rsa -C pi@pi2
	ssh $login@$target_ip -p $port 'mkdir -p .ssh'
	cat ~/.ssh/$USER_rsa.pub | ssh $login@$target_ip 'cat >> .ssh/authorized_keys' #///First You may check the existence of '$HOME/.ssh'


	#if [ -d !$HOME/.ssh ]; then mkdir $HOME/.ssh
	#cat ~/.ssh/PiMaker_rsa.pub | ssh pi@192.168.0.58 'cat >> .ssh/authorized_keys'
}

#. helper.script
check_root
ssh_defaults
ssh_key_copy