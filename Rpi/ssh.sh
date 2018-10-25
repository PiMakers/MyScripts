#!/bin/bash
set -e

defaults(){
	target_ip="proxy52.remot3.it" && echo "default target ip = $target_ip"	
	login="pi"&& echo "default login name = $login"
	passwd="raspi" && echo "default password = $passwd"
	ssh_keyname="PiMaker@NUC" && echo "default ssh_keyname = $ssh_keyname"
	ssh_key_path="/home/pimaker/.ssh/" && echo "default ssh_key_path = $ssh_key_path"
	port="38377"
}

ssh_key_copy(){
# uncomit if any
#dryrun="-n"
force="-f"

	ssh-copy-id $dryrun $force -i $ssh_key_path$ssh_keyname $login@$target_ip || ( echo "copyKey error" && \
 	ssh-keygen -f "$HOME/.ssh/known_hosts" -R ${target_ip} )
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

defaults
ssh_key_copy
