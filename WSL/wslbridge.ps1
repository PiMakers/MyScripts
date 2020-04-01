# https://github.com/microsoft/WSL/issues/4150

## WSL 2 TPC NETWORK FORWARDING
#Introduction

#With the introduction of WSL 2 Beta, Microsoft has made changes to the system architecture.
#The changes include changing from the default bridged network adapter to a hyper-v virtual network adapter.
#The implementation was not completed during the launch of the beta program. This makes accessing of network resources under WSL 2 complex.
#The work around is to forward the TCP ports of WSL 2 services to the host OS.
#The virtual adapter on WSL 2 machine changes it's ip address during reboot which makes it tough to implement a run once solution.
#Also a side note, windows firewall will block the redirected port.

#The work around is to use a script that does :

#Get Ip Address of WSL 2 machine
#Remove previous port forwarding rules
#Add port Forwarding rules
#Remove previously added firewall rules
#Add new Firewall Rules
#Configuration

#The script must be run at login ,under highest privileges to work, and Powershell must be allowed to run external sources.

#PowerShell Configuration

#Enable power shell to run external scripts, run the command below in power shell with administrative privileges.

#How To:
#Go to search, search for task scheduler. In the actions menu on the right, click on create task.
#Enter Name, go to triggers tab. Create a new trigger, with a begin task as you login, set delay to 10s.
#Go to the actions and add the script. If you are using Laptop, go to settings and enable run on power.

#Finally:
#I am no expert at security nor scripting and technically new to the windows OS.

#Update
#The update adds the feature to remove unwanted firewall rules.
#Here is the script.

#I saved your script in a file called "wslbridge.ps1" and then in Windows Scheduler just set Powershell.exe as Action and as argument I wrote this (instead of setting the Unrestricted ExecutionPolicy):
# -ExecutionPolicy Bypass c:\scripts\wslbridge.ps1


$remoteport = bash.exe -c "ifconfig eth0 | grep 'inet '"
$found = $remoteport -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';

if( $found ){
  $remoteport = $matches[0];
} else{
  echo "The Script Exited, the ip address of WSL 2 cannot be found";
  exit;
}

#[Ports]

#All the ports you want to forward separated by coma
$ports=@(0,69,80,443,10000,3000,5000);


#[Static ip]
#You can change the addr to your ip config to listen to a specific address
$addr='0.0.0.0';
$ports_a = $ports -join ",";


#Remove Firewall Exception Rules
iex "Remove-NetFireWallRule -DisplayName 'WSL2 Firewall Unlock (TCP)' ";
iex "Remove-NetFireWallRule -DisplayName 'WSL2 Firewall Unlock (UDP)' ";


#adding Exception Rules for inbound and outbound Rules
iex "New-NetFireWallRule -DisplayName 'WSL2 Firewall Unlock (TCP)' -Direction Outbound -LocalPort $ports_a -Action Allow -Protocol TCP";
iex "New-NetFireWallRule -DisplayName 'WSL2 Firewall Unlock (TCP)' -Direction Inbound -LocalPort $ports_a -Action Allow -Protocol TCP";
iex "New-NetFireWallRule -DisplayName 'WSL2 Firewall Unlock (UDP)' -Direction Inbound -LocalPort 10000 -Action Allow -Protocol UDP";

for( $i = 0; $i -lt $ports.length; $i++ ){
  $port = $ports[$i];
  iex "netsh interface portproxy delete v4tov4 listenport=$port listenaddress=$addr";
  iex "netsh interface portproxy add v4tov4 listenport=$port listenaddress=$addr connectport=$port connectaddress=$remoteport";
}

#pause