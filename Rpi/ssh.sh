#!/bin/bash
#set -e

ssh_defaults () {
	client_user=${USER} && echo "default client_user = $client_user"	
	client_host=$(hostname) && echo "default client_host = $client_host"
	
	target_host=Rpi3Dev && echo "default target_host = $target_host"
	target_ip="192.168.0.102" && echo "default target ip = $target_ip"
	target_ip="$target_host.local" && echo "default target ip = $target_ip"
	login="pi"&& echo "default login name = $login"
	passwd="raspi" && echo "default password = $passwd"
	# ssh-keygen -c [-P passphrase] [-C comment] [-f keyfile]
	ssh_keyname="$USER@$target_host" && echo "default ssh_keyname = $ssh_keyname"
	ssh_key_path="$HOME/.ssh/" && echo "default ssh_key_path = $ssh_key_path"
	passphrase="Pepe374189" && echo "default passphrase = $passphrase"
	comment="$client_user@$client_host" && echo "default comment = $comment"
	default_port="20" && echo "default port = $default_port"
}

ssh_key_copy(){
# uncomit if any
#dryrun="-n"
#force="-f"
keyfile=$ssh_key_path$ssh_keyname

	[ -f $keyfile ] || ssh-keygen -N $passphrase -C $comment -f $keyfile || echo "ERROR: generating keyfile!!!"
	ssh-copy-id $dryrun $force -i $ssh_key_path$ssh_keyname $login@$target_ip || ( echo "copyKey error" && \
 	ssh-keygen -f "$HOME/.ssh/known_hosts" -R ${target_ip} )
	ssh $login@${target_ip} || echo "$login@${target_ip} & bassza meg!!!!"
}

others(){
#remove/not working ones
ssh-keygen -f "/home/pimaker/.ssh/known_hosts" -R $target_ip

#On Host
##!!!!! ssh-keygen -t rsa -C pi@pi2
ssh $login@$target_ip -p $port 'mkdir -p .ssh'
cat ~/.ssh/$USER_rsa.pub | ssh $login@$target_ip 'cat >> .ssh/authorized_keys' #///First You may check the existence of '$HOME/.ssh'


#if [ -d !$HOME/.ssh ]; then mkdir $HOME/.ssh
#cat ~/.ssh/PiMaker_rsa.pub | ssh pi@192.168.0.58 'cat >> .ssh/authorized_keys'
}

. helper.script
check_root
ssh_defaults
ssh_key_copy
