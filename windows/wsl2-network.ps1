#https://gist.github.com/xmeng1/aae4b223e9ccc089911ee764928f5486
$protocol = "TCP"

$remoteport = bash.exe -c "ifconfig eth0 | grep 'inet '"
$found = $remoteport -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';

if( $found ){
  $remoteport = $matches[0];
} else{
  echo "The Script Exited, the ip address of WSL 2 cannot be found";
  exit;
}

#$remoteport = "172.25.64.1"

#[Ports]

#All the ports you want to forward separated by coma
#$ports=@(80,443,10000,3000,5000);
$ports=@(2049,111,2222);

#$ports=@(111);
#[Static ip]
#You can change the addr to your ip config to listen to a specific address
$addr='0.0.0.0';
$ports_a = $ports -join ",";

# Remove Firewall Exception Rules
iex "Remove-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock [$protocol]' ";

#adding Exception Rules for inbound and outbound Rules
iex "New-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock [$protocol]' -Direction Outbound -LocalPort $ports_a -Action Allow -Protocol $protocol";
iex "New-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock [$protocol]' -Direction Inbound -LocalPort $ports_a -Action Allow -Protocol $protocol";

for( $i = 0; $i -lt $ports.length; $i++ ){
  $port = $ports[$i];
  iex "netsh interface portproxy delete v4tov4 listenport=$port listenaddress=$addr";
  iex "netsh interface portproxy delete v4tov4  listenport=$port listenaddress='172.22.96.1'";
  iex "netsh interface portproxy add v4tov4 listenport=$port listenaddress=$addr connectport=$port connectaddress=$remoteport";
  iex "netsh interface portproxy show all"
}

  echo "Wsl ip: $remoteport";
  #pause